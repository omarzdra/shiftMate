import '../models/domain.dart';

class DashboardSummary {
  DashboardSummary(
    Workspace data,
    Member member,
    DateTime now,
    DateTime from,
    DateTime until,
  ) {
    final employer = member.isEmployer;
    final shifts =
        data.shifts.where((s) => employer || s.memberId == member.id).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    upcoming = shifts.where((s) => s.end.isAfter(now)).toList();
    today = shifts.where((s) {
      final day = s.start.toLocal();
      final local = now.toLocal();
      return day.year == local.year &&
          day.month == local.month &&
          day.day == local.day;
    }).length;
    unassigned = shifts
        .where((s) => s.memberId == null && s.end.isAfter(now))
        .length;
    employees = data.members.where((m) => !m.isEmployer).length;
    final logs = data.logs
        .where(
          (l) =>
              (employer || l.memberId == member.id) &&
              !l.start.isBefore(from) &&
              l.start.isBefore(until),
        )
        .toList();
    pending = logs.where((l) => l.status == LogStatus.pending).length;
    pendingHours = logs
        .where((l) => l.status == LogStatus.pending)
        .fold(0, (v, l) => v + l.hours);
    approvedHours = logs
        .where((l) => l.status == LogStatus.approved)
        .fold(0, (v, l) => v + l.hours);
    totalHours = logs.fold(0, (v, l) => v + l.hours);
    pay = logs.fold(0, (v, l) => v + l.pay);
  }
  late final List<Shift> upcoming;
  late final int today, unassigned, employees, pending;
  late final double pendingHours, approvedHours, totalHours, pay;
}
