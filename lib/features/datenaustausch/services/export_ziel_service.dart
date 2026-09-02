import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class ExportZielService {
  Future<String?> speichern({required String dateiname, required String inhalt});

  Future<void> teilen({required String dateiname, required String inhalt});
}

class SystemExportZielService implements ExportZielService {
  @override
  Future<String?> speichern({
    required String dateiname,
    required String inhalt,
  }) async {
    final ziel = await FilePicker.platform.saveFile(
      dialogTitle: 'Taugt’s?-Export speichern',
      fileName: dateiname,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (ziel == null) return null;
    await File(ziel).writeAsString(inhalt, flush: true);
    return ziel;
  }

  @override
  Future<void> teilen({
    required String dateiname,
    required String inhalt,
  }) async {
    final verzeichnis = await getTemporaryDirectory();
    final datei = File(p.join(verzeichnis.path, dateiname));
    await datei.writeAsString(inhalt, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(datei.path, mimeType: 'application/json')],
        text: 'Taugt’s?-Datensicherung',
      ),
    );
  }
}
