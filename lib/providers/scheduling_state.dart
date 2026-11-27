import 'package:flutter/foundation.dart';

import '../models/domain.dart';
import '../services/scheduling_service.dart';
import 'app_state.dart';

class SchedulingState extends ChangeNotifier {
  SchedulingState(this.app, {this.service = const SchedulingService()});
  final AppState app;
  final SchedulingService service;
  ScheduleProposal? proposal;
  String? error;
  bool saving = false;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void clear() {
    proposal = null;
    error = null;
    notifyListeners();
  }

  void generate(DateTime from, DateTime until) {
    final d = app.data;
    if (d == null || !app.isEmployer || app.offline) return;
    error = null;
    proposal = service.generate(
      members: d.members,
      unassigned: d.shifts
          .where(
            (s) =>
                s.memberId == null &&
                !s.start.isBefore(from) &&
                s.start.isBefore(until),
          )
          .toList(),
      availability: d.availabilities,
      assigned: d.shifts.where((s) => s.memberId != null).toList(),
      minRestHours: d.minRestHours,
    );
    notifyListeners();
  }

  void change(Shift shift, String? memberId) {
    final d = app.data;
    if (d == null || proposal == null || saving) return;
    final other = [
      ...d.shifts.where((s) => s.memberId != null),
      ...proposal!.shifts.where((s) => s.id != shift.id && s.memberId != null),
    ];
    if (memberId != null) {
      final member = d.members.where((m) => m.id == memberId).firstOrNull;
      final reason = member == null
          ? 'Zaposleni ni več na voljo.'
          : service.rejection(
              member,
              shift,
              d.availabilities,
              other,
              minRestHours: d.minRestHours,
            );
      if (reason != null) {
        error = reason;
        notifyListeners();
        return;
      }
    }
    proposal = ScheduleProposal(
      proposal!.shifts
          .map((s) => s.id == shift.id ? s.assign(memberId) : s)
          .toList(),
      proposal!.reasons,
    );
    error = null;
    notifyListeners();
  }

  Future<bool> confirm() async {
    if (saving ||
        proposal == null ||
        app.busy ||
        app.offline ||
        !app.isEmployer) {
      return false;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      final userId = app.userId;
      final selected = proposal!.shifts;
      await app.refresh();
      if (_disposed) return false;
      if (app.error != null ||
          app.data == null ||
          app.userId != userId ||
          !app.isEmployer) {
        error = app.error ?? 'Seja ni veljavna.';
        return false;
      }
      final d = app.data!;
      final working = d.shifts.where((s) => s.memberId != null).toList();
      for (final shift in selected.where((s) => s.memberId != null)) {
        final latest = d.shifts.where((s) => s.id == shift.id).firstOrNull;
        final member = d.members
            .where((m) => m.id == shift.memberId)
            .firstOrNull;
        final reason =
            latest == null ||
                latest.updatedAt != shift.updatedAt ||
                latest.memberId != null ||
                member == null
            ? 'Predlog je zastarel. Pripravi novega.'
            : service.rejection(
                member,
                shift,
                d.availabilities,
                working,
                minRestHours: d.minRestHours,
              );
        if (reason != null) {
          error = reason;
          return false;
        }
        working.add(shift);
      }
      final ok = await app.run(() => app.repository.confirm(selected));
      if (!ok) error = app.error ?? 'Urnika ni mogoče shraniti.';
      return ok;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
