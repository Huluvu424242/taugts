import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktentscheidung_service.dart';
import 'package:taugts/features/datenaustausch/services/import_strategie_service.dart';

class ImportErgebnisZaehler {
  const ImportErgebnisZaehler({
    this.hinzugefuegt = 0,
    this.aktualisiert = 0,
    this.uebersprungen = 0,
    this.zusammengefuehrt = 0,
    this.fehlerhaft = 0,
  });

  final int hinzugefuegt;
  final int aktualisiert;
  final int uebersprungen;
  final int zusammengefuehrt;
  final int fehlerhaft;

  ImportErgebnisZaehler plus({
    int hinzugefuegt = 0,
    int aktualisiert = 0,
    int uebersprungen = 0,
    int zusammengefuehrt = 0,
    int fehlerhaft = 0,
  }) => ImportErgebnisZaehler(
        hinzugefuegt: this.hinzugefuegt + hinzugefuegt,
        aktualisiert: this.aktualisiert + aktualisiert,
        uebersprungen: this.uebersprungen + uebersprungen,
        zusammengefuehrt: this.zusammengefuehrt + zusammengefuehrt,
        fehlerhaft: this.fehlerhaft + fehlerhaft,
      );
}

class ImportAusfuehrungsErgebnis {
  const ImportAusfuehrungsErgebnis(this.nachSammlung);
  final Map<String, ImportErgebnisZaehler> nachSammlung;

  ImportErgebnisZaehler get gesamt => nachSammlung.values.fold(
        const ImportErgebnisZaehler(),
        (summe, wert) => summe.plus(
          hinzugefuegt: wert.hinzugefuegt,
          aktualisiert: wert.aktualisiert,
          uebersprungen: wert.uebersprungen,
          zusammengefuehrt: wert.zusammengefuehrt,
          fehlerhaft: wert.fehlerhaft,
        ),
      );
}

class ImportAusfuehrungService {
  const ImportAusfuehrungService();

  static const _reihenfolge = <String>[
    'profile', 'objekte', 'orte', 'bewertungskriterien', 'erlebnisse',
    'erlebnisPositionen', 'preisbeobachtungen', 'ortsbewertungen', 'bewertungen',
  ];

  ImportAusfuehrungsErgebnis ausfuehren({
    required LokaleDatenbank datenbank,
    required Map<String, Object?> importDokument,
    required ImportStrategie strategie,
    ImportKonfliktEntscheidungsStand entscheidungen =
        const ImportKonfliktEntscheidungsStand(),
    Map<String, String> mergeAliase = const {},
  }) {
    final ergebnis = <String, ImportErgebnisZaehler>{};
    datenbank.transaktion(() {
      if (strategie == ImportStrategie.bestandErsetzen) {
        for (final tabelle in const [
          'bewertungen', 'ortsbewertungen', 'preisbeobachtungen',
          'erlebnispositionen', 'erlebnisse', 'produkte', 'objekte', 'orte',
        ]) {
          datenbank.verbindung.execute('DELETE FROM $tabelle');
        }
      }
      for (final sammlung in _reihenfolge) {
        var zaehler = const ImportErgebnisZaehler();
        for (final roh in (importDokument[sammlung] as List? ?? const [])) {
          final wert = Map<String, Object?>.from(roh as Map);
          final importId = wert['id'] as String?;
          if (importId == null) continue;
          final zielId = mergeAliase[importId] ?? importId;
          final aktion = _entscheidung(sammlung, importId, entscheidungen);
          if (aktion == ImportKonfliktAktion.ueberspringen ||
              aktion == ImportKonfliktAktion.lokaleVersion) {
            zaehler = zaehler.plus(uebersprungen: 1);
            continue;
          }
          if (aktion == ImportKonfliktAktion.zusammenfuehren &&
              mergeAliase.containsKey(importId)) {
            zaehler = zaehler.plus(zusammengefuehrt: 1);
            continue;
          }
          final existiert = _existiert(datenbank, sammlung, zielId);
          if (existiert && strategie == ImportStrategie.lokalBevorzugen &&
              aktion != ImportKonfliktAktion.importVersion) {
            zaehler = zaehler.plus(uebersprungen: 1);
            continue;
          }
          _schreibe(datenbank, sammlung, {...wert, 'id': zielId}, existiert);
          zaehler = existiert
              ? zaehler.plus(aktualisiert: 1)
              : zaehler.plus(hinzugefuegt: 1);
        }
        ergebnis[sammlung] = zaehler;
      }
    });
    return ImportAusfuehrungsErgebnis(Map.unmodifiable(ergebnis));
  }

