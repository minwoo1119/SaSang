import { StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

export function MoreScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { paddingTop: insets.top + 28 }]}>
      <Text style={styles.title}>더보기</Text>
      <Text style={styles.description}>
        프로필, 설정, 여행 기록 관리는 이후 단계에서 연결됩니다.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: "#F6F4EF",
    flex: 1,
    paddingHorizontal: 24,
  },
  description: {
    color: "#60646C",
    fontSize: 15,
    lineHeight: 22,
    marginTop: 10,
  },
  title: {
    color: "#17191D",
    fontSize: 28,
    fontWeight: "800",
    letterSpacing: 0,
  },
});
