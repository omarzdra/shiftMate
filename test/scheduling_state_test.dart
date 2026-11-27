import 'package:flutter_test/flutter_test.dart';
import 'package:shiftmate_business/models/domain.dart';
import 'package:shiftmate_business/providers/app_state.dart';
import 'package:shiftmate_business/providers/scheduling_state.dart';

import 'fixtures.dart';

void main() {
  late FakeRepository repository;
  late AppState app;
  late SchedulingState draft;
  setUp(() async {
    repository = FakeRepository(
      userId: 'user-owner',
      data: workspace(shifts: [shift()]),
    );
    app = AppState(repository, MemoryCache());
    await app.refresh();
    draft = SchedulingState(app);
    draft.generate(DateTime.utc(2026, 11, 23), DateTime.utc(2026, 11, 24));
  });
  tearDown(() async {
    draft.dispose();
    app.dispose();
    await repository.close();
  });
  test('Priprava predloga ne objavi urnika', () {
    expect(draft.proposal!.shifts.single.memberId, 'a');
    expect(repository.confirmations, isEmpty);
  });
  test(
    'Potrditev ponovno pridobi podatke in shrani veljaven predlog',
    () async {
      expect(await draft.confirm(), true);
      expect(repository.confirmations.single.single.memberId, 'a');
    },
  );
  test('Zastarela izmena prepreči shranjevanje', () async {
    final old = shift();
    repository.data = workspace(
      shifts: [
        Shift(
          id: old.id,
          businessId: old.businessId,
          start: old.start,
          end: old.end,
          position: old.position,
          updatedAt: '2026-11-21T00:00:00Z',
        ),
      ],
    );
    expect(await draft.confirm(), false);
    expect(repository.confirmations, isEmpty);
    expect(draft.error, contains('zastarel'));
  });
  test('Spremenjena razpoložljivost prepreči potrditev', () async {
    final old = workspace(shifts: [shift()]);
    repository.data = Workspace(
      businessId: old.businessId,
      businessName: old.businessName,
      members: old.members,
      shifts: old.shifts,
      availabilities: [],
      logs: [],
    );
    expect(await draft.confirm(), false);
    expect(repository.confirmations, isEmpty);
  });
  test('Ročno odstranjevanje predlagane dodelitve', () {
    draft.change(draft.proposal!.shifts.single, null);
    expect(draft.proposal!.shifts.single.memberId, isNull);
    expect(repository.confirmations, isEmpty);
  });
  test('Neveljavna ročna dodelitev ne spremeni predloga', () {
    draft.change(draft.proposal!.shifts.single, 'owner');
    expect(draft.proposal!.shifts.single.memberId, 'a');
    expect(draft.error, contains('pozicija'));
  });
}
