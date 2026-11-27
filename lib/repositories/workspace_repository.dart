import '../models/domain.dart';

abstract class WorkspaceRepository {
  String? get userId;
  String? get email;
  Stream<String?> get sessions;
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();
  Future<Workspace?> load();
  Future<void> createBusiness(String name, String fullName);
  Future<void> join(String token, String fullName);
  Future<String> invite(
    String email,
    String position,
    double rate,
    double maxHours,
  );
  Future<void> save(String table, Json row);
  Future<void> delete(String table, String id);
  Future<void> confirm(List<Shift> shifts);
  Future<void> review(String id, bool approve, String reason);
}
