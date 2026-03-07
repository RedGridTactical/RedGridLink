import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/ui/screens/tools/widgets/range_estimation_tool.dart';

void main() {
  final colors = getTacticalColors('red');

  Widget buildTool() {
    return MaterialApp(
      home: RangeEstimationTool(colors: colors),
    );
  }

  group('RangeEstimationTool', () {
    testWidgets('renders with title', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('RANGE ESTIMATION'), findsOneWidget);
    });

    testWidgets('shows mil-relation formula card',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('MIL-RELATION FORMULA'), findsOneWidget);
    });

    testWidgets('shows input fields', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('TARGET SIZE (meters)'), findsOneWidget);
      expect(find.text('ANGULAR SIZE (mils)'), findsOneWidget);
    });

    testWidgets('shows estimate button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('ESTIMATE RANGE'), findsOneWidget);
    });

    testWidgets('shows reference sizes section', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      // SectionHeader uppercases its title
      expect(find.text('REFERENCE SIZES'), findsOneWidget);
      expect(find.text('Person (standing)'), findsOneWidget);
    });

    testWidgets('calculates range for valid inputs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());

      // Enter 1.8m object at 5 mils = 360m
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '1.8');
      await tester.enterText(textFields.at(1), '5');
      await tester.tap(find.text('ESTIMATE RANGE'));
      await tester.pumpAndSettle();

      expect(find.text('ESTIMATED RANGE'), findsOneWidget);
      expect(find.text('360 m'), findsOneWidget);
    });

    testWidgets('shows error for invalid inputs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());

      // Leave size empty, enter mils
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), '5');
      await tester.tap(find.text('ESTIMATE RANGE'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid object size'), findsOneWidget);
    });

    testWidgets('tapping reference fills size field',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());

      // Tap "Person (standing)" reference
      await tester.tap(find.text('Person (standing)'));
      await tester.pumpAndSettle();

      // The size field should now contain 1.8
      final sizeField = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(sizeField.controller!.text, equals('1.8'));
    });
  });
}
