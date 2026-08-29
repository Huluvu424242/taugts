import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteBewertungsRepository repository;
  final zeit = DateTime.utc(2026, 8, 28, 20);
  const profilId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    datenbank.verbindung.execute(
      'INSERT INTO profile VALUES (?, NULL, ?, ?)',
      [profilId, zeit.toIso8601String(), zeit.toIso8601String()],
    );
    repository = SqliteBewertungsRepository(datenbank);
  });

  tearDown(() => datenbank.schliessen());

  test('speichert und lädt ein Produkt', () async {
    final produkt = Produkt(
      id: '2d30ae97-1a64-4bb5-a8fd-1df46be78d67',
      name: 'Testbier',
      marke: 'Testbrauerei',
      brauerei: 'Brauerei am Markt',
      sorte: 'Pils',
      alkoholgehalt: 4.9,
      herkunft: 'Sachsen',
      gebinde: 'Flasche',
      fuellmengeMl: 500,
      barcode: '1234567890123',
      notiz: 'Herb',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );

    await repository.speichereProdukt(produkt);

    final geladen = await repository.ladeProdukt(produkt.id);
    expect(geladen?.name, 'Testbier');
    expect(geladen?.marke, 'Testbrauerei');
    expect(geladen?.brauerei, 'Brauerei am Markt');
    expect(geladen?.sorte, 'Pils');
    expect(geladen?.alkoholgehalt, 4.9);
    expect(geladen?.fuellmengeMl, 500);
    expect(geladen?.barcode, '1234567890123');
    expect(geladen?.erstelltAm, zeit);
  });

  test('speichert ein minimales Produkt nur mit Barcode', () async {
    final produkt = Produkt(
      id: '55e34e0e-fb72-450d-9db7-20d42188d226',
      name: '',
      barcode: '987654321',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );

    await repository.speichereProdukt(produkt);

    final geladen = await repository.ladeProdukt(produkt.id);
    expect(geladen?.anzeigetitel, '987654321');
    expect(geladen?.istUnvollstaendig, isTrue);
  });

  test('weist ein Produkt ohne Minimalangabe zurück', () async {
    final produkt = Produkt(
      id: '55e34e0e-fb72-450d-9db7-20d42188d228',
      name: '  ',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );

    await expectLater(
      repository.speichereProdukt(produkt),
      throwsArgumentError,
    );
  });

  test('listet Produkte und erlaubt spätere Ergänzungen', () async {
    final produkt = Produkt(
      id: '55e34e0e-fb72-450d-9db7-20d42188d227',
      name: 'Später ergänzen',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);
    await repository.speichereProdukt(Produkt(
      id: produkt.id,
      name: produkt.name,
      marke: 'Ergänzte Marke',
      brauerei: 'Ergänzte Brauerei',
      sorte: 'Lager',
      erstelltAm: produkt.erstelltAm,
      geaendertAm: zeit.add(const Duration(minutes: 1)),
    ));

    final produkte = await repository.ladeProdukte();
    expect(produkte, hasLength(1));
    expect(produkte.single.marke, 'Ergänzte Marke');
    expect(produkte.single.erstelltAm, zeit);
    expect(produkte.single.istUnvollstaendig, isFalse);
  });

  test('sucht Produkte über ihre Stammdaten', () async {
    await repository.speichereProdukt(Produkt(
      id: '55e34e0e-fb72-450d-9db7-20d42188d235',
      name: 'Sonnenpils',
      marke: 'Erzgebirge',
      brauerei: 'Brauerei am Berg',
      sorte: 'Pils',
      barcode: '4012345678901',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));
    await repository.speichereProdukt(Produkt(
      id: '55e34e0e-fb72-450d-9db7-20d42188d236',
      name: 'Apfelschorle',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));

    expect(
      (await repository.ladeProdukte(suchtext: 'berg')).single.name,
      'Sonnenpils',
    );
    expect(
      (await repository.ladeProdukte(suchtext: '401234')).single.name,
      'Sonnenpils',
    );
    expect(await repository.ladeProdukte(suchtext: 'unbekannt'), isEmpty);
  });

  test('Produktänderungen lassen historische Erlebnisse bestehen', () async {
    const produktId = '55e34e0e-fb72-450d-9db7-20d42188d229';
    final produkt = Produkt(
      id: produktId,
      name: 'Alter Name',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);
    await repository.speichereErlebnis(Erlebnis(
      id: '65e34e0e-fb72-450d-9db7-20d42188d229',
      produktId: produktId,
      herkunftProfilId: profilId,
      erlebtAm: zeit,
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));

    await repository.speichereProdukt(Produkt(
      id: produkt.id,
      name: 'Neuer Name',
      erstelltAm: produkt.erstelltAm,
      geaendertAm: zeit.add(const Duration(minutes: 1)),
    ));

    final erlebnisse = datenbank.verbindung.select(
      'SELECT * FROM erlebnisse WHERE produkt_id = ?',
      [produktId],
    );
    expect(erlebnisse, hasLength(1));
    expect(erlebnisse.single['erlebt_am'], zeit.toIso8601String());
  });

  test('bewahrt mehrere Bewertungen mit Herkunftsprofil', () async {
    const produktId = '2d30ae97-1a64-4bb5-a8fd-1df46be78d67';
    const kriteriumId = '5ef4ace9-f038-40d4-a042-042eac68ca3f';
    await repository.speichereProdukt(Produkt(
      id: produktId,
      name: 'Testbier',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));
    await repository.speichereKriterium(Bewertungskriterium(
      id: kriteriumId,
      name: 'Geschmack',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));

    for (var index = 0; index < 2; index++) {
      final erlebnisId = '00000000-0000-4000-8000-00000000000$index';
      await repository.speichereErlebnis(Erlebnis(
        id: erlebnisId,
        produktId: produktId,
        herkunftProfilId: profilId,
        erlebtAm: zeit.add(Duration(days: index)),
        erstelltAm: zeit.add(Duration(days: index)),
        geaendertAm: zeit.add(Duration(days: index)),
      ));
      await repository.speichereBewertung(Bewertung(
        id: '10000000-0000-4000-8000-00000000000$index',
        erlebnisId: erlebnisId,
        kriteriumId: kriteriumId,
        herkunftProfilId: profilId,
        wert: 3.0 + index,
        erstelltAm: zeit.add(Duration(days: index)),
        geaendertAm: zeit.add(Duration(days: index)),
      ));
    }

    final bewertungen = await repository.ladeBewertungenFuerProdukt(produktId);
    expect(bewertungen.map((bewertung) => bewertung.wert), [3.0, 4.0]);
    expect(
      bewertungen.map((bewertung) => bewertung.herkunftProfilId).toSet(),
      {profilId},
    );
  });

  test('erzwingt Beziehungen zwischen Profil, Produkt und Erlebnis', () async {
    await expectLater(
      repository.speichereErlebnis(Erlebnis(
        id: '00000000-0000-4000-8000-000000000000',
        produktId: 'nicht-vorhanden',
        herkunftProfilId: profilId,
        erlebtAm: zeit,
        erstelltAm: zeit,
        geaendertAm: zeit,
      )),
      throwsA(isA<SqliteException>()),
    );
  });

  test('speichert, aktualisiert und verwirft einen Erlebnisentwurf', () async {
    const produktId = '2d30ae97-1a64-4bb5-a8fd-1df46be78d68';
    const erlebnisId = '3d30ae97-1a64-4bb5-a8fd-1df46be78d68';
    await repository.speichereProdukt(Produkt(
      id: produktId,
      name: 'Entwurfsbier',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));
    await repository.speichereErlebnis(Erlebnis(
      id: erlebnisId,
      produktId: produktId,
      herkunftProfilId: profilId,
      erlebtAm: zeit,
      erstelltAm: zeit,
      geaendertAm: zeit,
      preis: 4.9,
      menge: 0.5,
      gebinde: 'Glas',
      notiz: 'Später bewerten',
    ));

    var entwuerfe = await repository.ladeEntwuerfe();
    expect(entwuerfe, hasLength(1));
    expect(entwuerfe.single.preis, 4.9);
    expect(entwuerfe.single.notiz, 'Später bewerten');

    await repository.speichereErlebnis(Erlebnis(
      id: erlebnisId,
      produktId: produktId,
      herkunftProfilId: profilId,
      erlebtAm: zeit,
      erstelltAm: zeit,
      geaendertAm: zeit.add(const Duration(minutes: 1)),
      notiz: 'Fortgesetzt',
    ));
    entwuerfe = await repository.ladeEntwuerfe();
    expect(entwuerfe.single.notiz, 'Fortgesetzt');

    await repository.loescheErlebnis(erlebnisId);
    expect(await repository.ladeEntwuerfe(), isEmpty);
  });

  test('speichert, lädt und bearbeitet vollständige Ortsdaten', () async {
    final ort = Ort(
      id: '75e34e0e-fb72-450d-9db7-20d42188d229',
      name: 'Gasthaus am Markt',
      typ: Ortstyp.gastronomie,
      adresse: 'Markt 1, 09111 Chemnitz',
      breitengrad: 50.8323,
      laengengrad: 12.9253,
      osmReferenz: 'node/123456',
      notiz: 'Terrasse im Hof',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereOrt(ort);

    final geladen = await repository.ladeOrt(ort.id);
    expect(geladen?.name, ort.name);
    expect(geladen?.adresse, ort.adresse);
    expect(geladen?.breitengrad, 50.8323);
    expect(geladen?.osmReferenz, 'node/123456');

    await repository.speichereOrt(Ort(
      id: ort.id,
      name: 'Gasthaus am Neumarkt',
      typ: ort.typ,
      adresse: ort.adresse,
      erstelltAm: ort.erstelltAm,
      geaendertAm: zeit.add(const Duration(minutes: 1)),
    ));
    expect((await repository.ladeOrt(ort.id))?.name, 'Gasthaus am Neumarkt');
  });

  test('speichert einen privaten Ort ohne Adresse und Koordinaten', () async {
    final ort = Ort(
      id: '75e34e0e-fb72-450d-9db7-20d42188d230',
      name: 'Bei Freunden',
      typ: Ortstyp.privat,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );

    await repository.speichereOrt(ort);

    final geladen = await repository.ladeOrt(ort.id);
    expect(geladen?.typ, Ortstyp.privat);
    expect(geladen?.adresse, isNull);
    expect(geladen?.breitengrad, isNull);
  });

  test('sucht Orte lokal nach Name, Typ und Adresse', () async {
    for (final ort in [
      Ort(
        id: '75e34e0e-fb72-450d-9db7-20d42188d231',
        name: 'Brauhaus',
        typ: Ortstyp.gastronomie,
        adresse: 'Chemnitz Zentrum',
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
      Ort(
        id: '75e34e0e-fb72-450d-9db7-20d42188d232',
        name: 'Getränkemarkt',
        typ: Ortstyp.geschaeft,
        adresse: 'Leipzig',
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    ]) {
      await repository.speichereOrt(ort);
    }

    expect(
        (await repository.ladeOrte(suchtext: 'brau')).single.name, 'Brauhaus');
    expect(
      (await repository.ladeOrte(suchtext: 'geschaeft')).single.name,
      'Getränkemarkt',
    );
    expect((await repository.ladeOrte(suchtext: 'leipzig')).single.name,
        'Getränkemarkt');
  });

  test('findet mögliche Dubletten, ohne das Speichern zu verbieten', () async {
    final ersterOrt = Ort(
      id: '75e34e0e-fb72-450d-9db7-20d42188d233',
      name: 'Zum Anker',
      typ: Ortstyp.gastronomie,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereOrt(ersterOrt);

    final dubletten = await repository.findeAehnlicheOrte(
      name: '  ZUM ANKER ',
    );
    expect(dubletten.map((ort) => ort.id), contains(ersterOrt.id));

    final zweiterOrt = Ort(
      id: '75e34e0e-fb72-450d-9db7-20d42188d234',
      name: 'Zum Anker',
      typ: Ortstyp.gastronomie,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereOrt(zweiterOrt);
    expect(await repository.ladeOrte(), hasLength(2));
  });

  test('rollt einen fehlgeschlagenen atomaren Schreibvorgang zurück', () {
    expect(
      () => datenbank.transaktion(() {
        datenbank.verbindung.execute(
          "INSERT INTO objekte VALUES ('o1', 'Test', 'allgemein', 'x', 'x')",
        );
        throw StateError('simulierter Fehler');
      }),
      throwsStateError,
    );

    expect(
      datenbank.verbindung.select('SELECT * FROM objekte WHERE id = ?', ['o1']),
      isEmpty,
    );
  });
}
