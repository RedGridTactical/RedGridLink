import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_grid_link/app.dart';
import 'package:red_grid_link/data/repositories/settings_repository.dart';
import 'package:red_grid_link/providers/settings_provider.dart';

void main() {
  testWidgets('App renders RED GRID LINK title on onboarding', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: const RedGridLinkApp(),
      ),
    );

    // Default: hasCompletedOnboarding = false → OnboardingScreen → WelcomePage
    expect(find.text('RED GRID LINK'), findsOneWidget);
  });
}
