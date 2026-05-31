import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../providers/location_provider.dart';
import '../../../../providers/preflight_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../services/field_link/preflight/preflight_report.dart';

/// Field Readiness Preflight bottom sheet.
///
/// One-tap, pre-mission "is my kit ready?" check. Shows the local device's
/// readiness across GPS, Bluetooth, offline maps, encryption, roster, peer
/// contact, and battery, rolled into a single READY / CAUTION / NOT READY
/// verdict. For Pro/Team tiers it also shows a whole-team readiness board
/// built from teammates' broadcast status.
class PreflightSheet extends ConsumerWidget {
  const PreflightSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(currentThemeProvider);
    final report = ref.watch(localPreflightReportProvider);
    final teamUnlocked = ref.watch(teamPreflightUnlockedProvider);
    final teamReports = ref.watch(teamPreflightReportsProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: colors.border),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('FIELD READINESS', style: TacticalTextStyles.heading(colors)),
            const SizedBox(height: 4),
            Text(
              'Confirm your kit before you step off coverage.',
              style: TacticalTextStyles.caption(colors),
            ),
            const SizedBox(height: 16),

            _VerdictBanner(status: report.overall, report: report, colors: colors),
            const SizedBox(height: 16),

            ...report.checks.map(
              (c) => _CheckRow(check: c, colors: colors),
            ),

            const SizedBox(height: 20),
            _TeamBoard(
              unlocked: teamUnlocked,
              reports: teamReports.values.toList(),
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({
    required this.status,
    required this.report,
    required this.colors,
  });

  final PreflightStatus status;
  final PreflightReport report;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(status);
    final (label, sub) = switch (status) {
      PreflightStatus.ready => ('READY', 'All checks clear'),
      PreflightStatus.caution => (
          'CAUTION',
          '${report.cautionCount} item${report.cautionCount == 1 ? '' : 's'} to review'
        ),
      PreflightStatus.notReady => (
          'NOT READY',
          '${report.notReadyCount} blocker${report.notReadyCount == 1 ? '' : 's'}'
        ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(status), color: c, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TacticalTextStyles.subheading(colors)
                    .copyWith(color: c, fontWeight: FontWeight.bold),
              ),
              Text(sub, style: TacticalTextStyles.caption(colors)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends ConsumerWidget {
  const _CheckRow({required this.check, required this.colors});

  final PreflightCheck check;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = _statusColor(check.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(_statusIcon(check.status), color: c, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.label,
                  style: TacticalTextStyles.value(colors)
                      .copyWith(color: colors.text),
                ),
                Text(check.detail, style: TacticalTextStyles.caption(colors)),
              ],
            ),
          ),
          if (check.hasInAppFix)
            TextButton(
              onPressed: () => _runFix(context, ref, check.id),
              child: Text('Fix', style: TextStyle(color: colors.accent)),
            ),
        ],
      ),
    );
  }

  Future<void> _runFix(
    BuildContext context,
    WidgetRef ref,
    PreflightCheckId id,
  ) async {
    tapMedium();
    switch (id) {
      case PreflightCheckId.gpsPermission:
        // Reuse the location request path the onboarding + diagnostics use.
        await ref.read(locationServiceProvider).requestPermission();
        ref.invalidate(locationPermissionProvider);
      case PreflightCheckId.offlineMaps:
        // The download UI lives on the Map tab; point the user there rather
        // than flipping the source to offline with zero regions (blank map).
        if (context.mounted) {
          Navigator.of(context).maybePop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Open the Map tab to download your operating area'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      default:
        break;
    }
  }
}

class _TeamBoard extends StatelessWidget {
  const _TeamBoard({
    required this.unlocked,
    required this.reports,
    required this.colors,
  });

  final bool unlocked;
  final List<PreflightReport> reports;
  final TacticalColorScheme colors;

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, size: 18, color: colors.text3),
                const SizedBox(width: 8),
                Text('Whole-team readiness',
                    style: TacticalTextStyles.value(colors)
                        .copyWith(color: colors.text)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'See every teammate’s Ready / Not Ready status at a glance. '
              'Available on Pro+Link and Team.',
              style: TacticalTextStyles.caption(colors),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TEAM READINESS', style: TacticalTextStyles.heading(colors)),
        const SizedBox(height: 4),
        if (reports.isEmpty)
          Text(
            'Waiting for teammates to report…',
            style: TacticalTextStyles.caption(colors),
          )
        else
          ...reports.map((r) {
            final c = _statusColor(r.overall);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(_statusIcon(r.overall), color: c, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.callsign?.isNotEmpty == true
                          ? r.callsign!
                          : (r.deviceId ?? 'Teammate'),
                      style: TacticalTextStyles.value(colors)
                          .copyWith(color: colors.text),
                    ),
                  ),
                  Text(
                    _statusLabel(r.overall),
                    style: TacticalTextStyles.caption(colors).copyWith(color: c),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// --- shared status visuals ---

Color _statusColor(PreflightStatus s) => switch (s) {
      PreflightStatus.ready => const Color(0xFF3FB950),
      PreflightStatus.caution => const Color(0xFFD29922),
      PreflightStatus.notReady => const Color(0xFFCC0000),
    };

IconData _statusIcon(PreflightStatus s) => switch (s) {
      PreflightStatus.ready => Icons.check_circle,
      PreflightStatus.caution => Icons.error,
      PreflightStatus.notReady => Icons.cancel,
    };

String _statusLabel(PreflightStatus s) => switch (s) {
      PreflightStatus.ready => 'READY',
      PreflightStatus.caution => 'CAUTION',
      PreflightStatus.notReady => 'NOT READY',
    };
