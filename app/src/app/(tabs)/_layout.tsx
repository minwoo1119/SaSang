import { Tabs } from "expo-router";
import { SymbolView } from "expo-symbols";
import { Text } from "react-native";

type TabIconProps = {
  color: string;
  name: "map" | "photo.stack" | "ellipsis";
  fallback: string;
};

function TabIcon({ color, name, fallback }: TabIconProps) {
  return (
    <SymbolView
      fallback={<Text style={{ color, fontSize: 19 }}>{fallback}</Text>}
      name={name}
      size={21}
      tintColor={color}
    />
  );
}

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: "#17191D",
        tabBarInactiveTintColor: "#777C84",
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: "700",
        },
        tabBarItemStyle: {
          borderRadius: 28,
          height: 54,
          paddingVertical: 5,
        },
        tabBarStyle: {
          backgroundColor: "#FFFFFF",
          borderColor: "#E9E4DB",
          borderRadius: 32,
          borderTopWidth: 1,
          borderWidth: 1,
          bottom: 18,
          elevation: 10,
          height: 64,
          left: 18,
          paddingBottom: 6,
          paddingTop: 6,
          position: "absolute",
          right: 18,
          boxShadow: "0 8px 18px rgba(23, 25, 29, 0.12)",
        },
      }}
    >
      <Tabs.Screen
        name="map"
        options={{
          tabBarIcon: ({ color }) => (
            <TabIcon color={color} fallback="⌖" name="map" />
          ),
          tabBarLabel: "지도",
          title: "지도",
        }}
      />
      <Tabs.Screen
        name="places"
        options={{
          tabBarIcon: ({ color }) => (
            <TabIcon color={color} fallback="▧" name="photo.stack" />
          ),
          tabBarLabel: "장소",
          title: "장소",
        }}
      />
      <Tabs.Screen
        name="more"
        options={{
          tabBarIcon: ({ color }) => (
            <TabIcon color={color} fallback="•••" name="ellipsis" />
          ),
          tabBarLabel: "더보기",
          title: "더보기",
        }}
      />
    </Tabs>
  );
}
