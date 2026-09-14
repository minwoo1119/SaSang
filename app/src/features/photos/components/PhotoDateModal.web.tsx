import { Image } from "expo-image";
import { useEffect, useState } from "react";
import {
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { parsePhotoDate, toPhotoDateKey } from "../utils/photoDate";

type PhotoDateModalProps = {
  dateFromMetadata: boolean;
  initialDate: Date;
  isSaving: boolean;
  onCancel: () => void;
  onConfirm: (date: Date) => void;
  photoUri: string;
  visible: boolean;
};

export function PhotoDateModal({
  dateFromMetadata,
  initialDate,
  isSaving,
  onCancel,
  onConfirm,
  photoUri,
  visible,
}: PhotoDateModalProps) {
  const [value, setValue] = useState(toPhotoDateKey(initialDate));
  const parsedDate = parsePhotoDate(value);
  const isValid =
    parsedDate !== null &&
    toPhotoDateKey(parsedDate) === value &&
    parsedDate <= new Date();

  useEffect(() => {
    if (visible) setValue(toPhotoDateKey(initialDate));
  }, [initialDate, visible]);

  return (
    <Modal
      animationType="fade"
      onRequestClose={onCancel}
      transparent
      visible={visible}
    >
      <View style={styles.backdrop}>
        <Pressable onPress={onCancel} style={StyleSheet.absoluteFill} />
        <View style={styles.sheet}>
          <Text style={styles.title}>사진 날짜</Text>
          <Text style={styles.description}>
            {dateFromMetadata
              ? "사진에 기록된 촬영일을 불러왔어요."
              : "촬영일 정보가 없어 오늘 날짜로 설정했어요."}
          </Text>
          <Image
            contentFit="cover"
            source={{ uri: photoUri }}
            style={styles.preview}
          />
          <TextInput
            accessibilityLabel="사진 날짜"
            maxLength={10}
            onChangeText={setValue}
            placeholder="YYYY-MM-DD"
            style={styles.input}
            value={value}
          />
          {!isValid ? (
            <Text style={styles.error}>올바른 과거 날짜를 입력하세요.</Text>
          ) : null}
          <View style={styles.actions}>
            <Pressable
              disabled={isSaving}
              onPress={onCancel}
              style={styles.cancelButton}
            >
              <Text style={styles.cancelText}>취소</Text>
            </Pressable>
            <Pressable
              disabled={!isValid || isSaving}
              onPress={() => parsedDate && onConfirm(parsedDate)}
              style={[
                styles.confirmButton,
                (!isValid || isSaving) && styles.disabled,
              ]}
            >
              <Text style={styles.confirmText}>
                {isSaving ? "저장 중..." : "이 날짜로 저장"}
              </Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  actions: { flexDirection: "row", gap: 10 },
  backdrop: {
    alignItems: "center",
    backgroundColor: "rgba(0, 0, 0, 0.38)",
    flex: 1,
    justifyContent: "center",
    padding: 20,
  },
  cancelButton: {
    alignItems: "center",
    backgroundColor: "#F4F4F5",
    borderRadius: 8,
    flex: 1,
    height: 48,
    justifyContent: "center",
  },
  cancelText: { color: "#3F3F46", fontSize: 15, fontWeight: "700" },
  confirmButton: {
    alignItems: "center",
    backgroundColor: "#007AFF",
    borderRadius: 8,
    flex: 1.7,
    height: 48,
    justifyContent: "center",
  },
  confirmText: { color: "#FFFFFF", fontSize: 15, fontWeight: "800" },
  description: { color: "#71717A", fontSize: 13 },
  disabled: { opacity: 0.45 },
  error: { color: "#DC2626", fontSize: 12 },
  input: {
    borderColor: "#E4E4E7",
    borderRadius: 8,
    borderWidth: 1,
    color: "#18181B",
    fontSize: 16,
    height: 48,
    paddingHorizontal: 14,
  },
  preview: { aspectRatio: 2.2, borderRadius: 8, width: "100%" },
  sheet: {
    backgroundColor: "#FFFFFF",
    borderRadius: 8,
    gap: 14,
    maxWidth: 430,
    padding: 20,
    width: "100%",
  },
  title: { color: "#18181B", fontSize: 20, fontWeight: "800" },
});
