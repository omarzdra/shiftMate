import 'package:flutter_test/flutter_test.dart';
import 'package:shiftmate_business/models/domain.dart';
import 'package:shiftmate_business/services/validation.dart';

import 'fixtures.dart';

void main() {
  test(
    'Veljaven e-poštni naslov',
    () => expect(Validation.email('oseba@example.test'), isNull),
  );
  test(
    'E-pošta brez domene je zavrnjena',
    () => expect(Validation.email('oseba@'), isNotNull),
  );
  test(
    'Presledki v e-pošti so zavrnjeni',
    () => expect(Validation.email('a b@c.test'), isNotNull),
  );
  test(
    'Prekratko geslo je zavrnjeno',
    () => expect(Validation.password('123'), isNotNull),
  );
  test(
    'Izračun osmih delovnih ur',
    () => expect(
      Validation.workHours(
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 1, 16),
        0,
      ),
      8,
    ),
  );
  test('Odmor se odšteje od ur', () => expect(log().hours, 7.5));
  test(
    'Plačilo je izračunano iz potrjenih ur',
    () => expect(log(status: LogStatus.approved).pay, 75),
  );
  test('Nepotrjene ure se ne plačajo', () => expect(log().pay, 0));
  test(
    'Zavrnjene ure se ne plačajo',
    () => expect(log(status: LogStatus.rejected).pay, 0),
  );
  test(
    'Negativen interval je zavrnjen',
    () => expect(
      () => Validation.workHours(
        DateTime(2026, 1, 1, 16),
        DateTime(2026, 1, 1, 8),
        0,
      ),
      throwsArgumentError,
    ),
  );
  test(
    'Negativen odmor je zavrnjen',
    () => expect(
      () => Validation.workHours(
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 1, 16),
        -1,
      ),
      throwsArgumentError,
    ),
  );
  test(
    'Odmor ne more biti daljši od dela',
    () => expect(
      () => Validation.workHours(
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 1, 16),
        480,
      ),
      throwsArgumentError,
    ),
  );
  test(
    'Nočna izmena ima dejansko trajanje',
    () => expect(
      Validation.workHours(
        DateTime.utc(2026, 1, 1, 22),
        DateTime.utc(2026, 1, 2, 6),
        0,
      ),
      8,
    ),
  );
  test(
    'Stik intervalov ni prekrivanje',
    () => expect(
      Validation.overlaps(
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 1, 16),
        DateTime(2026, 1, 1, 16),
        DateTime(2026, 1, 1, 18),
      ),
      false,
    ),
  );
  test(
    'Prekrivanje intervalov',
    () => expect(
      Validation.overlaps(
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 1, 16),
        DateTime(2026, 1, 1, 15),
        DateTime(2026, 1, 1, 18),
      ),
      true,
    ),
  );
  test(
    'Model člana preživi JSON pretvorbo',
    () => expect(
      Member.fromJson(employee().toJson()).toJson(),
      employee().toJson(),
    ),
  );
  test(
    'Model izmene preživi JSON pretvorbo',
    () => expect(Shift.fromJson(shift().toJson()).toJson(), shift().toJson()),
  );
  test(
    'Razpoložljivost preživi JSON pretvorbo',
    () => expect(
      Availability.fromJson(window().toJson()).toJson(),
      window().toJson(),
    ),
  );
  test(
    'Evidenca preživi JSON pretvorbo',
    () => expect(WorkLog.fromJson(log().toJson()).toJson(), log().toJson()),
  );
  test(
    'Celoten predpomnilnik preživi JSON pretvorbo',
    () => expect(
      Workspace.fromJson(workspace(shifts: [shift()], logs: [log()]).toJson())
          .toJson(),
      workspace(shifts: [shift()], logs: [log()]).toJson(),
    ),
  );
  test('Ure se razdelijo na meji UTC tedna', () {
    final a = DateTime.utc(2026, 11, 29, 22), b = DateTime.utc(2026, 11, 30, 6);
    expect(Validation.hoursInWeek(a, b, DateTime.utc(2026, 11, 23)), 2);
    expect(Validation.hoursInWeek(a, b, DateTime.utc(2026, 11, 30)), 6);
  });
}
