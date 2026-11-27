import 'package:flutter_test/flutter_test.dart';
import 'package:shiftmate_business/models/domain.dart';
import 'package:shiftmate_business/services/dashboard_summary.dart';

import 'fixtures.dart';

void main() {
  test('Pregled izračuna dejanske potrjene in čakajoče ure', () {
    final summary = DashboardSummary(
      workspace(
        logs: [
          log(),
          log(status: LogStatus.approved),
        ],
      ),
      employee(),
      DateTime.utc(2026, 11, 23),
      DateTime.utc(2026, 11, 1),
      DateTime.utc(2026, 12, 1),
    );
    expect(summary.approvedHours, 7.5);
    expect(summary.pendingHours, 7.5);
    expect(summary.totalHours, 15);
    expect(summary.pay, 75);
  });
  test('Izbrano obdobje izloči zunanje evidence', () {
    final summary = DashboardSummary(
      workspace(logs: [log(status: LogStatus.approved)]),
      employee(),
      DateTime.utc(2026, 12, 1),
      DateTime.utc(2026, 12, 1),
      DateTime.utc(2027, 1, 1),
    );
    expect(summary.approvedHours, 0);
    expect(summary.pay, 0);
  });
  test('Zaposleni ne prišteje tuje izmene', () {
    final summary = DashboardSummary(
      workspace(
        shifts: [
          shift(member: 'a'),
          shift(id: 'other', member: 'b'),
        ],
      ),
      employee(),
      DateTime.utc(2026, 11, 23),
      DateTime.utc(2026, 11, 1),
      DateTime.utc(2026, 12, 1),
    );
    expect(summary.upcoming.length, 1);
  });
  test('Delodajalec vidi število nedodeljenih izmen', () {
    final summary = DashboardSummary(
      workspace(
        shifts: [
          shift(),
          shift(id: 'assigned', member: 'a'),
        ],
      ),
      employee(id: 'owner', role: 'employer'),
      DateTime.utc(2026, 11, 23),
      DateTime.utc(2026, 11, 1),
      DateTime.utc(2026, 12, 1),
    );
    expect(summary.unassigned, 1);
    expect(summary.employees, 1);
  });
}
