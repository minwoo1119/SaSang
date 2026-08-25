import { router } from "expo-router";
import { Image } from "expo-image";
import { Alert, Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { SocialLoginButton } from "@/features/auth/components/SocialLoginButton";

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
      <View style={styles.heroWrap}>
        <View style={styles.iconSurface}>
          <Image
            contentFit="cover"
            source={require("../../assets/images/icon.png")}
            style={styles.appIcon}
          />
        </View>
        <View style={styles.hero}>
          <Text style={styles.brand}>사상</Text>
          <Text style={styles.title}>사진으로 채우는 여행 지도</Text>
          <Text style={styles.description}>
            방문한 지역을 고르고, 그 경계 안에 내 사진을 담아보세요.
          </Text>
        </View>
      </View>

      <View style={styles.actions}>
        <SocialLoginButton
          label="카카오 로그인"
          onPress={() => showPendingLogin("Kakao")}
          provider="kakao"
        />
        <SocialLoginButton
          label="Google로 로그인"
          onPress={() => showPendingLogin("Google")}
          provider="google"
        />

        <Pressable
          accessibilityRole="button"
          onPress={continueAsGuest}
          style={({ pressed }) => [
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
    gap: 10,
    width: "100%",
  },
  appIcon: {
    borderRadius: 23,
    height: 76,
    width: 76,
  },
  brand: {
    color: "#18181B",
    fontSize: 34,
    fontWeight: "800",
    letterSpacing: 0,
    textAlign: "center",
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
  guestButton: {
    alignItems: "center",
    backgroundColor: "#007AFF",
    borderRadius: 12,
    flexDirection: "row",
    gap: 10,
    height: 56,
    justifyContent: "center",
    paddingHorizontal: 16,
    width: "100%",
  },
  guestText: {
    color: "#FFFFFF",
    fontSize: 15,
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
  pressed: {
    opacity: 0.72,
  },
  title: {
    color: "#3F3F46",
    fontSize: 19,
    fontWeight: "700",
    letterSpacing: 0,
    marginTop: 8,
    textAlign: "center",
  },
});
