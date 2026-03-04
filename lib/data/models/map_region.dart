/// Geographic bounds for a map region
class MapBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const MapBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  Map<String, dynamic> toJson() => {
    'n': north,
    's': south,
    'e': east,
    'w': west,
  };

  factory MapBounds.fromJson(Map<String, dynamic> json) => MapBounds(
    north: (json['n'] as num).toDouble(),
    south: (json['s'] as num).toDouble(),
    east: (json['e'] as num).toDouble(),
    west: (json['w'] as num).toDouble(),
  );
}

/// Downloadable offline map region
class MapRegion {
  final String id;
  final String name;
  final MapBounds bounds;
  final int minZoom;
  final int maxZoom;
  final int? sizeBytes;
  final DateTime? downloadedAt;
  final String? filePath;

  const MapRegion({
    required this.id,
    required this.name,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    this.sizeBytes,
    this.downloadedAt,
    this.filePath,
  });

  /// Whether this region has been downloaded and is available offline
  bool get isDownloaded => downloadedAt != null && filePath != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bounds': bounds.toJson(),
    'minZ': minZoom,
    'maxZ': maxZoom,
    'size': sizeBytes,
    'dlAt': downloadedAt?.millisecondsSinceEpoch,
    'path': filePath,
  };

  factory MapRegion.fromJson(Map<String, dynamic> json) => MapRegion(
    id: json['id'] as String,
    name: json['name'] as String,
    bounds: MapBounds.fromJson(json['bounds'] as Map<String, dynamic>),
    minZoom: json['minZ'] as int,
    maxZoom: json['maxZ'] as int,
    sizeBytes: json['size'] as int?,
    downloadedAt: json['dlAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['dlAt'] as int)
        : null,
    filePath: json['path'] as String?,
  );

  MapRegion copyWith({
    String? name,
    int? sizeBytes,
    DateTime? downloadedAt,
    String? filePath,
  }) =>
      MapRegion(
        id: id,
        name: name ?? this.name,
        bounds: bounds,
        minZoom: minZoom,
        maxZoom: maxZoom,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        downloadedAt: downloadedAt ?? this.downloadedAt,
        filePath: filePath ?? this.filePath,
      );
}
