import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/mgrs.dart';
import '../../../../core/utils/tactical.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../services/step_detector/step_detector_service.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';

/// Pace counter tool.
///
/// Supports two modes:
/// - **Manual**: Large tap area for field counting with +/- buttons.
/// - **Auto**: Accelerometer-based step detection via [StepDetectorService].
///
/// Shows distance traveled based on pace count setting.
class PaceCountTool extends ConsumerStatefulWidget {
  /// Optional step detector service for dependency injection in tests.
  final StepDetectorService? stepDetectorService;

  const PaceCountTool({super.key, this.stepDetectorService});

  @override
  ConsumerState<PaceCountTool> createState() => _PaceCountToolState();
}

class _PaceCountToolState extends ConsumerState<PaceCountTool> {
  int _paces = 0;
  bool _autoMode = false;

  StepDetectorService? _stepDetector;
  StreamSubscription<int>? _stepSub;

  @override
  void initState() {
    super.initState();
    _stepDetector = widget.stepDetectorService;
  }

  @override
  void dispose() {
    _stopAutoCount();
    // Only dispose if we created it (not injected).
    if (widget.stepDetectorService == null) {
      _stepDetector?.dispose();
    }
    super.dispose();
  }

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
    _stepDetector?.reset();
    tapMedium();
  }

  void _toggleAutoMode() {
    setState(() {
      _autoMode = !_autoMode;
      if (_autoMode) {
        _startAutoCount();
      } else {
        _stopAutoCount();
      }
    });
    tapMedium();
  }

  void _startAutoCount() {
    _stepDetector ??= StepDetectorService();
    _stepDetector!.start();
    // Sync auto count with current manual count: reset detector
    // and keep manual paces as the base.
    final basePaces = _paces;
    _stepSub?.cancel();
    _stepSub = _stepDetector!.stepStream.listen((stepCount) {
      setState(() {
        _paces = basePaces + stepCount;
      });
    });
  }

  void _stopAutoCount() {
    _stepSub?.cancel();
    _stepSub = null;
    _stepDetector?.stop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(currentThemeProvider);
    final paceCount = ref.watch(paceCountProvider);
    final double distance =
        pacesToDistance(_paces.toDouble(), paceCount.toDouble());

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title:
            Text('PACE COUNT', style: TacticalTextStyles.heading(colors)),
        elevation: 0,
        actions: [
          // Auto-count toggle
          IconButton(
            icon: Icon(
              _autoMode ? Icons.directions_walk : Icons.directions_walk_outlined,
              color: _autoMode ? colors.accent : colors.text,
            ),
            onPressed: _toggleAutoMode,
            tooltip: _autoMode ? 'Stop auto-count' : 'Start auto-count',
            iconSize: 28,
          ),
          // Reset
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          Clipboard.setData(
                              ClipboardData(text: formatDistance(distance)));
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

          // Auto mode indicator
          if (_autoMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TacticalCard(
                colors: colors,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.sensors, color: colors.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AUTO-COUNT ACTIVE — detecting steps',
                        style: TacticalTextStyles.label(colors).copyWith(
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Large pace count display
          Expanded(
            child: GestureDetector(
              onTap: _autoMode ? null : _increment,
              behavior: HitTestBehavior.opaque,
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _autoMode ? colors.accent : colors.border,
                    width: _autoMode ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _autoMode ? 'AUTO COUNTING' : 'TAP TO COUNT',
                      style: TacticalTextStyles.label(colors).copyWith(
                        color: _autoMode ? colors.accent : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_paces',
                      style: TacticalTextStyles.bearingDisplay(colors)
                          .copyWith(fontSize: 72),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PACES',
                      style: TacticalTextStyles.subheading(colors),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      formatDistance(distance),
                      style: TacticalTextStyles.value(colors)
                          .copyWith(fontSize: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // +/- buttons (always visible, but disabled label changes in auto mode)
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
                      onPressed: _autoMode ? null : _increment,
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
