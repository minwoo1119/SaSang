import { router } from "expo-router";
import { Image } from "expo-image";
import { Alert, Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Svg, { Path } from "react-native-svg";

type LoginProvider = "Kakao" | "Google";

function KakaoSymbol() {
  return (
    <Svg height={20} viewBox="0 0 24 22" width={22}>
      <Path
        d="M12 1C5.93 1 1 4.82 1 9.53c0 3.02 2.03 5.67 5.08 7.19l-1.04 3.79a.52.52 0 0 0 .8.57l4.55-3.03c.53.06 1.07.1 1.61.1 6.07 0 11-3.82 11-8.52S18.07 1 12 1Z"
        fill="#000000"
      />
    </Svg>
  );
}

function GoogleSymbol() {
  return (
    <Svg height={20} viewBox="0 0 18 18" width={20}>
      <Path
        d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.91c1.7-1.57 2.69-3.88 2.69-6.62Z"
        fill="#4285F4"
      />
      <Path
        d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.91-2.26c-.8.54-1.83.86-3.05.86-2.35 0-4.33-1.58-5.04-3.71H.96v2.33A9 9 0 0 0 9 18Z"
        fill="#34A853"
      />
      <Path
        d="M3.96 10.71A5.41 5.41 0 0 1 3.68 9c0-.59.1-1.16.28-1.71V4.96H.96A9 9 0 0 0 0 9c0 1.45.35 2.82.96 4.04l3-2.33Z"
        fill="#FBBC05"
      />
      <Path
        d="M9 3.58c1.32 0 2.51.45 3.44 1.35l2.58-2.58A8.65 8.65 0 0 0 9 0 9 9 0 0 0 .96 4.96l3 2.33C4.67 5.16 6.65 3.58 9 3.58Z"
        fill="#EA4335"
      />
    </Svg>
  );
}

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
        <Pressable
          accessibilityRole="button"
          onPress={() => showPendingLogin("Kakao")}
          style={({ pressed }) => [
            styles.button,
            styles.kakaoButton,
            pressed && styles.pressed,
          ]}
        >
          <View style={styles.providerMark}>
            <KakaoSymbol />
          </View>
          <Text style={styles.kakaoText}>카카오 로그인</Text>
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
          <View style={styles.providerMark}>
            <GoogleSymbol />
          </View>
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
  button: {
    alignItems: "center",
    borderRadius: 12,
    flexDirection: "row",
    gap: 10,
    height: 56,
    justifyContent: "center",
    paddingHorizontal: 16,
    width: "100%",
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
  googleButton: {
    backgroundColor: "#FFFFFF",
    borderColor: "#747775",
    borderWidth: 1,
  },
  googleText: {
    color: "#1F1F1F",
    fontSize: 14,
    fontWeight: "700",
  },
  guestButton: {
    backgroundColor: "#007AFF",
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
  kakaoButton: {
    backgroundColor: "#FEE500",
  },
  kakaoText: {
    color: "rgba(0, 0, 0, 0.85)",
    fontSize: 15,
    fontWeight: "700",
  },
  pressed: {
    opacity: 0.72,
  },
  providerMark: {
    alignItems: "center",
    height: 24,
    justifyContent: "center",
    width: 24,
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
