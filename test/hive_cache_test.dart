import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shiftmate_business/services/local_cache.dart';

import 'fixtures.dart';

void main() {
  test(
    'Hive ohrani podatke po ponovnem odprtju in jih izolira po uporabniku',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'shiftmate-cache-test-',
      );
      Hive.init(directory.path);
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
      var box = await Hive.openBox<String>('cache');
      var cache = HiveCache(box);
      await cache.write('user-a', workspace(shifts: [shift()]));
      await cache.setCompact(true);
      await box.close();
      box = await Hive.openBox<String>('cache');
      cache = HiveCache(box);
      expect(cache.read('user-a')!.shifts.single.id, 's');
      expect(cache.read('user-b'), isNull);
      expect(cache.compact, true);
      await cache.clear('user-a');
      expect(cache.read('user-a'), isNull);
    },
  );
}
