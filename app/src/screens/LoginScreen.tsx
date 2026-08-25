import { router } from "expo-router";
import { Alert, Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

type LoginProvider = "Kakao" | "Google";

export function LoginScreen() {
  const insets = useSafeAreaInsets();

  const showPendingLogin = (provider: LoginProvider) => {
    Alert.alert(
      `${provider} 로그인`,
      "아직 로그인 연동 전입니다. 지금은 로그인 없이 이용하기를 사용할 수 있어요.",
    );
  };

  const continueAsGuest = () => {
    router.replace("/map");
  };

  return (
    <View
      style={[
        styles.container,
        { paddingBottom: insets.bottom + 24, paddingTop: insets.top + 28 },
      ]}
    >
      <View style={styles.hero}>
        <Text style={styles.brand}>사상</Text>
        <Text style={styles.title}>나의 여행을 지도에 남기다</Text>
        <Text style={styles.description}>
          방문한 지역을 고르고, 그 경계 안에 내 사진을 담아 여행 지도를 완성하세요.
        </Text>
      </View>

      <View style={styles.actions}>
        <Pressable
          accessibilityRole="button"
          onPress={() => showPendingLogin("Kakao")}
          style={({ pressed }) => [
            styles.button,
            styles.kakaoButton,
            pressed && styles.pressed,
          ]}
        >
          <Text style={styles.kakaoMark}>K</Text>
          <Text style={styles.kakaoText}>Kakao로 로그인</Text>
        </Pressable>

        <Pressable
          accessibilityRole="button"
          onPress={() => showPendingLogin("Google")}
          style={({ pressed }) => [
            styles.button,
            styles.googleButton,
            pressed && styles.pressed,
          ]}
        >
          <Text style={styles.googleMark}>G</Text>
          <Text style={styles.googleText}>Google로 로그인</Text>
        </Pressable>

        <Pressable
          accessibilityRole="button"
          onPress={continueAsGuest}
          style={({ pressed }) => [
            styles.button,
            styles.guestButton,
            pressed && styles.pressed,
          ]}
        >
          <Text style={styles.guestText}>로그인 없이 이용하기</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  actions: {
    gap: 12,
    width: "100%",
  },
  brand: {
    color: "#17191D",
    fontSize: 40,
    fontWeight: "800",
    letterSpacing: 0,
    textAlign: "center",
  },
  button: {
    alignItems: "center",
    borderRadius: 8,
    flexDirection: "row",
    gap: 12,
    height: 54,
    justifyContent: "center",
    paddingHorizontal: 18,
    width: "100%",
  },
  container: {
    backgroundColor: "#FAFAFA",
    flex: 1,
    justifyContent: "space-between",
    paddingHorizontal: 24,
  },
  description: {
    color: "#6B7280",
    fontSize: 15,
    lineHeight: 22,
    marginTop: 12,
    textAlign: "center",
  },
  googleButton: {
    backgroundColor: "#FFFFFF",
    borderColor: "#E5E7EB",
    borderWidth: StyleSheet.hairlineWidth,
  },
  googleMark: {
    color: "#18181B",
    fontSize: 18,
    fontWeight: "800",
    width: 18,
  },
  googleText: {
    color: "#1F1F1F",
    fontSize: 16,
    fontWeight: "700",
  },
  guestButton: {
    backgroundColor: "#007AFF",
  },
  guestText: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "700",
  },
  hero: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
    maxWidth: 360,
    width: "100%",
  },
  kakaoButton: {
    backgroundColor: "#FFFFFF",
    borderColor: "#E5E7EB",
    borderWidth: StyleSheet.hairlineWidth,
  },
  kakaoMark: {
    color: "#191600",
    fontSize: 18,
    fontWeight: "900",
    width: 18,
  },
  kakaoText: {
    color: "#191600",
    fontSize: 16,
    fontWeight: "700",
  },
  pressed: {
    opacity: 0.72,
  },
  title: {
    color: "#3F3F46",
    fontSize: 20,
    fontWeight: "700",
    letterSpacing: 0,
    marginTop: 10,
    textAlign: "center",
  },
});
