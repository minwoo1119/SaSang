import { Tabs } from "expo-router";
import { SymbolView } from "expo-symbols";
import type { ComponentProps } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";

type TabMeta = {
  fallback: string;
  label: string;
  symbol: "map" | "photo.stack" | "ellipsis";
};

const TAB_META: Record<string, TabMeta> = {
  map: { fallback: "⌖", label: "지도", symbol: "map" },
  more: { fallback: "•••", label: "더보기", symbol: "ellipsis" },
  places: { fallback: "▧", label: "장소", symbol: "photo.stack" },
};

type FloatingTabBarProps = Parameters<
  NonNullable<ComponentProps<typeof Tabs>["tabBar"]>
>[0];

function FloatingTabBar({
  descriptors,
  insets,
  navigation,
  state,
}: FloatingTabBarProps) {
  return (
    <View
      pointerEvents="box-none"
      style={[styles.wrapper, { bottom: Math.max(insets.bottom, 14) }]}
    >
      <View style={styles.bar}>
        {state.routes.map((route, index) => {
          const focused = state.index === index;
          const options = descriptors[route.key]?.options;
          const meta = TAB_META[route.name];
          const color = focused ? "#007AFF" : "#71717A";

          const onPress = () => {
            const event = navigation.emit({
              canPreventDefault: true,
              target: route.key,
              type: "tabPress",
            });

            if (!focused && !event.defaultPrevented) {
              navigation.navigate(route.name, route.params);
            }
          };

          return (
            <Pressable
              accessibilityLabel={options?.tabBarAccessibilityLabel}
              accessibilityRole="button"
              accessibilityState={focused ? { selected: true } : {}}
              key={route.key}
              onPress={onPress}
              style={({ pressed }) => [
                styles.item,
                pressed && styles.itemPressed,
              ]}
            >
              <TabIcon
                color={color}
                fallback={meta.fallback}
                name={meta.symbol}
              />
              <Text style={[styles.label, { color }]}>{meta.label}</Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function TabIcon({
  color,
  fallback,
  name,
}: {
  color: string;
  fallback: string;
  name: TabMeta["symbol"];
}) {
  return (
    <SymbolView
      fallback={
        <Text style={[styles.fallbackIcon, { color }]}>{fallback}</Text>
      }
      name={name}
      size={20}
      tintColor={color}
    />
  );
}

export default function TabLayout() {
  return (
    <Tabs
      tabBar={(props) => <FloatingTabBar {...props} />}
      screenOptions={{
        headerShown: false,
      }}
    >
      <Tabs.Screen
        name="map"
        options={{
          tabBarLabel: "지도",
          title: "지도",
        }}
      />
      <Tabs.Screen
        name="places"
        options={{
          tabBarLabel: "장소",
          title: "장소",
        }}
      />
      <Tabs.Screen
        name="more"
        options={{
          tabBarLabel: "더보기",
          title: "더보기",
        }}
      />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  bar: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(228, 228, 231, 0.9)",
    borderRadius: 34,
    borderWidth: 1,
    boxShadow: "0 8px 18px rgba(24, 24, 27, 0.10)",
    elevation: 10,
    flexDirection: "row",
    gap: 4,
    height: 66,
    padding: 6,
  },
  fallbackIcon: {
    fontSize: 18,
    fontWeight: "800",
    lineHeight: 20,
    textAlign: "center",
  },
  item: {
    alignItems: "center",
    borderRadius: 28,
    flex: 1,
    gap: 2,
    height: 54,
    justifyContent: "center",
  },
  itemPressed: {
    opacity: 0.72,
  },
  label: {
    fontSize: 11,
    fontWeight: "700",
    lineHeight: 14,
  },
  wrapper: {
    left: 18,
    position: "absolute",
    right: 18,
  },
});
