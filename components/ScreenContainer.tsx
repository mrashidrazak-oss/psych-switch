// Wraps every screen with consistent dark background and safe-area padding.
// Keeping this here rather than repeating it in each screen.
import { ReactNode } from 'react';
import { ScrollView, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

export function ScreenContainer({
  children,
  scroll = true,
}: {
  children: ReactNode;
  scroll?: boolean;
}) {
  const inner = <View className="flex-1 bg-bg px-5 py-4">{children}</View>;
  return (
    <SafeAreaView className="flex-1 bg-bg" edges={['top', 'left', 'right']}>
      {scroll ? (
        <ScrollView
          className="flex-1 bg-bg"
          contentContainerStyle={{ paddingBottom: 40 }}
        >
          {inner}
        </ScrollView>
      ) : (
        inner
      )}
    </SafeAreaView>
  );
}
