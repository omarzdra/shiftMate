import 'package:flutter_test/flutter_test.dart';
import 'package:shiftmate_business/models/domain.dart';
import 'package:shiftmate_business/services/scheduling_service.dart';

import 'fixtures.dart';

void main() {
  const service = SchedulingService();
  ScheduleProposal run({
    List<Member>? members,
    List<Shift>? shifts,
    List<Availability>? availability,
    List<Shift> assigned = const [],
  }) => service.generate(
    members: members ?? [employee()],
    unassigned: shifts ?? [shift()],
    availability: availability ?? [window()],
    assigned: assigned,
  );
  test(
    'Razpoložljiv zaposleni prejme izmeno',
    () => expect(run().shifts.single.memberId, 'a'),
  );
  test(
    'Brez razpoložljivosti ni dodelitve',
    () => expect(run(availability: []).shifts.single.memberId, isNull),
  );
  test(
    'Nerazpoložljivost preglasi razpoložljivost',
    () => expect(
      run(
        availability: [
          window(),
          window(id: 'no', available: false),
        ],
      ).shifts.single.memberId,
      isNull,
    ),
  );
  test(
    'Delna razpoložljivost ne zadostuje',
    () => expect(
      run(availability: [window(end: DateTime.utc(2026, 11, 23, 12))])
          .shifts
          .single
          .memberId,
      isNull,
    ),
  );
  test(
    'Prekrivajoča se izmena je zavrnjena',
    () => expect(
      run(
        assigned: [shift(id: 'existing', member: 'a')],
      ).shifts.single.memberId,
      isNull,
    ),
  );
  test(
    'Tedenska omejitev se ne preseže',
    () => expect(
      run(members: [employee(maxHours: 7)]).shifts.single.memberId,
      isNull,
    ),
  );
  test(
    'Napačna pozicija je zavrnjena',
    () => expect(
      run(members: [employee(position: 'Kuhinja')]).shifts.single.memberId,
      isNull,
    ),
  );
  test(
    'Minimalni počitek se upošteva',
    () => expect(
      run(
        assigned: [
          shift(
            id: 'prev',
            member: 'a',
            start: DateTime.utc(2026, 11, 22, 20),
            end: DateTime.utc(2026, 11, 23, 2),
          ),
        ],
      ).shifts.single.memberId,
      isNull,
    ),
  );
  test(
    'Točno 11 ur počitka je dovolj',
    () => expect(
      run(
        assigned: [
          shift(
            id: 'prev',
            member: 'a',
            start: DateTime.utc(2026, 11, 22, 13),
            end: DateTime.utc(2026, 11, 22, 21),
          ),
        ],
      ).shifts.single.memberId,
      'a',
    ),
  );
  test(
    'Manj obremenjeni zaposleni ima prednost',
    () => expect(
      run(
        shifts: [shift(start: DateTime.utc(2026, 11, 24, 8))],
        members: [
          employee(),
          employee(id: 'b'),
        ],
        availability: [
          window(
            start: DateTime.utc(2026, 11, 24),
            end: DateTime.utc(2026, 11, 25),
          ),
          window(
            member: 'b',
            start: DateTime.utc(2026, 11, 24),
            end: DateTime.utc(2026, 11, 25),
          ),
        ],
        assigned: [
          shift(
            id: 'prev',
            member: 'a',
            start: DateTime.utc(2026, 11, 23, 0),
            end: DateTime.utc(2026, 11, 23, 1),
          ),
        ],
      ).shifts.single.memberId,
      'b',
    ),
  );
  test('Ni zaposlenih: izmena ostane nepokrita z razlogom', () {
    final p = run(members: []);
    expect(p.shifts.single.memberId, isNull);
    expect(p.reasons['s'], 'Ni zaposlenih');
  });
  test(
    'Enaki rezultati se deterministično razrešijo po ID',
    () => expect(
      run(
        members: [
          employee(id: 'b'),
          employee(),
        ],
        availability: [
          window(),
          window(member: 'b'),
        ],
      ).shifts.single.memberId,
      'a',
    ),
  );
  test(
    'Stroški vplivajo na enakovredne kandidate',
    () => expect(
      run(
        members: [
          employee(rate: 20),
          employee(id: 'b', rate: 10),
        ],
        availability: [
          window(),
          window(member: 'b'),
        ],
      ).shifts.single.memberId,
      'b',
    ),
  );
  test(
    'Preference vplivajo na izbiro',
    () => expect(
      run(
        members: [
          employee(),
          employee(id: 'b'),
        ],
        availability: [
          window(),
          window(member: 'b', preference: 5),
        ],
      ).shifts.single.memberId,
      'b',
    ),
  );
  test(
    'Delodajalec ne prejme izmene',
    () => expect(
      run(members: [employee(role: 'employer')]).shifts.single.memberId,
      isNull,
    ),
  );
  test(
    'Zaposleni drugega podjetja ne prejme izmene',
    () => expect(
      run(members: [employee(business: 'other')]).shifts.single.memberId,
      isNull,
    ),
  );
  test('Začasna dodelitev prepreči naslednje prekrivanje', () {
    final p = run(
      shifts: [
        shift(id: '1'),
        shift(id: '2'),
      ],
    );
    expect(p.shifts.where((s) => s.memberId != null).length, 1);
  });
  test('Tedenska meja razdeli nočno izmeno', () {
    final s = shift(
      start: DateTime.utc(2026, 11, 29, 22),
      end: DateTime.utc(2026, 11, 30, 6),
    );
    final p = run(
      members: [employee(maxHours: 6)],
      shifts: [s],
      availability: [window(start: s.start, end: s.end)],
    );
    expect(p.shifts.single.memberId, 'a');
  });
  test('Dodelitev ne spreminja vhodnih podatkov', () {
    final input = shift();
    run(shifts: [input]);
    expect(input.memberId, isNull);
  });
}
