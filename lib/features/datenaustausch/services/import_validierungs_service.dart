import 'dart:convert';

class ImportValidierungsGrenzen {
  const ImportValidierungsGrenzen({
    this.maxBytes = 10 * 1024 * 1024,
    this.maxTiefe = 40,
    this.maxKnoten = 250000,
    this.maxEintraegeProSammlung = 50000,
  });

  final int maxBytes;
  final int maxTiefe;
  final int maxKnoten;
  final int maxEintraegeProSammlung;
}

class ImportValidierungsFehler {
  const ImportValidierungsFehler({
    required this.code,
    required this.pfad,
    required this.nachricht,
  });

  final String code;
  final String pfad;
  final String nachricht;

  @override
  String toString() => '$pfad: $nachricht';
}

class ImportValidierungsErgebnis {
  const ImportValidierungsErgebnis({
    required this.fehler,
    this.dokument,
    this.urspruenglicheSchemaVersion,
    this.schemaVersion,
  });

  final List<ImportValidierungsFehler> fehler;
  final Map<String, Object?>? dokument;
  final int? urspruenglicheSchemaVersion;
  final int? schemaVersion;

  bool get istGueltig => fehler.isEmpty && dokument != null;
  bool get wurdeMigriert =>
      istGueltig &&
      urspruenglicheSchemaVersion != null &&
      urspruenglicheSchemaVersion != schemaVersion;
}

class ImportValidierungsService {
  const ImportValidierungsService({
    this.grenzen = const ImportValidierungsGrenzen(),
  });

  static const aktuelleSchemaVersion = 1;
  static const aeltesteUnterstuetzteSchemaVersion = 0;

  final ImportValidierungsGrenzen grenzen;

  ImportValidierungsErgebnis validiere(String inhalt) {
    final fehler = <ImportValidierungsFehler>[];
    if (utf8.encode(inhalt).length > grenzen.maxBytes) {
      return ImportValidierungsErgebnis(
        fehler: [
          ImportValidierungsFehler(
            code: 'datei_zu_gross',
            pfad: r'$',
            nachricht:
                'Die Importdatei überschreitet die erlaubte Größe von '
                '${grenzen.maxBytes} Bytes.',
          ),
        ],
      );
    }

    Object? dekodiert;
    try {
      dekodiert = jsonDecode(inhalt);
    } on FormatException {
      return const ImportValidierungsErgebnis(
        fehler: [
          ImportValidierungsFehler(
            code: 'ungueltiges_json',
            pfad: r'$',
            nachricht: 'Die Datei enthält kein gültiges JSON.',
          ),
        ],
      );
    }

    final strukturFehler = _pruefeStrukturgrenzen(dekodiert);
    if (strukturFehler != null) {
      return ImportValidierungsErgebnis(fehler: [strukturFehler]);
    }
    if (dekodiert is! Map) {
      return const ImportValidierungsErgebnis(
        fehler: [
          ImportValidierungsFehler(
            code: 'wurzel_ungueltig',
            pfad: r'$',
            nachricht: 'Die Importdatei muss ein JSON-Objekt enthalten.',
          ),
        ],
      );
    }

    final wurzel = <String, Object?>{};
    for (final eintrag in dekodiert.entries) {
      if (eintrag.key is! String) {
        fehler.add(
          const ImportValidierungsFehler(
            code: 'schluessel_ungueltig',
            pfad: r'$',
            nachricht: 'JSON-Objektschlüssel müssen Zeichenketten sein.',
          ),
        );
        continue;
      }
      wurzel[eintrag.key as String] = eintrag.value;
    }

    if (wurzel['format'] != 'taugts-export') {
      fehler.add(
        const ImportValidierungsFehler(
          code: 'format_ungueltig',
          pfad: r'$.format',
          nachricht: 'Die Datei ist kein Taugt’s?-Export.',
        ),
      );
    }

    final version = wurzel['schemaVersion'];
    if (version is! int) {
      fehler.add(
        const ImportValidierungsFehler(
          code: 'schema_version_ungueltig',
          pfad: r'$.schemaVersion',
          nachricht: 'Die Schemaversion fehlt oder ist keine Ganzzahl.',
        ),
      );
      return ImportValidierungsErgebnis(fehler: fehler);
    }
    if (version > aktuelleSchemaVersion) {
      fehler.add(
        ImportValidierungsFehler(
          code: 'schema_version_zu_neu',
          pfad: r'$.schemaVersion',
          nachricht:
              'Schemaversion $version wird von dieser App noch nicht '
              'unterstützt.',
        ),
      );
      return ImportValidierungsErgebnis(
        fehler: fehler,
        urspruenglicheSchemaVersion: version,
      );
    }
    if (version < aeltesteUnterstuetzteSchemaVersion) {
      fehler.add(
        ImportValidierungsFehler(
          code: 'schema_version_zu_alt',
          pfad: r'$.schemaVersion',
          nachricht: 'Schemaversion $version wird nicht mehr unterstützt.',
        ),
      );
      return ImportValidierungsErgebnis(
        fehler: fehler,
        urspruenglicheSchemaVersion: version,
      );
    }

    final migriert = _migriere(wurzel, version, fehler);
    if (migriert == null) {
      return ImportValidierungsErgebnis(
        fehler: fehler,
        urspruenglicheSchemaVersion: version,
      );
    }

    _validiereDokument(migriert, fehler);
    return ImportValidierungsErgebnis(
      fehler: List.unmodifiable(fehler),
      dokument: fehler.isEmpty ? Map.unmodifiable(migriert) : null,
      urspruenglicheSchemaVersion: version,
      schemaVersion: fehler.isEmpty ? aktuelleSchemaVersion : null,
    );
  }

