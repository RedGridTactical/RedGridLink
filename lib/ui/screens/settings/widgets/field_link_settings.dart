import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/tactical_card.dart';

/// Field Link default settings section.
///
/// Controls display name, default security mode, battery/sync mode,
/// and position update interval.
class FieldLinkSettings extends ConsumerStatefulWidget {
  const FieldLinkSettings({super.key});

  @override
  ConsumerState<FieldLinkSettings> createState() => _FieldLinkSettingsState();
}

class _FieldLinkSettingsState extends ConsumerState<FieldLinkSettings> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(displayNameProvider),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final syncMode = ref.watch(syncModeProvider);
    final updateInterval = ref.watch(updateIntervalProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Field Link', colors: colors),
        const SizedBox(height: 12),

        // --- Display Name ---
        TacticalCard(
          colors: colors,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DISPLAY NAME', style: TacticalTextStyles.label(colors)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TacticalTextStyles.body(colors),
                maxLength: 16,
                decoration: InputDecoration(
                  hintText: 'Operator',
                  counterStyle: TacticalTextStyles.dim(colors),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  if (value.trim().isNotEmpty) {
                    ref.read(displayNameProvider.notifier).set(value.trim());
                  }
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Shown to nearby peers during sync.',
                style: TacticalTextStyles.dim(colors),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // --- Battery Mode ---
        TacticalCard(
          colors: colors,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BATTERY MODE', style: TacticalTextStyles.label(colors)),
              const SizedBox(height: 8),
              _RadioOption(
                label: 'EXPEDITION',
                description: 'Low power, updates every 30-60s',
                value: 'expedition',
                groupValue: syncMode,
                colors: colors,
                onChanged: (v) =>
                    ref.read(syncModeProvider.notifier).set(v),
              ),
              const SizedBox(height: 4),
              _RadioOption(
                label: 'ACTIVE',
                description: 'Real-time updates, higher battery use',
                value: 'active',
                groupValue: syncMode,
                colors: colors,
                onChanged: (v) =>
                    ref.read(syncModeProvider.notifier).set(v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // --- Update Interval ---
        TacticalCard(
          colors: colors,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPDATE INTERVAL',
                style: TacticalTextStyles.label(colors),
              ),
              const SizedBox(height: 8),
              _IntervalSelector(
                currentInterval: updateInterval,
                colors: colors,
                onChanged: (v) =>
                    ref.read(updateIntervalProvider.notifier).set(v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Single radio option row.
class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final String description;
  final String value;
  final String groupValue;
  final TacticalColorScheme colors;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () {
        tapLight();
        onChanged(value);
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppConstants.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.accent : colors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.accent,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TacticalTextStyles.body(colors).copyWith(
                      color: isSelected ? colors.text : colors.text3,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(description, style: TacticalTextStyles.dim(colors)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of interval chips (5s, 15s, 30s, 60s).
class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({
    required this.currentInterval,
    required this.colors,
    required this.onChanged,
  });

  final int currentInterval;
  final TacticalColorScheme colors;
  final ValueChanged<int> onChanged;

  static const List<_IntervalOption> _options = [
    _IntervalOption(label: '5s', ms: 5000),
    _IntervalOption(label: '15s', ms: 15000),
    _IntervalOption(label: '30s', ms: 30000),
    _IntervalOption(label: '60s', ms: 60000),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final isSelected = opt.ms == currentInterval;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                tapLight();
                onChanged(opt.ms);
              },
              child: Container(
                height: AppConstants.minTouchTarget,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colors.accent : colors.card2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? colors.accent : colors.border,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: TacticalTextStyles.caption(colors).copyWith(
                    color: isSelected ? Colors.white : colors.text2,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _IntervalOption {
  final String label;
  final int ms;
  const _IntervalOption({required this.label, required this.ms});
}
