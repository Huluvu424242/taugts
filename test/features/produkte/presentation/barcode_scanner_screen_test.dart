import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taugts/features/produkte/presentation/barcode_scanner_screen.dart';

void main() {
  testWidgets('zeigt einen erkannten Code vor der bewussten Übernahme',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ScannerTestStart()));

    await tester.tap(find.text('Scan starten'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Bilddaten werden lokal verarbeitet'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ungültigen Code erkennen'));
    await tester.pumpAndSettle();
    expect(find.text('Barcode erkannt'), findsNothing);

    await tester.tap(find.text('EAN erkennen'));
    await tester.pumpAndSettle();
    expect(find.text('Barcode erkannt'), findsOneWidget);
    expect(find.text('4012345678901'), findsOneWidget);
    expect(find.text('Barcode übernehmen'), findsOneWidget);

    await tester.tap(find.text('Barcode übernehmen'));
    await tester.pumpAndSettle();
    expect(find.text('Übernommen: 4012345678901'), findsOneWidget);
  });

  testWidgets('Kameraausfall lässt die manuelle Erfassung erreichbar',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _ScannerTestStart(),
        ),
      ),
    );

    await tester.tap(find.text('Scan starten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kamera ablehnen'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Die Kamera ist nicht verfügbar oder die Berechtigung wurde abgelehnt.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Die manuelle Barcode-Eingabe bleibt verfügbar.'),
      findsOneWidget,
    );
    expect(find.text('Abbrechen und manuell eingeben'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ScannerTestStart extends StatefulWidget {
  const _ScannerTestStart();

  @override
  State<_ScannerTestStart> createState() => _ScannerTestStartState();
}

class _ScannerTestStartState extends State<_ScannerTestStart> {
  String? _code;

  Future<void> _starten() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(
          scannerBuilder: (context, erkannt, fehlgeschlagen) => Column(
            children: [
              FilledButton(
                onPressed: () => erkannt('4012345678901'),
                child: const Text('EAN erkennen'),
              ),
              FilledButton(
                onPressed: () => erkannt('12345'),
                child: const Text('Ungültigen Code erkennen'),
              ),
              FilledButton(
                onPressed: fehlgeschlagen,
                child: const Text('Kamera ablehnen'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() => _code = code);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: _code == null
              ? FilledButton(
                  onPressed: _starten,
                  child: const Text('Scan starten'),
                )
              : Text('Übernommen: $_code'),
        ),
      );
}
