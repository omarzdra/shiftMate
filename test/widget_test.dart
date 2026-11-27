import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftmate_business/main.dart';
import 'package:shiftmate_business/providers/app_state.dart';

import 'fixtures.dart';

void main() {
  testWidgets('Iztek seje odstrani zaščitene poti iz sklada', (tester) async {
    final repository = FakeRepository(
      userId: 'user-owner',
      data: workspace(shifts: [shift()]),
    );
    final state = AppState(repository, MemoryCache());
    addTearDown(state.dispose);
    addTearDown(repository.close);
    await state.refresh();
    await tester.pumpWidget(ShiftMateApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Samodejni urnik'));
    await tester.pumpAndSettle();
    expect(find.text('Predlog urnika'), findsOneWidget);
    await repository.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Dobrodošli nazaj'), findsOneWidget);
    expect(find.text('Predlog urnika'), findsNothing);
  });
  Future<AppState> launch(
    WidgetTester tester, {
    bool signedIn = false,
    bool employer = false,
    bool populated = false,
  }) async {
    final r = FakeRepository(
      userId: signedIn ? (employer ? 'user-owner' : 'user-a') : null,
      data: workspace(shifts: populated ? [shift(member: 'a')] : []),
    );
    final s = AppState(r, MemoryCache());
    addTearDown(s.dispose);
    addTearDown(r.close);
    if (signedIn) await s.refresh();
    await tester.pumpWidget(ShiftMateApp(state: s));
    await tester.pumpAndSettle();
    return s;
  }

  testWidgets('Brez konfiguracije ni lažne prijave', (tester) async {
    await tester.pumpWidget(const ShiftMateApp());
    expect(find.text('Priprava povezave'), findsOneWidget);
    expect(find.text('Prijava'), findsNothing);
  });
  testWidgets('Prijavni obrazec vsebuje e-pošto in geslo', (tester) async {
    await launch(tester);
    expect(find.widgetWithText(TextFormField, 'E-pošta'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Geslo'), findsOneWidget);
  });
  testWidgets('Prazen prijavni obrazec prikaže validacijo', (tester) async {
    await launch(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Prijava'));
    await tester.pumpAndSettle();
    expect(find.text('Vnesi veljaven e-poštni naslov.'), findsOneWidget);
    expect(find.text('Geslo naj vsebuje vsaj 8 znakov.'), findsOneWidget);
  });
  testWidgets('Registracija je dostopna iz prijave', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Nov uporabnik? Registracija'));
    await tester.pumpAndSettle();
    expect(find.text('Ustvari račun'), findsOneWidget);
  });
  testWidgets('Navigacija na prazen seznam izmen', (tester) async {
    await launch(tester, signedIn: true);
    await tester.tap(find.text('Moje izmene'));
    await tester.pumpAndSettle();
    expect(find.text('Ni izmen'), findsOneWidget);
  });
  testWidgets('Podatki testnega repozitorija so prikazani', (tester) async {
    await launch(tester, signedIn: true, populated: true);
    await tester.tap(find.text('Moje izmene'));
    await tester.pumpAndSettle();
    expect(find.text('Dodeljeno'), findsOneWidget);
    expect(find.textContaining('Strežba'), findsOneWidget);
    expect(find.text('Kavarna Test'), findsOneWidget);
  });
  testWidgets('Napaka prijave ostane na zaščitenem obrazcu', (tester) async {
    final s = await launch(tester);
    (s.repository as FakeRepository).failure = ArgumentError('Napačno geslo');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-pošta'),
      'a@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Geslo'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Prijava'));
    await tester.pumpAndSettle();
    expect(find.text('Napačno geslo'), findsOneWidget);
    expect(find.text('Dobrodošli nazaj'), findsOneWidget);
  });
  testWidgets('Delodajalec vidi upravljanje zaposlenih', (tester) async {
    await launch(tester, signedIn: true, employer: true);
    await tester.tap(find.text('Zaposleni').last);
    await tester.pumpAndSettle();
    expect(find.text('Povabi zaposlenega'), findsOneWidget);
    expect(find.text('Oseba a'), findsOneWidget);
  });
  testWidgets('Prijava pridobi podjetje in omogoči odjavo', (tester) async {
    await launch(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-pošta'),
      'a@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Geslo'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Prijava'));
    await tester.pumpAndSettle();
    expect(find.text('Kavarna Test'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odjava'));
    await tester.pumpAndSettle();
    expect(find.text('Dobrodošli nazaj'), findsOneWidget);
  });
}
