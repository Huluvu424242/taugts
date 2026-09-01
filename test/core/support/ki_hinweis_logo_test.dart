import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/core/support/app_info.dart';
import 'package:taugts/core/support/app_info_service.dart';
import 'package:taugts/core/support/app_support.dart';

void main() {
  testWidgets('KI-Hinweislogo lädt auf kleinem Bildschirm ohne Exception',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: const [
              AppSupportMenu(
                contextName: 'KI-Hinweislogo-Test',
                appInfoGateway: _FakeAppInfoGateway(),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('App-Menü öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Über'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppLogo), findsOneWidget);
    final imageFinder = find.descendant(
      of: find.byType(AppLogo),
      matching: find.byType(Image),
    );
    expect(imageFinder, findsOneWidget);
    final image = tester.widget<Image>(imageFinder);
    expect(image.width, 48);
    expect(image.height, 48);
    expect(tester.getSize(imageFinder), const Size.square(48));
  });

  test('KI-Hinweislogo ist ein vollständig dekodierbares quadratisches PNG',
      () async {
    final data = await rootBundle.load(appLogoAsset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    addTearDown(codec.dispose);
    final frame = await codec.getNextFrame();
    addTearDown(frame.image.dispose);

    expect(frame.image.width, 64);
    expect(frame.image.height, 64);
  });
}

class _FakeAppInfoGateway implements AppInfoGateway {
  const _FakeAppInfoGateway();

  @override
  Future<AppInfo> laden() async =>
      const AppInfo(version: '1.2.3', buildNumber: '45');
}
