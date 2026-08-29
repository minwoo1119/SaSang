import { router } from "expo-router";
import { Image } from "expo-image";
import { useEffect } from "react";
import { Alert, Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useLocalSessionStore } from "@/features/auth/store/localSession.store";
import { trackEvent, trackScreenView } from "@/services/analytics/analytics";

export function LoginScreen() {
  const insets = useSafeAreaInsets();
  const startSession = useLocalSessionStore((state) => state.start);

  useEffect(() => {
    void trackScreenView("Login");
  }, []);

  const confirmStart = () => {
    startSession();
    void trackEvent("start_app", { local_storage_agreed: true });
    router.replace("/map");
  };

  const startApp = () => {
    Alert.alert(
      "사진 저장 안내",
      "이 앱에서 사용한 사진은 일체 서버로 전송되지 않으며, 기기 내부에 저장됩니다.",
      [
        {
          style: "cancel",
          text: "취소하기",
        },
        {
          onPress: confirmStart,
          text: "동의하고 시작하기",
        },
      ],
    );
  };

  return (
    <View
      style={[
        styles.container,
        { paddingBottom: insets.bottom + 24, paddingTop: insets.top + 28 },
      ]}
    >
      <View style={styles.heroWrap}>
        <View style={styles.iconSurface}>
          <Image
            contentFit="cover"
            source={require("../../assets/images/icon.png")}
            style={styles.appIcon}
          />
        </View>
        <View style={styles.hero}>
          <Image
            contentFit="contain"
            source={require("../../assets/images/main-text-design.png")}
            style={styles.brandImage}
          />
          <Text style={styles.title}>사진으로 채우는 여행 지도</Text>
          <Text style={styles.description}>
            방문한 지역을 고르고, 그 경계 안에 내 사진을 담아보세요.
          </Text>
        </View>
      </View>

      <View style={styles.actions}>
        <Pressable
          accessibilityRole="button"
          onPress={startApp}
          style={({ pressed }) => [
            styles.startButton,
            pressed && styles.pressed,
          ]}
        >
          <Text style={styles.startText}>시작하기</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  actions: {
    gap: 10,
    width: "100%",
  },
  appIcon: {
    borderRadius: 23,
    height: 76,
    width: 76,
  },
  brandImage: {
    height: 75,
    width: 210,
  },
  container: {
    backgroundColor: "#FAFAFA",
    flex: 1,
    justifyContent: "space-between",
    paddingHorizontal: 24,
  },
  description: {
    color: "#71717A",
    fontSize: 15,
    lineHeight: 22,
    marginTop: 10,
    textAlign: "center",
  },
  startButton: {
    alignItems: "center",
    backgroundColor: "#007AFF",
    borderRadius: 16,
    flexDirection: "row",
    gap: 10,
    height: 56,
    justifyContent: "center",
    paddingHorizontal: 16,
    width: "100%",
  },
  startText: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "800",
  },
  hero: {
    alignItems: "center",
    maxWidth: 360,
    width: "100%",
  },
  heroWrap: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  iconSurface: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderRadius: 31,
    borderWidth: StyleSheet.hairlineWidth,
    height: 94,
    justifyContent: "center",
    marginBottom: 24,
    shadowColor: "#18181B",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 18,
    width: 94,
  },
  pressed: { opacity: 0.78 },
  title: {
    color: "#3F3F46",
    fontSize: 19,
    fontWeight: "700",
    letterSpacing: 0,
    marginTop: 8,
    textAlign: "center",
  },
});
