import { router, useLocalSearchParams } from "expo-router";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { findInfoItem } from "@/features/more/models/infoContent";

export function InfoDetailScreen() {
  const insets = useSafeAreaInsets();
  const { type } = useLocalSearchParams<{ type?: string }>();
  const info = findInfoItem(type);

  return (
    <ScrollView
      contentContainerStyle={[
        styles.content,
        { paddingBottom: insets.bottom + 40, paddingTop: insets.top + 16 },
      ]}
      showsVerticalScrollIndicator={false}
      style={styles.container}
    >
      <View style={styles.header}>
        <Pressable
          accessibilityLabel="뒤로 가기"
          accessibilityRole="button"
          onPress={() => router.back()}
          style={({ pressed }) => [
            styles.backButton,
            pressed && styles.backButtonPressed,
          ]}
        >
          <Text style={styles.backIcon}>‹</Text>
        </Pressable>
        <Text style={styles.headerTitle}>약관 및 정보</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.title}>{info.title}</Text>
        {info.body.map((paragraph) => (
          <Text key={paragraph} style={styles.bodyText}>
            {paragraph}
          </Text>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  backButton: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.07)",
    borderRadius: 18,
    borderWidth: StyleSheet.hairlineWidth,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  backButtonPressed: {
    backgroundColor: "#F4F4F5",
  },
  backIcon: {
    color: "#18181B",
    fontSize: 28,
    fontWeight: "500",
    lineHeight: 30,
  },
  bodyText: {
    color: "#52525B",
    fontSize: 15,
    lineHeight: 23,
  },
  container: {
    backgroundColor: "#FAFAFA",
    flex: 1,
  },
  content: {
    gap: 18,
    paddingHorizontal: 20,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
    minHeight: 44,
  },
  headerTitle: {
    color: "#18181B",
    fontSize: 17,
    fontWeight: "800",
  },
  panel: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.07)",
    borderRadius: 20,
    borderWidth: StyleSheet.hairlineWidth,
    gap: 14,
    padding: 18,
  },
  title: {
    color: "#18181B",
    fontSize: 23,
    fontWeight: "800",
    marginBottom: 4,
  },
});
