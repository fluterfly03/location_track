import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task1/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify application renders title or loading indicator cleanly
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