  ImportKonfliktAktion? _entscheidung(
    String sammlung,
    String id,
    ImportKonfliktEntscheidungsStand stand,
  ) {
    for (final eintrag in stand.entscheidungen.entries) {
      final teile = eintrag.key.split('|');
      if (teile.length >= 2 && teile[0] == sammlung && teile[1] == id) {
        return eintrag.value;
      }
    }
    return null;
  }

  bool _existiert(LokaleDatenbank db, String sammlung, String id) {
    final tabelle = _tabelle(sammlung);
    if (tabelle == null) return false;
    return db.verbindung.select('SELECT 1 FROM $tabelle WHERE id = ?', [id]).isNotEmpty;
  }

  String? _tabelle(String sammlung) => switch (sammlung) {
        'profile' => 'profile', 'objekte' => 'objekte', 'orte' => 'orte',
        'bewertungskriterien' => 'kriterien', 'erlebnisse' => 'erlebnisse',
        'erlebnisPositionen' => 'erlebnispositionen',
        'preisbeobachtungen' => 'preisbeobachtungen',
        'ortsbewertungen' => 'ortsbewertungen', 'bewertungen' => 'bewertungen',
        _ => null,
      };

  void _schreibe(
    LokaleDatenbank db,
    String sammlung,
    Map<String, Object?> wert,
    bool existiert,
  ) {
    if (sammlung == 'objekte') {
      _upsert(db, 'objekte', _werte(wert, const {
        'id': 'id', 'name': 'name', 'art': 'art', 'erstelltAm': 'erstellt_am',
        'geaendertAm': 'geaendert_am',
      }), existiert);
      final produktExistiert = db.verbindung
          .select('SELECT 1 FROM produkte WHERE objekt_id = ?', [wert['id']]).isNotEmpty;
      _upsert(db, 'produkte', _werte(wert, const {
        'id': 'objekt_id', 'marke': 'marke', 'produktart': 'produktart',
        'brauerei': 'brauerei', 'sorte': 'sorte', 'alkoholgehalt': 'alkoholgehalt',
        'herkunft': 'herkunft', 'gebinde': 'gebinde', 'fuellmengeMl': 'fuellmenge_ml',
        'barcode': 'barcode', 'notiz': 'notiz',
      }), produktExistiert, idSpalte: 'objekt_id');
      return;
    }
    final mapping = _mapping(sammlung);
    final tabelle = _tabelle(sammlung);
    if (mapping == null || tabelle == null) return;
    _upsert(db, tabelle, _werte(wert, mapping), existiert);
  }

