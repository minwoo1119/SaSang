import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useFonts } from "expo-font";
import { Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { useCallback, useRef, useState } from "react";
import { View } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import "react-native-reanimated";
import { SafeAreaProvider } from "react-native-safe-area-context";

void SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [queryClient] = useState(() => new QueryClient());
  const splashHiddenRef = useRef(false);
  const [fontsLoaded] = useFonts({
    "SUIT-Heavy": require("../../assets/fonts/SUIT-Heavy.ttf"),
  });

  const handleRootLayout = useCallback(() => {
    if (!fontsLoaded || splashHiddenRef.current) return;

    splashHiddenRef.current = true;
    void SplashScreen.hideAsync().catch(() => {
      splashHiddenRef.current = false;
    });
  }, [fontsLoaded]);

  if (!fontsLoaded) {
    return <View style={{ backgroundColor: "#FAFAFA", flex: 1 }} />;
  }

  return (
    <GestureHandlerRootView onLayout={handleRootLayout} style={{ flex: 1 }}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <Stack screenOptions={{ headerShown: false }} />
          <StatusBar style="dark" translucent />
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
