import 'dart:io';

import 'package:exif/exif.dart';

class PhotoMetadata {
  const PhotoMetadata({this.takenAt, this.latitude, this.longitude});

  final DateTime? takenAt;
  final double? latitude;
  final double? longitude;
}

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

Future<PhotoMetadata> readPhotoMetadata(File file) async {
  try {
    final tags = await readExifFromBytes(await file.readAsBytes());
    DateTime? takenAt;
    for (final key in const [
      'EXIF DateTimeOriginal',
      'EXIF DateTimeDigitized',
      'Image DateTime',
    ]) {
      final date = parsePhotoDate(tags[key]?.printable);
      if (date != null) {
        takenAt = date;
        break;
      }
    }
    final latitude = _gpsCoordinate(
      tags['GPS GPSLatitude']?.values,
      tags['GPS GPSLatitudeRef']?.printable,
      negativeReference: 'S',
    );
    final longitude = _gpsCoordinate(
      tags['GPS GPSLongitude']?.values,
      tags['GPS GPSLongitudeRef']?.printable,
      negativeReference: 'W',
    );
    final validLocation =
        latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
    return PhotoMetadata(
      takenAt: takenAt,
      latitude: validLocation ? latitude : null,
      longitude: validLocation ? longitude : null,
    );
  } on Object {
    return const PhotoMetadata();
  }
}

Future<DateTime?> readPhotoTakenDate(File file) async =>
    (await readPhotoMetadata(file)).takenAt;

double? _gpsCoordinate(
  IfdValues? values,
  String? reference, {
  required String negativeReference,
}) {
  if (values is! IfdRatios || values.ratios.length < 3 || reference == null) {
    return null;
  }
  final degrees = values.ratios[0].toDouble();
  final minutes = values.ratios[1].toDouble();
  final seconds = values.ratios[2].toDouble();
  final coordinate = degrees + minutes / 60 + seconds / 3600;
  return reference.trim().toUpperCase() == negativeReference
      ? -coordinate
      : coordinate;
}

String photoDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime regionPhotoDate(String? takenAt, String createdAt) =>
    parsePhotoDate(takenAt) ??
    parsePhotoDate(createdAt) ??
    DateTime.fromMillisecondsSinceEpoch(0);

String koreanDate(DateTime date) => '${date.year}년 ${date.month}월 ${date.day}일';
