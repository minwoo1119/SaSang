type AnalyticsParams = Record<string, boolean | number | string | null>;

export async function trackEvent(
  _name: string,
  _params?: AnalyticsParams,
): Promise<void> {
  // Analytical events stub
  return Promise.resolve();
}

export async function trackScreenView(_screenName: string): Promise<void> {
  // Screen views stub
  return Promise.resolve();
}
