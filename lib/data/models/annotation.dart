/// Annotation geometry type
enum AnnotationType {
  polyline,
  polygon;

  static AnnotationType fromString(String value) =>
      AnnotationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AnnotationType.polyline,
      );
}

/// A lat/lon point within an annotation
class AnnotationPoint {
  final double lat;
  final double lon;

  const AnnotationPoint({required this.lat, required this.lon});

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon};

  factory AnnotationPoint.fromJson(Map<String, dynamic> json) =>
      AnnotationPoint(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );
}

/// Synced map annotation (polylines and polygons)
class Annotation {
  final String id;
  final AnnotationType type;
  final List<AnnotationPoint> points;
  final int color;
  final double strokeWidth;
  final String? label;
  final String createdBy;
  final DateTime createdAt;
  final bool isSynced;

  const Annotation({
    required this.id,
    required this.type,
    required this.points,
    this.color = 0xFFFF0000,
    this.strokeWidth = 2.0,
    this.label,
    required this.createdBy,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'pts': points.map((p) => p.toJson()).toList(),
    'clr': color,
    'sw': strokeWidth,
    'lbl': label,
    'by': createdBy,
    'at': createdAt.millisecondsSinceEpoch,
    'syn': isSynced,
  };

  factory Annotation.fromJson(Map<String, dynamic> json) => Annotation(
    id: json['id'] as String,
    type: AnnotationType.fromString(json['type'] as String),
    points: (json['pts'] as List<dynamic>)
        .map((p) => AnnotationPoint.fromJson(p as Map<String, dynamic>))
        .toList(),
    color: json['clr'] as int? ?? 0xFFFF0000,
    strokeWidth: (json['sw'] as num?)?.toDouble() ?? 2.0,
    label: json['lbl'] as String?,
    createdBy: json['by'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
    isSynced: json['syn'] as bool? ?? false,
  );

  Annotation copyWith({
    List<AnnotationPoint>? points,
    int? color,
    double? strokeWidth,
    String? label,
    bool? isSynced,
  }) =>
      Annotation(
        id: id,
        type: type,
        points: points ?? this.points,
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        label: label ?? this.label,
        createdBy: createdBy,
        createdAt: createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
}
