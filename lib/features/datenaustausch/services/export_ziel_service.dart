import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class ExportZielService {
  Future<String?> speichern(
      {required String dateiname, required String inhalt});

  Future<void> teilen({required String dateiname, required String inhalt});
}

typedef ExportSpeichernDialog = Future<String?> Function(
  String dateiname,
  Uint8List inhalt,
);

class SystemExportZielService implements ExportZielService {
  SystemExportZielService({ExportSpeichernDialog? speichernDialog})
      : _speichernDialog = speichernDialog ?? _systemSpeichernDialog;

  final ExportSpeichernDialog _speichernDialog;

  static Future<String?> _systemSpeichernDialog(
    String dateiname,
    Uint8List inhalt,
  ) {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Taugt’s?-Export speichern',
      fileName: dateiname,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: inhalt,
    );
  }

  @override
  Future<String?> speichern({
    required String dateiname,
    required String inhalt,
  }) {
    return _speichernDialog(
      dateiname,
      Uint8List.fromList(utf8.encode(inhalt)),
    );
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
