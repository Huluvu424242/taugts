import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktentscheidung_service.dart';

/// Ergänzt den bestehenden transaktionalen Import um Klassifikationsdaten.
/// Aufruf ausschließlich innerhalb der Import-Transaktion.
class ImportKlassifikationService {
  const ImportKlassifikationService();

  static const tabellenFuerErsatz = <String>[
    'kategorie_kriterien',
    'kategorie_kriterienset_regeln',
    'produkt_kategorien',
    'ort_kategorien',
    'objekt_tags',
    'objekt_klassifikationsmerkmale',
    'kategorien',
  ];

  void ersetzenVorbereiten(LokaleDatenbank db) {
    for (final tabelle in tabellenFuerErsatz) {
      db.verbindung.execute('DELETE FROM $tabelle');
    }
  }

  void importieren({
    required LokaleDatenbank datenbank,
    required Map<String, Object?> dokument,
    required ImportStrategie strategie,
    required ImportKonfliktEntscheidungsStand entscheidungen,
  }) {
    final db = datenbank.verbindung;
    final bevorzugtLokal = strategie == ImportStrategie.lokalBevorzugen;
    final explizit = entscheidungen.entscheidungen;

    // Elternrelationen erst nach Anlage aller Kategorien setzen:
    // dadurch sind auch unsortierte hierarchische Exporte importierbar.
    final kategorien = _liste(dokument, 'kategorien');
    final vorhandeneKategorieIds = db
        .select('SELECT id FROM kategorien')
        .map((zeile) => zeile['id'] as String)
        .toSet();
    for (final kategorie in kategorien) {
      final auswahl = explizit['kategorien|${kategorie['id']}|${kategorie['id']}'];
      if (auswahl == ImportKonfliktAktion.ueberspringen ||
          auswahl == ImportKonfliktAktion.lokaleVersion) {
        continue;
      }
      _schreibe(
        datenbank,
        'kategorien',
        const ['id'],
        {
          'id': kategorie['id'],
          'name': kategorie['name'],
          'bereich': kategorie['zielart'] == 'ort' ? 'ort' : 'produkt',
          'eltern_id': null,
          'ist_standard': kategorie['istStandard'] == true ? 1 : 0,
        },
        bevorzugtLokal: auswahl != ImportKonfliktAktion.importVersion &&
            bevorzugtLokal,
      );
    }
    for (final kategorie in kategorien) {
      final auswahl = explizit['kategorien|${kategorie['id']}|${kategorie['id']}'];
      if (auswahl == ImportKonfliktAktion.ueberspringen ||
          auswahl == ImportKonfliktAktion.lokaleVersion) {
        continue;
      }
      if (kategorie['elternKategorieId'] == null) continue;
      if (bevorzugtLokal &&
          auswahl != ImportKonfliktAktion.importVersion &&
          vorhandeneKategorieIds.contains(kategorie['id'])) {
        continue;
      }
      db.execute(
        'UPDATE kategorien SET eltern_id = ? WHERE id = ?',
        [kategorie['elternKategorieId'], kategorie['id']],
      );
    }
    for (final wert in _liste(dokument, 'kategorieZuordnungen')) {
      final kategorie = db.select(
        'SELECT bereich FROM kategorien WHERE id = ?',
        [wert['kategorieId']],
      );
      if (kategorie.isEmpty) {
        throw const FormatException('Kategoriezuordnung ohne Kategorie.');
      }
      final istOrt = kategorie.single['bereich'] == 'ort';
      _schreibe(
        datenbank,
        istOrt ? 'ort_kategorien' : 'produkt_kategorien',
        istOrt
            ? const ['ort_id', 'kategorie_id']
            : const ['produkt_id', 'kategorie_id'],
        {
          istOrt ? 'ort_id' : 'produkt_id': wert['zielId'],
          'kategorie_id': wert['kategorieId'],
        },
        bevorzugtLokal: bevorzugtLokal,
      );
    }
    for (final wert in _liste(dokument, 'objektTags')) {
      final id = ImportKonfliktentscheidungService.identitaet(
        'objektTags', wert,
      );
      final auswahl = explizit['objektTags|$id|$id'];
      if (auswahl == ImportKonfliktAktion.ueberspringen ||
          auswahl == ImportKonfliktAktion.lokaleVersion) {
        continue;
      }
      _schreibe(
        datenbank,
        'objekt_tags',
        const ['objekt_id', 'normalisiert'],
        {
          'objekt_id': wert['objektId'],
          'normalisiert': wert['normalisiert'],
          'text': wert['text'],
        },
        bevorzugtLokal: auswahl != ImportKonfliktAktion.importVersion &&
            bevorzugtLokal,
      );
    }
    for (final wert in _liste(dokument, 'objektKlassifikationsmerkmale')) {
      final id = ImportKonfliktentscheidungService.identitaet(
        'objektKlassifikationsmerkmale', wert,
      );
      final auswahl = explizit['objektKlassifikationsmerkmale|$id|$id'];
      if (auswahl == ImportKonfliktAktion.ueberspringen ||
          auswahl == ImportKonfliktAktion.lokaleVersion) {
        continue;
      }
      _schreibe(
        datenbank,
        'objekt_klassifikationsmerkmale',
        const ['objekt_id', 'dimension', 'schluessel'],
        {
          'objekt_id': wert['objektId'],
          'dimension': wert['dimension'],
          'schluessel': wert['schluessel'],
          'wert': wert['wert'],
        },
        bevorzugtLokal: auswahl != ImportKonfliktAktion.importVersion &&
            bevorzugtLokal,
      );
    }
    for (final wert in _liste(dokument, 'kategorieKriteriensetRegeln')) {
      final id = ImportKonfliktentscheidungService.identitaet(
        'kategorieKriteriensetRegeln', wert,
      );
      final auswahl = explizit['kategorieKriteriensetRegeln|$id|$id'];
      if (auswahl == ImportKonfliktAktion.ueberspringen ||
          auswahl == ImportKonfliktAktion.lokaleVersion) {
        continue;
      }
      _schreibe(
        datenbank,
        'kategorie_kriterienset_regeln',
        const ['kategorie_id'],
        {
          'kategorie_id': wert['kategorieId'],
          'fallback_objektart': wert['fallbackObjektart'],
          'modus': wert['modus'],
          'version': wert['version'],
        },
        bevorzugtLokal: auswahl != ImportKonfliktAktion.importVersion &&
            bevorzugtLokal,
      );
    }
    for (final wert in _liste(dokument, 'kategorieKriterien')) {
      final id = ImportKonfliktentscheidungService.identitaet(
        'kategorieKriterien', wert,
      );
      final auswahl = explizit['kategorieKriterien|$id|$id'];
      if (auswahl == ImportKonfliktAktion.ueberspringen ||
          auswahl == ImportKonfliktAktion.lokaleVersion) {
        continue;
      }
      _schreibe(
        datenbank,
        'kategorie_kriterien',
        const ['kategorie_id', 'kriterium_id'],
        {
          'kategorie_id': wert['kategorieId'],
          'kriterium_id': wert['kriteriumId'],
          'reihenfolge': wert['reihenfolge'],
        },
        bevorzugtLokal: auswahl != ImportKonfliktAktion.importVersion &&
            bevorzugtLokal,
      );
    }
  }

