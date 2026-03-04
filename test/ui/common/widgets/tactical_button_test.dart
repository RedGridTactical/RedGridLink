import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/ui/common/widgets/tactical_button.dart';

void main() {
  // Use the default red tactical theme for tests.
  final colors = getTacticalColors('red');

  Widget buildButton({
    String label = 'Test',
    VoidCallback? onPressed,
    IconData? icon,
    bool isCompact = false,
    bool isDestructive = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TacticalButton(
          label: label,
          onPressed: onPressed,
          icon: icon,
          isCompact: isCompact,
          isDestructive: isDestructive,
          colors: colors,
        ),
      ),
    );
  }

  group('TacticalButton', () {
    testWidgets('renders with correct label text (uppercased)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildButton(label: 'Submit'));
      expect(find.text('SUBMIT'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (
      WidgetTester tester,
    ) async {
      bool pressed = false;
      await tester.pumpWidget(buildButton(
        onPressed: () => pressed = true,
      ));

      await tester.tap(find.byType(TacticalButton));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled (null)', (
      WidgetTester tester,
    ) async {
      bool pressed = false;
      await tester.pumpWidget(buildButton(onPressed: null));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(pressed, isFalse);
    });

    testWidgets('shows icon when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildButton(
        icon: Icons.send,
        onPressed: () {},
      ));

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('does not show icon when not provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildButton(onPressed: () {}));

      // No Icon widget besides those possibly in Scaffold/MaterialApp
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('applies accent color as background by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildButton(onPressed: () {}));

      // The background Material should use the accent color.
      // TacticalButton's build tree: Opacity > Material > InkWell > ...
      // Find the Material that is a descendant of TacticalButton.
      final materialFinder = find.descendant(
        of: find.byType(TacticalButton),
        matching: find.byType(Material),
      );
      // The first Material descendant of TacticalButton is the one with
      // the colored background.
      final material = tester.widgetList<Material>(materialFinder).first;
      expect(material.color, colors.accent);
    });

    testWidgets('applies destructive red color when isDestructive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildButton(
        isDestructive: true,
        onPressed: () {},
      ));

      final materialFinder = find.descendant(
        of: find.byType(TacticalButton),
        matching: find.byType(Material),
      );
      final material = tester.widgetList<Material>(materialFinder).first;
      expect(material.color, const Color(0xFFCC0000));
    });

    testWidgets('reduced opacity when disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildButton(onPressed: null));

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(TacticalButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.30);
    });

    testWidgets('full opacity when enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildButton(onPressed: () {}));

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(TacticalButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('meets minimum touch target height of 44px', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildButton(onPressed: () {}));

      final constraints = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(TacticalButton),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constraints.constraints.minHeight, 44.0);
    });

    testWidgets('renders correctly with green theme colors', (
      WidgetTester tester,
    ) async {
      final greenColors = getTacticalColors('green');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TacticalButton(
            label: 'Green',
            onPressed: () {},
            colors: greenColors,
          ),
        ),
      ));

      final materialFinder = find.descendant(
        of: find.byType(TacticalButton),
        matching: find.byType(Material),
      );
      final material = tester.widgetList<Material>(materialFinder).first;
      expect(material.color, greenColors.accent);
      expect(find.text('GREEN'), findsOneWidget);
    });
  });
}
