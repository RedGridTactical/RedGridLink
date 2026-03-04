/// Last-Writer-Wins Register for CRDT-based position sync.
///
/// A conflict-free replicated data type (CRDT) that resolves write
/// conflicts by keeping the value with the highest timestamp. When
/// timestamps are equal, the lexicographically greater [nodeId] wins
/// (deterministic tiebreaker).
///
/// Satisfies the three CRDT merge properties:
/// - **Commutative**: merge(a, b) == merge(b, a)
/// - **Associative**: merge(merge(a, b), c) == merge(a, merge(b, c))
/// - **Idempotent**: merge(a, a) == a
class LwwRegister<T> {
  /// Device ID that wrote this value.
  final String nodeId;

  /// Logical timestamp (milliseconds since epoch).
  final int timestamp;

  /// The stored value.
  final T value;

  const LwwRegister({
    required this.nodeId,
    required this.timestamp,
    required this.value,
  });

  /// Returns `true` if this register has a strictly newer timestamp than
  /// [other], or if timestamps are equal and this [nodeId] is
  /// lexicographically greater.
  bool isNewerThan(LwwRegister<T> other) {
    if (timestamp != other.timestamp) {
      return timestamp > other.timestamp;
    }
    return nodeId.compareTo(other.nodeId) > 0;
  }

  /// Merge two registers, keeping the one with the higher timestamp.
  ///
  /// Tiebreaker: if timestamps are equal, the register whose [nodeId]
  /// is lexicographically greater wins.
  ///
  /// This operation is commutative, associative, and idempotent.
  LwwRegister<T> merge(LwwRegister<T> other) {
    if (isNewerThan(other)) {
      return this;
    }
    if (other.isNewerThan(this)) {
      return other;
    }
    // Completely equal — idempotent case.
    return this;
  }

  /// Create a new register with the given [value] and the current wall-clock
  /// time as the timestamp.
  LwwRegister<T> withValue(T newValue) => LwwRegister<T>(
        nodeId: nodeId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        value: newValue,
      );

  @override
  String toString() =>
      'LwwRegister(nodeId: $nodeId, ts: $timestamp, value: $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LwwRegister<T> &&
          nodeId == other.nodeId &&
          timestamp == other.timestamp &&
          value == other.value;

  @override
  int get hashCode => Object.hash(nodeId, timestamp, value);
}