  ImportValidierungsFehler? _pruefeStrukturgrenzen(Object? wurzel) {
    var knoten = 0;
    ImportValidierungsFehler? fehler;

    void besuchen(Object? wert, int tiefe, String pfad) {
      if (fehler != null) return;
      knoten++;
      if (knoten > grenzen.maxKnoten) {
        fehler = ImportValidierungsFehler(
          code: 'zu_viele_knoten',
          pfad: pfad,
          nachricht:
              'Die Importdatei enthält zu viele Werte. Erlaubt sind höchstens '
              '${grenzen.maxKnoten}.',
        );
        return;
      }
      if (tiefe > grenzen.maxTiefe) {
        fehler = ImportValidierungsFehler(
          code: 'zu_tief_verschachtelt',
          pfad: pfad,
          nachricht:
              'Die Importdatei ist tiefer als ${grenzen.maxTiefe} Ebenen '
              'verschachtelt.',
        );
        return;
      }
      if (wert is List) {
        for (var index = 0; index < wert.length; index++) {
          besuchen(wert[index], tiefe + 1, '$pfad[$index]');
        }
      } else if (wert is Map) {
        for (final eintrag in wert.entries) {
          besuchen(eintrag.value, tiefe + 1, '$pfad.${eintrag.key}');
        }
      }
    }

    besuchen(wurzel, 0, r'$');
    return fehler;
  }

  Map<String, Object?>? _migriere(
    Map<String, Object?> dokument,
    int version,
    List<ImportValidierungsFehler> fehler,
  ) {
    var aktuell = Map<String, Object?>.from(dokument);
    var aktuelleVersion = version;
    while (aktuelleVersion < aktuelleSchemaVersion) {
      switch (aktuelleVersion) {
        case 0:
          aktuell = _migriereV0NachV1(aktuell);
          aktuelleVersion = 1;
        default:
          if (aktuelleVersion < aktuelleSchemaVersion) {
            fehler.add(
              ImportValidierungsFehler(
                code: 'migration_fehlend',
                pfad: r'$.schemaVersion',
                nachricht:
                    'Für Schemaversion $aktuelleVersion ist keine sichere '
                    'Migration verfügbar.',
              ),
            );
            return null;
          }
      }
    }
    return aktuell;
  }

  Map<String, Object?> _migriereV0NachV1(Map<String, Object?> dokument) {
    final migriert = Map<String, Object?>.from(dokument);
    migriert['schemaVersion'] = 1;
    migriert.putIfAbsent('kategorien', () => <Object?>[]);
    migriert.putIfAbsent('kategorieZuordnungen', () => <Object?>[]);
    return migriert;
  }

  void _validiereDokument(
    Map<String, Object?> dokument,
    List<ImportValidierungsFehler> fehler,
  ) {
    _text(dokument, 'format', r'$.format', fehler, erforderlich: true);
    _ganzzahl(
      dokument,
      'schemaVersion',
      r'$.schemaVersion',
      fehler,
      erforderlich: true,
    );
    _utcZeit(dokument, 'exportiertAm', r'$.exportiertAm', fehler);
    _text(dokument, 'appVersion', r'$.appVersion', fehler, erforderlich: true);

    const sammlungen = [
      'profile',
      'objekte',
      'orte',
      'erlebnisse',
      'erlebnisPositionen',
      'preisbeobachtungen',
      'bewertungskriterien',
      'bewertungen',
      'ortsbewertungen',
      'kategorien',
      'kategorieZuordnungen',
    ];
    for (final name in sammlungen) {
      _sammlung(dokument, name, fehler);
    }
    if (fehler.isNotEmpty) return;

    final profile = _objektListe(dokument['profile']!);
    final objekte = _objektListe(dokument['objekte']!);
    final orte = _objektListe(dokument['orte']!);
    final erlebnisse = _objektListe(dokument['erlebnisse']!);
    final positionen = _objektListe(dokument['erlebnisPositionen']!);
    final preise = _objektListe(dokument['preisbeobachtungen']!);
    final kriterien = _objektListe(dokument['bewertungskriterien']!);
    final bewertungen = _objektListe(dokument['bewertungen']!);
    final ortsbewertungen = _objektListe(dokument['ortsbewertungen']!);
    final kategorien = _objektListe(dokument['kategorien']!);
    final zuordnungen = _objektListe(dokument['kategorieZuordnungen']!);

    _validiereProfile(profile, fehler);
    _validiereObjekte(objekte, fehler);
    _validiereOrte(orte, fehler);
    _validiereErlebnisse(erlebnisse, fehler);
    _validierePositionen(positionen, fehler);
    _validierePreise(preise, fehler);
    _validiereKriterien(kriterien, fehler);
    _validiereOrtsbewertungen(ortsbewertungen, fehler);
    _validiereBewertungen(bewertungen, fehler);
    _validiereKategorien(kategorien, zuordnungen, fehler);
    if (fehler.isNotEmpty) return;

    _validiereReferenzen(
      profile: profile,
      objekte: objekte,
      orte: orte,
      erlebnisse: erlebnisse,
      positionen: positionen,
      preise: preise,
      kriterien: kriterien,
      bewertungen: bewertungen,
      ortsbewertungen: ortsbewertungen,
      kategorien: kategorien,
      zuordnungen: zuordnungen,
      fehler: fehler,
    );
  }

