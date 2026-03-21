import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tactical_colors.dart';
import '../../../core/theme/tactical_text_styles.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/aar_data.dart';
import '../../../providers/aar_provider.dart';
import '../../../providers/theme_provider.dart';
import '../report/report_screen.dart';
import 'widgets/export_import_buttons.dart';

/// Provider that exposes the live session history list from the database.
///
/// Must be overridden in root ProviderScope with a concrete implementation
/// that streams [SessionHistoryDao.watchAll].
final sessionHistoryStreamProvider =
    StreamProvider<List<SessionHistoryEntry>>((ref) {
  throw UnimplementedError(
    'sessionHistoryStreamProvider must be overridden in root ProviderScope.',
  );
});

/// Lightweight data class mirroring the Drift-generated row.
///
/// Used so the UI layer does not depend on the Drift `SessionHistoryEntry`
/// generated class directly.
class SessionHistoryEntry {
  final String id;
  final String name;
  final String mode;
  final int startTime;
  final int? endTime;
  final int peerCount;
  final int markerCount;

  const SessionHistoryEntry({
    required this.id,
    required this.name,
    required this.mode,
    required this.startTime,
    this.endTime,
    this.peerCount = 0,
    this.markerCount = 0,
  });
}

/// Full-screen session history list with export/import support.
///
/// Each completed session row has an export button. The app bar includes
/// an import button that reads a JSON file and navigates to the report
/// screen with the imported data.
class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final historyAsync = ref.watch(sessionHistoryStreamProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.accent),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Icon(Icons.history, size: 22, color: colors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'SESSION HISTORY',
                    style: TacticalTextStyles.heading(colors),
                  ),
                  const Spacer(),
                  ExportImportActions(
                    colors: colors,
                    onImported: (aar) => _onImported(context, aar),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Past sessions and data export',
                style: TacticalTextStyles.caption(colors),
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Expanded(
              child: historyAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: colors.accent),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load history',
                    style: TacticalTextStyles.caption(colors),
                  ),
                ),
                data: (entries) => entries.isEmpty
                    ? _EmptyState(colors: colors)
                    : _SessionList(
                        entries: entries,
                        colors: colors,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onImported(BuildContext context, AarData aar) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportScreen(sessionId: aar.sessionId),
      ),
    );
  }
}

/// Shown when no session history entries exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});

  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: colors.text3),
          const SizedBox(height: 12),
          Text(
            'NO SESSIONS YET',
            style: TacticalTextStyles.subheading(colors),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed sessions will appear here',
            style: TacticalTextStyles.caption(colors),
          ),
        ],
      ),
    );
  }
}

/// Scrollable list of session history entries.
class _SessionList extends ConsumerWidget {
  const _SessionList({
    required this.entries,
    required this.colors,
  });

  final List<SessionHistoryEntry> entries;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _SessionTile(entry: entry, colors: colors);
      },
    );
  }
}

/// Single session history row.
class _SessionTile extends ConsumerWidget {
  const _SessionTile({
    required this.entry,
    required this.colors,
  });

  final SessionHistoryEntry entry;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = DateTime.fromMillisecondsSinceEpoch(entry.startTime);
    final dateStr =
        '${start.day.toString().padLeft(2, '0')}/'
        '${start.month.toString().padLeft(2, '0')}/'
        '${start.year}';
    final timeStr =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';

    final durationStr = entry.endTime != null
        ? _formatDuration(
            Duration(milliseconds: entry.endTime! - entry.startTime),
          )
        : 'In progress';

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.text3.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          entry.name.toUpperCase(),
          style: TacticalTextStyles.body(colors).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$dateStr $timeStr  |  $durationStr  |  '
          '${entry.peerCount} peers  |  ${entry.markerCount} markers',
          style: TacticalTextStyles.dim(colors).copyWith(fontSize: 11),
        ),
        trailing: _buildExportButton(ref),
        onTap: () {
          tapLight();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReportScreen(sessionId: entry.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportButton(WidgetRef ref) {
    // We use a FutureBuilder-like approach: watch the session AAR provider
    // and show the export button once data is available.
    final aarAsync = ref.watch(sessionAarProvider(entry.id));
    return aarAsync.when(
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Icon(Icons.error_outline, color: colors.text3, size: 20),
      data: (aar) => SessionExportButton(aarData: aar, colors: colors),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
