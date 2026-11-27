import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftmate_business/main.dart';
import 'package:shiftmate_business/providers/app_state.dart';

import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    final fontFile = File(
      '$root/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    );
    if (await fontFile.exists()) {
      final loader = FontLoader('Roboto')
        ..addFont(fontFile.readAsBytes().then((b) => ByteData.sublistView(b)));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
          ).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      await icons.load();
    } else if (const bool.fromEnvironment('CAPTURE_VISUALS')) {
      throw StateError(
        'Za vizualni zajem nastavi FLUTTER_ROOT na uporabljeni Flutter SDK.',
      );
    }
  });
  for (final width in [390.0, 1200.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Zasloni pri širini $width in povečavi $scale ne prelivajo vsebine',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = FakeRepository(
            userId: 'user-owner',
            data: workspace(
              shifts: [
                shift(),
                shift(id: '2', member: 'a'),
              ],
            ),
          );
          final state = AppState(repository, MemoryCache());
          addTearDown(state.dispose);
          addTearDown(repository.close);
          await state.refresh();
          const boundary = Key('visual');
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: TextScaler.linear(scale),
                ),
                child: ShiftMateApp(state: state),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final tab in ['Urnik', 'Zaposleni', 'Delovne ure', 'Profil']) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: tab);
          }
          await tester.tap(find.text('Urnik').last);
          await tester.pumpAndSettle();
          if (const bool.fromEnvironment('CAPTURE_VISUALS')) {
            final render = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(boundary),
            );
            await tester.runAsync(() async {
              final image = await render.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'build/visual/schedule-${width.toInt()}-$scale.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        },
      );
    }
  }
}
