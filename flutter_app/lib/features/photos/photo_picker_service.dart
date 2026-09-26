import 'dart:io';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

class PickedPhoto {
  const PickedPhoto({
    required this.file,
    required this.width,
    required this.height,
    required this.id,
  });

  final File file;
  final double width;
  final double height;
  final String id;
}

class PhotoPickerService {
  PhotoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<PickedPhoto?> pick({int imageQuality = 90}) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      requestFullMetadata: true,
    );
    if (xFile == null) return null;
    final file = File(xFile.path);
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final frame = await codec.getNextFrame();
    codec.dispose();
    final decoded = frame.image;
    final result = PickedPhoto(
      file: file,
      width: decoded.width.toDouble(),
      height: decoded.height.toDouble(),
      id: xFile.name.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : xFile.name,
    );
    decoded.dispose();
    return result;
  }
}
