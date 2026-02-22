// Basic Flutter widget test for Dia Plus app.

import 'package:flutter_test/flutter_test.dart';

import 'package:dia_plus/main.dart';

void main() {
  testWidgets('App loads and shows starting page', (WidgetTester tester) async {
    await tester.pumpWidget(const DiaPlusApp());
    await tester.pumpAndSettle();

    expect(find.text('Dia Plus'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
