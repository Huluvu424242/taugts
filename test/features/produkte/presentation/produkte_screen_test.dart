import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/produkte/presentation/produkte_screen.dart';

class _FesterIdGenerator implements IdGenerator {
  @override
  String neueId() => '55e34e0e-fb72-450d-9db7-20d42188d238';
}

void main() {
  testWidgets('filtert Produkte und zeigt einen zugänglichen Leerzustand', (
    tester,
  ) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final repository = SqliteBewertungsRepository(datenbank);
    final zeit = DateTime.utc(2026, 8, 29);
    await repository.speichereProdukt(Produkt(
      id: '55e34e0e-fb72-450d-9db7-20d42188d239',
      name: 'Sonnenpils',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: ProdukteScreen(
          repository: repository,
          idGenerator: _FesterIdGenerator(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sonnenpils'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Apfelsaft');
    await tester.pumpAndSettle();

    expect(find.text('Keine passenden Produkte gefunden.'), findsOneWidget);
    expect(find.text('Produkt anlegen'), findsWidgets);
  });

  testWidgets('schlägt ein vorhandenes Scan-Produkt zur Auswahl vor',
      (tester) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final repository = SqliteBewertungsRepository(datenbank);
    final zeit = DateTime.utc(2026, 8, 31);
    final produkt = Produkt(
      id: '55e34e0e-fb72-450d-9db7-20d42188d240',
      name: 'Scan-Pils',
      barcode: '4012345678901',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);

    await tester.pumpWidget(MaterialApp(
      home: _ProduktauswahlTestStart(
        repository: repository,
        scanCode: '4012345678901',
      ),
    ));
    await tester.tap(find.text('Produktauswahl öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Barcode scannen'));
    await tester.pumpAndSettle();

    expect(find.text('Produkt gefunden'), findsOneWidget);
    expect(
      find.text(
        'Scan-Pils\nBarcode: 4012345678901\n\n'
        'Dieses vorhandene Produkt verwenden?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Produkt verwenden'));
    await tester.pumpAndSettle();
    expect(find.text('Ausgewählt: Scan-Pils'), findsOneWidget);
  });

  testWidgets('legt einen unbekannten Barcode als unvollständiges Produkt an',
      (tester) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final repository = SqliteBewertungsRepository(datenbank);

    await tester.pumpWidget(MaterialApp(
      home: _ProduktauswahlTestStart(
        repository: repository,
        scanCode: '9876543210128',
      ),
    ));
    await tester.tap(find.text('Produktauswahl öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Barcode scannen'));
    await tester.pumpAndSettle();

    final barcodeFeld = find.widgetWithText(TextFormField, 'EAN / Barcode');
    expect(
      tester.widget<TextFormField>(barcodeFeld).controller?.text,
      '9876543210128',
    );
    await tester.fling(
      find.byType(ListView).last,
      const Offset(0, -1000),
      2000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Produkt speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Ausgewählt: 9876543210128'), findsOneWidget);
    final gespeichert = await repository.ladeProduktMitBarcode('9876543210128');
    expect(gespeichert, isNotNull);
    expect(gespeichert!.istUnvollstaendig, isTrue);
  });

  testWidgets('Suchfehler blockiert die manuelle Produkterfassung nicht',
      (tester) async {
    final datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(datenbank.schliessen);
    final repository = _BarcodeFehlerRepository(datenbank);

    await tester.pumpWidget(MaterialApp(
      home: ProdukteScreen(
        repository: repository,
        idGenerator: _FesterIdGenerator(),
        barcodeScanStart: (_) async => '4012345678901',
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Barcode scannen'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Der Barcode konnte nicht gesucht werden. Die manuelle Eingabe bleibt verfügbar.',
      ),
      findsOneWidget,
    );
    expect(find.text('Produkt anlegen'), findsWidgets);
  });
}

class _BarcodeFehlerRepository extends SqliteBewertungsRepository {
  _BarcodeFehlerRepository(super.datenbank);

  @override
  Future<Produkt?> ladeProduktMitBarcode(String barcode) =>
      Future.error(StateError('Testfehler'));
}

class _ProduktauswahlTestStart extends StatefulWidget {
  const _ProduktauswahlTestStart({
    required this.repository,
    required this.scanCode,
  });

  final SqliteBewertungsRepository repository;
  final String scanCode;

  @override
  State<_ProduktauswahlTestStart> createState() =>
      _ProduktauswahlTestStartState();
}

class _ProduktauswahlTestStartState extends State<_ProduktauswahlTestStart> {
  Produkt? _produkt;

  Future<void> _oeffnen() async {
    final produkt = await Navigator.of(context).push<Produkt>(
      MaterialPageRoute(
        builder: (_) => ProdukteScreen(
          repository: widget.repository,
          idGenerator: _FesterIdGenerator(),
          zurAuswahl: true,
          barcodeScanStart: (_) async => widget.scanCode,
        ),
      ),
    );
    if (mounted) setState(() => _produkt = produkt);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: _produkt == null
              ? FilledButton(
                  onPressed: _oeffnen,
                  child: const Text('Produktauswahl öffnen'),
                )
              : Text('Ausgewählt: ${_produkt!.anzeigetitel}'),
        ),
      );
}
