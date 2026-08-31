import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:taugts/core/support/app_support.dart';

typedef BarcodeScannerBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> erkannt,
  VoidCallback fehlgeschlagen,
);

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({this.scannerBuilder, super.key});

  final BarcodeScannerBuilder? scannerBuilder;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _controller;
  String? _code;
  String? _fehler;

  @override
  void initState() {
    super.initState();
    if (widget.scannerBuilder == null) {
      _controller = MobileScannerController(
        formats: const [
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.upcA,
          BarcodeFormat.itf14,
        ],
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _erkannt(BarcodeCapture capture) {
    if (_code != null) return;
    String? code;
    for (final barcode in capture.barcodes) {
      final wert = barcode.rawValue?.trim();
      if (wert != null && wert.isNotEmpty) {
        code = wert;
        break;
      }
    }
    if (code != null) _codeErkannt(code);
  }

  void _codeErkannt(String wert) {
    final code = wert.trim();
    if (!_istGueltigeGtin(code) || _code != null || !mounted) return;
    setState(() {
      _code = code;
      _fehler = null;
    });
    _controller?.stop();
  }

  bool _istGueltigeGtin(String code) {
    if (!const {8, 12, 13, 14}.contains(code.length) ||
        !RegExp(r'^\d+$').hasMatch(code)) {
      return false;
    }
    final ziffern = code.split('').map(int.parse).toList();
    final pruefziffer = ziffern.removeLast();
    var summe = 0;
    for (var index = ziffern.length - 1, position = 0;
        index >= 0;
        index--, position++) {
      summe += ziffern[index] * (position.isEven ? 3 : 1);
    }
    return (10 - summe % 10) % 10 == pruefziffer;
  }

  void _kameraFehlgeschlagen() {
    if (!mounted || _fehler != null) return;
    setState(() => _fehler =
        'Die Kamera ist nicht verfügbar oder die Berechtigung wurde abgelehnt.');
  }

  Widget _scanner(BuildContext context) {
    final scannerBuilder = widget.scannerBuilder;
    if (scannerBuilder != null) {
      return scannerBuilder(context, _codeErkannt, _kameraFehlgeschlagen);
    }
    return MobileScanner(
      controller: _controller!,
      onDetect: _erkannt,
      errorBuilder: (context, error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _kameraFehlgeschlagen();
        });
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Barcode scannen'),
          actions: const [AppSupportMenu(contextName: 'Barcode scannen')],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Die Kamera wird nur für diesen Scan verwendet. Bilddaten '
                'werden lokal verarbeitet und weder gespeichert noch übertragen.',
              ),
              const SizedBox(height: 16),
              if (_code == null && _fehler == null)
                SizedBox(
                  height: 320,
                  child: Semantics(
                    label: 'Kamerabild zur lokalen Barcode-Erkennung',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _scanner(context),
                    ),
                  ),
                ),
              if (_fehler != null) ...[
                Semantics(liveRegion: true, child: Text(_fehler!)),
                const SizedBox(height: 16),
                const Text('Die manuelle Barcode-Eingabe bleibt verfügbar.'),
              ],
              if (_code != null) ...[
                Semantics(
                  liveRegion: true,
                  header: true,
                  child: const Text('Barcode erkannt'),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _code!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_code),
                  child: const Text('Barcode übernehmen'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _code = null);
                    _controller?.start();
                  },
                  child: const Text('Erneut scannen'),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen und manuell eingeben'),
              ),
            ],
          ),
        ),
      );
}
