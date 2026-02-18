import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_alarm_app/main.dart';

void main() {
  testWidgets('App bootstraps', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(onboardingCompleted: false));
    expect(find.text('Skip'), findsOneWidget);
  });
}
