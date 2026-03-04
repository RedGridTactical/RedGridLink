import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/data/repositories/annotation_repository.dart';
import 'package:red_grid_link/data/repositories/marker_repository.dart';
import 'package:red_grid_link/data/repositories/peer_repository.dart';
import 'package:red_grid_link/data/repositories/session_repository.dart';
import 'package:red_grid_link/providers/location_provider.dart';
import 'package:red_grid_link/services/aar/aar_service.dart';
import 'package:red_grid_link/services/aar/export_service.dart';
import 'package:red_grid_link/services/aar/pdf_generator.dart';

// ---------------------------------------------------------------------------
// Repository providers — must be overridden in root ProviderScope
// ---------------------------------------------------------------------------

/// Provider for [SessionRepository].
///
/// Must be overridden in the root [ProviderScope] with a concrete
/// instance backed by the initialized [AppDatabase].
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  throw UnimplementedError(
    'sessionRepositoryProvider must be overridden in the root ProviderScope.',
  );
});

/// Provider for [PeerRepository].
///
/// Must be overridden in the root [ProviderScope] with a concrete
/// instance backed by the initialized [AppDatabase].
final peerRepositoryProvider = Provider<PeerRepository>((ref) {
  throw UnimplementedError(
    'peerRepositoryProvider must be overridden in the root ProviderScope.',
  );
});

/// Provider for [MarkerRepository].
///
/// Must be overridden in the root [ProviderScope] with a concrete
/// instance backed by the initialized [AppDatabase].
final markerRepositoryProvider = Provider<MarkerRepository>((ref) {
  throw UnimplementedError(
    'markerRepositoryProvider must be overridden in the root ProviderScope.',
  );
});

/// Provider for [AnnotationRepository].
///
/// Must be overridden in the root [ProviderScope] with a concrete
/// instance backed by the initialized [AppDatabase].
final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  throw UnimplementedError(
    'annotationRepositoryProvider must be overridden in the root ProviderScope.',
  );
});

// ---------------------------------------------------------------------------
// AAR Service
// ---------------------------------------------------------------------------

/// Provides the [AarService] singleton.
///
/// Depends on all five repositories to compile session data.
/// Reuses [trackRepositoryProvider] from location_provider.dart.
final aarServiceProvider = Provider<AarService>((ref) {
  return AarService(
    sessionRepository: ref.watch(sessionRepositoryProvider),
    peerRepository: ref.watch(peerRepositoryProvider),
    markerRepository: ref.watch(markerRepositoryProvider),
    trackRepository: ref.watch(trackRepositoryProvider),
    annotationRepository: ref.watch(annotationRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// PDF Generator
// ---------------------------------------------------------------------------

/// Provides the [PdfGenerator] instance.
final pdfGeneratorProvider = Provider<PdfGenerator>((ref) {
  return PdfGenerator();
});

// ---------------------------------------------------------------------------
// Export Service
// ---------------------------------------------------------------------------

/// Provides the [ExportService] for PDF generation and sharing.
final exportServiceProvider = Provider<ExportService>((ref) {
  final pdfGenerator = ref.watch(pdfGeneratorProvider);
  return ExportService(pdfGenerator: pdfGenerator);
});

// ---------------------------------------------------------------------------
// Session AAR data
// ---------------------------------------------------------------------------

/// Compiles the [AarData] for a given session ID.
///
/// This is a [FutureProvider.family] so it can be called with different
/// session IDs. The compiled data is cached by Riverpod until the
/// provider is invalidated.
final sessionAarProvider =
    FutureProvider.family<AarData, String>((ref, sessionId) async {
  final aarService = ref.watch(aarServiceProvider);
  return aarService.compileAar(sessionId);
});

// ---------------------------------------------------------------------------
// Export state
// ---------------------------------------------------------------------------

/// Tracks the export operation state for the report screen.
///
/// Holds null when idle, or the file path after a successful export.
class ExportNotifier extends StateNotifier<AsyncValue<String?>> {
  final ExportService _exportService;

  ExportNotifier(this._exportService) : super(const AsyncData(null));

  /// Export a PDF for the given [AarData] and share it.
  Future<void> exportAndShare(AarData aar) async {
    state = const AsyncLoading();
    try {
      final path = await _exportService.exportAndShare(aar);
      state = AsyncData(path);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Reset the export state back to idle.
  void reset() {
    state = const AsyncData(null);
  }
}

/// Provider for the [ExportNotifier].
final exportNotifierProvider =
    StateNotifierProvider<ExportNotifier, AsyncValue<String?>>((ref) {
  final exportService = ref.watch(exportServiceProvider);
  return ExportNotifier(exportService);
});
