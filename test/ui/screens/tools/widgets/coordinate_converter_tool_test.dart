import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_grid_link/core/theme/tactical_colors.dart';
import 'package:red_grid_link/ui/screens/tools/widgets/coordinate_converter_tool.dart';

void main() {
  final colors = getTacticalColors('red');

  Widget buildTool() {
    return MaterialApp(
      home: CoordinateConverterTool(colors: colors),
    );
  }

  group('CoordinateConverterTool', () {
    testWidgets('renders with title', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('COORD CONVERTER'), findsOneWidget);
    });

    testWidgets('shows format dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('MGRS'), findsOneWidget);
    });

    testWidgets('shows MGRS input field by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('MGRS COORDINATE'), findsOneWidget);
    });

    testWidgets('shows convert button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      expect(find.text('CONVERT'), findsOneWidget);
    });

    testWidgets('shows error for invalid MGRS', (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());

      // Enter invalid MGRS
      await tester.enterText(
          find.byType(TextField).first, 'INVALID');
      await tester.tap(find.text('CONVERT'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid MGRS coordinate'), findsOneWidget);
    });

    testWidgets('converts valid MGRS to other formats',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());

      // Enter valid MGRS for Washington DC
      await tester.enterText(
          find.byType(TextField).first, '18SUJ2337806446');
      await tester.tap(find.text('CONVERT'));
      await tester.pumpAndSettle();

      // Should show results section
      expect(find.text('LAT/LON DD'), findsOneWidget);
      expect(find.text('LAT/LON DMS'), findsOneWidget);
      expect(find.text('UTM'), findsOneWidget);
    });

    testWidgets('input format section header visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTool());
      // SectionHeader uppercases its title
      expect(find.text('INPUT FORMAT'), findsOneWidget);
    });
  });
}
