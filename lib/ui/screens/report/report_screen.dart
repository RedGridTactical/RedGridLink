import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:red_grid_link/core/theme/tactical_text_styles.dart';
import 'package:red_grid_link/core/utils/haptics.dart';
import 'package:red_grid_link/data/models/aar_data.dart';
import 'package:red_grid_link/providers/aar_provider.dart';
import 'package:red_grid_link/providers/theme_provider.dart';
import 'package:red_grid_link/ui/common/widgets/tactical_button.dart';
import 'widgets/aar_summary_card.dart';
import 'widgets/marker_log_card.dart';
import 'widgets/participant_list_card.dart';

/// AAR (After-Action Report) preview screen.
///
/// Shows a summary of the compiled session data and provides an
/// "Export PDF" button that triggers PDF generation and system share.
///
/// Requires a [sessionId] parameter to load the session data.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final aarAsync = ref.watch(sessionAarProvider(sessionId));
    final exportState = ref.watch(exportNotifierProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.accent),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Icon(
                    Icons.description,
                    size: 22,
                    color: colors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AFTER-ACTION REPORT',
                    style: TacticalTextStyles.heading(colors),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Session review and PDF export',
                style: TacticalTextStyles.caption(colors),
              ),
            ),

            const SizedBox(height: 8),

            // Content
            Expanded(
              child: aarAsync.when(
                loading: () => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colors.accent),
                      const SizedBox(height: 16),
                      Text(
                        'COMPILING REPORT...',
                        style: TacticalTextStyles.caption(colors),
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => _ErrorView(
                  error: error,
                  colors: colors,
                  onRetry: () =>
                      ref.invalidate(sessionAarProvider(sessionId)),
                ),
                data: (aar) => _AarContent(aar: aar),
              ),
            ),

            // Export button (pinned at bottom)
            if (aarAsync.hasValue)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: exportState.when(
                  loading: () => TacticalButton(
                    label: 'Generating PDF...',
                    icon: Icons.hourglass_top,
                    colors: colors,
                    onPressed: null,
                  ),
                  error: (error, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF330000),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF660000)),
                        ),
                        child: Text(
                          'EXPORT FAILED: ${error.toString()}',
                          style: TacticalTextStyles.caption(colors).copyWith(
                            color: const Color(0xFFFF4444),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TacticalButton(
                        label: 'Retry Export',
                        icon: Icons.refresh,
                        colors: colors,
                        onPressed: () {
                          tapMedium();
                          ref.read(exportNotifierProvider.notifier).reset();
                          _export(ref, aarAsync.value!);
                        },
                      ),
                    ],
                  ),
                  data: (path) => TacticalButton(
                    label: path != null ? 'Export Again' : 'Export PDF',
                    icon: Icons.share,
                    colors: colors,
                    onPressed: () {
                      tapMedium();
                      _export(ref, aarAsync.value!);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _export(WidgetRef ref, AarData aar) {
    ref.read(exportNotifierProvider.notifier).exportAndShare(aar);
  }
}

/// Scrollable content showing the AAR data cards.
class _AarContent extends ConsumerWidget {
  const _AarContent({required this.aar});

  final AarData aar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          AarSummaryCard(aar: aar, colors: colors),
          const SizedBox(height: 12),

          // Participant list
          ParticipantListCard(aar: aar, colors: colors),
          const SizedBox(height: 12),

          // Marker log
          MarkerLogCard(aar: aar, colors: colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Error display with retry button.
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.colors,
    required this.onRetry,
  });

  final Object error;
  final dynamic colors;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFCC0000),
            ),
            const SizedBox(height: 16),
            Text(
              'FAILED TO COMPILE REPORT',
              style: TacticalTextStyles.subheading(colors),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TacticalTextStyles.caption(colors),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TacticalButton(
              label: 'Retry',
              icon: Icons.refresh,
              colors: colors,
              onPressed: () {
                tapMedium();
                onRetry();
              },
            ),
          ],
        ),
      ),
    );
  }
}