  void _validiereProfile(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('profile', werte, fehler);
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.profile[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _optionalerText(wert, 'anzeigename', '$pfad.anzeigename', fehler);
      _zeitstempel(wert, pfad, fehler);
    }
  }

  void _validiereObjekte(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('objekte', werte, fehler);
    const arten = {'allgemein', 'produkt'};
    const produktarten = {'bier', 'getraenk', 'speise', 'sonstiges'};
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.objekte[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _text(wert, 'name', '$pfad.name', fehler, erforderlich: true);
      _enumWert(wert, 'art', arten, '$pfad.art', fehler);
      if (wert['art'] == 'produkt') {
        _enumWert(
          wert,
          'produktart',
          produktarten,
          '$pfad.produktart',
          fehler,
        );
      }
      _optionaleDezimalzahl(
        wert,
        'alkoholgehalt',
        '$pfad.alkoholgehalt',
        fehler,
      );
      _optionaleGanzzahl(
        wert,
        'fuellmengeMl',
        '$pfad.fuellmengeMl',
        fehler,
        minimum: 0,
      );
      _zeitstempel(wert, pfad, fehler);
    }
  }

  void _validiereOrte(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('orte', werte, fehler);
    const typen = {'gastronomie', 'geschaeft', 'privat', 'sonstiger'};
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.orte[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _text(wert, 'name', '$pfad.name', fehler, erforderlich: true);
      _enumWert(wert, 'typ', typen, '$pfad.typ', fehler);
      _optionaleDezimalzahl(wert, 'breitengrad', '$pfad.breitengrad', fehler);
      _optionaleDezimalzahl(wert, 'laengengrad', '$pfad.laengengrad', fehler);
      _zeitstempel(wert, pfad, fehler);
    }
  }

  void _validiereErlebnisse(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('erlebnisse', werte, fehler);
    const typen = {'restaurantbesuch', 'einkauf'};
    const statussen = {'geplant', 'aktiv', 'beendet'};
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.erlebnisse[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _uuid(wert, 'herkunftProfilId', '$pfad.herkunftProfilId', fehler);
      _optionaleUuid(wert, 'ortId', '$pfad.ortId', fehler);
      _enumWert(wert, 'typ', typen, '$pfad.typ', fehler);
      _enumWert(wert, 'status', statussen, '$pfad.status', fehler);
      _bool(wert, 'istEntwurf', '$pfad.istEntwurf', fehler);
      _optionalesDatum(wert, 'geplanterTag', '$pfad.geplanterTag', fehler);
      _optionaleGanzzahl(
        wert,
        'geplanteMinute',
        '$pfad.geplanteMinute',
        fehler,
        minimum: 0,
        maximum: 1439,
      );
      _optionaleGanzzahl(
        wert,
        'geplanteDauerMinuten',
        '$pfad.geplanteDauerMinuten',
        fehler,
        minimum: 1,
      );
      _optionaleUtcZeit(
        wert,
        'tatsaechlicherBeginn',
        '$pfad.tatsaechlicherBeginn',
        fehler,
      );
      _optionaleUtcZeit(
        wert,
        'tatsaechlichesEnde',
        '$pfad.tatsaechlichesEnde',
        fehler,
      );
      _zeitstempel(wert, pfad, fehler);

      if (wert['geplanteMinute'] != null && wert['geplanterTag'] == null) {
        _fehler(
          fehler,
          'zeitkombination_ungueltig',
          '$pfad.geplanteMinute',
          'Eine geplante Uhrzeit benötigt einen geplanten Tag.',
        );
      }
      final beginn = _parseUtc(wert['tatsaechlicherBeginn']);
      final ende = _parseUtc(wert['tatsaechlichesEnde']);
      if (ende != null && beginn == null) {
        _fehler(
          fehler,
          'zeitkombination_ungueltig',
          '$pfad.tatsaechlichesEnde',
          'Ein tatsächliches Ende benötigt einen Beginn.',
        );
      }
      if (beginn != null && ende != null && ende.isBefore(beginn)) {
        _fehler(
          fehler,
          'zeitreihenfolge_ungueltig',
          '$pfad.tatsaechlichesEnde',
          'Das tatsächliche Ende darf nicht vor dem Beginn liegen.',
        );
      }
      if (wert['status'] == 'aktiv' && beginn == null) {
        _fehler(
          fehler,
          'status_ungueltig',
          '$pfad.status',
          'Ein aktives Erlebnis benötigt einen tatsächlichen Beginn.',
        );
      }
      if (wert['status'] == 'beendet' && (beginn == null || ende == null)) {
        _fehler(
          fehler,
          'status_ungueltig',
          '$pfad.status',
          'Ein beendetes Erlebnis benötigt tatsächlichen Beginn und Ende.',
        );
      }
    }
  }

