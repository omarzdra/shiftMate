import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/domain.dart';
import 'workspace_repository.dart';

class SupabaseRepository implements WorkspaceRepository {
  SupabaseRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  String? get email => client.auth.currentUser?.email;
  @override
  Stream<String?> get sessions =>
      client.auth.onAuthStateChange.map((s) => s.session?.user.id);
  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
  Future<List<Json>> _rows(String table, String businessId) async {
    final rows = <Json>[];
    const pageSize = 200;
    for (var offset = 0; ; offset += pageSize) {
      final page = await client
          .from(table)
          .select()
          .eq('business_id', businessId)
          .order('id', ascending: true)
          .range(offset, offset + pageSize - 1);
      rows.addAll(page);
      if (page.length < pageSize) return rows;
    }
  }

  @override
  Future<Workspace?> load() async {
    final own = await client
        .from('business_members')
        .select()
        .eq('user_id', userId!)
        .maybeSingle();
    if (own == null) return null;
    final id = own['business_id'] as String;
    final business = await client
        .from('businesses')
        .select()
        .eq('id', id)
        .single();
    final results = await Future.wait([
      _rows('business_members', id),
      _rows('shifts', id),
      _rows('availabilities', id),
      _rows('work_logs', id),
    ]);
    results[1].sort(
      (a, b) => (a['starts_at'] as String).compareTo(b['starts_at'] as String),
    );
    results[2].sort(
      (a, b) => (a['starts_at'] as String).compareTo(b['starts_at'] as String),
    );
    results[3].sort(
      (a, b) => (b['starts_at'] as String).compareTo(a['starts_at'] as String),
    );
    return Workspace.fromJson({
      'business_id': id,
      'business_name': business['name'],
      'min_rest_hours': business['min_rest_hours'],
      'members': results[0],
      'shifts': results[1],
      'availabilities': results[2],
      'logs': results[3],
    });
  }

  @override
  Future<void> createBusiness(String name, String fullName) async {
    await client.rpc(
      'create_business',
      params: {'business_name': name, 'full_name': fullName},
    );
  }

  @override
  Future<void> join(String token, String fullName) async {
    await client.rpc(
      'join_business',
      params: {'invite_token': token, 'full_name': fullName},
    );
  }

  @override
  Future<String> invite(
    String email,
    String position,
    double rate,
    double maxHours,
  ) async {
    return await client.rpc(
      'invite_employee',
      params: {
        'invite_email': email,
        'job_position': position,
        'rate': rate,
        'max_hours': maxHours,
      },
    ) as String;
  }

  @override
  Future<void> save(String table, Json row) async {
    final values = Map<String, dynamic>.from(row)..remove('updated_at');
    final id = values.remove('id');
    if (id == null || id == '') {
      await client.from(table).insert(values);
    } else {
      await client.from(table).update(values).eq('id', id).select().single();
    }
  }

  @override
  Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('id', id).select().single();
  }

  @override
  Future<void> confirm(List<Shift> shifts) async {
    await client.rpc(
      'confirm_schedule',
      params: {
        'assignments': shifts
            .where((s) => s.memberId != null)
            .map(
              (s) => {
                'id': s.id,
                'member_id': s.memberId,
                'updated_at': s.updatedAt,
              },
            )
            .toList(),
      },
    );
  }

  @override
  Future<void> review(String id, bool approve, String reason) async {
    await client.rpc(
      'review_work_log',
      params: {'log_id': id, 'approve': approve, 'reason': reason},
    );
  }
}
