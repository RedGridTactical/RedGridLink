import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:red_grid_link/ui/screens/field_link/qr_scanner_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen() {
    return const MaterialApp(
      home: QrScannerScreen(),
    );
  }

  group('QrScannerScreen', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('SCAN SESSION QR'), findsOneWidget);
    });

    testWidgets('renders instruction text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Point camera at a session QR code'), findsOneWidget);
    });

    testWidgets('close button is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('close button pops the screen', (tester) async {
      // Use a Navigator to test pop behavior.
      bool didPop = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final result =
                      await Navigator.of(context).push<Map<String, dynamic>>(
                    MaterialPageRoute(
                      builder: (_) => const QrScannerScreen(),
                    ),
                  );
                  didPop = true;
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      // Open scanner screen
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Tap close
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
    });
  });
}
