import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/features/home/presentation/home_screen.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';

void main() {
  testWidgets('Hauptmenü zeigt gut erkennbares KI-Logo ohne höhere App-Bar',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final jetzt = DateTime(2026, 9, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          profil: Profil(
            id: 'profil-1',
            anzeigename: 'Test',
            erstelltAm: jetzt,
            geaendertAm: jetzt,
          ),
          profilRepository: _FakeProfilRepository(),
        ),
      ),
    );

    final logoFinder = find.byKey(const Key('hauptmenue-logo'));
    expect(logoFinder, findsOneWidget);
    expect(tester.widget<AppLogo>(logoFinder).size, 32);
    expect(tester.getSize(logoFinder), const Size.square(32));
    expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);

    final titel = tester.getRect(find.text('Taugt’s?'));
    final logo = tester.getRect(logoFinder);
    expect(logo.left, greaterThan(titel.right));
    expect(find.byTooltip('Mein Profil bearbeiten'), findsOneWidget);
    expect(find.byTooltip('App-Menü öffnen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeProfilRepository implements ProfilRepository {
  @override
  Future<Profil> ladeOderErstelleProfil() => throw UnimplementedError();

  @override
  Future<void> speichereProfil(Profil profil) => throw UnimplementedError();
}
