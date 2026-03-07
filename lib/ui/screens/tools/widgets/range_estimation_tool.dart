import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tactical_colors.dart';
import '../../../../core/theme/tactical_text_styles.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/tactical.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/tactical_button.dart';
import '../../../common/widgets/tactical_card.dart';

/// Range Estimation tool using the mil-relation formula.
///
/// Range = Object Size (m) x 1000 / Angular Size (mils)
///
/// Includes a reference table of common object sizes for field use.
class RangeEstimationTool extends StatefulWidget {
  const RangeEstimationTool({super.key, required this.colors});

  final TacticalColorScheme colors;

  @override
  State<RangeEstimationTool> createState() => _RangeEstimationToolState();
}

class _RangeEstimationToolState extends State<RangeEstimationTool> {
  final _sizeController = TextEditingController();
  final _milsController = TextEditingController();

  double? _rangeMeters;
  String? _error;

  TacticalColorScheme get colors => widget.colors;

  /// Common reference object sizes for quick selection.
  static const List<({String name, double sizeM})> _references = [
    (name: 'Person (standing)', sizeM: 1.8),
    (name: 'Person (kneeling)', sizeM: 1.0),
    (name: 'Door', sizeM: 2.1),
    (name: 'Vehicle (sedan)', sizeM: 1.5),
    (name: 'Truck / SUV', sizeM: 2.5),
    (name: 'Utility pole', sizeM: 10.7),
    (name: 'Telephone pole spacing', sizeM: 38.0),
    (name: 'Deer (body)', sizeM: 1.0),
  ];

  @override
  void dispose() {
    _sizeController.dispose();
    _milsController.dispose();
    super.dispose();
  }

  void _calculate() {
    tapMedium();
    final size = double.tryParse(_sizeController.text);
    final mils = double.tryParse(_milsController.text);

    if (size == null || size <= 0) {
      setState(() {
        _error = 'Enter a valid object size';
        _rangeMeters = null;
      });
      return;
    }
    if (mils == null || mils <= 0) {
      setState(() {
        _error = 'Enter a valid angular size in mils';
        _rangeMeters = null;
      });
      return;
    }

    final range = estimateRange(
      objectSizeMeters: size,
      angularSizeMils: mils,
    );

    setState(() {
      _rangeMeters = range;
      _error = null;
    });
    if (range != null) notifySuccess();
  }

  void _selectReference(double sizeM) {
    tapLight();
    _sizeController.text = sizeM.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        title: Text('RANGE ESTIMATION',
            style: TacticalTextStyles.heading(colors)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Formula explanation
            TacticalCard(
              colors: colors,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MIL-RELATION FORMULA',
                      style: TacticalTextStyles.label(colors)),
                  const SizedBox(height: 4),
                  Text(
                    'Range = Size (m) \u00D7 1000 \u00F7 Mils',
                    style: TacticalTextStyles.value(colors),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SectionHeader(title: 'Input', colors: colors),
            const SizedBox(height: 8),

            // Object size input
            _buildField(
              controller: _sizeController,
              label: 'TARGET SIZE (meters)',
              hint: 'e.g., 1.8',
            ),
            const SizedBox(height: 12),

            // Angular size input
            _buildField(
              controller: _milsController,
              label: 'ANGULAR SIZE (mils)',
              hint: 'e.g., 5.0',
            ),
            const SizedBox(height: 16),

            // Calculate button
            TacticalButton(
              label: 'Estimate Range',
              icon: Icons.straighten,
              colors: colors,
              onPressed: _calculate,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TacticalTextStyles.body(colors).copyWith(
                  color: const Color(0xFFCC0000),
                ),
              ),
            ],

            if (_rangeMeters != null) ...[
              const SizedBox(height: 20),
              TacticalCard(
                colors: colors,
                padding: const EdgeInsets.all(16),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: '${_rangeMeters!.toStringAsFixed(0)}m'));
                  notifySuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('RANGE COPIED',
                          style: TacticalTextStyles.caption(colors)
                              .copyWith(color: Colors.white)),
                      backgroundColor: colors.accent,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ESTIMATED RANGE',
                        style: TacticalTextStyles.label(colors)),
                    const SizedBox(height: 4),
                    Text(
                      '${_rangeMeters!.toStringAsFixed(0)} m',
                      style: TacticalTextStyles.bearingDisplay(colors),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${metersToFeet(_rangeMeters!).toStringAsFixed(0)} ft  '
                      '(${metersToMiles(_rangeMeters!).toStringAsFixed(2)} mi)',
                      style: TacticalTextStyles.dim(colors),
                    ),
                    const SizedBox(height: 4),
                    Text('Tap to copy',
                        style: TacticalTextStyles.dim(colors)),
                  ],
                ),
              ),
            ],

            // Reference table
            const SizedBox(height: 24),
            SectionHeader(title: 'Reference Sizes', colors: colors),
            const SizedBox(height: 8),
            ..._references.map((ref) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TacticalCard(
                    colors: colors,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    onTap: () => _selectReference(ref.sizeM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ref.name,
                            style: TacticalTextStyles.body(colors)),
                        Text('${ref.sizeM}m',
                            style: TacticalTextStyles.value(colors)),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TacticalTextStyles.label(colors)),
        const SizedBox(height: 4),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: TacticalTextStyles.value(colors),
            onSubmitted: (_) => _calculate(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TacticalTextStyles.dim(colors),
              filled: true,
              fillColor: colors.card2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.accent, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
