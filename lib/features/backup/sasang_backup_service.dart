import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/sasang_storage.dart';
import '../../models/map_models.dart';

class SasangBackupResult {
  const SasangBackupResult({
    required this.file,
    required this.createdAt,
    required this.photoCount,
  });

  final File file;
  final DateTime createdAt;
  final int photoCount;
}

class SasangBackupException implements Exception {
  const SasangBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SasangBackupService {
  SasangBackupService({
    required this.storage,
    this.outputDirectory,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const format = 'sasang-backup';
  static const formatVersion = 1;

  final SasangStorage storage;
  final Directory? outputDirectory;
  final DateTime Function() _clock;

  Future<SasangBackupResult> create({
    required String name,
    required String? profileImageUri,
    required Map<String, RegionPhotoAlbum> albums,
  }) async {
    final createdAt = _clock();
    final directory =
        outputDirectory ??
        Directory(
          p.join((await getTemporaryDirectory()).path, 'sasang', 'backups'),
        );
    await directory.create(recursive: true);

    final mediaFiles = <String, File>{};
    final archivePathByUri = <String, String>{};
    var mediaIndex = 0;

    Future<String?> archiveImage(String? uri, String role) async {
      if (uri == null || uri.isEmpty) return null;
      final existing = archivePathByUri[uri];
      if (existing != null) return existing;
      final source = await storage.resolveImage(uri);
      if (source == null || !await source.exists()) {
        throw SasangBackupException(
          role == 'profile'
              ? '프로필 사진 파일을 찾을 수 없어 백업을 만들지 못했어요.'
              : '여행 사진 파일을 찾을 수 없어 백업을 만들지 못했어요.',
        );
      }
      final extension = _safeExtension(source.path);
      final archivePath =
          'media/${mediaIndex.toString().padLeft(5, '0')}$extension';
      mediaIndex += 1;
      archivePathByUri[uri] = archivePath;
      mediaFiles[archivePath] = source;
      return archivePath;
    }

    final profileImage = await archiveImage(profileImageUri, 'profile');
    final albumData = <String, dynamic>{};
    final sortedEntries = albums.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    var photoCount = 0;
    for (final entry in sortedEntries) {
      final photos = <Map<String, dynamic>>[];
      for (final photo in entry.value.photos) {
        final archivePath = await archiveImage(photo.uri, 'photo');
        photos.add({...photo.toJson(), 'uri': archivePath});
        photoCount += 1;
      }
      albumData[entry.key] = {
        'version': 1,
        'photos': photos,
        'coverPhotoId': entry.value.coverPhotoId,
      };
    }

    final manifest = <String, dynamic>{
      'format': format,
      'formatVersion': formatVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'profile': {'name': name, 'image': profileImage},
      'regionPhotoAlbums': albumData,
    };
    final timestamp = _filenameTimestamp(createdAt);
    final output = File(
      p.join(directory.path, 'Sasang-backup-$timestamp.sasangbackup'),
    );
    final manifestFile = File(
      p.join(
        directory.path,
        '.sasang-manifest-${createdAt.microsecondsSinceEpoch}.json',
      ),
    );
    await manifestFile.writeAsString(jsonEncode(manifest), flush: true);
    if (await output.exists()) await output.delete();

    final encoder = ZipFileEncoder();
    try {
      encoder.create(output.path, modified: createdAt);
      await encoder.addFile(manifestFile, 'manifest.json');
      for (final entry in mediaFiles.entries) {
        await encoder.addFile(entry.value, entry.key);
      }
      await encoder.close();
    } on Object {
      if (await output.exists()) await output.delete();
      rethrow;
    } finally {
      if (await manifestFile.exists()) await manifestFile.delete();
    }

    return SasangBackupResult(
      file: output,
      createdAt: createdAt,
      photoCount: photoCount,
    );
  }
}

String _safeExtension(String path) {
  final extension = p.extension(path).toLowerCase();
  return RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension) ? extension : '.jpg';
}

String _filenameTimestamp(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}${twoDigits(value.month)}${twoDigits(value.day)}-'
      '${twoDigits(value.hour)}${twoDigits(value.minute)}'
      '${twoDigits(value.second)}';
}
