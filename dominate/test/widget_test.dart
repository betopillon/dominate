// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:dominate/main.dart';

void main() {
  testWidgets('Dominate app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DominateApp());

    // Verify that the app title is displayed.
    expect(find.text('Dominate'), findsOneWidget);
    expect(find.text('Choose Game Mode'), findsOneWidget);

    // Verify that game mode buttons are present.
    expect(find.text('1 vs Machine'), findsOneWidget);
    expect(find.text('1 vs 1'), findsOneWidget);
    expect(find.text('1 vs 2'), findsOneWidget);
    expect(find.text('1 vs 3'), findsOneWidget);
  });
}
