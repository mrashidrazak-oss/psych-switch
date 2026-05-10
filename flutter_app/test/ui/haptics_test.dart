// Haptics helpers — verify each tier emits the expected platform call.
//
// We intercept the SystemChannels.platform method-channel calls and
// assert which `HapticFeedbackType` argument was passed. That's enough
// to lock the tap → selection / confirm → medium / warning → heavy
// contract without standing up a real device.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch/src/ui/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('hapticsTap → HapticFeedbackType.selectionClick', () async {
    await hapticsTap();
    expect(calls, <String>['HapticFeedbackType.selectionClick']);
  });

  test('hapticsConfirm → HapticFeedbackType.mediumImpact', () async {
    await hapticsConfirm();
    expect(calls, <String>['HapticFeedbackType.mediumImpact']);
  });

  test('hapticsWarning → HapticFeedbackType.heavyImpact', () async {
    await hapticsWarning();
    expect(calls, <String>['HapticFeedbackType.heavyImpact']);
  });
}
