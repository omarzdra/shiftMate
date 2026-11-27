import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/domain.dart';
import '../repositories/workspace_repository.dart';
import '../services/local_cache.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository, this.cache) {
    _userId = repository.userId;
    _subscription = repository.sessions.listen(
      (id) {
        if (id == _userId) return;
        final previous = _userId;
        _userId = id;
        _generation++;
        data = null;
        error = null;
        offline = false;
        busy = false;
        if (previous != null) {
          unawaited(cache.clear(previous).catchError((Object _) {}));
        }
        if (id != null) {
          unawaited(refresh());
        } else {
          notifyListeners();
        }
      },
      onError: (Object e) {
        error = message(e);
        notifyListeners();
      },
    );
  }
  final WorkspaceRepository repository;
  final LocalCache cache;
  StreamSubscription<String?>? _subscription;
  String? _userId;
  int _generation = 0;
  bool _disposed = false;
  Workspace? data;
  bool busy = false, offline = false;
  String? error;
  String? get userId => _userId;
  Member? get me => data?.members.where((m) => m.userId == _userId).firstOrNull;
  bool get isEmployer => me?.isEmployer ?? false;
  bool get compact => cache.compact;
  static String message(Object e) {
    if (e is AuthException) {
      return switch (e.code) {
        'invalid_credentials' => 'E-pošta ali geslo ni pravilno.',
        'email_not_confirmed' => 'Pred prijavo potrdi svoj e-poštni naslov.',
        _ => e.message,
      };
    }
    if (e is PostgrestException) {
      return switch (e.code) {
        '23505' =>
          'Vnos že obstaja. Za posamezno izmeno je dovoljena ena evidenca.',
        '23503' =>
          'Vnosa ni mogoče spremeniti, ker je povezan z drugimi podatki.',
        '23514' =>
          'Preveri časovni interval, postavko in dovoljeno število ur.',
        '42501' => 'Za to dejanje nimaš dovoljenja.',
        'P0001' => e.message,
        _ => 'Podatkov ni mogoče obdelati. Osveži prikaz in poskusi znova.',
      };
    }
    if (e is ArgumentError) return e.message.toString();
    return 'Podatkov ni mogoče pridobiti. Preveri povezavo in poskusi znova.';
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> refresh() async {
    final id = _userId;
    if (id == null) return;
    final generation = ++_generation;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await repository.load();
      if (_disposed || generation != _generation) return;
      data = result;
      offline = false;
      if (result != null) {
        await cache.write(id, result);
        if (_disposed || generation != _generation) {
          await cache.clear(id);
          return;
        }
      } else {
        await cache.clear(id);
      }
    } catch (e) {
      if (_disposed || generation != _generation) return;
      error = message(e);
      // Only network failures may use the cached authorization snapshot.
      // API/auth errors (including revoked membership) must never revive it.
      if (e is! PostgrestException && e is! AuthException) {
        data ??= cache.read(id);
        offline = data != null;
      } else {
        data = null;
        offline = false;
        await cache.clear(id);
      }
    } finally {
      if (generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<bool> authenticate(String email, String password, bool register) =>
      run(
        () async {
          if (register) {
            await repository.signUp(email, password);
          } else {
            await repository.signIn(email, password);
          }
        },
        reload: false,
        allowOffline: true,
      );
  Future<bool> run(
    Future<void> Function() action, {
    bool reload = true,
    bool allowOffline = false,
  }) async {
    if (busy) return false;
    if (offline && !allowOffline) {
      error = 'Brez povezave je na voljo samo branje. Najprej osveži podatke.';
      notifyListeners();
      return false;
    }
    final generation = _generation;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      if (reload && !_disposed && generation == _generation) await refresh();
      return true;
    } catch (e) {
      if (generation == _generation) error = message(e);
      return false;
    } finally {
      if (generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> signOut() async {
    await run(
      () async {
        final previous = _userId;
        await repository.signOut();
        if (previous != null) await cache.clear(previous);
      },
      reload: false,
      allowOffline: true,
    );
  }

  Future<void> setCompact(bool value) async {
    await cache.setCompact(value);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
