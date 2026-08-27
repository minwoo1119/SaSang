import {
  Modal,
  Pressable,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

type AdPlaceholderModalProps = {
  onClose: () => void;
  visible: boolean;
};

export function AdPlaceholderModal({
  onClose,
  visible,
}: AdPlaceholderModalProps) {
  const insets = useSafeAreaInsets();
  const { height } = useWindowDimensions();
  const sheetMaxHeight = Math.max(240, height * 0.42);
  const adSlotHeight = Math.max(132, Math.min(220, height * 0.24));

  return (
    <Modal
      animationType="slide"
      onRequestClose={onClose}
      transparent
      visible={visible}
    >
      <View style={styles.backdrop}>
        <View
          style={[
            styles.sheet,
            {
              maxHeight: sheetMaxHeight,
              paddingBottom: Math.max(insets.bottom, 8) + 4,
            },
          ]}
        >
          <View style={[styles.adSlot, { height: adSlotHeight }]}>
            <Text style={styles.adLabel}>AdMob</Text>
            <Text style={styles.adText}>광고 영역</Text>
          </View>
          <Pressable
            accessibilityRole="button"
            onPress={onClose}
            style={({ pressed }) => [
              styles.closeButton,
              pressed && styles.closeButtonPressed,
            ]}
          >
            <Text style={styles.closeButtonText}>닫기</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  adLabel: {
    color: "#007AFF",
    fontSize: 13,
    fontWeight: "800",
  },
  adSlot: {
    alignItems: "center",
    backgroundColor: "#F8F8FA",
    borderColor: "rgba(0, 0, 0, 0.06)",
    borderRadius: 18,
    borderWidth: StyleSheet.hairlineWidth,
    gap: 6,
    justifyContent: "center",
    width: "100%",
  },
  adText: {
    color: "#71717A",
    fontSize: 16,
    fontWeight: "700",
  },
  backdrop: {
    backgroundColor: "rgba(24, 24, 27, 0.18)",
    flex: 1,
    justifyContent: "flex-end",
  },
  closeButton: {
    alignItems: "center",
    alignSelf: "flex-end",
    borderRadius: 14,
    height: 42,
    justifyContent: "center",
    marginTop: 8,
    paddingHorizontal: 16,
  },
  closeButtonPressed: {
    backgroundColor: "#F4F4F5",
  },
  closeButtonText: {
    color: "#18181B",
    fontSize: 14,
    fontWeight: "800",
  },
  sheet: {
    backgroundColor: "#FFFFFF",
    borderTopLeftRadius: 26,
    borderTopRightRadius: 26,
    paddingHorizontal: 18,
    paddingTop: 18,
  },
});
