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

  static const _sammlungsNamen = [
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

  final ImportValidierungsGrenzen grenzen;

  ImportValidierungsErgebnis validiere(String inhalt) {
    if (utf8.encode(inhalt).length > grenzen.maxBytes) {
      return _ungueltig(
        'datei_zu_gross',
        r'$',
        'Die Importdatei überschreitet die erlaubte Größe von '
            '${grenzen.maxBytes} Bytes.',
      );
    }

    Object? dekodiert;
    try {
      dekodiert = jsonDecode(inhalt);
    } on FormatException {
      return _ungueltig(
        'ungueltiges_json',
        r'$',
        'Die Datei enthält kein gültiges JSON.',
      );
    }

    final strukturFehler = _pruefeStrukturgrenzen(dekodiert);
    if (strukturFehler != null) {
      return ImportValidierungsErgebnis(fehler: [strukturFehler]);
    }
    if (dekodiert is! Map) {
      return _ungueltig(
        'wurzel_ungueltig',
        r'$',
        'Die Importdatei muss ein JSON-Objekt enthalten.',
      );
    }

    final dokument = _map(dekodiert);
    final fehler = <ImportValidierungsFehler>[];
    if (dokument['format'] != 'taugts-export') {
      _fehler(
        fehler,
        'format_ungueltig',
        r'$.format',
        'Die Datei ist kein Taugt’s?-Export.',
      );
    }

    final version = dokument['schemaVersion'];
    if (version is! int) {
      _fehler(
        fehler,
        'schema_version_ungueltig',
        r'$.schemaVersion',
        'Die Schemaversion fehlt oder ist keine Ganzzahl.',
      );
      return ImportValidierungsErgebnis(fehler: fehler);
    }
    if (version > aktuelleSchemaVersion) {
      return _versionsFehler(
        fehler,
        version,
        'schema_version_zu_neu',
        'Schemaversion $version wird von dieser App noch nicht unterstützt.',
      );
    }
    if (version < aeltesteUnterstuetzteSchemaVersion) {
      return _versionsFehler(
        fehler,
        version,
        'schema_version_zu_alt',
        'Schemaversion $version wird nicht mehr unterstützt.',
      );
    }

    final normalisiert = _migriere(dokument, version);
    _validiereSchema(normalisiert, fehler);
    if (fehler.isEmpty) {
      _validiereReferenzen(normalisiert, fehler);
    }

    return ImportValidierungsErgebnis(
      fehler: List.unmodifiable(fehler),
      dokument: fehler.isEmpty ? Map.unmodifiable(normalisiert) : null,
      urspruenglicheSchemaVersion: version,
      schemaVersion: fehler.isEmpty ? aktuelleSchemaVersion : null,
    );
  }

  ImportValidierungsErgebnis _versionsFehler(
    List<ImportValidierungsFehler> bisherigeFehler,
    int version,
    String code,
    String nachricht,
  ) {
    _fehler(bisherigeFehler, code, r'$.schemaVersion', nachricht);
    return ImportValidierungsErgebnis(
      fehler: List.unmodifiable(bisherigeFehler),
      urspruenglicheSchemaVersion: version,
    );
  }

  ImportValidierungsErgebnis _ungueltig(
    String code,
    String pfad,
    String nachricht,
  ) =>
      ImportValidierungsErgebnis(
        fehler: [
          ImportValidierungsFehler(
            code: code,
            pfad: pfad,
            nachricht: nachricht,
          ),
        ],
      );

  ImportValidierungsFehler? _pruefeStrukturgrenzen(Object? wurzel) {
    var knoten = 0;
    ImportValidierungsFehler? gefunden;

    void besuchen(Object? wert, int tiefe, String pfad) {
      if (gefunden != null) return;
      knoten++;
      if (knoten > grenzen.maxKnoten) {
        gefunden = ImportValidierungsFehler(
          code: 'zu_viele_knoten',
          pfad: pfad,
          nachricht: 'Die Importdatei enthält mehr als '
              '${grenzen.maxKnoten} JSON-Werte.',
        );
        return;
      }
      if (tiefe > grenzen.maxTiefe) {
        gefunden = ImportValidierungsFehler(
          code: 'zu_tief_verschachtelt',
          pfad: pfad,
          nachricht: 'Die Importdatei ist tiefer als '
              '${grenzen.maxTiefe} Ebenen verschachtelt.',
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
    return gefunden;
  }

  Map<String, Object?> _migriere(
    Map<String, Object?> dokument,
    int version,
  ) {
    final migriert = Map<String, Object?>.from(dokument);
    if (version == 0) {
      migriert['schemaVersion'] = 1;
      migriert.putIfAbsent('kategorien', () => <Object?>[]);
      migriert.putIfAbsent('kategorieZuordnungen', () => <Object?>[]);
    }
    return migriert;
  }

  void _validiereSchema(
    Map<String, Object?> dokument,
    List<ImportValidierungsFehler> fehler,
  ) {
    _text(dokument, 'format', r'$.format', fehler, nichtLeer: true);
    _ganzzahl(dokument, 'schemaVersion', r'$.schemaVersion', fehler);
    _utcZeit(dokument, 'exportiertAm', r'$.exportiertAm', fehler);
    _text(dokument, 'appVersion', r'$.appVersion', fehler, nichtLeer: true);

    for (final name in _sammlungsNamen) {
      final wert = dokument[name];
      if (wert is! List) {
        _fehler(
          fehler,
          'sammlung_ungueltig',
          r'$.' '$name',
          'Die erforderliche Sammlung „$name“ fehlt oder ist kein Array.',
        );
      } else if (wert.length > grenzen.maxEintraegeProSammlung) {
        _fehler(
          fehler,
          'sammlung_zu_gross',
          r'$.' '$name',
          'Die Sammlung „$name“ enthält mehr als '
              '${grenzen.maxEintraegeProSammlung} Einträge.',
        );
      } else if (wert.any((eintrag) => eintrag is! Map)) {
        _fehler(
          fehler,
          'datensatz_ungueltig',
          r'$.' '$name',
          'Die Sammlung „$name“ enthält einen Eintrag, der kein Objekt ist.',
        );
      }
    }
    if (fehler.isNotEmpty) return;

    _validiereProfile(_liste(dokument, 'profile'), fehler);
    _validiereObjekte(_liste(dokument, 'objekte'), fehler);
    _validiereOrte(_liste(dokument, 'orte'), fehler);
    _validiereErlebnisse(_liste(dokument, 'erlebnisse'), fehler);
    _validierePositionen(_liste(dokument, 'erlebnisPositionen'), fehler);
    _validierePreise(_liste(dokument, 'preisbeobachtungen'), fehler);
    _validiereKriterien(_liste(dokument, 'bewertungskriterien'), fehler);
    _validiereBewertungen(_liste(dokument, 'bewertungen'), fehler);
    _validiereOrtsbewertungen(_liste(dokument, 'ortsbewertungen'), fehler);
    _validiereKategorien(
      _liste(dokument, 'kategorien'),
      _liste(dokument, 'kategorieZuordnungen'),
      fehler,
    );
  }

  void _validiereProfile(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('profile', werte, fehler);
    for (var i = 0; i < werte.length; i++) {
      final pfad = r'$.profile[' '$i]';
      _uuid(werte[i], 'id', '$pfad.id', fehler);
      _optionalerText(werte[i], 'anzeigename', '$pfad.anzeigename', fehler);
      _zeitstempel(werte[i], pfad, fehler);
    }
  }

  void _validiereObjekte(
    List<Map<String, Object?>> werte,
    List<ImportValidierungsFehler> fehler,
  ) {
    _eindeutigeIds('objekte', werte, fehler);
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.objekte[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _text(wert, 'name', '$pfad.name', fehler);
      _enumWert(wert, 'art', {'allgemein', 'produkt'}, '$pfad.art', fehler);
      if (wert['art'] == 'produkt') {
        _enumWert(
          wert,
          'produktart',
          {'bier', 'getraenk', 'speise', 'sonstiges'},
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
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.orte[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _text(wert, 'name', '$pfad.name', fehler, nichtLeer: true);
      _enumWert(
        wert,
        'typ',
        {'gastronomie', 'geschaeft', 'privat', 'sonstiger'},
        '$pfad.typ',
        fehler,
      );
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
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.erlebnisse[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _uuid(wert, 'herkunftProfilId', '$pfad.herkunftProfilId', fehler);
      _optionaleUuid(wert, 'ortId', '$pfad.ortId', fehler);
      _enumWert(
        wert,
        'typ',
        {'restaurantbesuch', 'einkauf'},
        '$pfad.typ',
        fehler,
      );
      _enumWert(
        wert,
        'status',
        {'geplant', 'aktiv', 'beendet'},
        '$pfad.status',
        fehler,
      );
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
      _validiereErlebnisZeiten(wert, pfad, fehler);
    }
  }

  void _validiereErlebnisZeiten(
    Map<String, Object?> wert,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
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
      _ganzzahl(wert, 'anzahl', '$pfad.anzahl', fehler, minimum: 1);
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
      _text(wert, 'name', '$pfad.name', fehler, nichtLeer: true);
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
      _ganzzahl(wert, 'reihenfolge', '$pfad.reihenfolge', fehler);
      _ganzzahl(wert, 'version', '$pfad.version', fehler, minimum: 1);
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
    const eingabetypen = {
      'wertung',
      'intensitaet',
      'jaNein',
      'zahl',
      'auswahl',
      'freitext',
    };
    for (var i = 0; i < werte.length; i++) {
      final wert = werte[i];
      final pfad = r'$.bewertungen[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _enumWert(wert, 'zielart', {'produkt', 'ort'}, '$pfad.zielart', fehler);
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
      final kriterium = _map(snapshot);
      _uuid(kriterium, 'id', '$pfad.kriterium.id', fehler);
      _text(kriterium, 'name', '$pfad.kriterium.name', fehler, nichtLeer: true);
      _enumWert(
        kriterium,
        'eingabetyp',
        eingabetypen,
        '$pfad.kriterium.eingabetyp',
        fehler,
      );
      _ganzzahl(
        kriterium,
        'reihenfolge',
        '$pfad.kriterium.reihenfolge',
        fehler,
      );
      _ganzzahl(
        kriterium,
        'version',
        '$pfad.kriterium.version',
        fehler,
        minimum: 1,
      );
      _textListe(
        kriterium,
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
    for (var i = 0; i < kategorien.length; i++) {
      final wert = kategorien[i];
      final pfad = r'$.kategorien[' '$i]';
      _uuid(wert, 'id', '$pfad.id', fehler);
      _text(wert, 'name', '$pfad.name', fehler, nichtLeer: true);
      _enumWert(wert, 'zielart', {'objekt', 'ort'}, '$pfad.zielart', fehler);
      _optionaleUuid(
        wert,
        'elternKategorieId',
        '$pfad.elternKategorieId',
        fehler,
      );
      _zeitstempel(wert, pfad, fehler);
    }
    for (var i = 0; i < zuordnungen.length; i++) {
      final pfad = r'$.kategorieZuordnungen[' '$i]';
      _uuid(zuordnungen[i], 'kategorieId', '$pfad.kategorieId', fehler);
      _uuid(zuordnungen[i], 'zielId', '$pfad.zielId', fehler);
    }
  }

  void _validiereReferenzen(
    Map<String, Object?> dokument,
    List<ImportValidierungsFehler> fehler,
  ) {
    final profile = _liste(dokument, 'profile');
    final objekte = _liste(dokument, 'objekte');
    final orte = _liste(dokument, 'orte');
    final erlebnisse = _liste(dokument, 'erlebnisse');
    final positionen = _liste(dokument, 'erlebnisPositionen');
    final preise = _liste(dokument, 'preisbeobachtungen');
    final kriterien = _liste(dokument, 'bewertungskriterien');
    final bewertungen = _liste(dokument, 'bewertungen');
    final ortsbewertungen = _liste(dokument, 'ortsbewertungen');
    final kategorien = _liste(dokument, 'kategorien');
    final zuordnungen = _liste(dokument, 'kategorieZuordnungen');

    final profilIds = _ids(profile);
    final objektIds = _ids(objekte);
    final produktIds = objekte
        .where((wert) => wert['art'] == 'produkt')
        .map((wert) => wert['id'] as String)
        .toSet();
    final ortIds = _ids(orte);
    final erlebnisIds = _ids(erlebnisse);
    final positionsIds = _ids(positionen);
    final kriteriumIds = _ids(kriterien);
    final ortsbewertungsIds = _ids(ortsbewertungen);
    final kategorieIds = _ids(kategorien);
    final positionNachId = _nachId(positionen);
    final ortsbewertungNachId = _nachId(ortsbewertungen);
    final kriteriumNachId = _nachId(kriterien);
    final kategorieNachId = _nachId(kategorien);

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
          'Preisbeobachtung und Erlebnisposition passen nicht zusammen.',
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
      _validiereBewertungsReferenzen(
        bewertungen[i],
        i,
        profilIds,
        produktIds,
        ortIds,
        erlebnisIds,
        positionsIds,
        kriteriumIds,
        ortsbewertungsIds,
        positionNachId,
        kriteriumNachId,
        ortsbewertungNachId,
        fehler,
      );
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
        final zielIds = kategorie['zielart'] == 'ort' ? ortIds : objektIds;
        _referenz(wert['zielId'], zielIds, '$pfad.zielId', 'Ziel', fehler);
      }
    }
  }

  void _validiereBewertungsReferenzen(
    Map<String, Object?> wert,
    int index,
    Set<String> profilIds,
    Set<String> produktIds,
    Set<String> ortIds,
    Set<String> erlebnisIds,
    Set<String> positionsIds,
    Set<String> kriteriumIds,
    Set<String> ortsbewertungsIds,
    Map<Object?, Map<String, Object?>> positionNachId,
    Map<Object?, Map<String, Object?>> kriteriumNachId,
    Map<Object?, Map<String, Object?>> ortsbewertungNachId,
    List<ImportValidierungsFehler> fehler,
  ) {
    final pfad = r'$.bewertungen[' '$index]';
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
    _optionaleReferenz(wert['ortId'], ortIds, '$pfad.ortId', 'Ort', fehler);

    final snapshot = _map(wert['kriterium'] as Map);
    _referenz(
      snapshot['id'],
      kriteriumIds,
      '$pfad.kriterium.id',
      'Bewertungskriterium',
      fehler,
    );
    final aktivesKriterium = kriteriumNachId[snapshot['id']];
    if (aktivesKriterium != null &&
        snapshot['version'] is int &&
        aktivesKriterium['version'] is int &&
        (snapshot['version'] as int) > (aktivesKriterium['version'] as int)) {
      _fehler(
        fehler,
        'kriterium_version_ungueltig',
        '$pfad.kriterium.version',
        'Die historische Kriterienversion ist neuer als das exportierte '
            'Kriterium.',
      );
    }

    if (wert['zielart'] == 'produkt') {
      _referenz(
          wert['objektId'], produktIds, '$pfad.objektId', 'Produkt', fehler);
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
      return;
    }

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
        'Ortsbewertung, Erlebnis und bewerteter Ort passen nicht zusammen.',
      );
    }
  }

  List<Map<String, Object?>> _liste(
    Map<String, Object?> dokument,
    String name,
  ) =>
      (dokument[name] as List).map((wert) => _map(wert as Map)).toList();

  Map<String, Object?> _map(Map wert) =>
      wert.map((schluessel, inhalt) => MapEntry(schluessel as String, inhalt));

  Set<String> _ids(List<Map<String, Object?>> werte) =>
      werte.map((wert) => wert['id'] as String).toSet();

  Map<Object?, Map<String, Object?>> _nachId(
    List<Map<String, Object?>> werte,
  ) =>
      {for (final wert in werte) wert['id']: wert};

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
          r'$.' '$sammlung[$i].id',
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
    if (wert[feld] != null) _uuid(wert, feld, pfad, fehler);
  }

  void _text(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler, {
    bool nichtLeer = false,
  }) {
    final inhalt = wert[feld];
    if (inhalt is! String || (nichtLeer && inhalt.isEmpty)) {
      _fehler(
        fehler,
        'text_ungueltig',
        pfad,
        'Das Feld „$feld“ muss eine gültige Zeichenkette sein.',
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
    if (wert[feld] is! String || !erlaubt.contains(wert[feld])) {
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
    int? minimum,
    int? maximum,
  }) {
    final inhalt = wert[feld];
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
  }) {
    if (wert[feld] == null) return;
    _ganzzahl(
      wert,
      feld,
      pfad,
      fehler,
      minimum: minimum,
      maximum: maximum,
    );
  }

  void _dezimalzahl(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (wert[feld] is! String ||
        !_dezimalRegExp.hasMatch(wert[feld] as String)) {
      _fehler(
        fehler,
        'dezimalzahl_ungueltig',
        pfad,
        'Das Feld „$feld“ muss eine kanonische Dezimalzahl mit Punkt enthalten.',
      );
    }
  }

  void _optionaleDezimalzahl(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (wert[feld] != null) _dezimalzahl(wert, feld, pfad, fehler);
  }

  void _waehrung(
    Map<String, Object?> wert,
    String feld,
    String pfad,
    List<ImportValidierungsFehler> fehler,
  ) {
    if (wert[feld] is! String ||
        !_waehrungRegExp.hasMatch(wert[feld] as String)) {
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
    if (_parseUtc(wert[feld]) == null) {
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
    if (wert[feld] != null) _utcZeit(wert, feld, pfad, fehler);
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
    if (id != null) _referenz(id, erlaubteIds, pfad, ziel, fehler);
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
