import { Directory, File, Paths } from "expo-file-system";

type ImageFolder = "photos" | "profile";

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
