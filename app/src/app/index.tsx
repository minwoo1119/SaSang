import { Redirect } from "expo-router";
import { useLocalSessionStore } from "@/features/auth/store/localSession.store";
import { LoginScreen } from "@/screens/LoginScreen";

export default function IndexScreen() {
  const hasStarted = useLocalSessionStore((state) => state.hasStarted);

  if (hasStarted) {
    return <Redirect href="/map" />;
  }

  return <LoginScreen />;
}
