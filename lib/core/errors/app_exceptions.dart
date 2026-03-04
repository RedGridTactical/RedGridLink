/// Custom exception hierarchy for Red Grid Link

class AppException implements Exception {
  final String message;
  final Object? cause;
  const AppException(this.message, [this.cause]);
  @override
  String toString() => 'AppException: $message';
}

class MgrsException extends AppException {
  const MgrsException(super.message, [super.cause]);
}

class FieldLinkException extends AppException {
  const FieldLinkException(super.message, [super.cause]);
}

class TransportException extends FieldLinkException {
  const TransportException(super.message, [super.cause]);
}

class SyncException extends FieldLinkException {
  const SyncException(super.message, [super.cause]);
}

class SecurityException extends FieldLinkException {
  const SecurityException(super.message, [super.cause]);
}

class MapException extends AppException {
  const MapException(super.message, [super.cause]);
}

class LocationException extends AppException {
  const LocationException(super.message, [super.cause]);
}

class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}

class EntitlementException extends AppException {
  const EntitlementException(super.message, [super.cause]);
}
