import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/mgrs.dart';
import '../../../../core/utils/tactical.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';

/// Pace counter tool.
///
/// Large tap area for field counting. + / - buttons.
/// Shows distance traveled based on pace count setting.
class PaceCountTool extends ConsumerStatefulWidget {
  const PaceCountTool({super.key});

  @override
  ConsumerState<PaceCountTool> createState() => _PaceCountToolState();
}

class _PaceCountToolState extends ConsumerState<PaceCountTool> {
  int _paces = 0;

  void _increment() {
    setState(() => _paces++);
    selectionTick();
  }

  void _decrement() {
    if (_paces > 0) {
      setState(() => _paces--);
      selectionTick();
    }
  }

  void _reset() {
    setState(() => _paces = 0);
    tapMedium();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final paceCount = ref.watch(paceCountProvider);
    final double distance = pacesToDistance(_paces.toDouble(), paceCount.toDouble());

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title: Text('PACE COUNT', style: TacticalTextStyles.heading(colors)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.text),
            onPressed: _reset,
            tooltip: 'Reset',
            iconSize: 28,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TacticalCard(
              colors: colors,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PACE SETTING',
                          style: TacticalTextStyles.label(colors)),
                      Text(
                        '$paceCount paces / 100m',
                        style: TacticalTextStyles.body(colors),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('DISTANCE',
                          style: TacticalTextStyles.label(colors)),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: formatDistance(distance)));
                          notifySuccess();
                        },
                        child: Text(
                          formatDistance(distance),
                          style: TacticalTextStyles.value(colors),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Large pace count display
          Expanded(
            child: GestureDetector(
              onTap: _increment,
              behavior: HitTestBehavior.opaque,
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TAP TO COUNT',
                      style: TacticalTextStyles.label(colors),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_paces',
                      style: TacticalTextStyles.bearingDisplay(colors).copyWith(
                        fontSize: 72,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PACES',
                      style: TacticalTextStyles.subheading(colors),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      formatDistance(distance),
                      style: TacticalTextStyles.value(colors).copyWith(
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // +/- buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: TacticalButton(
                      label: '- 1',
                      colors: colors,
                      isDestructive: true,
                      onPressed: _paces > 0 ? _decrement : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: TacticalButton(
                      label: '+ 1',
                      colors: colors,
                      onPressed: _increment,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
