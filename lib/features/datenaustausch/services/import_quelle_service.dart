import 'dart:convert';

import 'package:file_picker/file_picker.dart';

abstract interface class ImportQuelleService {
  Future<String?> dateiAuswaehlen();
}

class SystemImportQuelleService implements ImportQuelleService {
  @override
  Future<String?> dateiAuswaehlen() async {
    final ergebnis = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (ergebnis == null) return null;
    final bytes = ergebnis.files.single.bytes;
    if (bytes == null) {
      throw StateError('Die ausgewählte Datei konnte nicht gelesen werden.');
    }
    return utf8.decode(bytes);
  }
}
