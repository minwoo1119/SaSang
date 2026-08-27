import Constants from "expo-constants";
import { Platform } from "react-native";

type AnalyticsParams = Record<string, boolean | number | string | null>;
type AnalyticsClient = {
  logEvent: (name: string, params?: AnalyticsParams) => Promise<void>;
  logScreenView: (params: {
    screen_class: string;
    screen_name: string;
  }) => Promise<void>;
};

declare const require: (moduleName: string) => unknown;

let analyticsClient: AnalyticsClient | null | undefined;

function getAnalyticsClient() {
  if (Platform.OS === "web" || Constants.appOwnership === "expo") return null;
  if (analyticsClient !== undefined) return analyticsClient;

  try {
    const module = require("@react-native-firebase/analytics") as
      | { default?: () => AnalyticsClient }
      | (() => AnalyticsClient);
    const analyticsFactory =
      typeof module === "function" ? module : module.default;
    analyticsClient = analyticsFactory ? analyticsFactory() : null;
  } catch {
    analyticsClient = null;
  }

  return analyticsClient;
}

function cleanParams(params?: AnalyticsParams) {
  if (!params) return undefined;
  return Object.fromEntries(
    Object.entries(params).filter(([, value]) => value !== null),
  ) as AnalyticsParams;
}

export async function trackEvent(
  name: string,
  params?: AnalyticsParams,
): Promise<void> {
  try {
    const analytics = getAnalyticsClient();
    if (!analytics) return;
    await analytics.logEvent(name, cleanParams(params));
  } catch {
    analyticsClient = null;
  }
}

export async function trackScreenView(screenName: string): Promise<void> {
  try {
    const analytics = getAnalyticsClient();
    if (!analytics) return;
    await analytics.logScreenView({
      screen_class: screenName,
      screen_name: screenName,
    });
  } catch {
    analyticsClient = null;
  }
}