  void _validierePositionen(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('erlebnisPositionen', werte, fehler);
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.erlebnisPositionen[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _uuid(wert, 'erlebnisId', '$pfad.erlebnisId', fehler);
      _uuid(wert, 'produktId', '$pfad.produktId', fehler);
      _ganzzahl(
        wert,
        'anzahl',
        '$pfad.anzahl',
        fehler,
        erforderlich: true,
        minimum: 1,
      );
      _zeitstempel(wert, pfad, fehler);
    }
  }

  void _validierePreise(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('preisbeobachtungen', werte, fehler);
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.preisbeobachtungen[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _uuid(wert, 'erlebnisId', '$pfad.erlebnisId', fehler);
      _uuid(wert, 'erlebnisPositionId', '$pfad.erlebnisPositionId', fehler);
      _uuid(wert, 'produktId', '$pfad.produktId', fehler);
      _optionaleUuid(wert, 'ortId', '$pfad.ortId', fehler);
      _ganzzahl(
        wert,
        'betragMinor',
        '$pfad.betragMinor',
        fehler,
        erforderlich: true,
        minimum: 0,
      );
      _waehrung(wert, 'waehrung', '$pfad.waehrung', fehler);
      _utcZeit(wert, 'beobachtetAm', '$pfad.beobachtetAm', fehler);
      _zeitstempel(wert, pfad, fehler);
    }
  }

  void _validiereKriterien(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('bewertungskriterien', werte, fehler);
    const eingabetypen = {
      'wertung',
      'intensitaet',
      'jaNein',
      'zahl',
      'auswahl',
      'freitext',
    };
    const objektarten = {
      'getraenk',
      'speise',
      'sonstigesProdukt',
      'gastronomie',
      'geschaeft',
    };
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.bewertungskriterien[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _text(wert, 'name', '$pfad.name', fehler, erforderlich: true);
      _enumWert(
        wert,
        'eingabetyp',
        eingabetypen,
        '$pfad.eingabetyp',
        fehler,
      );
      _enumWert(
        wert,
        'objektart',
        objektarten,
        '$pfad.objektart',
        fehler,
      );
      _ganzzahl(
        wert,
        'reihenfolge',
        '$pfad.reihenfolge',
        fehler,
        erforderlich: true,
      );
      _ganzzahl(
        wert,
        'version',
        '$pfad.version',
        fehler,
        erforderlich: true,
        minimum: 1,
      );
      _bool(wert, 'aktiv', '$pfad.aktiv', fehler);
      _textListe(wert, 'auswahlwerte', '$pfad.auswahlwerte', fehler);
      _zeitstempel(wert, pfad, fehler);
    }
  }

  void _validiereBewertungen(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('bewertungen', werte, fehler);
    const zielarten = {'produkt', 'ort'};
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.bewertungen[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _enumWert(wert, 'zielart', zielarten, '$pfad.zielart', fehler);
      _uuid(wert, 'objektId', '$pfad.objektId', fehler);
      _uuid(wert, 'erlebnisId', '$pfad.erlebnisId', fehler);
      _optionaleUuid(
        wert,
        'erlebnisPositionId',
        '$pfad.erlebnisPositionId',
        fehler,
      );
      _optionaleUuid(
        wert,
        'ortsbewertungId',
        '$pfad.ortsbewertungId',
        fehler,
      );
      _optionaleUuid(wert, 'ortId', '$pfad.ortId', fehler);
      _uuid(wert, 'herkunftProfilId', '$pfad.herkunftProfilId', fehler);
      _utcZeit(wert, 'bewertetAm', '$pfad.bewertetAm', fehler);
      _dezimalzahl(wert, 'wert', '$pfad.wert', fehler);
      _zeitstempel(wert, pfad, fehler);
      final snapshot = wert['kriterium'];
      if (snapshot is! Map) {
        _fehler(
          fehler,
          'kriterium_snapshot_ungueltig',
          '$pfad.kriterium',
          'Eine Bewertung benötigt einen vollständigen Kriterium-Snapshot.',
        );
        continue;
      }
      final map = Map<String, Object?>.from(snapshot);
      _uuid(map, 'id', '$pfad.kriterium.id', fehler);
      _text(
        map,
        'name',
        '$pfad.kriterium.name',
        fehler,
        erforderlich: true,
      );
      _text(
        map,
        'eingabetyp',
        '$pfad.kriterium.eingabetyp',
        fehler,
        erforderlich: true,
      );
      _ganzzahl(
        map,
        'reihenfolge',
        '$pfad.kriterium.reihenfolge',
        fehler,
        erforderlich: true,
      );
      _ganzzahl(
        map,
        'version',
        '$pfad.kriterium.version',
        fehler,
        erforderlich: true,
        minimum: 1,
      );
      _textListe(
        map,
        'auswahlwerte',
        '$pfad.kriterium.auswahlwerte',
        fehler,
      );
    }
  }

