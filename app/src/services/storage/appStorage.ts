import { Directory, File, Paths } from "expo-file-system";

function getStorageFile(name: string) {
  const directory = new Directory(Paths.document, "sasang", "state");
  directory.create({ idempotent: true, intermediates: true });
  return new File(directory, `${encodeURIComponent(name)}.json`);
}

export const appStorage = {
  async clear() {
    const directory = new Directory(Paths.document, "sasang", "state");
    if (directory.exists) {
      directory.delete();
    }
  },
  async getItem(name: string) {
    const file = getStorageFile(name);
    return file.exists ? file.text() : null;
  },
  async removeItem(name: string) {
    const file = getStorageFile(name);
    if (file.exists) {
      file.delete();
    }
  },
  async setItem(name: string, value: string) {
    const file = getStorageFile(name);
    file.write(value);
  },
};
