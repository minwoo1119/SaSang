/// Disables advertising only in binaries built for deterministic store captures.
const bool kSasangStoreCapture = bool.fromEnvironment('SASANG_STORE_CAPTURE');

/// Opens the world map only in dedicated store-capture binaries.
const bool kSasangStoreCaptureWorld = bool.fromEnvironment(
  'SASANG_STORE_CAPTURE_WORLD',
);