  void _validiereOrtsbewertungen(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('ortsbewertungen', werte, fehler);
    final erlebnisIds = <String>{};
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.ortsbewertungen[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _uuid(wert, 'erlebnisId', '$pfad.erlebnisId', fehler);
      _uuid(wert, 'ortId', '$pfad.ortId', fehler);
      _uuid(wert, 'herkunftProfilId', '$pfad.herkunftProfilId', fehler);
      _utcZeit(wert, 'bewertetAm', '$pfad.bewertetAm', fehler);
      _zeitstempel(wert, pfad, fehler);
      final erlebnisId = wert['erlebnisId'];
      if (erlebnisId is String && !erlebnisIds.add(erlebnisId)) {
        _fehler(
          fehler,
          'ortsbewertung_mehrfach',
          '$pfad.erlebnisId',
          'Ein Erlebnis darf nur eine Ortsbewertung besitzen.',
        );
      }
    }
  }

  void _validiereKategorien(
    List<Map<String, Object?>> kategorien,
    List<Map<String, Object?>> zuordnungen,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('kategorien', kategorien, fehler);
    const zielarten = {'objekt', 'ort'};
    for (var i = 0; i < kategorien.length; i++) {
      final wert = kategorien[i];
      final pfad = r'$.kategorien[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _text(wert, 'name', '$pfad.name', fehler, erforderlich: true);
      _enumWert(wert, 'zielart', zielarten, '$pfad.zielart', fehler);
      _optionaleUuid(
        wert,
        'elternKategorieId',
        '$pfad.elternKategorieId',
        fehler,
      );
      _zeitstempel(wert, pfad, fehler);
    }
    for (var i = 0; i < zuordnungen.length; i++) {
      final wert = zuordnungen[i];
      final pfad = r'$.kategorieZuordnungen[' '$i]';
      _uuid(wert, 'kategorieId', '$pfad.kategorieId', fehler);
      _uuid(wert, 'zielId', '$pfad.zielId', fehler);
    }
  }

