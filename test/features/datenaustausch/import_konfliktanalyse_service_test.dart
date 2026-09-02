import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/datenaustausch/services/import_konfliktanalyse_service.dart';

void main() {
  const service = ImportKonfliktanalyseService();

  Map<String, Object?> dokument({
    List<Map<String, Object?>> profile = const [],
    List<Map<String, Object?>> objekte = const [],
    List<Map<String, Object?>> orte = const [],
    List<Map<String, Object?>> erlebnisse = const [],
    List<Map<String, Object?>> bewertungen = const [],
    List<Map<String, Object?>> kriterien = const [],
    List<Map<String, Object?>> kategorien = const [],
  }) => {
    'profile': profile,
    'objekte': objekte,
    'orte': orte,
    'erlebnisse': erlebnisse,
    'bewertungen': bewertungen,
    'bewertungskriterien': kriterien,
    'kategorien': kategorien,
  };

  test('zählt neue, unveränderte und geänderte Datensätze nach UUID', () {
    final lokal = dokument(objekte: [
      {'id': '1', 'name': 'A', 'produktart': 'bier'},
      {'id': '2', 'name': 'B', 'produktart': 'bier'},
    ]);
    final import = dokument(objekte: [
      {'id': '1', 'name': 'A', 'produktart': 'bier'},
      {'id': '2', 'name': 'B geändert', 'produktart': 'bier'},
      {'id': '3', 'name': 'C', 'produktart': 'bier'},
    ]);

    final analyse = service.analysiere(importDokument: import, lokalesDokument: lokal);
    final objekte = analyse.sammlungen.singleWhere((e) => e.name == 'Objekte');
    expect(objekte.neu, 1);
    expect(objekte.unveraendert, 1);
    expect(objekte.geaendert, 1);
  });

  test('zusätzliche Bewertung mit anderer UUID bleibt neuer Historieneintrag', () {
    final lokal = dokument(bewertungen: [
      {'id': 'bew-1', 'objektId': 'obj-1', 'erstelltAm': '2026-01-01T10:00:00Z'},
    ]);
    final import = dokument(bewertungen: [
      {'id': 'bew-2', 'objektId': 'obj-1', 'erstelltAm': '2026-01-01T10:00:00Z'},
    ]);

    final analyse = service.analysiere(importDokument: import, lokalesDokument: lokal);
    final bewertungen = analyse.sammlungen.singleWhere((e) => e.name == 'Bewertungen');
    expect(bewertungen.neu, 1);
    expect(bewertungen.geaendert, 0);
  });

  test('erkennt fachliche Produkt- und Ortsdubletten nachvollziehbar', () {
    final lokal = dokument(
      objekte: [{'id': 'lokal-produkt', 'name': 'Pils', 'barcode': '123', 'produktart': 'bier'}],
      orte: [{'id': 'lokal-ort', 'name': 'Zum Test', 'adresse': 'Markt 1', 'typ': 'gastronomie'}],
    );
    final import = dokument(
      objekte: [{'id': 'import-produkt', 'name': 'Anderer Name', 'barcode': '123', 'produktart': 'bier'}],
      orte: [{'id': 'import-ort', 'name': ' zum test ', 'adresse': 'MARKT 1', 'typ': 'gastronomie'}],
    );

    final analyse = service.analysiere(importDokument: import, lokalesDokument: lokal);
    expect(analyse.fachlicheDubletten, hasLength(2));
    expect(analyse.fachlicheDubletten.every((e) => e.begruendung.isNotEmpty), isTrue);
  });

  test('macht eigene und fremde Herkunft sichtbar', () {
    final lokal = dokument(profile: [{'id': 'eigen'}]);
    final import = dokument(erlebnisse: [
      {'id': '1', 'herkunftProfilId': 'eigen'},
      {'id': '2', 'herkunftProfilId': 'fremd'},
      {'id': '3', 'herkunftProfilId': 'fremd'},
    ]);

    final analyse = service.analysiere(importDokument: import, lokalesDokument: lokal);
    expect(analyse.eigeneHerkunft, 1);
    expect(analyse.fremdeHerkunft, 2);
  });
}
