import 'dart:convert';

enum MapMode {
  korea,
  world;

  String get storageKey => name;
  String get label => this == korea ? '대한민국 지도' : '세계 지도';
  String get description => this == korea ? '시·군·구별 여행 기록' : '국가별 여행 기록';
}

class RegionBounds {
  const RegionBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory RegionBounds.fromJson(Map<String, dynamic> json) => RegionBounds(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
  );

  final double x;
  final double y;
  final double width;
  final double height;
}

class MapRegion {
  const MapRegion({
    required this.code,
    required this.name,
    required this.geometryType,
    required this.polygonCount,
    required this.bounds,
    required this.pathData,
    this.englishName,
    this.provinceCode,
    this.provinceName,
  });

  factory MapRegion.fromJson(Map<String, dynamic> json) => MapRegion(
    code: json['code'] as String,
    name: json['name'] as String,
    englishName: json['englishName'] as String?,
    provinceCode: json['provinceCode'] as String?,
    provinceName: json['provinceName'] as String?,
    geometryType: json['geometryType'] as String,
    polygonCount: json['polygonCount'] as int,
    bounds: RegionBounds.fromJson(json['bounds'] as Map<String, dynamic>),
    pathData: json['path'] as String,
  );

  final String code;
  final String name;
  final String? englishName;
  final String? provinceCode;
  final String? provinceName;
  final String geometryType;
  final int polygonCount;
  final RegionBounds bounds;
  final String pathData;
}

class RegionPhoto {
  const RegionPhoto({
    required this.id,
    required this.uri,
    required this.width,
    required this.height,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.createdAt,
    this.takenAt,
  });

  factory RegionPhoto.fromJson(Map<String, dynamic> json) => RegionPhoto(
    id: json['id'] as String,
    uri: json['uri'] as String,
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    scale: (json['scale'] as num?)?.toDouble() ?? 1,
    offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0,
    offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0,
    createdAt: json['createdAt'] as String,
    takenAt: json['takenAt'] as String?,
  );

  final String id;
  final String uri;
  final double width;
  final double height;
  final double scale;
  final double offsetX;
  final double offsetY;
  final String createdAt;
  final String? takenAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'uri': uri,
    'width': width,
    'height': height,
    'scale': scale,
    'offsetX': offsetX,
    'offsetY': offsetY,
    'createdAt': createdAt,
    if (takenAt != null) 'takenAt': takenAt,
  };
}

class RegionPhotoAlbum {
  const RegionPhotoAlbum({required this.photos, required this.coverPhotoId});

  factory RegionPhotoAlbum.fromJson(Map<String, dynamic> json) {
    final photos = <RegionPhoto>[];
    final values = json['photos'];
    if (values is List<dynamic>) {
      for (final value in values) {
        if (value is Map<String, dynamic>) {
          photos.add(RegionPhoto.fromJson(value));
        }
      }
    }
    final requestedCover = json['coverPhotoId'] as String?;
    final coverExists = photos.any((photo) => photo.id == requestedCover);
    return RegionPhotoAlbum(
      photos: List.unmodifiable(photos),
      coverPhotoId: coverExists
          ? requestedCover!
          : photos.isEmpty
          ? ''
          : photos.first.id,
    );
  }

  factory RegionPhotoAlbum.fromLegacy(RegionPhoto photo) => RegionPhotoAlbum(
    photos: List.unmodifiable([photo]),
    coverPhotoId: photo.id,
  );

  final List<RegionPhoto> photos;
  final String coverPhotoId;

  RegionPhoto? get coverPhoto {
    for (final photo in photos) {
      if (photo.id == coverPhotoId) return photo;
    }
    return photos.isEmpty ? null : photos.first;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'coverPhotoId': coverPhoto?.id ?? '',
    'photos': photos.map((photo) => photo.toJson()).toList(growable: false),
  };
}

class RegionMapAsset {
  const RegionMapAsset({
    required this.version,
    required this.width,
    required this.height,
    required this.regions,
  });

  factory RegionMapAsset.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final metadata = json['metadata'] as Map<String, dynamic>;
    final viewBox = json['viewBox'] as Map<String, dynamic>;
    return RegionMapAsset(
      version: metadata['version'] as String,
      width: (viewBox['width'] as num).toDouble(),
      height: (viewBox['height'] as num).toDouble(),
      regions: (json['regions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MapRegion.fromJson)
          .toList(growable: false),
    );
  }

  final String version;
  final double width;
  final double height;
  final List<MapRegion> regions;
}

String regionPhotoKey(MapMode mode, String regionCode) =>
    '${mode.storageKey}:$regionCode';