  void _validiereReferenzen({
    required List<Map<String, Object?>> profile,
    required List<Map<String, Object?>> objekte,
    required List<Map<String, Object?>> orte,
    required List<Map<String, Object?>> erlebnisse,
    required List<Map<String, Object?>> positionen,
    required List<Map<String, Object?>> preise,
    required List<Map<String, Object?>> kriterien,
    required List<Map<String, Object?>> bewertungen,
    required List<Map<String, Object?>> ortsbewertungen,
    required List<Map<String, Object?>> kategorien,
    required List<Map<String, Object?>> zuordnungen,
    required List<ImportValidierungsFehler> fehler,
  }) {
    final profilIds = _ids(profile);
    final objektIds = _ids(objekte);
    final produktIds = objekte
        .where((wert) => wert['art'] == 'produkt')
        .map((wert) => wert['id'] as String)
        .toSet();
    final ortIds = _ids(orte);
    final erlebnisIds = _ids(erlebnisse);
    final positionsIds = _ids(positionen);
    final kriterienIds = _ids(kriterien);
    final ortsbewertungsIds = _ids(ortsbewertungen);
    final kategorieIds = _ids(kategorien);
    final positionNachId = {
      for (final wert in positionen) wert['id'] as String: wert,
    };
    final ortsbewertungNachId = {
      for (final wert in ortsbewertungen) wert['id'] as String: wert,
    };

    for (var i = 0; i < erlebnisse.length; i++) {
      final wert = erlebnisse[i];
      final pfad = r'$.erlebnisse[' '$i]';
      _referenz(
        wert['herkunftProfilId'],
        profilIds,
        '$pfad.herkunftProfilId',
        'Profil',
        fehler,
      );
      _optionaleReferenz(wert['ortId'], ortIds, '$pfad.ortId', 'Ort', fehler);
    }

    for (var i = 0; i < positionen.length; i++) {
      final wert = positionen[i];
      final pfad = r'$.erlebnisPositionen[' '$i]';
      _referenz(
        wert['erlebnisId'],
        erlebnisIds,
        '$pfad.erlebnisId',
        'Erlebnis',
        fehler,
      );
      _referenz(
        wert['produktId'],
        produktIds,
        '$pfad.produktId',
        'Produkt',
        fehler,
      );
    }

    for (var i = 0; i < preise.length; i++) {
      final wert = preise[i];
      final pfad = r'$.preisbeobachtungen[' '$i]';
      _referenz(
        wert['erlebnisId'],
        erlebnisIds,
        '$pfad.erlebnisId',
        'Erlebnis',
        fehler,
      );
      _referenz(
        wert['erlebnisPositionId'],
        positionsIds,
        '$pfad.erlebnisPositionId',
        'Erlebnisposition',
        fehler,
      );
      _referenz(
        wert['produktId'],
        produktIds,
        '$pfad.produktId',
        'Produkt',
        fehler,
      );
      _optionaleReferenz(wert['ortId'], ortIds, '$pfad.ortId', 'Ort', fehler);
      final position = positionNachId[wert['erlebnisPositionId']];
      if (position != null &&
          (position['erlebnisId'] != wert['erlebnisId'] ||
              position['produktId'] != wert['produktId'])) {
        _fehler(
          fehler,
          'preis_position_widerspruch',
          pfad,
          'Preisbeobachtung, Erlebnisposition, Erlebnis und Produkt passen '
              'nicht zusammen.',
        );
      }
    }

    for (var i = 0; i < ortsbewertungen.length; i++) {
      final wert = ortsbewertungen[i];
      final pfad = r'$.ortsbewertungen[' '$i]';
      _referenz(
        wert['erlebnisId'],
        erlebnisIds,
        '$pfad.erlebnisId',
        'Erlebnis',
        fehler,
      );
      _referenz(wert['ortId'], ortIds, '$pfad.ortId', 'Ort', fehler);
      _referenz(
        wert['herkunftProfilId'],
        profilIds,
        '$pfad.herkunftProfilId',
        'Profil',
        fehler,
      );
    }

    for (var i = 0; i < bewertungen.length; i++) {
      final wert = bewertungen[i];
      final pfad = r'$.bewertungen[' '$i]';
      _referenz(
        wert['erlebnisId'],
        erlebnisIds,
        '$pfad.erlebnisId',
        'Erlebnis',
        fehler,
      );
      _referenz(
        wert['herkunftProfilId'],
        profilIds,
        '$pfad.herkunftProfilId',
        'Profil',
        fehler,
      );
      final snapshot = Map<String, Object?>.from(wert['kriterium'] as Map);
      _referenz(
        snapshot['id'],
        kriterienIds,
        '$pfad.kriterium.id',
        'Bewertungskriterium',
        fehler,
      );
      final kriterium = kriterien.firstWhere(
        (eintrag) => eintrag['id'] == snapshot['id'],
        orElse: () => const <String, Object?>{},
      );
      if (kriterium.isNotEmpty &&
          kriterium['version'] is int &&
          snapshot['version'] is int &&
          (snapshot['version'] as int) > (kriterium['version'] as int)) {
        _fehler(
          fehler,
          'kriterium_version_ungueltig',
          '$pfad.kriterium.version',
          'Die historische Kriterienversion ist neuer als das zugehörige '
              'exportierte Kriterium.',
        );
      }

      if (wert['zielart'] == 'produkt') {
        _referenz(
          wert['objektId'],
          produktIds,
          '$pfad.objektId',
          'Produkt',
          fehler,
        );
        _referenz(
          wert['erlebnisPositionId'],
          positionsIds,
          '$pfad.erlebnisPositionId',
          'Erlebnisposition',
          fehler,
        );
        final position = positionNachId[wert['erlebnisPositionId']];
        if (position != null &&
            (position['erlebnisId'] != wert['erlebnisId'] ||
                position['produktId'] != wert['objektId'])) {
          _fehler(
            fehler,
            'bewertung_position_widerspruch',
            pfad,
            'Produktbewertung und Erlebnisposition passen nicht zusammen.',
          );
        }
      } else if (wert['zielart'] == 'ort') {
        _referenz(wert['objektId'], ortIds, '$pfad.objektId', 'Ort', fehler);
        _referenz(
          wert['ortsbewertungId'],
          ortsbewertungsIds,
          '$pfad.ortsbewertungId',
          'Ortsbewertung',
          fehler,
        );
        final ortsbewertung = ortsbewertungNachId[wert['ortsbewertungId']];
        if (ortsbewertung != null &&
            (ortsbewertung['erlebnisId'] != wert['erlebnisId'] ||
                ortsbewertung['ortId'] != wert['objektId'])) {
          _fehler(
            fehler,
            'ortsbewertung_widerspruch',
            pfad,
            'Ortsbewertung, Erlebnis und bewerteter Ort passen nicht '
                'zusammen.',
          );
        }
      }
      _optionaleReferenz(wert['ortId'], ortIds, '$pfad.ortId', 'Ort', fehler);
    }

    for (var i = 0; i < kategorien.length; i++) {
      final wert = kategorien[i];
      final pfad = r'$.kategorien[' '$i]';
      _optionaleReferenz(
        wert['elternKategorieId'],
        kategorieIds,
        '$pfad.elternKategorieId',
        'Kategorie',
        fehler,
      );
      if (wert['elternKategorieId'] == wert['id']) {
        _fehler(
          fehler,
          'kategorie_selbstreferenz',
          '$pfad.elternKategorieId',
          'Eine Kategorie darf nicht ihr eigener Elternknoten sein.',
        );
      }
    }

    final kategorieNachId = {
      for (final wert in kategorien) wert['id'] as String: wert,
    };
    for (var i = 0; i < zuordnungen.length; i++) {
      final wert = zuordnungen[i];
      final pfad = r'$.kategorieZuordnungen[' '$i]';
      _referenz(
        wert['kategorieId'],
        kategorieIds,
        '$pfad.kategorieId',
        'Kategorie',
        fehler,
      );
      final kategorie = kategorieNachId[wert['kategorieId']];
      if (kategorie != null) {
        final ziele = kategorie['zielart'] == 'ort' ? ortIds : objektIds;
        _referenz(wert['zielId'], ziele, '$pfad.zielId', 'Ziel', fehler);
      }
    }
  }

