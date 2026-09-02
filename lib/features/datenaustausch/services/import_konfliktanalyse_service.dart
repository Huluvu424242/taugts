class ImportSammlungsAnalyse {
  const ImportSammlungsAnalyse({required this.name, required this.neu, required this.unveraendert, required this.geaendert});
  final String name;
  final int neu;
  final int unveraendert;
  final int geaendert;
  int get gesamt => neu + unveraendert + geaendert;
}

class FachlicheDublette {
  const FachlicheDublette({required this.sammlung, required this.importId, required this.lokaleId, required this.begruendung});
  final String sammlung;
  final String importId;
  final String lokaleId;
  final String begruendung;
}

class ImportKonfliktAnalyse {
  const ImportKonfliktAnalyse({required this.sammlungen, required this.fachlicheDubletten, required this.eigeneHerkunft, required this.fremdeHerkunft});
  final List<ImportSammlungsAnalyse> sammlungen;
  final List<FachlicheDublette> fachlicheDubletten;
  final int eigeneHerkunft;
  final int fremdeHerkunft;
}

class ImportKonfliktanalyseService {
  const ImportKonfliktanalyseService();

  static const _sichtbareSammlungen = <String, String>{
    'objekte': 'Objekte',
    'orte': 'Orte',
    'bewertungen': 'Bewertungen',
    'bewertungskriterien': 'Kriterien',
    'kategorien': 'Kategorien',
  };

  ImportKonfliktAnalyse analysiere({required Map<String, Object?> importDokument, required Map<String, Object?> lokalesDokument}) {
    final sammlungen = <ImportSammlungsAnalyse>[];
    for (final eintrag in _sichtbareSammlungen.entries) {
      final importWerte = _liste(importDokument, eintrag.key);
      final lokalNachId = {for (final wert in _liste(lokalesDokument, eintrag.key)) wert['id'] as String: wert};
      var neu = 0;
      var unveraendert = 0;
      var geaendert = 0;
      for (final wert in importWerte) {
        final lokal = lokalNachId[wert['id']];
        if (lokal == null) {
          neu++;
        } else if (_gleich(wert, lokal)) {
          unveraendert++;
        } else {
          geaendert++;
        }
      }
      sammlungen.add(ImportSammlungsAnalyse(name: eintrag.value, neu: neu, unveraendert: unveraendert, geaendert: geaendert));
    }

    final lokaleProfilIds = _liste(lokalesDokument, 'profile').map((e) => e['id']).whereType<String>().toSet();
    var eigeneHerkunft = 0;
    var fremdeHerkunft = 0;
    for (final erlebnis in _liste(importDokument, 'erlebnisse')) {
      if (lokaleProfilIds.contains(erlebnis['herkunftProfilId'])) {
        eigeneHerkunft++;
      } else {
        fremdeHerkunft++;
      }
    }

    return ImportKonfliktAnalyse(
      sammlungen: List.unmodifiable(sammlungen),
      fachlicheDubletten: List.unmodifiable(_findeFachlicheDubletten(importDokument, lokalesDokument)),
      eigeneHerkunft: eigeneHerkunft,
      fremdeHerkunft: fremdeHerkunft,
    );
  }

  List<FachlicheDublette> _findeFachlicheDubletten(Map<String, Object?> importDokument, Map<String, Object?> lokal) {
    final result = <FachlicheDublette>[];
    void pruefen(String sammlung, String Function(Map<String, Object?>) schluessel, String begruendung) {
      final lokale = _liste(lokal, sammlung);
      final lokalNachSchluessel = <String, Map<String, Object?>>{};
      for (final wert in lokale) {
        final key = schluessel(wert);
        if (key.isNotEmpty) lokalNachSchluessel.putIfAbsent(key, () => wert);
      }
      for (final wert in _liste(importDokument, sammlung)) {
        final key = schluessel(wert);
        final treffer = lokalNachSchluessel[key];
        if (key.isNotEmpty && treffer != null && treffer['id'] != wert['id']) {
          result.add(FachlicheDublette(sammlung: sammlung, importId: wert['id'] as String, lokaleId: treffer['id'] as String, begruendung: begruendung));
        }
      }
    }
    String norm(Object? wert) => (wert as String? ?? '').trim().toLowerCase();
    pruefen('objekte', (w) {
      final barcode = norm(w['barcode']);
      return barcode.isNotEmpty ? 'barcode:$barcode' : 'name:${norm(w['name'])}|art:${norm(w['produktart'])}';
    }, 'Gleicher Barcode oder gleicher Name und Produkttyp bei unterschiedlicher UUID.');
    pruefen('orte', (w) => '${norm(w['name'])}|${norm(w['adresse'])}|${norm(w['typ'])}', 'Gleicher Name, Ortstyp und gleiche Adresse bei unterschiedlicher UUID.');
    pruefen('bewertungskriterien', (w) => '${norm(w['name'])}|${norm(w['ziel'])}', 'Gleicher Kriterienname und gleicher Bewertungsbereich bei unterschiedlicher UUID.');
    pruefen('kategorien', (w) => norm(w['name']), 'Gleicher Kategoriename bei unterschiedlicher UUID.');
    return result;
  }

  List<Map<String, Object?>> _liste(Map<String, Object?> dokument, String name) =>
      ((dokument[name] as List?) ?? const []).whereType<Map>().map((e) => Map<String, Object?>.from(e)).toList();

  bool _gleich(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_gleich(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_gleich(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}
