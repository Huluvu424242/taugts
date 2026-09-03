import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/features/bewertungen/models/fachmodelle.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/bewertungen/services/sqlite_bewertungs_repository.dart';
import 'package:taugts/features/kategorien/models/kategorie.dart';
import 'package:taugts/features/kategorien/models/kriterienset.dart';
import 'package:taugts/features/kategorien/services/kriterienset_service.dart';
import 'package:taugts/features/kategorien/services/sqlite_kategorie_repository.dart';
import 'package:taugts/features/kategorien/services/sqlite_kriterienset_repository.dart';

void main() {
  test('Kindkategorie erbt und kann das Set erweitert oder ersetzen', () async {
    final db = LokaleDatenbank.oeffnen(sqlite3.openInMemory());
    addTearDown(db.schliessen);
    final kategorien = SqliteKategorieRepository(db);
    final sets = SqliteKriteriensetRepository(db);
    final bewertungen = SqliteBewertungsRepository(db);
    const kind = Kategorie(
      id: 'kind',
      name: 'IPA',
      bereich: KategorieBereich.produkt,
      elternId: '10000000-0000-4000-8000-000000000003',
    );
    kategorien.speichern(kind);
    final alle = await bewertungen.ladeAktiveKriterienFuerObjektart(
      KriteriumObjektart.getraenk,
    );
    sets.speichereRegel(const KategorieKriteriensetRegel(
      kategorieId: '10000000-0000-4000-8000-000000000003',
      fallbackObjektart: KriteriumObjektart.getraenk,
    ));
    sets.setzeZuordnungen(
      '10000000-0000-4000-8000-000000000003',
      [alle.first.id],
    );
    final service = KriteriensetService(
      kategorien: kategorien,
      kriteriensets: sets,
      bewertungen: bewertungen,
    );

    final geerbt = await service.ermittle(
      kategorieId: kind.id,
      fallbackObjektart: KriteriumObjektart.getraenk,
    );
    expect(geerbt.eintraege, isNotEmpty);
    expect(geerbt.eintraege.any((wert) => wert.geerbt), isTrue);

    sets.speichereRegel(const KategorieKriteriensetRegel(
      kategorieId: 'kind',
      fallbackObjektart: KriteriumObjektart.getraenk,
      modus: KriteriensetModus.ersetzen,
    ));
    sets.setzeZuordnungen('kind', [alle.last.id]);
    final ersetzt = await service.ermittle(
      kategorieId: kind.id,
      fallbackObjektart: KriteriumObjektart.getraenk,
    );
    expect(ersetzt.eintraege.map((wert) => wert.kriterium.id), [alle.last.id]);
    expect(ersetzt.eintraege.single.geerbt, isFalse);
  });
}