  void _sammlung(
    Map<String, Object?> dokument,
    String name,
    List<ImportValidierungsFehler> fehler,
  ) {
    final wert = dokument[name];
    if (wert is! List) {
      _fehler(
        fehler,
        'sammlung_ungueltig',
        r'$.' + name,
        'Die erforderliche Sammlung „$name“ fehlt oder ist kein Array.',
      );
      return;
    }
    if (wert.length > grenzen.maxEintraegeProSammlung) {
      _fehler(
        fehler,
        'sammlung_zu_gross',
        r'$.' + name,
        'Die Sammlung „$name“ enthält mehr als '
            '${grenzen.maxEintraegeProSammlung} Einträge.',
      );
      return;
    }
    for (var i = 0; i < wert.length; i++) {
      if (wert[i] is! Map) {
        _fehler(
          fehler,
          'datensatz_ungueltig',
          r'$.' + name + '[$i]',
          'Der Eintrag ist kein JSON-Objekt.',
        );
      }
    }
  }

  List<Map<String, Object?>> _objektListe(Object wert) => (wert as List)
      .map((eintrag) => Map<String, Object?>.from(eintrag as Map))
      .toList();

  Set<String> _ids(List<Map<String, Object?>> werte) =>
      werte.map((wert) => wert['id'] as String).toSet();

  void _eindeutigeIds(
    String sammlung,
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    final ids = <String>{};
    for (var i = 0; i < werte.length; i++) {
      final id = werte[i]['id'];
      if (id is String && !ids.add(id)) {
        _fehler(
          fehler,
          'id_mehrfach',
          r'$.' + sammlung + '[$i].id',
          'Die ID „$id“ kommt in derselben Sammlung mehrfach vor.',
        );
      }
    }
  }

  void _zeitstempel(
    Map<String, Object?> wert,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    _utcZeit(wert, 'erstelltAm', '$pfad.erstelltAm', fehler);
    _utcZeit(wert, 'geaendertAm', '$pfad.geaendertAm', fehler);
  }

  void _uuid(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    final id = wert[feld];
    if (id is! String || !_uuidRegExp.hasMatch(id)) {
      _fehler(
        fehler,
        'uuid_ungueltig',
        pfad,
        'Das Feld „$feld“ muss eine gültige UUID enthalten.',
      );
    }
  }

  void _optionaleUuid(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (wert[feld] == null) return;
    _uuid(wert, feld, pfad, fehler);
  }

  void _text(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler, {
    bool erforderlich = false,
  }) {
    final inhalt = wert[feld];
    if (inhalt is! String || (erforderlich && inhalt.isEmpty)) {
      _fehler(
        fehler,
        'text_ungueltig',
        pfad,
        'Das Feld „$feld“ muss eine${erforderlich ? ' nicht leere' : ''} '
            'Zeichenkette sein.',
      );
    }
  }

  void _optionalerText(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (wert[feld] != null && wert[feld] is! String) {
      _fehler(
        fehler,
        'text_ungueltig',
        pfad,
        'Das optionale Feld „$feld“ muss eine Zeichenkette oder null sein.',
      );
    }
  }

