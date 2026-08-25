import { router } from "expo-router";
import { Image } from "expo-image";
import * as ImagePicker from "expo-image-picker";
import { useState } from "react";
import {
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { INFO_ITEMS, type InfoType } from "@/features/more/models/infoContent";

type LoginProvider = "Kakao" | "Google";

export function MoreScreen() {
  const insets = useSafeAreaInsets();
  const [isEditingName, setIsEditingName] = useState(false);
  const [name, setName] = useState("여행자");
  const [draftName, setDraftName] = useState(name);
  const [profileImageUri, setProfileImageUri] = useState<string | null>(null);

  const pickProfileImage = async () => {
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        allowsEditing: true,
        aspect: [1, 1],
        mediaTypes: ["images"],
        quality: 0.85,
      });
      const asset = result.assets?.[0];
      if (!result.canceled && asset) {
        setProfileImageUri(asset.uri);
      }
    } catch (error: unknown) {
      const message =
        error instanceof Error
          ? error.message
          : "프로필 이미지를 불러오지 못했습니다.";
      Alert.alert("이미지를 변경할 수 없어요", message);
    }
  };

  const startNameEdit = () => {
    setDraftName(name);
    setIsEditingName(true);
  };

  const saveName = () => {
    const nextName = draftName.trim();
    if (!nextName) {
      Alert.alert("이름을 입력해주세요", "표시할 이름은 비워둘 수 없습니다.");
      return;
    }
    setName(nextName);
    setIsEditingName(false);
  };

  const openInfoPage = (type: InfoType) => {
    router.push({ pathname: "/info/[type]", params: { type } });
  };

  const showPendingTransfer = (provider: LoginProvider) => {
    Alert.alert(
      `${provider} 데이터 내보내기`,
      "아직 로그인 및 서버 동기화 연동 전입니다. 연동 후에는 이 기기에 저장된 여행 기록을 계정으로 내보냅니다.",
    );
  };

  const showPendingLogout = () => {
    Alert.alert(
      "로그아웃",
      "아직 로그인 연동 전이라 로그아웃할 계정이 없습니다.",
    );
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={[
        styles.content,
        { paddingBottom: insets.bottom + 112, paddingTop: insets.top + 28 },
      ]}
      showsVerticalScrollIndicator={false}
    >
      <Text style={styles.title}>더보기</Text>

      <View style={styles.profileSection}>
        <View style={styles.profileHeader}>
          <Pressable
            accessibilityLabel="프로필 이미지 수정"
            accessibilityRole="button"
            onPress={pickProfileImage}
            style={({ pressed }) => [
              styles.avatarButton,
              pressed && styles.pressed,
            ]}
          >
            {profileImageUri ? (
              <Image
                contentFit="cover"
                source={{ uri: profileImageUri }}
                style={styles.avatarImage}
              />
            ) : (
              <Image
                contentFit="cover"
                source={require("../../assets/images/default-profile.png")}
                style={styles.avatarImage}
              />
            )}
          </Pressable>

          <View style={styles.profileCopy}>
            <Text style={styles.sectionLabel}>개인 프로필</Text>
            {isEditingName ? (
              <TextInput
                autoFocus
                maxLength={20}
                onChangeText={setDraftName}
                onSubmitEditing={saveName}
                returnKeyType="done"
                style={styles.nameInput}
                value={draftName}
              />
            ) : (
              <Text numberOfLines={1} style={styles.profileName}>
                {name}
              </Text>
            )}
            <Text style={styles.profileHint}>
              프로필 사진과 표시 이름을 관리해요
            </Text>
          </View>
        </View>

        <Pressable
          accessibilityRole="button"
          onPress={isEditingName ? saveName : startNameEdit}
          style={({ pressed }) => [
            styles.editButton,
            pressed && styles.pressed,
          ]}
        >
          <Text style={styles.editButtonText}>
            {isEditingName ? "저장" : "수정"}
          </Text>
        </Pressable>
      </View>

      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>데이터 내보내기</Text>
        <View style={styles.infoList}>
          <MoreRow
            label="Kakao로 로그인하여 내보내기"
            onPress={() => showPendingTransfer("Kakao")}
          />
          <MoreRow
            label="Google로 로그인하여 내보내기"
            onPress={() => showPendingTransfer("Google")}
          />
        </View>
      </View>

      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>약관 및 정보</Text>
        <View style={styles.infoList}>
          {INFO_ITEMS.map((item) => (
            <MoreRow
              key={item.id}
              label={item.label}
              onPress={() => openInfoPage(item.id)}
            />
          ))}
        </View>
      </View>

      <Pressable
        accessibilityRole="button"
        onPress={showPendingLogout}
        style={({ pressed }) => [
          styles.logoutButton,
          pressed && styles.logoutButtonPressed,
        ]}
      >
        <Text style={styles.logoutButtonText}>로그아웃</Text>
      </Pressable>
    </ScrollView>
  );
}

