import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiftmate_business/main.dart';
import 'package:shiftmate_business/providers/app_state.dart';

import '../test/fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Prijava → urnik → profil → odjava na napravi s testnim repozitorijem',
    (tester) async {
      final repository = FakeRepository(
        data: workspace(shifts: [shift(member: 'a')]),
      );
      final state = AppState(repository, MemoryCache());
      addTearDown(state.dispose);
      addTearDown(repository.close);
      await tester.pumpWidget(ShiftMateApp(state: state));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-pošta'),
        'employee@example.test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Geslo'),
        'local-test-password',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Prijava'));
      await tester.pumpAndSettle();
      expect(find.text('Kavarna Test'), findsOneWidget);
      await tester.tap(find.text('Moje izmene'));
      await tester.pumpAndSettle();
      expect(find.text('Dodeljeno'), findsOneWidget);
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Odjava'));
      await tester.pumpAndSettle();
      expect(find.text('Dobrodošli nazaj'), findsOneWidget);
    },
  );
}