  void _enumWert(
    Map<String, Object?> wert,
    String feld,
    Set<String> erlaubt,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    final inhalt = wert[feld];
    if (inhalt is! String || !erlaubt.contains(inhalt)) {
      _fehler(
        fehler,
        'wert_unbekannt',
        pfad,
        'Das Feld „$feld“ enthält einen unbekannten Wert.',
      );
    }
  }

  void _bool(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (wert[feld] is! bool) {
      _fehler(
        fehler,
        'bool_ungueltig',
        pfad,
        'Das Feld „$feld“ muss true oder false sein.',
      );
    }
  }

  void _ganzzahl(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler, {
    required bool erforderlich,
    int? minimum,
    int? maximum,
  }) {
    final inhalt = wert[feld];
    if (inhalt == null && !erforderlich) return;
    if (inhalt is! int ||
        (minimum != null && inhalt < minimum) ||
        (maximum != null && inhalt > maximum)) {
      _fehler(
        fehler,
        'ganzzahl_ungueltig',
        pfad,
        'Das Feld „$feld“ enthält keine zulässige Ganzzahl.',
      );
    }
  }

  void _optionaleGanzzahl(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler, {
    int? minimum,
    int? maximum,
  }) =>
      _ganzzahl(
        wert,
        feld,
        pfad,
        fehler,
        erforderlich: false,
        minimum: minimum,
        maximum: maximum,
      );

  void _dezimalzahl(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    final inhalt = wert[feld];
    if (inhalt is! String || !_dezimalRegExp.hasMatch(inhalt)) {
      _fehler(
        fehler,
        'dezimalzahl_ungueltig',
        pfad,
        'Das Feld „$feld“ muss eine kanonische Dezimalzahl mit Punkt '
            'enthalten.',
      );
    }
  }

  void _optionaleDezimalzahl(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (wert[feld] == null) return;
    _dezimalzahl(wert, feld, pfad, fehler);
  }

  void _waehrung(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    final inhalt = wert[feld];
    if (inhalt is! String || !_waehrungRegExp.hasMatch(inhalt)) {
      _fehler(
        fehler,
        'waehrung_ungueltig',
        pfad,
        'Die Währung muss aus genau drei Großbuchstaben bestehen.',
      );
    }
  }

  void _utcZeit(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    final inhalt = wert[feld];
    if (_parseUtc(inhalt) == null) {
      _fehler(
        fehler,
        'zeitstempel_ungueltig',
        pfad,
        'Das Feld „$feld“ muss ein ISO-8601-UTC-Zeitstempel mit Z sein.',
      );
    }
  }

  void _optionaleUtcZeit(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (wert[feld] == null) return;
    _utcZeit(wert, feld, pfad, fehler);
  }

  DateTime? _parseUtc(Object? wert) {
    if (wert is! String || !wert.endsWith('Z')) return null;
    return DateTime.tryParse(wert)?.toUtc();
  }

  void _optionalesDatum(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    final inhalt = wert[feld];
    if (inhalt == null) return;
    if (inhalt is! String || !_datumRegExp.hasMatch(inhalt)) {
      _fehler(
        fehler,
        'datum_ungueltig',
        pfad,
        'Das Feld „$feld“ muss ein Datum im Format YYYY-MM-DD sein.',
      );
      return;
    }
    final teile = inhalt.split('-').map(int.parse).toList();
    final datum = DateTime.utc(teile[0], teile[1], teile[2]);
    if (datum.year != teile[0] ||
        datum.month != teile[1] ||
        datum.day != teile[2]) {
      _fehler(
        fehler,
        'datum_ungueltig',
        pfad,
        'Das Feld „$feld“ enthält kein gültiges Kalenderdatum.',
      );
    }
  }

  void _textListe(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    final inhalt = wert[feld];
    if (inhalt is! List || inhalt.any((element) => element is! String)) {
      _fehler(
        fehler,
        'liste_ungueltig',
        pfad,
        'Das Feld „$feld“ muss ein Array aus Zeichenketten sein.',
      );
    }
  }

  void _referenz(
    Object? id,
    Set<String> erlaubteIds,
    String pfad,
    String ziel,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (id is! String || !erlaubteIds.contains(id)) {
      _fehler(
        fehler,
        'referenz_ungueltig',
        pfad,
        'Die referenzierte $ziel-ID existiert im Import nicht.',
      );
    }
  }

  void _optionaleReferenz(
    Object? id,
    Set<String> erlaubteIds,
    String pfad,
    String ziel,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (id == null) return;
    _referenz(id, erlaubteIds, pfad, ziel, fehler);
  }

  void _fehler(
    List<ImportValidierungsFehler> fehler,
    String code,
    String pfad,
    String nachricht,
  ) {
    fehler.add(
      ImportValidierungsFehler(code: code, pfad: pfad, nachricht: nachricht),
    );
  }

  static final _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final _dezimalRegExp = RegExp(
    r'^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$',
  );
  static final _waehrungRegExp = RegExp(r'^[A-Z]{3}$');
  static final _datumRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
}
