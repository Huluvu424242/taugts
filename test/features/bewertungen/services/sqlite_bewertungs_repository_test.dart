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

  test('speichert einen geplanten Einkauf ohne Uhrzeit und Produkt', () async {
    final erlebnis = Erlebnis(
      id: '3d30ae97-1a64-4bb5-a8fd-1df46be78d69',
      typ: Erlebnistyp.einkauf,
      status: Erlebnisstatus.geplant,
      geplanterTag: DateTime.utc(2026, 9, 5),
      herkunftProfilId: profilId,
      istEntwurf: false,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );

    await repository.speichereErlebnis(erlebnis);

    final geladen = await repository.ladeErlebnis(erlebnis.id);
    expect(geladen?.typ, Erlebnistyp.einkauf);
    expect(geladen?.status, Erlebnisstatus.geplant);
    expect(geladen?.geplanterTag, DateTime.utc(2026, 9, 5));
    expect(geladen?.geplanteMinute, isNull);
    expect(geladen?.produktId, isNull);
  });

  test('validiert Statuszeiten vor dem atomaren Speichern', () async {
    final geplant = Erlebnis(
      id: '3d30ae97-1a64-4bb5-a8fd-1df46be78d70',
      herkunftProfilId: profilId,
      status: Erlebnisstatus.geplant,
      istEntwurf: false,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereErlebnis(geplant);

    await expectLater(
      repository.speichereErlebnis(
        geplant.kopiereMit(
          status: Erlebnisstatus.beendet,
          tatsaechlicherBeginn: zeit.add(const Duration(hours: 2)),
          tatsaechlichesEnde: zeit,
        ),
      ),
      throwsArgumentError,
    );

    final unveraendert = await repository.ladeErlebnis(geplant.id);
    expect(unveraendert?.status, Erlebnisstatus.geplant);
    expect(unveraendert?.tatsaechlicherBeginn, isNull);
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

  test('liefert aktive Getränkekriterien in definierter Reihenfolge', () async {
    final kriterien = await repository.ladeAktiveGetraenkekriterien();

    expect(
      kriterien.map((kriterium) => kriterium.name),
      [
        'Gesamturteil',
        'Geschmack',
        'Aroma',
        'Frische',
        'Preis-Leistung',
        'Bitterkeit',
        'Farbintensität',
      ],
    );
    expect(kriterien.every((kriterium) => kriterium.aktiv), isTrue);
    expect(
      kriterien.last.eingabetyp,
      KriteriumEingabetyp.intensitaet,
    );
  });

  test('speichert Korrektur und neue historische Bewertung getrennt', () async {
    const produktId = '80000000-0000-4000-8000-000000000001';
    final produkt = Produkt(
      id: produktId,
      name: 'Historisches Pils',
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereProdukt(produkt);

    final erstesErlebnis = Erlebnis(
      id: '80000000-0000-4000-8000-000000000002',
      produktId: produktId,
      herkunftProfilId: profilId,
      erlebtAm: zeit,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereErlebnis(erstesErlebnis);
    final ersteBewertung = Bewertung(
      id: '80000000-0000-4000-8000-000000000003',
      erlebnisId: erstesErlebnis.id,
      kriteriumId: StandardGetraenkekriterien.gesamturteilId,
      herkunftProfilId: profilId,
      wert: 3,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );

    await repository.speichereGetraenkebewertung(
      erlebnis: erstesErlebnis.kopiereMit(
        notiz: 'Erster Eindruck',
        istEntwurf: false,
        geaendertAm: zeit.add(const Duration(minutes: 1)),
      ),
      bewertungen: [ersteBewertung],
    );
    expect(await repository.ladeEntwuerfe(), isEmpty);

    await repository.speichereGetraenkebewertung(
      erlebnis: erstesErlebnis.kopiereMit(
        notiz: 'Korrigierter Eindruck',
        istEntwurf: false,
        geaendertAm: zeit.add(const Duration(minutes: 2)),
      ),
      bewertungen: [
        Bewertung(
          id: ersteBewertung.id,
          erlebnisId: erstesErlebnis.id,
          kriteriumId: ersteBewertung.kriteriumId,
          herkunftProfilId: profilId,
          wert: 4,
          erstelltAm: ersteBewertung.erstelltAm,
          geaendertAm: zeit.add(const Duration(minutes: 2)),
        ),
      ],
    );
    final korrigiert =
        await repository.ladeBewertungenFuerErlebnis(erstesErlebnis.id);
    expect(korrigiert, hasLength(1));
    expect(korrigiert.single.id, ersteBewertung.id);
    expect(korrigiert.single.wert, 4);

    final spaeter = zeit.add(const Duration(days: 365));
    final zweitesErlebnis = Erlebnis(
      id: '80000000-0000-4000-8000-000000000004',
      produktId: produktId,
      herkunftProfilId: profilId,
      erlebtAm: spaeter,
      erstelltAm: spaeter,
      geaendertAm: spaeter,
      istEntwurf: false,
    );
    await repository.speichereGetraenkebewertung(
      erlebnis: zweitesErlebnis,
      bewertungen: [
        Bewertung(
          id: '80000000-0000-4000-8000-000000000005',
          erlebnisId: zweitesErlebnis.id,
          kriteriumId: StandardGetraenkekriterien.gesamturteilId,
          herkunftProfilId: profilId,
          wert: 2,
          erstelltAm: spaeter,
          geaendertAm: spaeter,
        ),
      ],
    );

    final historie = await repository.ladeBewertungenFuerProdukt(produktId);
    expect(historie.map((bewertung) => bewertung.wert), [4, 2]);
    expect(
      historie.map((bewertung) => bewertung.erlebnisId).toSet(),
      {erstesErlebnis.id, zweitesErlebnis.id},
    );
  });

  test('rollt Erlebnis und Bewertungen gemeinsam zurück', () async {
    const produktId = '90000000-0000-4000-8000-000000000001';
    final erlebnis = Erlebnis(
      id: '90000000-0000-4000-8000-000000000002',
      produktId: produktId,
      herkunftProfilId: profilId,
      erlebtAm: zeit,
      erstelltAm: zeit,
      geaendertAm: zeit,
      notiz: 'Entwurf bleibt',
    );
    await repository.speichereProdukt(Produkt(
      id: produktId,
      name: 'Rollback-Pils',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));
    await repository.speichereErlebnis(erlebnis);

    await expectLater(
      repository.speichereGetraenkebewertung(
        erlebnis: erlebnis.kopiereMit(
          notiz: 'Darf nicht bleiben',
          istEntwurf: false,
        ),
        bewertungen: [
          Bewertung(
            id: '90000000-0000-4000-8000-000000000003',
            erlebnisId: erlebnis.id,
            kriteriumId: 'nicht-vorhanden',
            herkunftProfilId: profilId,
            wert: 5,
            erstelltAm: zeit,
            geaendertAm: zeit,
          ),
        ],
      ),
      throwsA(isA<SqliteException>()),
    );

    final zeile = datenbank.verbindung.select(
      'SELECT * FROM erlebnisse WHERE id = ?',
      [erlebnis.id],
    ).single;
    expect(zeile['ist_entwurf'], 1);
    expect(zeile['notiz'], 'Entwurf bleibt');
    expect(
      await repository.ladeBewertungenFuerErlebnis(erlebnis.id),
      isEmpty,
    );
  });

  test('speichert Position und Preis atomar und korrigierbar', () async {
    const produktId = '91000000-0000-4000-8000-000000000001';
    const erlebnisId = '91000000-0000-4000-8000-000000000002';
    const positionId = '91000000-0000-4000-8000-000000000003';
    await repository.speichereProdukt(Produkt(
      id: produktId,
      name: 'Marktprodukt',
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));
    await repository.speichereErlebnis(Erlebnis(
      id: erlebnisId,
      typ: Erlebnistyp.einkauf,
      herkunftProfilId: profilId,
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));
    final position = ErlebnisPosition(
      id: positionId,
      erlebnisId: erlebnisId,
      produktId: produktId,
      anzahl: 2,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await repository.speichereErlebnisposition(
      position: position,
      preis: Preisbeobachtung(
        id: '91000000-0000-4000-8000-000000000004',
        erlebnisId: erlebnisId,
        erlebnisPositionId: positionId,
        produktId: produktId,
        beobachtetAm: zeit,
        betrag: const Geldbetrag(minorEinheiten: 299),
        erstelltAm: zeit,
        geaendertAm: zeit,
      ),
    );
    await repository.speichereErlebnisposition(
      position: position.mitAnzahl(3, zeit.add(const Duration(minutes: 1))),
      preis: Preisbeobachtung(
        id: 'ignorierte-korrektur-id',
        erlebnisId: erlebnisId,
        erlebnisPositionId: positionId,
        produktId: produktId,
        beobachtetAm: zeit,
        betrag: const Geldbetrag(minorEinheiten: 349),
        erstelltAm: zeit,
        geaendertAm: zeit.add(const Duration(minutes: 1)),
      ),
    );

    final geladen = await repository.ladeErlebnispositionen(erlebnisId);
    expect(geladen.single.position.anzahl, 3);
    expect(geladen.single.preis?.betrag.minorEinheiten, 349);
    expect(
      (await repository.ladeLetztenPreis(
        produktId: produktId,
        waehrung: 'EUR',
      ))
          ?.betrag
          .minorEinheiten,
      349,
    );
    expect(
      datenbank.verbindung.select('SELECT * FROM preisbeobachtungen'),
      hasLength(1),
    );
  });

  test('verwirft Position und Preis gemeinsam bei einem Fehler', () async {
    final position = ErlebnisPosition(
      id: '92000000-0000-4000-8000-000000000001',
      erlebnisId: 'nicht-vorhanden',
      produktId: 'nicht-vorhanden',
      anzahl: 1,
      erstelltAm: zeit,
      geaendertAm: zeit,
    );
    await expectLater(
      repository.speichereErlebnisposition(position: position),
      throwsA(isA<SqliteException>()),
    );
    expect(
      datenbank.verbindung.select('SELECT * FROM erlebnispositionen'),
      isEmpty,
    );
  });

  test('parst Geldbeträge ohne Gleitkomma-Rundung', () {
    expect(
      Geldbetrag.ausEingabe('12,30', 'EUR')?.minorEinheiten,
      1230,
    );
    expect(Geldbetrag.ausEingabe('1.234', 'EUR'), isNull);
    expect(Geldbetrag.ausEingabe('-1', 'EUR'), isNull);
  });

  test('wählt Speise- und Fallbackkriterien anhand der Produktart', () async {
    final speise = await repository.ladeAktiveKriterienFuerProduktart(
      Produktart.speise,
    );
    final fallback = await repository.ladeAktiveKriterienFuerProduktart(
      Produktart.sonstiges,
    );

    expect(speise.map((kriterium) => kriterium.name), contains('Temperatur'));
    expect(speise.map((kriterium) => kriterium.name), isNot(contains('Aroma')));
    expect(fallback.map((kriterium) => kriterium.name), ['Gesamturteil']);
  });

  test('bewahrt Bewertungen je Erlebnisposition historisch getrennt', () async {
    const produktId = '93000000-0000-4000-8000-000000000001';
    await repository.speichereProdukt(Produkt(
      id: produktId,
      name: 'Pommes',
      produktart: Produktart.speise,
      erstelltAm: zeit,
      geaendertAm: zeit,
    ));
    for (var index = 0; index < 2; index++) {
      final erlebnis = Erlebnis(
        id: '93000000-0000-4000-8000-00000000001$index',
        herkunftProfilId: profilId,
        erstelltAm: zeit.add(Duration(days: index)),
        geaendertAm: zeit.add(Duration(days: index)),
      );
      final position = ErlebnisPosition(
        id: '93000000-0000-4000-8000-00000000002$index',
        erlebnisId: erlebnis.id,
        produktId: produktId,
        anzahl: 1,
        erstelltAm: erlebnis.erstelltAm,
        geaendertAm: erlebnis.geaendertAm,
      );
      await repository.speichereErlebnis(erlebnis);
      await repository.speichereErlebnisposition(position: position);
      await repository.speichereProduktbewertung(
        erlebnis: erlebnis,
        position: position,
        bewertungen: [
          Bewertung(
            id: '93000000-0000-4000-8000-00000000003$index',
            erlebnisId: erlebnis.id,
            erlebnisPositionId: position.id,
            kriteriumId: StandardSpeisekriterien.gesamturteilId,
            herkunftProfilId: profilId,
            wert: 3 + index,
            erstelltAm: erlebnis.erstelltAm,
            geaendertAm: erlebnis.geaendertAm,
          ),
        ],
      );
    }

    final historie = await repository.ladeBewertungenFuerProdukt(produktId);
    expect(historie.map((bewertung) => bewertung.wert), [3, 4]);
    expect(
      historie.map((bewertung) => bewertung.erlebnisPositionId).toSet(),
      hasLength(2),
    );
  });
}
