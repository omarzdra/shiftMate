typedef Json = Map<String, dynamic>;

DateTime instant(dynamic value) => DateTime.parse(value as String).toUtc();
double number(dynamic value) => (value as num).toDouble();

class Member {
  const Member({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.name,
    required this.role,
    required this.position,
    required this.hourlyRate,
    required this.maxWeeklyHours,
  });
  final String id, businessId, userId, name, role, position;
  final double hourlyRate, maxWeeklyHours;
  bool get isEmployer => role == 'employer';
  factory Member.fromJson(Json j) => Member(
    id: j['id'],
    businessId: j['business_id'],
    userId: j['user_id'],
    name: j['name'],
    role: j['role'],
    position: j['position'],
    hourlyRate: number(j['hourly_rate']),
    maxWeeklyHours: number(j['max_weekly_hours']),
  );
  Json toJson() => {
    'id': id,
    'business_id': businessId,
    'user_id': userId,
    'name': name,
    'role': role,
    'position': position,
    'hourly_rate': hourlyRate,
    'max_weekly_hours': maxWeeklyHours,
  };
}

class Shift {
  const Shift({
    required this.id,
    required this.businessId,
    required this.start,
    required this.end,
    required this.position,
    this.memberId,
    this.updatedAt,
  });
  final String id, businessId, position;
  final String? memberId, updatedAt;
  final DateTime start, end;
  double get hours => end.difference(start).inMinutes / 60;
  Shift assign(String? value) => Shift(
    id: id,
    businessId: businessId,
    start: start,
    end: end,
    position: position,
    memberId: value,
    updatedAt: updatedAt,
  );
  factory Shift.fromJson(Json j) => Shift(
    id: j['id'],
    businessId: j['business_id'],
    start: instant(j['starts_at']),
    end: instant(j['ends_at']),
    position: j['position'],
    memberId: j['member_id'],
    updatedAt: j['updated_at'],
  );
  Json toJson() => {
    'id': id,
    'business_id': businessId,
    'starts_at': start.toUtc().toIso8601String(),
    'ends_at': end.toUtc().toIso8601String(),
    'position': position,
    'member_id': memberId,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}

class Availability {
  const Availability({
    required this.id,
    required this.businessId,
    required this.memberId,
    required this.start,
    required this.end,
    required this.available,
    this.preference = 0,
  });
  final String id, businessId, memberId;
  final DateTime start, end;
  final bool available;
  final double preference;
  factory Availability.fromJson(Json j) => Availability(
    id: j['id'],
    businessId: j['business_id'],
    memberId: j['member_id'],
    start: instant(j['starts_at']),
    end: instant(j['ends_at']),
    available: j['available'],
    preference: number(j['preference'] ?? 0),
  );
  Json toJson() => {
    'id': id,
    'business_id': businessId,
    'member_id': memberId,
    'starts_at': start.toUtc().toIso8601String(),
    'ends_at': end.toUtc().toIso8601String(),
    'available': available,
    'preference': preference,
  };
}

enum LogStatus { pending, approved, rejected }

class WorkLog {
  const WorkLog({
    required this.id,
    required this.businessId,
    required this.memberId,
    required this.shiftId,
    required this.start,
    required this.end,
    required this.breakMinutes,
    required this.status,
    required this.hourlyRate,
    this.note = '',
    this.rejectionReason = '',
  });
  final String id, businessId, memberId, shiftId, note, rejectionReason;
  final DateTime start, end;
  final int breakMinutes;
  final LogStatus status;
  final double hourlyRate;
  double get hours => end.difference(start).inMinutes / 60 - breakMinutes / 60;
  double get pay => status == LogStatus.approved ? hours * hourlyRate : 0;
  factory WorkLog.fromJson(Json j) => WorkLog(
    id: j['id'],
    businessId: j['business_id'],
    memberId: j['member_id'],
    shiftId: j['shift_id'],
    start: instant(j['starts_at']),
    end: instant(j['ends_at']),
    breakMinutes: j['break_minutes'],
    status: LogStatus.values.byName(j['status']),
    hourlyRate: number(j['hourly_rate']),
    note: j['note'] ?? '',
    rejectionReason: j['rejection_reason'] ?? '',
  );
  Json toJson() => {
    'id': id,
    'business_id': businessId,
    'member_id': memberId,
    'shift_id': shiftId,
    'starts_at': start.toUtc().toIso8601String(),
    'ends_at': end.toUtc().toIso8601String(),
    'break_minutes': breakMinutes,
    'status': status.name,
    'hourly_rate': hourlyRate,
    'note': note,
    'rejection_reason': rejectionReason,
  };
}

class Workspace {
  const Workspace({
    required this.businessId,
    required this.businessName,
    required this.members,
    required this.shifts,
    required this.availabilities,
    required this.logs,
    this.minRestHours = 11,
  });
  final String businessId, businessName;
  final double minRestHours;
  final List<Member> members;
  final List<Shift> shifts;
  final List<Availability> availabilities;
  final List<WorkLog> logs;
  factory Workspace.fromJson(Json j) => Workspace(
    businessId: j['business_id'],
    businessName: j['business_name'],
    minRestHours: number(j['min_rest_hours']),
    members: (j['members'] as List)
        .map((e) => Member.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    shifts: (j['shifts'] as List)
        .map((e) => Shift.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    availabilities: (j['availabilities'] as List)
        .map((e) => Availability.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    logs: (j['logs'] as List)
        .map((e) => WorkLog.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
  Json toJson() => {
    'business_id': businessId,
    'business_name': businessName,
    'min_rest_hours': minRestHours,
    'members': members.map((e) => e.toJson()).toList(),
    'shifts': shifts.map((e) => e.toJson()).toList(),
    'availabilities': availabilities.map((e) => e.toJson()).toList(),
    'logs': logs.map((e) => e.toJson()).toList(),
  };
}
