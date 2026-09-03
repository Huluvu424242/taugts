import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taugts/core/persistenz/aktuelles_datenbankschema.dart';
import 'package:taugts/features/bewertungen/services/lokale_datenbank.dart';

Future<LokaleDatenbank> oeffneLokaleDatenbank() async {
  final verzeichnis = await getApplicationSupportDirectory();
  final datenbank = LokaleDatenbank.oeffnen(
    sqlite3.open(p.join(verzeichnis.path, 'taugts.sqlite')),
  );
  AktuellesDatenbankschema.stelleFeatureTabellenBereit(datenbank.verbindung);
  return datenbank;
}
