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

type InfoTab = "privacy" | "terms" | "app";

const infoTabs: { id: InfoTab; label: string }[] = [
  { id: "privacy", label: "개인정보" },
  { id: "terms", label: "이용약관" },
  { id: "app", label: "앱 정보" },
];

const infoContent: Record<InfoTab, { title: string; body: string[] }> = {
  app: {
    body: [
      "Sasang은 방문한 지역을 사진으로 채우는 개인 여행 지도 앱입니다.",
      "현재 버전은 지도 선택, 지역 사진 등록, 장소 피드 확인을 중심으로 구성되어 있습니다.",
      "오픈소스 라이선스와 세부 앱 정보는 정식 배포 단계에서 별도 문서로 연결됩니다.",
    ],
    title: "앱 정보",
  },
  privacy: {
    body: [
      "프로필 이름과 이미지는 앱에서 사용자 식별 및 개인화된 화면 표시를 위해 사용됩니다.",
      "선택한 여행 사진은 사용자가 지정한 지역의 지도 표현과 장소 피드에 표시됩니다.",
      "정식 개인정보 처리방침은 계정, 백엔드, 저장소 연동 시점에 맞춰 별도 고지됩니다.",
    ],
    title: "개인정보 처리방침",
  },
  terms: {
    body: [
      "사용자는 본인이 권리를 가진 사진을 등록해야 합니다.",
      "지도 경계와 지역 정보는 행정구역 데이터 변경에 따라 업데이트될 수 있습니다.",
      "정식 이용약관은 서비스 배포 전에 세부 조항을 확정해 제공합니다.",
    ],
    title: "이용약관",
  },
};

export function MoreScreen() {
  const insets = useSafeAreaInsets();
  const [activeInfoTab, setActiveInfoTab] = useState<InfoTab>("privacy");
  const [isEditingName, setIsEditingName] = useState(false);
  const [name, setName] = useState("여행자");
  const [draftName, setDraftName] = useState(name);
  const [profileImageUri, setProfileImageUri] = useState<string | null>(null);
  const activeInfo = infoContent[activeInfoTab];

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
              <Image source={{ uri: profileImageUri }} style={styles.avatarImage} />
            ) : (
              <Text style={styles.avatarInitial}>{name.slice(0, 1)}</Text>
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
            <Text style={styles.profileHint}>프로필 사진과 표시 이름을 관리해요</Text>
          </View>
        </View>

        <Pressable
          accessibilityRole="button"
          onPress={isEditingName ? saveName : startNameEdit}
          style={({ pressed }) => [styles.editButton, pressed && styles.pressed]}
        >
          <Text style={styles.editButtonText}>
            {isEditingName ? "저장" : "수정"}
          </Text>
        </Pressable>
      </View>

      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>약관 및 정보</Text>
        <View style={styles.tabList}>
          {infoTabs.map((tab) => {
            const selected = activeInfoTab === tab.id;
            return (
              <Pressable
                accessibilityRole="tab"
                accessibilityState={{ selected }}
                key={tab.id}
                onPress={() => setActiveInfoTab(tab.id)}
                style={[styles.infoTab, selected && styles.infoTabSelected]}
              >
                <Text
                  style={[
                    styles.infoTabText,
                    selected && styles.infoTabTextSelected,
                  ]}
                >
                  {tab.label}
                </Text>
              </Pressable>
            );
          })}
        </View>

        <View style={styles.infoPanel}>
          <Text style={styles.panelTitle}>{activeInfo.title}</Text>
          {activeInfo.body.map((paragraph) => (
            <Text key={paragraph} style={styles.panelText}>
              {paragraph}
            </Text>
          ))}
        </View>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  avatarButton: {
    alignItems: "center",
    backgroundColor: "#007AFF",
    borderColor: "rgba(255, 255, 255, 0.92)",
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
  avatarInitial: {
    color: "#FFFFFF",
    fontSize: 30,
    fontWeight: "800",
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
  infoPanel: {
    gap: 10,
    paddingTop: 16,
  },
  infoSection: {
    gap: 14,
  },
  infoTab: {
    alignItems: "center",
    borderRadius: 8,
    flex: 1,
    height: 38,
    justifyContent: "center",
  },
  infoTabSelected: {
    backgroundColor: "#FFFFFF",
  },
  infoTabText: {
    color: "#71717A",
    fontSize: 13,
    fontWeight: "800",
  },
  infoTabTextSelected: {
    color: "#007AFF",
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
  panelText: {
    color: "#52525B",
    fontSize: 14,
    lineHeight: 21,
  },
  panelTitle: {
    color: "#18181B",
    fontSize: 16,
    fontWeight: "800",
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
    backgroundColor: "#F8FBFF",
    borderColor: "#D6E9FF",
    borderRadius: 28,
    borderWidth: 1,
    gap: 18,
    padding: 18,
  },
  sectionLabel: {
    color: "#71717A",
    fontSize: 12,
    fontWeight: "800",
  },
  tabList: {
    backgroundColor: "#F1F5F9",
    borderRadius: 10,
    flexDirection: "row",
    gap: 4,
    padding: 4,
  },
  title: {
    color: "#18181B",
    fontSize: 28,
    fontWeight: "800",
    letterSpacing: 0,
  },
});
