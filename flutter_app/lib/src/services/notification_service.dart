// Local-only monitoring reminders.
//
// When a clinician saves a case, we derive its monitoring plan and
// schedule one local notification per actionable entry (dayOffset ≥ 1)
// at the user's preferred reminder time. Notifications fire on-device
// only — never via a remote push service — so no PHI ever leaves
// the phone, and the feature works offline.
//
// Each notification carries:
//   • Title — the case label ("Mr A · 12/05")
//   • Body  — "Day {N}: {label}" e.g. "Day 7: Lithium level"
//   • Payload — caseId so a tap routes to the right Result screen.
//
// Schedule indices are persisted in SharedPreferences under
// `psychswitch.notifications.{caseId}` as a comma-separated list of
// integer notification ids — used for cancellation when a case is
// deleted or the user opts out.
//
// Per-case cancellation: see [cancelForCase]. Wipe everything: see
// [cancelAll].

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:psychswitch_engine/case_pulse.dart' show SavedCase;
import 'package:psychswitch_engine/monitoring.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  /// Default reminder time-of-day. Settings can override.
  static const int defaultHour = 9;
  static const int defaultMinute = 0;

  /// Android notification channel — set once.
  static const _androidChannelId = 'psychswitch_monitoring';
  static const _androidChannelName = 'Monitoring reminders';
  static const _androidChannelDescription =
      'PsychSwitch fires a local reminder on the day a saved-case '
      'monitoring entry comes due. Strictly on-device — no remote push, '
      'no PHI ever transits a server.';

  /// Initialise the plugin + tz database. Idempotent.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    tzdata.initializeTimeZones();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initSettings);

    // Android 13+: declare the channel so notifications have correct
    // importance + the user can mute via system Settings.
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: _androidChannelDescription,
        ),
      );
    }
  }

  /// Ask the user for permission to post notifications. Idempotent on
  /// iOS; Android only matters from API 33.
  ///
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final ok = await ios?.requestPermissions(alert: true, badge: true) ??
          false;
      return ok;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ok = await android?.requestNotificationsPermission() ?? true;
      return ok;
    }
    return false;
  }

  /// Schedule reminders for a single saved case.
  ///
  /// Wipes any prior schedule for this case before re-scheduling so
  /// double-saves don't double-fire.
  ///
  /// Notification ids are persisted in SharedPreferences under
  /// `psychswitch.notifications.{caseId}` — survives app restarts.
  Future<void> scheduleForCase({
    required SavedCase saved,
    required SwitchingEngine engine,
    required PatientContext context,
    int hour = defaultHour,
    int minute = defaultMinute,
  }) async {
    await init();
    await cancelForCase(saved.id);

    final plan = generateMonitoringPlan(
      fromDrugId: saved.fromDrugId,
      toDrugId: saved.toDrugId,
      context: context,
    );
    final actionable =
        plan.entries.where((e) => e.dayOffset >= 1).toList(growable: false);
    if (actionable.isEmpty) return;

    final start = DateTime.parse(saved.startedISO);
    final ids = <int>[];

    for (final entry in actionable) {
      final fireDay = start.add(Duration(days: entry.dayOffset));
      final fireLocal = DateTime(
        fireDay.year,
        fireDay.month,
        fireDay.day,
        hour,
        minute,
      );
      // Skip if already in the past (case saved late).
      if (fireLocal.isBefore(DateTime.now())) continue;

      final id = _idFor(saved.id, entry.dayOffset);
      ids.add(id);

      await _plugin.zonedSchedule(
        id,
        saved.label.isEmpty
            ? '${engine.getDrug(saved.fromDrugId)?.genericName ?? saved.fromDrugId} → '
                '${engine.getDrug(saved.toDrugId)?.genericName ?? saved.toDrugId}'
            : saved.label,
        'Day ${entry.dayOffset}: ${entry.label}',
        tz.TZDateTime.from(fireLocal, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: saved.id,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Persist ids so we can cancel later.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefKey(saved.id),
      ids.map((i) => i.toString()).toList(),
    );
  }

  /// Cancel any scheduled reminders for this case id.
  Future<void> cancelForCase(String caseId) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefKey(caseId));
    if (stored == null) return;
    for (final s in stored) {
      final id = int.tryParse(s);
      if (id == null) continue;
      await _plugin.cancel(id);
    }
    await prefs.remove(_prefKey(caseId));
  }

  /// Cancel every PsychSwitch reminder. Used by the Settings
  /// destructive action and the disclaimer-revoke flow.
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith('psychswitch.notifications.'))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  static String _prefKey(String caseId) =>
      'psychswitch.notifications.$caseId';

  /// Stable per-(case, dayOffset) integer id within
  /// `flutter_local_notifications`'s int32 namespace. We hash the
  /// caseId to a 24-bit space so the offset can stack on top
  /// without overlapping other cases' ids.
  static int _idFor(String caseId, int dayOffset) {
    var hash = 0;
    for (final code in caseId.codeUnits) {
      hash = (hash * 31 + code) & 0xFFFFFF;
    }
    return (hash << 8) | (dayOffset & 0xFF);
  }
}