function MoreRow({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.infoRow,
        pressed && styles.infoRowPressed,
      ]}
    >
      <Text numberOfLines={1} style={styles.infoRowText}>
        {label}
      </Text>
      <Text style={styles.infoChevron}>›</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  avatarButton: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderColor: "#FFFFFF",
    borderRadius: 42,
    borderWidth: 3,
    height: 84,
    justifyContent: "center",
    overflow: "hidden",
    width: 84,
  },
  avatarImage: {
    height: 84,
    width: 84,
  },
  container: {
    backgroundColor: "#FAFAFA",
    flex: 1,
  },
  content: {
    gap: 22,
    paddingHorizontal: 20,
  },
  editButton: {
    alignItems: "center",
    alignSelf: "stretch",
    backgroundColor: "#007AFF",
    borderRadius: 14,
    height: 44,
    justifyContent: "center",
    paddingHorizontal: 15,
  },
  editButtonText: {
    color: "#FFFFFF",
    fontSize: 13,
    fontWeight: "800",
  },
  infoSection: {
    gap: 12,
  },
  infoTitle: {
    color: "#18181B",
    fontSize: 18,
    fontWeight: "800",
  },
  nameInput: {
    borderBottomColor: "#007AFF",
    borderBottomWidth: 1,
    color: "#18181B",
    fontSize: 22,
    fontWeight: "800",
    minWidth: 120,
    padding: 0,
  },
  pressed: {
    opacity: 0.72,
  },
  profileCopy: {
    flex: 1,
    gap: 5,
    minWidth: 0,
  },
  profileHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 16,
  },
  profileHint: {
    color: "#71717A",
    fontSize: 13,
    lineHeight: 18,
  },
  profileName: {
    color: "#18181B",
    fontSize: 24,
    fontWeight: "800",
  },
  profileSection: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.07)",
    borderRadius: 24,
    borderWidth: StyleSheet.hairlineWidth,
    gap: 18,
    padding: 18,
  },
  sectionLabel: {
    color: "#007AFF",
    fontSize: 12,
    fontWeight: "800",
  },
  infoChevron: {
    color: "#007AFF",
    fontSize: 24,
    fontWeight: "500",
    lineHeight: 26,
  },
  infoList: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.07)",
    borderRadius: 18,
    borderWidth: StyleSheet.hairlineWidth,
    overflow: "hidden",
  },
  infoRow: {
    alignItems: "center",
    borderBottomColor: "rgba(0, 0, 0, 0.07)",
    borderBottomWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    justifyContent: "space-between",
    minHeight: 52,
    paddingHorizontal: 16,
  },
  infoRowPressed: {
    backgroundColor: "rgba(0, 122, 255, 0.06)",
  },
  infoRowText: {
    color: "#18181B",
    fontSize: 15,
    fontWeight: "700",
    flex: 1,
    minWidth: 0,
    paddingRight: 12,
  },
  logoutButton: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(239, 68, 68, 0.28)",
    borderRadius: 18,
    borderWidth: 1,
    height: 52,
    justifyContent: "center",
  },
  logoutButtonPressed: {
    backgroundColor: "rgba(239, 68, 68, 0.06)",
  },
  logoutButtonText: {
    color: "#EF4444",
    fontSize: 15,
    fontWeight: "800",
  },
  title: {
    color: "#18181B",
    fontSize: 28,
    fontWeight: "800",
    letterSpacing: 0,
  },
});
