import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/ui/screens/tools/widgets/slope_calculator_tool.dart';

void main() {
  final colors = getTacticalColors('red');

  Widget buildTool() {
    return MaterialApp(
      home: SlopeCalculatorTool(colors: colors),
    );
  }

  group('SlopeCalculatorTool', () {
    testWidgets('renders with title', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('SLOPE CALCULATOR'), findsOneWidget);
    });

    testWidgets('shows input fields', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('HORIZONTAL DISTANCE (meters)'), findsOneWidget);
      expect(find.text('ELEVATION CHANGE (meters)'), findsOneWidget);
    });

    testWidgets('shows calculate button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('CALCULATE SLOPE'), findsOneWidget);
    });

    testWidgets('calculates 45-degree slope correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());

      // 100m horizontal, 100m rise = 100% slope, 45 degrees
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '100');
      await tester.enterText(textFields.at(1), '100');
      await tester.tap(find.text('CALCULATE SLOPE'));
      await tester.pumpAndSettle();

      expect(find.text('SLOPE %'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('ANGLE'), findsOneWidget);
      expect(find.text('45.0\u00B0'), findsOneWidget);
    });

    testWidgets('shows terrain category', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());

      // Gentle 10% slope
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '100');
      await tester.enterText(textFields.at(1), '10');
      await tester.tap(find.text('CALCULATE SLOPE'));
      await tester.pumpAndSettle();

      expect(find.text('TERRAIN'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
    });

    testWidgets('shows error for invalid horizontal distance',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), '25');
      await tester.tap(find.text('CALCULATE SLOPE'));
      await tester.pumpAndSettle();

      expect(
          find.text('Enter a valid horizontal distance'), findsOneWidget);
    });

    testWidgets('shows uphill indicator for positive elevation',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '100');
      await tester.enterText(textFields.at(1), '25');
      await tester.tap(find.text('CALCULATE SLOPE'));
      await tester.pumpAndSettle();

      expect(find.text('UPHILL'), findsOneWidget);
    });
  });
}
