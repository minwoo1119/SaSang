import { router } from "expo-router";
import { ChevronLeft, Lock, X } from "lucide-react-native";
import { useEffect, useState } from "react";
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { MapPreview } from "@/features/map/components/MapPreview";
import {
  STORE_MAP_PRODUCTS,
  type StoreMapProduct,
} from "@/features/map/models/mapCatalog";
import { trackEvent, trackScreenView } from "@/services/analytics/analytics";

export function MapStoreScreen() {
  const insets = useSafeAreaInsets();
  const [selectedProduct, setSelectedProduct] =
    useState<StoreMapProduct | null>(null);

  useEffect(() => {
    void trackScreenView("MapStore");
  }, []);

  const openProduct = (product: StoreMapProduct) => {
    setSelectedProduct(product);
    void trackEvent("map_store_product_opened", {
      country_code: product.countryCode,
      product_id: product.id,
    });
  };

  return (
    <View style={styles.container}>
      <View style={[styles.header, { paddingTop: insets.top + 10 }]}>
        <Pressable
          accessibilityLabel="뒤로"
          accessibilityRole="button"
          hitSlop={8}
          onPress={router.back}
          style={({ pressed }) => [
            styles.headerButton,
            pressed && styles.pressed,
          ]}
        >
          <ChevronLeft color="#18181B" size={24} />
        </Pressable>
        <Text style={styles.headerTitle}>지도 상점</Text>
        <View style={styles.headerButton} />
      </View>

      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingBottom: Math.max(insets.bottom, 20) + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.intro}>
          <Text style={styles.introTitle}>여행을 더 자세하게 기록하세요</Text>
          <Text style={styles.introDescription}>
            국가 지도를 열면 도시와 지역 단위로 사진을 남길 수 있어요.
          </Text>
        </View>

        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>국가별 지도</Text>
          <Text style={styles.sectionCount}>{STORE_MAP_PRODUCTS.length}개</Text>
        </View>

        <View style={styles.productGrid}>
          {STORE_MAP_PRODUCTS.map((product) => (
            <Pressable
              accessibilityLabel={`${product.name}, ${product.priceLabel}`}
              accessibilityRole="button"
              key={product.id}
              onPress={() => openProduct(product)}
              style={({ pressed }) => [
                styles.productCard,
                pressed && styles.productCardPressed,
              ]}
            >
              <View style={styles.productPreview}>
                <MapPreview countryCode={product.countryCode} />
                <View style={styles.lockBadge}>
                  <Lock color="#FFFFFF" size={12} strokeWidth={2.5} />
                </View>
              </View>
              <View style={styles.productCopy}>
                <Text numberOfLines={1} style={styles.productName}>
                  {product.name}
                </Text>
                <Text numberOfLines={2} style={styles.productDescription}>
                  {product.description}
                </Text>
                <View style={styles.priceRow}>
                  <Text style={styles.price}>{product.priceLabel}</Text>
                  <Text style={styles.comingSoon}>출시 예정</Text>
                </View>
              </View>
            </Pressable>
          ))}
        </View>
      </ScrollView>

      <ProductModal
        onClose={() => setSelectedProduct(null)}
        product={selectedProduct}
      />
    </View>
  );
}

