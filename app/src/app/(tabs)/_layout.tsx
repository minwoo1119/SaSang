import { Tabs } from "expo-router";

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
          tabBarLabel: "지도",
          title: "지도",
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
