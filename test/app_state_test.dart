import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shiftmate_business/providers/app_state.dart';

import 'fixtures.dart';

void main() {
  test('Osvežitev pridobi podatke in jih shrani v predpomnilnik', () async {
    final r = FakeRepository(userId: 'user-a', data: workspace());
    final cache = MemoryCache();
    final s = AppState(r, cache);
    addTearDown(s.dispose);
    addTearDown(r.close);
    await s.refresh();
    expect(s.me!.id, 'a');
    expect(cache.read('user-a')!.businessName, 'Kavarna Test');
  });
  test('Izguba omrežja omogoči branje predpomnilnika', () async {
    final cache = MemoryCache();
    await cache.write('user-a', workspace());
    final r = FakeRepository(userId: 'user-a')
      ..failure = const SocketException('offline');
    final s = AppState(r, cache);
    addTearDown(s.dispose);
    addTearDown(r.close);
    await s.refresh();
    expect(s.offline, true);
    expect(s.data, isNotNull);
  });
  test('Offline spremembe so blokirane', () async {
    final cache = MemoryCache();
    await cache.write('user-a', workspace());
    final r = FakeRepository(userId: 'user-a')
      ..failure = const SocketException('offline');
    final s = AppState(r, cache);
    addTearDown(s.dispose);
    addTearDown(r.close);
    await s.refresh();
    var called = false;
    expect(
      await s.run(() async {
        called = true;
      }),
      false,
    );
    expect(called, false);
  });
  test('API zavrnitev ne obnovi starega članstva iz predpomnilnika', () async {
    final cache = MemoryCache();
    await cache.write('user-a', workspace());
    final r = FakeRepository(userId: 'user-a')
      ..failure = const PostgrestException(message: 'forbidden', code: '42501');
    final s = AppState(r, cache);
    addTearDown(s.dispose);
    addTearDown(r.close);
    await s.refresh();
    expect(s.data, isNull);
    expect(cache.read('user-a'), isNull);
  });
  test('Odjava odstrani osebne podatke', () async {
    final cache = MemoryCache();
    final r = FakeRepository(userId: 'user-a', data: workspace());
    final s = AppState(r, cache);
    addTearDown(s.dispose);
    addTearDown(r.close);
    await s.refresh();
    await s.signOut();
    expect(s.userId, isNull);
    expect(s.data, isNull);
    expect(cache.read('user-a'), isNull);
  });
  test('Pozen odgovor po odjavi ne obnovi podatkov', () async {
    final r = FakeRepository(userId: 'user-a')..pending = Completer();
    final cache = MemoryCache();
    final s = AppState(r, cache);
    addTearDown(s.dispose);
    addTearDown(r.close);
    final refresh = s.refresh();
    await r.signOut();
    r.pending!.complete(workspace());
    await refresh;
    expect(s.data, isNull);
    expect(cache.read('user-a'), isNull);
  });
  test('Dvojna oddaja je blokirana med zahtevo', () async {
    final r = FakeRepository();
    final s = AppState(r, MemoryCache());
    addTearDown(s.dispose);
    addTearDown(r.close);
    final pending = Completer<void>();
    final first = s.run(() => pending.future, reload: false);
    expect(await s.run(() async {}, reload: false), false);
    pending.complete();
    expect(await first, true);
  });
  test('Nastavitev gostote se shrani', () async {
    final r = FakeRepository();
    final s = AppState(r, MemoryCache());
    addTearDown(s.dispose);
    addTearDown(r.close);
    await s.setCompact(true);
    expect(s.compact, true);
  });
}
