import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:red_grid_link/ui/screens/field_link/widgets/session_qr_code.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildWidget({
    required String sessionId,
    String? pin,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SessionQrCode(
            sessionId: sessionId,
            pin: pin,
          ),
        ),
      ),
    );
  }

  group('SessionQrCode', () {
    testWidgets('renders QR code widget', (tester) async {
      await tester.pumpWidget(buildWidget(sessionId: 'test-session-123'));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Scan to Join'), findsOneWidget);
    });

    testWidgets('renders with PIN provided', (tester) async {
      await tester.pumpWidget(buildWidget(
        sessionId: 'session-abc',
        pin: '4321',
      ));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('renders without PIN', (tester) async {
      await tester.pumpWidget(buildWidget(sessionId: 'session-no-pin'));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('renders with white background', (tester) async {
      await tester.pumpWidget(buildWidget(sessionId: 'test-id'));
      await tester.pump();

      final qrWidget = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrWidget.backgroundColor, Colors.white);
    });
  });
}
