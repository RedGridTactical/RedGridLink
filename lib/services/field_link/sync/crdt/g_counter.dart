/// Grow-only Counter (G-Counter) CRDT for sequence number generation.
///
/// Each node independently increments its own counter. The global
/// counter value is the sum of all per-node counts. Merge takes the
/// per-node maximum, guaranteeing convergence.
///
/// Satisfies CRDT merge properties:
/// - **Commutative**: merge(a, b) == merge(b, a)
/// - **Associative**: merge(merge(a, b), c) == merge(a, merge(b, c))
/// - **Idempotent**: merge(a, a) == a
class GCounter {
  final Map<String, int> _counts;

  /// Create a G-Counter with the given per-node counts.
  const GCounter(this._counts);

  /// Create an empty G-Counter.
  const GCounter.zero() : _counts = const {};

  /// Increment the counter for [nodeId] by 1.
  ///
  /// Returns a new [GCounter] with the updated count. The original
  /// instance is not modified (immutable).
  GCounter increment(String nodeId) {
    final updated = Map<String, int>.from(_counts);
    updated[nodeId] = (updated[nodeId] ?? 0) + 1;
    return GCounter(Map.unmodifiable(updated));
  }

  /// Merge with [other] by taking the per-node maximum.
  ///
  /// This operation is commutative, associative, and idempotent.
  GCounter merge(GCounter other) {
    final merged = Map<String, int>.from(_counts);
    for (final entry in other._counts.entries) {
      final current = merged[entry.key] ?? 0;
      if (entry.value > current) {
        merged[entry.key] = entry.value;
      }
    }
    return GCounter(Map.unmodifiable(merged));
  }

  /// The global counter value (sum of all per-node counts).
  int get value => _counts.values.fold(0, (sum, v) => sum + v);

  /// The count for a specific [nodeId], or 0 if unknown.
  int countFor(String nodeId) => _counts[nodeId] ?? 0;

  /// All known node IDs.
  Set<String> get nodeIds => _counts.keys.toSet();

  /// Serialize to JSON-compatible map.
  Map<String, int> toJson() => Map<String, int>.from(_counts);

  /// Deserialize from JSON map.
  factory GCounter.fromJson(Map<String, dynamic> json) {
    final counts = <String, int>{};
    for (final entry in json.entries) {
      counts[entry.key] = (entry.value as num).toInt();
    }
    return GCounter(Map.unmodifiable(counts));
  }

  @override
  String toString() => 'GCounter(value: $value, nodes: $_counts)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GCounter) return false;
    if (_counts.length != other._counts.length) return false;
    for (final entry in _counts.entries) {
      if (other._counts[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        _counts.entries.map((e) => Object.hash(e.key, e.value)),
      );
}
