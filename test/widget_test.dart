import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuet_bus/features/auth/signup_screen.dart';

void main() {
  testWidgets('Signup screen renders expected fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignupScreen(),
      ),
    );

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Join the KUET Bus transportation community.'),
        findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
  });
}
