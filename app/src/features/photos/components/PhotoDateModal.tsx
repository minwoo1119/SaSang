import DateTimePicker, {
  type DateTimePickerEvent,
} from "@react-native-community/datetimepicker";
import { Image } from "expo-image";
import { useEffect, useState } from "react";
import {
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { toPhotoDateKey } from "../utils/photoDate";

type PhotoDateModalProps = {
  dateFromMetadata: boolean;
  initialDate: Date;
  isSaving: boolean;
  onCancel: () => void;
  onConfirm: (date: Date) => void;
  photoUri: string;
  visible: boolean;
};

const dateFormatter = new Intl.DateTimeFormat("ko-KR", {
  day: "numeric",
  month: "long",
  year: "numeric",
});

export function PhotoDateModal({
  dateFromMetadata,
  initialDate,
  isSaving,
  onCancel,
  onConfirm,
  photoUri,
  visible,
}: PhotoDateModalProps) {
  const [date, setDate] = useState(initialDate);
  const [showAndroidPicker, setShowAndroidPicker] = useState(false);

  useEffect(() => {
    if (visible) {
      setDate(initialDate);
      setShowAndroidPicker(false);
    }
  }, [initialDate, visible]);

  const handleChange = (event: DateTimePickerEvent, selectedDate?: Date) => {
    if (Platform.OS === "android") setShowAndroidPicker(false);
    if (event.type === "set" && selectedDate) setDate(selectedDate);
  };

  return (
    <Modal
      animationType="fade"
      onRequestClose={isSaving ? undefined : onCancel}
      presentationStyle="overFullScreen"
      transparent
      visible={visible}
    >
      <View style={styles.backdrop}>
        <Pressable
          accessibilityLabel="날짜 등록 취소"
          disabled={isSaving}
          onPress={onCancel}
          style={StyleSheet.absoluteFill}
        />
        <View accessibilityViewIsModal style={styles.sheet}>
          <View style={styles.header}>
            <Text style={styles.title}>사진 날짜</Text>
            <Text style={styles.description}>
              {dateFromMetadata
                ? "사진에 기록된 촬영일을 불러왔어요."
                : "촬영일 정보가 없어 오늘 날짜로 설정했어요."}
            </Text>
          </View>

          <Image
            contentFit="cover"
            source={{ uri: photoUri }}
            style={styles.preview}
          />

          {Platform.OS === "ios" ? (
            <View style={styles.dateButton}>
              <Text style={styles.dateLabel}>사진 날짜</Text>
              <DateTimePicker
                accentColor="#007AFF"
                display="compact"
                locale="ko-KR"
                maximumDate={new Date()}
                mode="date"
                onChange={handleChange}
                style={styles.iosPicker}
                value={date}
              />
            </View>
          ) : (
            <>
              <Pressable
                accessibilityHint="시스템 날짜 선택기를 엽니다"
                accessibilityRole="button"
                onPress={() => setShowAndroidPicker(true)}
                style={({ pressed }) => [
                  styles.dateButton,
                  pressed && styles.pressed,
                ]}
              >
                <Text style={styles.dateLabel}>사진 날짜</Text>
                <Text style={styles.dateValue}>
                  {dateFormatter.format(date)}
                </Text>
                <Text style={styles.editLabel}>변경</Text>
              </Pressable>
              {showAndroidPicker ? (
                <DateTimePicker
                  display="calendar"
                  maximumDate={new Date()}
                  mode="date"
                  onChange={handleChange}
                  value={date}
                />
              ) : null}
            </>
          )}

          <Text style={styles.selectedDate}>기록일 {toPhotoDateKey(date)}</Text>

          <View style={styles.actions}>
            <Pressable
              accessibilityRole="button"
              disabled={isSaving}
              onPress={onCancel}
              style={({ pressed }) => [
                styles.cancelButton,
                pressed && styles.pressed,
              ]}
            >
              <Text style={styles.cancelText}>취소</Text>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              accessibilityState={{ disabled: isSaving }}
              disabled={isSaving}
              onPress={() => onConfirm(date)}
              style={({ pressed }) => [
                styles.confirmButton,
                pressed && styles.confirmButtonPressed,
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
  confirmButtonPressed: { backgroundColor: "#0068D9" },
  confirmText: { color: "#FFFFFF", fontSize: 15, fontWeight: "800" },
  dateButton: {
    alignItems: "center",
    borderColor: "#E4E4E7",
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: "row",
    minHeight: 54,
    paddingHorizontal: 14,
  },
  dateLabel: { color: "#71717A", fontSize: 12, fontWeight: "700" },
  dateValue: {
    color: "#18181B",
    flex: 1,
    fontSize: 15,
    fontWeight: "700",
    marginLeft: 14,
  },
  description: { color: "#71717A", fontSize: 13, lineHeight: 19 },
  editLabel: { color: "#007AFF", fontSize: 13, fontWeight: "800" },
  header: { gap: 5 },
  iosPicker: { marginLeft: "auto" },
  pressed: { opacity: 0.58 },
  preview: {
    aspectRatio: 2.2,
    backgroundColor: "#F4F4F5",
    borderRadius: 8,
    width: "100%",
  },
  selectedDate: {
    color: "#71717A",
    fontSize: 12,
    fontWeight: "600",
    textAlign: "center",
  },
  sheet: {
    backgroundColor: "#FFFFFF",
    borderRadius: 8,
    gap: 16,
    maxWidth: 430,
    padding: 20,
    width: "100%",
  },
  title: { color: "#18181B", fontSize: 20, fontWeight: "800" },
});
