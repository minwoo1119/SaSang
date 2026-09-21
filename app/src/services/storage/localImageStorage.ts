import { Directory, File, Paths } from "expo-file-system";

type ImageFolder = "photos" | "profile";
const LOCAL_IMAGE_PATH_MARKER = "/sasang/";

function getExtension(uri: string) {
  const match = uri.match(/\.([a-zA-Z0-9]+)(?:\?|#|$)/);
  return match?.[1]?.toLowerCase() ?? "jpg";
}

export async function saveImageToDevice(
  sourceUri: string,
  folder: ImageFolder,
  filePrefix: string,
) {
  const directory = new Directory(Paths.document, "sasang", folder);
  directory.create({ idempotent: true, intermediates: true });

  const extension = getExtension(sourceUri);
  const destination = new File(
    directory,
    `${filePrefix}-${Date.now()}.${extension}`,
  );
  const source = new File(sourceUri);
  source.copy(destination);

  return destination.uri;
}

export function resolveLocalImageUri(uri: string) {
  if (!uri.startsWith("file://")) return uri;

  const markerIndex = uri.lastIndexOf(LOCAL_IMAGE_PATH_MARKER);
  if (markerIndex < 0) return uri;

  const relativePath = uri.slice(
    markerIndex + LOCAL_IMAGE_PATH_MARKER.length,
  );
  const pathSegments = relativePath.split("/").filter(Boolean);
  if (pathSegments.length === 0) return uri;

  try {
    return new File(Paths.document, "sasang", ...pathSegments).uri;
  } catch {
    return uri;
  }
}
