import 'package:flutter/widgets.dart';

import '../../core/storage/sasang_storage.dart';
import '../../models/map_models.dart';
import 'photo_date.dart';
import 'photo_date_dialog.dart';
import 'photo_picker_service.dart';

Future<RegionPhoto?> pickRegionPhoto({
  required BuildContext context,
  required PhotoPickerService picker,
  required SasangStorage storage,
  required MapMode mode,
  required MapRegion region,
}) async {
  final picked = await picker.pick();
  if (picked == null || !context.mounted) return null;
  final metadataDate = await readPhotoTakenDate(picked.file);
  final now = DateTime.now();
  final validMetadata = metadataDate != null && !metadataDate.isAfter(now);
  if (!context.mounted) return null;
  final selectedDate = await showPhotoDateDialog(
    context,
    photo: picked.file,
    initialDate: validMetadata ? metadataDate : now,
    dateFromMetadata: validMetadata,
  );
  if (selectedDate == null) return null;
  final createdAt = DateTime.now().toUtc();
  final saved = await storage.copyImage(
    picked.file,
    'photos',
    '${mode.storageKey}-${region.code}',
  );
  return RegionPhoto(
    id: '${picked.id}-${createdAt.microsecondsSinceEpoch}',
    uri: saved.uri.toString(),
    width: picked.width,
    height: picked.height,
    scale: 1,
    offsetX: 0,
    offsetY: 0,
    createdAt: createdAt.toIso8601String(),
    takenAt: photoDateKey(selectedDate),
  );
}
