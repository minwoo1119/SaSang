import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/map_models.dart';

Map<String, dynamic> decodeZustandState(String source) {
  final value = jsonDecode(source);
  if (value is Map<String, dynamic> && value['state'] is Map<String, dynamic>) {
    return value['state'] as Map<String, dynamic>;
  }
  return <String, dynamic>{};
}

class StoredSasangState {
  const StoredSasangState({
    required this.hasStarted,
    required this.name,
    required this.profileImageUri,
    required this.regionPhotos,
  });

  final bool hasStarted;
  final String name;
  final String? profileImageUri;
  final Map<String, RegionPhoto> regionPhotos;
}

/// Reads and writes the exact envelope produced by Zustand persist.
class SasangStorage {
  static const _sessionKey = 'sasang-local-session';
  static const _profileKey = 'sasang-profile';
  static const _mapKey = 'sasang-map-ui';

  Directory? _primaryRoot;
  List<Directory> _candidateRoots = const [];

  Future<void> _initialize() async {
    if (_primaryRoot != null) return;
    final documents = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    _primaryRoot = Directory(p.join(documents.path, 'sasang'));
    final roots = <String>{
      p.join(documents.path, 'sasang'),
      p.join(support.path, 'sasang'),
      p.join(documents.parent.path, 'files', 'sasang'),
    };
    _candidateRoots = roots.map(Directory.new).toList(growable: false);
  }

  Future<StoredSasangState> read() async {
    await _initialize();
    final session = await _readStore(_sessionKey);
    final profile = await _readStore(_profileKey);
    final map = await _readStore(_mapKey);
    final photos = <String, RegionPhoto>{};
    final photoJson = map['regionPhotos'];
    if (photoJson is Map<String, dynamic>) {
      for (final entry in photoJson.entries) {
        if (entry.value is Map<String, dynamic>) {
          photos[entry.key] = RegionPhoto.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }
    await _writeMigrationMarker();
    return StoredSasangState(
      hasStarted: session['hasStarted'] as bool? ?? false,
      name: profile['name'] as String? ?? '여행자',
      profileImageUri: profile['profileImageUri'] as String?,
      regionPhotos: photos,
    );
  }

  Future<Map<String, dynamic>> _readStore(String key) async {
    final filename = '${Uri.encodeComponent(key)}.json';
    for (final root in _candidateRoots) {
      final file = File(p.join(root.path, 'state', filename));
      if (!await file.exists()) continue;
      try {
        return decodeZustandState(await file.readAsString());
      } on FormatException {
        // Keep probing: another application-owned root may contain a valid copy.
      }
    }
    return <String, dynamic>{};
  }

  Future<void> writeSession(bool hasStarted) =>
      _writeStore(_sessionKey, {'hasStarted': hasStarted});

  Future<void> writeProfile(String name, String? profileImageUri) =>
      _writeStore(_profileKey, {
        'name': name,
        'profileImageUri': profileImageUri,
      });

  Future<void> writePhotos(Map<String, RegionPhoto> photos) => _writeStore(
    _mapKey,
    {'regionPhotos': photos.map((key, value) => MapEntry(key, value.toJson()))},
  );

  Future<void> _writeStore(String key, Map<String, dynamic> state) async {
    await _initialize();
    final directory = Directory(p.join(_primaryRoot!.path, 'state'));
    await directory.create(recursive: true);
    final target = File(
      p.join(directory.path, '${Uri.encodeComponent(key)}.json'),
    );
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsString(jsonEncode({'state': state, 'version': 0}));
    if (await target.exists()) await target.delete();
    await temporary.rename(target.path);
  }

  Future<File> copyImage(File source, String folder, String prefix) async {
    await _initialize();
    final directory = Directory(p.join(_primaryRoot!.path, folder));
    await directory.create(recursive: true);
    final extension = p.extension(source.path).isEmpty
        ? '.jpg'
        : p.extension(source.path).toLowerCase();
    return source.copy(
      p.join(
        directory.path,
        '$prefix-${DateTime.now().millisecondsSinceEpoch}$extension',
      ),
    );
  }

  Future<File?> resolveImage(String? uri) async {
    if (uri == null || uri.isEmpty) return null;
    await _initialize();
    final parsed = Uri.tryParse(uri);
    if (parsed != null && parsed.scheme == 'file') {
      final direct = File(parsed.toFilePath());
      if (await direct.exists()) return direct;
    }
    final marker = uri.lastIndexOf('/sasang/');
    if (marker < 0) return null;
    final relative = uri.substring(marker + '/sasang/'.length);
    if (relative.split('/').contains('..')) return null;
    for (final root in _candidateRoots) {
      final file = File(p.join(root.path, relative));
      if (await file.exists()) return file;
    }
    return null;
  }

  Future<void> clearState() async {
    await _initialize();
    final directory = Directory(p.join(_primaryRoot!.path, 'state'));
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<void> _writeMigrationMarker() async {
    final directory = Directory(p.join(_primaryRoot!.path, 'state'));
    await directory.create(recursive: true);
    final marker = File(p.join(directory.path, 'flutter-migration-v1.json'));
    if (!await marker.exists()) {
      await marker.writeAsString(
        jsonEncode({
          'version': 1,
          'completedAt': DateTime.now().toUtc().toIso8601String(),
          'source': 'zustand-file-storage',
        }),
      );
    }
  }
}
