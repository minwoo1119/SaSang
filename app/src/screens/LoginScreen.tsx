import { router } from "expo-router";
import { Image } from "expo-image";
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
            <Text style={styles.kakaoMark}>K</Text>
          </View>
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
          <View style={styles.providerMark}>
            <Text style={styles.googleMark}>G</Text>
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
    borderRadius: 18,
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
    borderColor: "#E5E7EB",
    borderWidth: StyleSheet.hairlineWidth,
  },
  googleMark: {
    color: "#18181B",
    fontSize: 15,
    fontWeight: "800",
    lineHeight: 17,
  },
  googleText: {
    color: "#18181B",
    fontSize: 15,
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
    backgroundColor: "#FFFFFF",
    borderColor: "#E5E7EB",
    borderWidth: StyleSheet.hairlineWidth,
  },
  kakaoMark: {
    color: "#191600",
    fontSize: 15,
    fontWeight: "900",
    lineHeight: 17,
  },
  kakaoText: {
    color: "#18181B",
    fontSize: 15,
    fontWeight: "700",
  },
  pressed: {
    opacity: 0.72,
  },
  providerMark: {
    alignItems: "center",
    backgroundColor: "#F4F4F5",
    borderRadius: 12,
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
