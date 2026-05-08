// Cross-platform "Save case" modal.
//
// Replaces the previous Alert.prompt usage which was iOS-only — on
// Android it returned undefined and the save silently no-op'd, so the
// user pressed "Save" and nothing visibly happened.
//
// This modal works identically on iOS, Android and Web. It renders a
// TextInput pre-filled with a default label, plus Cancel / Save
// buttons. Save is disabled while empty (we always have at least the
// auto-generated default), and the label is trimmed before persist.
import { useEffect, useRef, useState } from 'react';
import {
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  Text,
  TextInput,
  View,
} from 'react-native';
import { confirm, tap } from '../utils/haptics';
import { Icon } from './Icon';

export function SaveCaseModal({
  visible,
  defaultLabel,
  onCancel,
  onSave,
}: {
  visible: boolean;
  defaultLabel: string;
  onCancel: () => void;
  onSave: (label: string) => void;
}) {
  const [label, setLabel] = useState(defaultLabel);
  const inputRef = useRef<TextInput>(null);

  // Reset the field whenever the modal re-opens — otherwise stale
  // input from a previous save lingers across switches.
  useEffect(() => {
    if (visible) setLabel(defaultLabel);
  }, [visible, defaultLabel]);

  // Auto-focus the input when the modal opens. Tiny delay so the
  // animation lands first.
  useEffect(() => {
    if (!visible) return;
    const id = setTimeout(() => inputRef.current?.focus(), 250);
    return () => clearTimeout(id);
  }, [visible]);

  const handleSave = () => {
    confirm();
    const trimmed = label.trim() || defaultLabel;
    onSave(trimmed);
  };

  const handleCancel = () => {
    tap();
    onCancel();
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={handleCancel}
    >
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <Pressable
          style={{
            flex: 1,
            backgroundColor: 'rgba(0,0,0,0.6)',
            justifyContent: 'center',
            paddingHorizontal: 24,
          }}
          onPress={handleCancel}
        >
          {/* Inner Pressable swallows backdrop taps */}
          <Pressable
            onPress={(e) => e.stopPropagation()}
            style={{
              backgroundColor: '#141a22',
              borderRadius: 20,
              borderWidth: 1,
              borderColor: '#1f2933',
              padding: 20,
            }}
          >
            <View className="flex-row items-center mb-3">
              <View className="w-9 h-9 rounded-xl bg-warning/15 border border-warning/30 items-center justify-center mr-3">
                <Icon name="star" size={16} color="#f59e0b" />
              </View>
              <View className="flex-1">
                <Text className="text-text text-base font-bold">Save case</Text>
                <Text className="text-muted text-micro">
                  Local-only · use initials or codes
                </Text>
              </View>
            </View>

            <Text className="text-muted text-xs leading-4 mb-3">
              Never enter patient-identifying data (name, MRN, NRIC, DOB).
              The label is stored on this device only and used to
              identify the case in your saved-cases list.
            </Text>

            <TextInput
              ref={inputRef}
              value={label}
              onChangeText={setLabel}
              placeholder="e.g. Mr A — 12/07"
              placeholderTextColor="#6b7280"
              className="bg-bg border border-border rounded-2xl px-4 py-3 text-text text-base mb-4"
              autoCapitalize="sentences"
              autoCorrect={false}
              returnKeyType="done"
              onSubmitEditing={handleSave}
              maxLength={48}
            />

            <View className="flex-row" style={{ gap: 10 }}>
              <Pressable
                onPress={handleCancel}
                className="flex-1 bg-surface border border-border rounded-2xl py-3 active:opacity-70"
              >
                <Text className="text-text text-sm font-semibold text-center">
                  Cancel
                </Text>
              </Pressable>
              <Pressable
                onPress={handleSave}
                className="flex-1 bg-accent rounded-2xl py-3 active:opacity-80"
              >
                <Text className="text-white text-sm font-bold text-center">
                  Save
                </Text>
              </Pressable>
            </View>

            <Text className="text-muted text-eyebrow text-center mt-3">
              Reminders for the monitoring schedule will be set automatically
              if enabled in Settings.
            </Text>
          </Pressable>
        </Pressable>
      </KeyboardAvoidingView>
    </Modal>
  );
}
