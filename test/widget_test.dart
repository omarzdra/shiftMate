// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shiftmate_business/main.dart';

void main() {
  group('ShiftMate Business - začetni testi', () {
    testWidgets('Aplikacija se uspešno zažene', (tester) async {
      await tester.pumpWidget(const ShiftMateApp());

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Prikazan je naslov aplikacije', (tester) async {
      await tester.pumpWidget(const ShiftMateApp());

      expect(find.text('ShiftMate Business'), findsOneWidget);
    });

    testWidgets('Prikazano je pozdravno sporočilo', (tester) async {
      await tester.pumpWidget(const ShiftMateApp());

      expect(find.text('Dobrodošli v ShiftMate Business'), findsOneWidget);

      expect(find.text('Upravljanje delovnih izmen'), findsOneWidget);
    });

    testWidgets('Prikazana je ikona koledarja', (tester) async {
      await tester.pumpWidget(const ShiftMateApp());

      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    });
  });
}
