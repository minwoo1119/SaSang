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
        tabBarStyle: {
          backgroundColor: "#FFFFFF",
          borderTopColor: "#E6E2DA",
          height: 78,
          paddingBottom: 20,
          paddingTop: 8,
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
