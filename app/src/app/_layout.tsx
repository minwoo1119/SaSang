import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useFonts } from "expo-font";
import { Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { useEffect, useState } from "react";
import { View } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import "react-native-reanimated";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { initializeMobileAds } from "@/features/ads/services/mobileAds";

void SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [queryClient] = useState(() => new QueryClient());
  const [fontsLoaded] = useFonts({
    "SUIT-Heavy": require("../../assets/fonts/SUIT-Heavy.ttf"),
  });

  useEffect(() => {
    if (fontsLoaded) {
      void (async () => {
        try {
          await initializeMobileAds();
        } finally {
          await SplashScreen.hideAsync();
        }
      })();
    }
  }, [fontsLoaded]);

  if (!fontsLoaded) {
    return <View style={{ backgroundColor: "#FAFAFA", flex: 1 }} />;
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <Stack screenOptions={{ headerShown: false }} />
          <StatusBar style="dark" translucent />
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
