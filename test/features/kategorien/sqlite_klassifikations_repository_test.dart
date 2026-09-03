import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/kategorien/services/sqlite_klassifikations_repository.dart';

void main() {
  late LokaleDatenbank datenbank;
  late SqliteKlassifikationsRepository repository;

  setUp(() {
    datenbank = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    repository = SqliteKlassifikationsRepository(datenbank);
  });

  tearDown(() => datenbank.schliessen());

  test('Tags werden normalisiert und bleiben von Merkmalen getrennt', () {
    repository.setzeTags('objekt-1', [' IPA ', 'ipa', 'sehr  bitter']);
    repository.setzeHerkunft('objekt-1', 'Deutschland');
    repository.setzeHersteller('objekt-1', 'Brauerei Beispiel');
    repository.setzeEigenschaft('objekt-1', 'Farbe', 'Bernstein');

    final klassifikation = repository.lade('objekt-1');

    expect(klassifikation.tags, {'IPA', 'sehr bitter'});
    expect(klassifikation.herkunft, 'Deutschland');
    expect(klassifikation.hersteller, 'Brauerei Beispiel');
    expect(klassifikation.eigenschaften, {'Farbe': 'Bernstein'});
  });

  test('Entfernen eines Tags entfernt keine anderen Klassifikationsdaten', () {
    repository.setzeTags('objekt-1', ['IPA', 'regional']);
    repository.setzeEigenschaft('objekt-1', 'Farbe', 'Hell');

    repository.entferneTag('objekt-1', ' ipa ');

    final klassifikation = repository.lade('objekt-1');
    expect(klassifikation.tags, {'regional'});
    expect(klassifikation.eigenschaften, {'Farbe': 'Hell'});
  });
}
