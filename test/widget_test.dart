import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('MaterialApp should build', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Test App'),
          ),
        ),
      );
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('Scaffold should display text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Hello World'),
            ),
          ),
        ),
      );
      expect(find.text('Hello World'), findsOneWidget);
    });
  });
}