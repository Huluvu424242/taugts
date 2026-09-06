import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/datenaustausch/services/export_ziel_service.dart';

void main() {
  test('übergibt Dateiname und UTF-8-Inhalt an den Speicherdialog', () async {
    String? empfangenerDateiname;
    Uint8List? empfangenerInhalt;
    final service = SystemExportZielService(
      speichernDialog: (dateiname, inhalt) async {
        empfangenerDateiname = dateiname;
        empfangenerInhalt = inhalt;
        return '/ausgewaehlt/export.json';
      },
    );

    final ziel = await service.speichern(
      dateiname: 'taugts-export.json',
      inhalt: '{"name":"Taugt’s?","wert":"Größe"}',
    );

    expect(ziel, '/ausgewaehlt/export.json');
    expect(empfangenerDateiname, 'taugts-export.json');
    expect(
      utf8.decode(empfangenerInhalt!),
      '{"name":"Taugt’s?","wert":"Größe"}',
    );
  });

  test('gibt einen Abbruch des Speicherdialogs unverändert zurück', () async {
    final service = SystemExportZielService(
      speichernDialog: (dateiname, inhalt) async => null,
    );

    final ziel = await service.speichern(
      dateiname: 'taugts-export.json',
      inhalt: '{}',
    );

    expect(ziel, isNull);
  });
}
