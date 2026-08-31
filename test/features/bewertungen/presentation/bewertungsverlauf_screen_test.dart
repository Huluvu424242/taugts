import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/presentation/bewertungsverlauf_screen.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';

void main() {
  testWidgets('zeigt Leerzustand offline und bleibt mit großer Schrift nutzbar',
      (tester) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final repository = SqliteBewertungsRepository(datenbank);
    final zeit = DateTime.utc(2026, 8, 31);
    final produkt = Produkt(
      id: '98000000-0000-4000-8000-000000000001',
      name: 'Historienprodukt',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: BewertungsverlaufScreen.fuerProdukt(
          repository: repository,
          produkt: produkt,
          eigenesProfilId: 'eigen',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Historienprodukt'), findsOneWidget);
    expect(
      find.text('Für dieses Objekt liegen noch keine historischen Bewertungen oder Preise vor.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('zeigt Gesamtwertung, Preis, Herkunft und Einzelwerte historisch',
      (tester) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final zeit = DateTime.utc(2026, 8, 31, 18);
    final produkt = Produkt(
      id: '98000000-0000-4000-8000-000000000010',
      name: 'Historienprodukt',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final erlebnis = Erlebnis(
      id: '98000000-0000-4000-8000-000000000011',
      typ: Erlebnistyp.restaurantbesuch,
      ortId: '98000000-0000-4000-8000-000000000012',
      herkunftProfilId: 'importiert',
      tatsaechlicherBeginn: zeit,
      tatsaechlichesEnde: zeit.add(const Duration(hours: 2)),
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    final eintrag = BewertungsverlaufEintrag(
      erlebnis: erlebnis,
      ort: Ort(
        id: erlebnis.ortId!,
        name: 'Historischer Ort mit langem Namen',
        typ: Ortstyp.gastronomie,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
      position: ErlebnisPosition(
        id: '98000000-0000-4000-8000-000000000013',
        erlebnisId: erlebnis.id,
        produktId: produkt.id,
        anzahl: 2,
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
      preis: Preisbeobachtung(
        id: '98000000-0000-4000-8000-000000000014',
        erlebnisId: erlebnis.id,
        erlebnisPositionId: '98000000-0000-4000-8000-000000000013',
        produktId: produkt.id,
        beobachtetAm: zeit,
        betrag: const Geldbetrag(minorEinheiten: 399),
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
      bewertungen: [
        for (final daten in [('Gesamturteil', 4.0), ('Aroma', 5.0)])
          Bewertung(
            id: 'bewertung-${daten.$1}',
            erlebnisId: erlebnis.id,
            erlebnisPositionId:
                '98000000-0000-4000-8000-000000000013',
            kriteriumId: 'kriterium-${daten.$1}',
            kriteriumName: daten.$1,
            kriteriumVersion: 2,
            herkunftProfilId: 'importiert',
            wert: daten.$2,
            erstelltAm: zeit,
            geaendertAm: zeit,
          ),
      ],
      herkunftProfilId: 'importiert',
      notiz: 'Historische Notiz',
    );
    final repository = _VerlaufRepository(datenbank, [eintrag]);

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: BewertungsverlaufScreen.fuerProdukt(
          repository: repository,
          produkt: produkt,
          eigenesProfilId: 'eigen',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gesamtwertung: 4 / 5'), findsOneWidget);
    expect(find.textContaining('3,99 EUR'), findsOneWidget);
    expect(find.textContaining('2 ×'), findsOneWidget);
    expect(find.textContaining('Importierte Bewertung'), findsOneWidget);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(find.text('Aroma'), findsOneWidget);
    expect(find.text('Notiz: Historische Notiz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zeigt einen verständlichen Ladefehler mit Wiederholung',
      (tester) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final zeit = DateTime.utc(2026, 8, 31);
    await tester.pumpWidget(MaterialApp(
      home: BewertungsverlaufScreen.fuerProdukt(
        repository: _LadefehlerRepository(datenbank),
        produkt: Produkt(
          id: '98000000-0000-4000-8000-000000000020',
          name: 'Fehlerprodukt',
          erstelltAm: zeit,
          geaendertAm: zeit,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('Der Bewertungsverlauf konnte nicht geladen werden.'),
      findsOneWidget,
    );
    expect(find.text('Verlauf erneut laden'), findsOneWidget);
  });
}

class _VerlaufRepository extends SqliteBewertungsRepository {
  _VerlaufRepository(super.datenbank, this.eintraege);

  final List<BewertungsverlaufEintrag> eintraege;

  @override
  Future<List<BewertungsverlaufEintrag>> ladeProduktverlauf(
    String produktId,
  ) async =>
      eintraege;
}

class _LadefehlerRepository extends SqliteBewertungsRepository {
  _LadefehlerRepository(super.datenbank);

  @override
  Future<List<BewertungsverlaufEintrag>> ladeProduktverlauf(
    String produktId,
  ) =>
      Future.error(StateError('Testfehler'));
}
