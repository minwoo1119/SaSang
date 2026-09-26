import 'dart:io';

import 'package:exif/exif.dart';

DateTime? parsePhotoDate(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  final match = RegExp(r'^(\d{4})[:-](\d{2})[:-](\d{2})').firstMatch(text);
  if (match != null) {
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final value = DateTime(year, month, day, 12);
    if (value.year == year && value.month == month && value.day == day) {
      return value;
    }
    return null;
  }
  return DateTime.tryParse(text);
}

Future<DateTime?> readPhotoTakenDate(File file) async {
  try {
    final tags = await readExifFromBytes(await file.readAsBytes());
    for (final key in const [
      'EXIF DateTimeOriginal',
      'EXIF DateTimeDigitized',
      'Image DateTime',
    ]) {
      final date = parsePhotoDate(tags[key]?.printable);
      if (date != null) return date;
    }
  } on Object {
    return null;
  }
  return null;
}

String photoDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime regionPhotoDate(String? takenAt, String createdAt) =>
    parsePhotoDate(takenAt) ??
    parsePhotoDate(createdAt) ??
    DateTime.fromMillisecondsSinceEpoch(0);

String koreanDate(DateTime date) => '${date.year}년 ${date.month}월 ${date.day}일';
