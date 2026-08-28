import 'package:taugts/core/ids/id_generator.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';
import 'package:taugts/features/profil/models/profil.dart';
import 'package:taugts/features/profil/services/profil_repository.dart';

class SqliteProfilRepository implements ProfilRepository {
  SqliteProfilRepository(
    this.datenbank, {
    required this.idGenerator,
    DateTime Function()? jetzt,
  }) : jetzt = jetzt ?? DateTime.now;

  final LokaleDatenbank datenbank;
  final IdGenerator idGenerator;
  final DateTime Function() jetzt;

  @override
  Future<Profil> ladeOderErstelleProfil() async {
    final zeilen = datenbank.verbindung.select(
      'SELECT * FROM profile ORDER BY erstellt_am LIMIT 1',
    );
    if (zeilen.isNotEmpty) {
      return _ausZeile(zeilen.single);
    }

    final zeitpunkt = jetzt().toUtc();
    final profil = Profil(
      id: idGenerator.neueId(),
      erstelltAm: zeitpunkt,
      geaendertAm: zeitpunkt,
    );
    await speichereProfil(profil);
    return profil;
  }

  @override
  Future<void> speichereProfil(Profil profil) async {
    final anzeigename = profil.anzeigename?.trim();
    datenbank.verbindung.execute(
      '''
        INSERT INTO profile VALUES (?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          anzeigename = excluded.anzeigename,
          geaendert_am = excluded.geaendert_am
      ''',
      [
        profil.id,
        anzeigename == null || anzeigename.isEmpty ? null : anzeigename,
        _zeit(profil.erstelltAm),
        _zeit(profil.geaendertAm),
      ],
    );
  }

  Profil _ausZeile(Map<String, Object?> zeile) => Profil(
        id: zeile['id']! as String,
        anzeigename: zeile['anzeigename'] as String?,
        erstelltAm: DateTime.parse(zeile['erstellt_am']! as String),
        geaendertAm: DateTime.parse(zeile['geaendert_am']! as String),
      );

  String _zeit(DateTime wert) => wert.toUtc().toIso8601String();
}
