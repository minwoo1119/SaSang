const EXIF_DATE_KEYS = [
  "DateTimeOriginal",
  "DateTimeDigitized",
  "DateTime",
  "CreationDate",
] as const;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function createValidLocalDate(year: number, month: number, day: number) {
  const date = new Date(year, month - 1, day, 12);
  if (
    date.getFullYear() !== year ||
    date.getMonth() !== month - 1 ||
    date.getDate() !== day
  ) {
    return null;
  }

  return date;
}

export function parsePhotoDate(value: unknown): Date | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    const date = new Date(value < 1_000_000_000_000 ? value * 1000 : value);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  if (typeof value !== "string") return null;

  const dateParts = value.match(/^(\d{4})[:-](\d{2})[:-](\d{2})/);
  if (dateParts) {
    const [, year, month, day] = dateParts;
    return createValidLocalDate(Number(year), Number(month), Number(day));
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

export function getPhotoTakenDate(
  exif: Record<string, unknown> | null | undefined,
): Date | null {
  if (!exif) return null;

  const groups = [
    exif,
    exif.Exif,
    exif["{Exif}"],
    exif.TIFF,
    exif["{TIFF}"],
  ].filter(isRecord);

  for (const group of groups) {
    for (const key of EXIF_DATE_KEYS) {
      const date = parsePhotoDate(group[key]);
      if (date) return date;
    }
  }

  return null;
}

export function toPhotoDateKey(date: Date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function getRegionPhotoDateKey(photo: {
  createdAt: string;
  takenAt?: string;
}) {
  const takenAt = parsePhotoDate(photo.takenAt);
  if (takenAt) return toPhotoDateKey(takenAt);

  const createdAt = parsePhotoDate(photo.createdAt);
  return toPhotoDateKey(createdAt ?? new Date(0));
}