function ProductModal({
  onClose,
  product,
}: {
  onClose: () => void;
  product: StoreMapProduct | null;
}) {
  const insets = useSafeAreaInsets();

  return (
    <Modal
      animationType="slide"
      onRequestClose={onClose}
      presentationStyle="overFullScreen"
      transparent
      visible={product !== null}
    >
      <View style={styles.modalRoot}>
        <Pressable
          accessibilityLabel="상품 닫기"
          onPress={onClose}
          style={styles.backdrop}
        />
        {product ? (
          <View
            style={[
              styles.productSheet,
              { paddingBottom: Math.max(insets.bottom, 18) },
            ]}
          >
            <View style={styles.modalHeader}>
              <View style={styles.modalTitleBlock}>
                <Text style={styles.modalEyebrow}>국가별 상세 지도</Text>
                <Text style={styles.modalTitle}>{product.name}</Text>
              </View>
              <Pressable
                accessibilityLabel="닫기"
                accessibilityRole="button"
                hitSlop={8}
                onPress={onClose}
                style={({ pressed }) => [
                  styles.modalCloseButton,
                  pressed && styles.pressed,
                ]}
              >
                <X color="#52525B" size={20} />
              </Pressable>
            </View>

            <View style={styles.modalPreview}>
              <MapPreview countryCode={product.countryCode} selected />
            </View>
            <Text style={styles.modalDescription}>{product.description}</Text>
            <View style={styles.modalPriceRow}>
              <Text style={styles.modalPriceLabel}>지도 가격</Text>
              <Text style={styles.modalPrice}>{product.priceLabel}</Text>
            </View>
            <Pressable
              accessibilityRole="button"
              accessibilityState={{ disabled: true }}
              disabled
              style={styles.disabledPurchaseButton}
            >
              <Text style={styles.disabledPurchaseText}>출시 예정</Text>
            </Pressable>
          </View>
        ) : null}
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    backgroundColor: "rgba(0, 0, 0, 0.32)",
    bottom: 0,
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  comingSoon: {
    color: "#71717A",
    fontSize: 10,
    fontWeight: "700",
  },
  container: { backgroundColor: "#FAFAFA", flex: 1 },
  content: { paddingHorizontal: 18, paddingTop: 18 },
  disabledPurchaseButton: {
    alignItems: "center",
    backgroundColor: "#E4E4E7",
    borderRadius: 8,
    height: 50,
    justifyContent: "center",
  },
  disabledPurchaseText: {
    color: "#71717A",
    fontSize: 15,
    fontWeight: "800",
  },
  header: {
    alignItems: "center",
    backgroundColor: "rgba(250, 250, 250, 0.96)",
    borderBottomColor: "rgba(0, 0, 0, 0.07)",
    borderBottomWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    justifyContent: "space-between",
    paddingBottom: 11,
    paddingHorizontal: 14,
  },
  headerButton: {
    alignItems: "center",
    height: 38,
    justifyContent: "center",
    width: 38,
  },
  headerTitle: { color: "#18181B", fontSize: 17, fontWeight: "800" },
  intro: { marginBottom: 26 },
  introDescription: {
    color: "#71717A",
    fontSize: 14,
    lineHeight: 20,
    marginTop: 7,
    maxWidth: 330,
  },
  introTitle: { color: "#18181B", fontSize: 24, fontWeight: "800" },
  lockBadge: {
    alignItems: "center",
    backgroundColor: "rgba(24, 24, 27, 0.82)",
    borderRadius: 8,
    height: 26,
    justifyContent: "center",
    position: "absolute",
    right: 8,
    top: 8,
    width: 26,
  },
  modalCloseButton: {
    alignItems: "center",
    backgroundColor: "#F4F4F5",
    borderRadius: 8,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  modalDescription: { color: "#52525B", fontSize: 14, lineHeight: 20 },
  modalEyebrow: {
    color: "#007AFF",
    fontSize: 11,
    fontWeight: "800",
    marginBottom: 4,
  },
  modalHeader: {
    alignItems: "flex-start",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  modalPrice: { color: "#18181B", fontSize: 18, fontWeight: "800" },
  modalPriceLabel: { color: "#71717A", fontSize: 13, fontWeight: "700" },
  modalPriceRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  modalPreview: { borderRadius: 8, height: 150, overflow: "hidden" },
  modalRoot: { flex: 1, justifyContent: "flex-end" },
  modalTitle: { color: "#18181B", fontSize: 23, fontWeight: "800" },
  modalTitleBlock: { flex: 1 },
  pressed: { opacity: 0.65 },
  price: { color: "#18181B", fontSize: 14, fontWeight: "800" },
  priceRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 12,
  },
  productCard: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderRadius: 8,
    borderWidth: StyleSheet.hairlineWidth,
    flexBasis: "48%",
    flexGrow: 1,
    maxWidth: "49%",
    overflow: "hidden",
  },
  productCardPressed: { opacity: 0.72, transform: [{ scale: 0.985 }] },
  productCopy: { padding: 12 },
  productDescription: {
    color: "#71717A",
    fontSize: 11,
    lineHeight: 16,
    marginTop: 4,
    minHeight: 32,
  },
  productGrid: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
  productName: { color: "#18181B", fontSize: 15, fontWeight: "800" },
  productPreview: { height: 108, position: "relative" },
  productSheet: {
    backgroundColor: "#FAFAFA",
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    gap: 17,
    paddingHorizontal: 18,
    paddingTop: 20,
  },
  sectionCount: { color: "#71717A", fontSize: 12, fontWeight: "700" },
  sectionHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  sectionTitle: { color: "#18181B", fontSize: 18, fontWeight: "800" },
});
