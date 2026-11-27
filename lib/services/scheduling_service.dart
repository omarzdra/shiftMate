import '../models/domain.dart';
import 'validation.dart';

class SchedulingWeights {
  const SchedulingWeights({
    this.balance = 1,
    this.cost = .02,
    this.preference = 1,
  });
  final double balance, cost, preference;
}

class ScheduleProposal {
  const ScheduleProposal(this.shifts, this.reasons);
  final List<Shift> shifts;
  final Map<String, String> reasons;
}

class SchedulingService {
  const SchedulingService({this.weights = const SchedulingWeights()});
  final SchedulingWeights weights;

  String? rejection(
    Member member,
    Shift shift,
    List<Availability> availability,
    List<Shift> assigned, {
    double minRestHours = 11,
  }) {
    if (!Validation.interval(shift.start, shift.end)) {
      return 'Neveljaven časovni interval';
    }
    if (member.isEmployer ||
        member.businessId != shift.businessId ||
        member.position != shift.position) {
      return 'Neustrezna delovna pozicija';
    }
    final windows = availability.where(
      (a) => a.memberId == member.id && a.businessId == shift.businessId,
    );
    if (windows.any(
          (a) =>
              !a.available &&
              Validation.overlaps(a.start, a.end, shift.start, shift.end),
        ) ||
        !windows.any(
          (a) =>
              a.available &&
              !a.start.isAfter(shift.start) &&
              !a.end.isBefore(shift.end),
        )) {
      return 'Ni razpoložljivosti za celotno izmeno';
    }
    final existing = assigned
        .where((s) => s.memberId == member.id && s.id != shift.id)
        .toList();
    for (final other in existing) {
      if (Validation.overlaps(shift.start, shift.end, other.start, other.end)) {
        return 'Prekrivanje izmen';
      }
      final rest = shift.start.isAfter(other.start)
          ? shift.start.difference(other.end)
          : other.start.difference(shift.end);
      if (rest.inMinutes < minRestHours * 60) return 'Premalo počitka';
    }
    for (
      var week = Validation.weekStart(shift.start);
      week.isBefore(shift.end);
      week = week.add(const Duration(days: 7))
    ) {
      final hours = existing.fold<double>(
        0,
        (sum, s) => sum + Validation.hoursInWeek(s.start, s.end, week),
      );
      if (hours + Validation.hoursInWeek(shift.start, shift.end, week) >
          member.maxWeeklyHours + .00001) {
        return 'Presežene tedenske ure';
      }
    }
    return null;
  }

  ScheduleProposal generate({
    required List<Member> members,
    required List<Shift> unassigned,
    required List<Availability> availability,
    required List<Shift> assigned,
    double minRestHours = 11,
  }) {
    final working = [...assigned];
    final result = <Shift>[];
    final reasons = <String, String>{};
    List<Member> candidates(Shift s) => members
        .where(
          (m) =>
              rejection(
                m,
                s,
                availability,
                working,
                minRestHours: minRestHours,
              ) ==
              null,
        )
        .toList();
    final pending = unassigned.where((s) => s.memberId == null).toList();
    while (pending.isNotEmpty) {
      pending.sort((a, b) {
        final scarcity = candidates(a).length.compareTo(candidates(b).length);
        if (scarcity != 0) return scarcity;
        final time = a.start.compareTo(b.start);
        return time == 0 ? a.id.compareTo(b.id) : time;
      });
      final shift = pending.removeAt(0);
      final eligible = candidates(shift);
      double score(Member m) {
        final week = Validation.weekStart(shift.start);
        final hours = working
            .where((s) => s.memberId == m.id)
            .fold<double>(
              0,
              (v, s) => v + Validation.hoursInWeek(s.start, s.end, week),
            );
        final preferences = availability.where(
          (a) =>
              a.memberId == m.id &&
              a.available &&
              !a.start.isAfter(shift.start) &&
              !a.end.isBefore(shift.end),
        );
        final preference = preferences.fold<double>(
          0,
          (v, a) => a.preference > v ? a.preference : v,
        );
        return hours * weights.balance +
            m.hourlyRate * shift.hours * weights.cost -
            preference * weights.preference;
      }

      eligible.sort((a, b) {
        final comparison = score(a).compareTo(score(b));
        return comparison == 0 ? a.id.compareTo(b.id) : comparison;
      });
      if (eligible.isEmpty) {
        reasons[shift.id] = members
            .where((m) => !m.isEmployer)
            .map(
              (m) =>
                  '${m.name}: ${rejection(m, shift, availability, working, minRestHours: minRestHours)}',
            )
            .join('; ');
        if (reasons[shift.id]!.isEmpty) reasons[shift.id] = 'Ni zaposlenih';
        result.add(shift);
      } else {
        final selected = shift.assign(eligible.first.id);
        result.add(selected);
        working.add(selected);
      }
    }
    return ScheduleProposal(result, reasons);
  }
}
