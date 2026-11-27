import 'dart:async';

import 'package:shiftmate_business/models/domain.dart';
import 'package:shiftmate_business/repositories/workspace_repository.dart';
import 'package:shiftmate_business/services/local_cache.dart';

Member employee({
  String id = 'a',
  String business = 'b',
  String position = 'Strežba',
  double rate = 10,
  double maxHours = 40,
  String role = 'employee',
}) => Member(
  id: id,
  businessId: business,
  userId: 'user-$id',
  name: 'Oseba $id',
  role: role,
  position: position,
  hourlyRate: rate,
  maxWeeklyHours: maxHours,
);
Shift shift({
  String id = 's',
  String? member,
  DateTime? start,
  DateTime? end,
  String position = 'Strežba',
}) {
  final a = start ?? DateTime.utc(2026, 11, 23, 8);
  return Shift(
    id: id,
    businessId: 'b',
    start: a,
    end: end ?? a.add(const Duration(hours: 8)),
    position: position,
    memberId: member,
    updatedAt: '2026-11-20T00:00:00Z',
  );
}

Availability window({
  String id = 'v',
  String member = 'a',
  DateTime? start,
  DateTime? end,
  bool available = true,
  double preference = 0,
}) => Availability(
  id: id,
  businessId: 'b',
  memberId: member,
  start: start ?? DateTime.utc(2026, 11, 23),
  end: end ?? DateTime.utc(2026, 11, 24),
  available: available,
  preference: preference,
);
WorkLog log({LogStatus status = LogStatus.pending, int pause = 30}) => WorkLog(
  id: 'l',
  businessId: 'b',
  memberId: 'a',
  shiftId: 's',
  start: DateTime.utc(2026, 11, 23, 8),
  end: DateTime.utc(2026, 11, 23, 16),
  breakMinutes: pause,
  status: status,
  hourlyRate: 10,
);
Workspace workspace({
  bool employer = false,
  List<Shift>? shifts,
  List<WorkLog>? logs,
}) => Workspace(
  businessId: 'b',
  businessName: 'Kavarna Test',
  members: [
    employee(),
    employee(id: 'owner', role: 'employer'),
  ],
  shifts: shifts ?? [],
  availabilities: [window()],
  logs: logs ?? [],
);

class MemoryCache implements LocalCache {
  final values = <String, Workspace>{};
  bool _compact = false;
  @override
  Workspace? read(String userId) => values[userId];
  @override
  Future<void> write(String userId, Workspace data) async {
    values[userId] = data;
  }

  @override
  Future<void> clear(String userId) async {
    values.remove(userId);
  }

  @override
  bool get compact => _compact;
  @override
  Future<void> setCompact(bool value) async {
    _compact = value;
  }
}

class FakeRepository implements WorkspaceRepository {
  FakeRepository({this.userId, this.data});
  @override
  String? userId;
  @override
  String? get email => 'oseba@example.test';
  Workspace? data;
  Object? failure;
  Completer<Workspace?>? pending;
  final changes = StreamController<String?>.broadcast(sync: true);
  final writes = <Json>[];
  final confirmations = <List<Shift>>[];
  @override
  Stream<String?> get sessions => changes.stream;
  @override
  Future<Workspace?> load() async {
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return data;
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (failure != null) throw failure!;
    userId = 'user-a';
    changes.add(userId);
  }

  @override
  Future<void> signUp(String email, String password) async {
    if (failure != null) throw failure!;
  }

  @override
  Future<void> signOut() async {
    userId = null;
    changes.add(null);
  }

  @override
  Future<void> createBusiness(String name, String fullName) async {}
  @override
  Future<void> join(String token, String fullName) async {}
  @override
  Future<String> invite(
    String email,
    String position,
    double rate,
    double maxHours,
  ) async => 'token';
  @override
  Future<void> save(String table, Json row) async {
    writes.add({'table': table, ...row});
  }

  @override
  Future<void> delete(String table, String id) async {}
  @override
  Future<void> confirm(List<Shift> shifts) async {
    confirmations.add(shifts);
  }

  @override
  Future<void> review(String id, bool approve, String reason) async {}
  Future<void> close() => changes.close();
}
