import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/home/presentation/hauptnavigation_screen.dart';
import 'package:taugts/features/suche/models/suchmodelle.dart';
import 'package:taugts/features/suche/services/suche_service.dart';

void main() {
  testWidgets('Such-Kachel öffnet den globalen Suchbereich', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HauptnavigationScreen(
          profil: null,
          profilRepository: null,
          bewertungsRepository: null,
          exportService: null,
          exportZielService: null,
          idGenerator: null,
          kategorieRepository: null,
          kriteriensetRepository: null,
          sucheService: _FakeSucheService(),
          auswertungsService: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final suchKachel = find.widgetWithText(OutlinedButton, 'Suche');
    expect(suchKachel, findsOneWidget);

    await tester.ensureVisible(suchKachel);
    await tester.tap(suchKachel);
    await tester.pumpAndSettle();

    expect(find.text('Suchbegriff'), findsOneWidget);
    expect(find.text('Suche noch nicht verfügbar'), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
}

class _FakeSucheService implements SucheService {
  @override
  Future<List<Suchtreffer>> suche(Suchfilter filter) async => [];
}
