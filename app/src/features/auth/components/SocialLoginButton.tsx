import {
  Pressable,
  StyleSheet,
  Text,
  type StyleProp,
  type ViewStyle,
} from "react-native";
import Svg, { Path } from "react-native-svg";

export type SocialLoginProvider = "kakao" | "google";

type SocialLoginButtonProps = {
  label: string;
  onPress: () => void;
  provider: SocialLoginProvider;
  style?: StyleProp<ViewStyle>;
};

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

export function SocialLoginButton({
  label,
  onPress,
  provider,
  style,
}: SocialLoginButtonProps) {
  const isKakao = provider === "kakao";

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        isKakao ? styles.kakaoButton : styles.googleButton,
        pressed && styles.pressed,
        style,
      ]}
    >
      {isKakao ? <KakaoSymbol /> : <GoogleSymbol />}
      <Text
        adjustsFontSizeToFit
        numberOfLines={1}
        style={isKakao ? styles.kakaoText : styles.googleText}
      >
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
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
  googleButton: {
    backgroundColor: "#F2F2F2",
  },
  googleText: {
    color: "#1F1F1F",
    flexShrink: 1,
    fontSize: 14,
    fontWeight: "700",
    minWidth: 0,
  },
  kakaoButton: {
    backgroundColor: "#FEE500",
  },
  kakaoText: {
    color: "rgba(0, 0, 0, 0.85)",
    flexShrink: 1,
    fontSize: 15,
    fontWeight: "700",
    minWidth: 0,
  },
  pressed: {
    opacity: 0.72,
  },
});