  List<Map<String, Object?>> _liste(
    Map<String, Object?> dokument,
    String name,
  ) {
    final roh = dokument[name] ?? const <Object?>[];
    if (roh is! List) {
      throw FormatException('Sammlung $name ist kein Array.');
    }
    return [
      for (final wert in roh)
        if (wert is Map)
          Map<String, Object?>.from(wert)
        else
          throw FormatException('Ungültiger Eintrag in $name.'),
    ];
  }

  void _schreibe(
    LokaleDatenbank datenbank,
    String tabelle,
    List<String> schluessel,
    Map<String, Object?> werte, {
    required bool bevorzugtLokal,
  }) {
    final spalten = werte.keys.toList();
    final platzhalter = List.filled(spalten.length, '?').join(', ');
    final konflikt = schluessel.join(', ');
    final aktualisieren = spalten
        .where((spalte) => !schluessel.contains(spalte))
        .map((spalte) => '$spalte = excluded.$spalte')
        .join(', ');
    datenbank.verbindung.execute(
      'INSERT INTO $tabelle (${spalten.join(', ')}) '
      'VALUES ($platzhalter) ON CONFLICT($konflikt) '
      '${bevorzugtLokal || aktualisieren.isEmpty ? 'DO NOTHING' : 'DO UPDATE SET $aktualisieren'}',
      werte.values.toList(),
    );
  }
}