  Map<String, String>? _mapping(String sammlung) => switch (sammlung) {
    'profile' => const {'id':'id','anzeigename':'anzeigename','erstelltAm':'erstellt_am','geaendertAm':'geaendert_am'},
    'orte' => const {'id':'id','name':'name','typ':'typ','adresse':'adresse','breitengrad':'breitengrad','laengengrad':'laengengrad','osmReferenz':'osm_referenz','notiz':'notiz','erstelltAm':'erstellt_am','geaendertAm':'geaendert_am'},
    'erlebnisse' => const {'id':'id','herkunftProfilId':'herkunft_profil_id','typ':'typ','status':'status','ortId':'ort_id','geplanterTag':'geplanter_tag','geplanteMinute':'geplante_minute','geplanteDauerMinuten':'geplante_dauer_minuten','tatsaechlicherBeginn':'tatsaechlicher_beginn','tatsaechlichesEnde':'tatsaechliches_ende','notiz':'notiz','istEntwurf':'ist_entwurf','erstelltAm':'erstellt_am','geaendertAm':'geaendert_am'},
    'erlebnisPositionen' => const {'id':'id','erlebnisId':'erlebnis_id','produktId':'produkt_id','anzahl':'anzahl','erstelltAm':'erstellt_am','geaendertAm':'geaendert_am'},
    'preisbeobachtungen' => const {'id':'id','erlebnisId':'erlebnis_id','erlebnisPositionId':'erlebnis_position_id','produktId':'produkt_id','ortId':'ort_id','betragMinor':'betrag_minor','waehrung':'waehrung','beobachtetAm':'beobachtet_am','erstelltAm':'erstellt_am','geaendertAm':'geaendert_am'},
    'ortsbewertungen' => const {'id':'id','erlebnisId':'erlebnis_id','ortId':'ort_id','herkunftProfilId':'herkunft_profil_id','bewertetAm':'bewertet_am','notiz':'notiz','erstelltAm':'erstellt_am','geaendertAm':'geaendert_am'},
    'bewertungskriterien' => const {'id':'id','name':'name','beschreibung':'beschreibung','eingabetyp':'eingabetyp','reihenfolge':'reihenfolge','aktiv':'aktiv','produktart':'produktart','objektart':'objektart','version':'version','erstelltAm':'erstellt_am','geaendertAm':'geaendert_am'},
    'bewertungen' => const {'id':'id','erlebnisId':'erlebnis_id','erlebnisPositionId':'erlebnis_position_id','ortsbewertungId':'ortsbewertung_id','ortId':'ort_id','herkunftProfilId':'herkunft_profil_id','wert':'wert','erstelltAm':'erstellt_am','geaendertAm':'geaendert_am'},
    _ => null,
  };

  Map<String, Object?> _werte(Map<String, Object?> quelle, Map<String, String> mapping) {
    final ziel = <String, Object?>{};
    for (final eintrag in mapping.entries) {
      var wert = quelle[eintrag.key];
      if (wert is bool) wert = wert ? 1 : 0;
      ziel[eintrag.value] = wert;
    }
    if (quelle['kriterium'] case final Map kriterium) {
      ziel['kriterium_id'] = kriterium['id'];
      ziel['kriterium_name'] = kriterium['name'];
      ziel['kriterium_beschreibung'] = kriterium['beschreibung'];
      ziel['kriterium_eingabetyp'] = kriterium['eingabetyp'];
      ziel['kriterium_reihenfolge'] = kriterium['reihenfolge'];
      ziel['kriterium_version'] = kriterium['version'];
      ziel['kriterium_auswahlwerte'] = (kriterium['auswahlwerte'] as List? ?? const []).join('\n');
    }
    if (quelle['auswahlwerte'] is List) {
      ziel['auswahlwerte'] = (quelle['auswahlwerte'] as List).join('\n');
    }
    return ziel;
  }

  void _upsert(LokaleDatenbank db, String tabelle, Map<String, Object?> werte,
      bool existiert, {String idSpalte = 'id'}) {
    if (existiert) {
      final set = werte.keys.where((k) => k != idSpalte).map((k) => '$k = ?').join(', ');
      final params = [for (final e in werte.entries) if (e.key != idSpalte) e.value, werte[idSpalte]];
      db.verbindung.execute('UPDATE $tabelle SET $set WHERE $idSpalte = ?', params);
    } else {
      final spalten = werte.keys.join(', ');
      final platzhalter = List.filled(werte.length, '?').join(', ');
      db.verbindung.execute('INSERT INTO $tabelle ($spalten) VALUES ($platzhalter)', werte.values.toList());
    }
  }
}
