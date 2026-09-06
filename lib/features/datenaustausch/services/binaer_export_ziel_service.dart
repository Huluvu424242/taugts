import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

abstract interface class BinaerExportZielService {
  Future<String?> speichern({
    required String dateiname,
    required Uint8List inhalt,
    required String dateiendung,
  });
}

typedef BinaerExportSpeichernDialog = Future<String?> Function(
  String dateiname,
  Uint8List inhalt,
  String dateiendung,
);

class SystemBinaerExportZielService implements BinaerExportZielService {
  SystemBinaerExportZielService({
    BinaerExportSpeichernDialog? speichernDialog,
  }) : _speichernDialog = speichernDialog ?? _systemSpeichernDialog;

  final BinaerExportSpeichernDialog _speichernDialog;

  static Future<String?> _systemSpeichernDialog(
    String dateiname,
    Uint8List inhalt,
    String dateiendung,
  ) =>
      FilePicker.platform.saveFile(
        dialogTitle: 'Taugt’s?-Export speichern',
        fileName: dateiname,
        type: FileType.custom,
        allowedExtensions: [dateiendung],
        bytes: inhalt,
      );

  @override
  Future<String?> speichern({
    required String dateiname,
    required Uint8List inhalt,
    required String dateiendung,
  }) =>
      _speichernDialog(dateiname, inhalt, dateiendung);
}
