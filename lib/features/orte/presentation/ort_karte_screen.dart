import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:taugts/core/support/app_support.dart';
import 'package:taugts/core/support/external_url_service.dart';
import 'package:taugts/features/orte/services/karten_provider.dart';

typedef KartenFlaecheBuilder = Widget Function(
  BuildContext context,
  LatLng position,
  ValueChanged<LatLng> positionGeaendert,
);

class OrtKarteScreen extends StatefulWidget {
  const OrtKarteScreen({
    this.ausgangsposition,
    this.provider = KartenProvider.openStreetMap,
    this.externalUrlGateway,
    this.kartenFlaecheBuilder,
    super.key,
  });

  final LatLng? ausgangsposition;
  final KartenProvider provider;
  final ExternalUrlGateway? externalUrlGateway;
  final KartenFlaecheBuilder? kartenFlaecheBuilder;

  @override
  State<OrtKarteScreen> createState() => _OrtKarteScreenState();
}

class _OrtKarteScreenState extends State<OrtKarteScreen> {
  late LatLng _position =
      widget.ausgangsposition ?? const LatLng(51.1634, 10.4477);

  Future<void> _attributionOeffnen() async {
    try {
      await (widget.externalUrlGateway ?? ExternalUrlService()).oeffnen(
        widget.provider.attributionUrl,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Die Informationen zu OpenStreetMap konnten nicht geöffnet werden.',
          ),
        ),
      );
    }
  }

  Widget _kartenFlaeche(BuildContext context) {
    final builder = widget.kartenFlaecheBuilder;
    if (builder != null) {
      return builder(
        context,
        _position,
        (position) => setState(() => _position = position),
      );
    }
    return FlutterMap(
      options: MapOptions(
        initialCenter: _position,
        initialZoom: widget.ausgangsposition == null ? 6 : 16,
        onTap: (_, punkt) => setState(() => _position = punkt),
      ),
      children: [
        TileLayer(
          urlTemplate: widget.provider.kachelUrl,
          userAgentPackageName: 'de.huluvu.taugts',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _position,
              width: 56,
              height: 56,
              child: Semantics(
                label: 'Ausgewählte Position',
                child: const Icon(Icons.location_pin, size: 48),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Ort auf Karte auswählen'),
          actions: const [
            AppSupportMenu(contextName: 'Ort auf OpenStreetMap auswählen'),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    'Ausgewählte Position: '
                    '${_position.latitude.toStringAsFixed(6)}, '
                    '${_position.longitude.toStringAsFixed(6)}. '
                    'Karte antippen, um den Marker zu verschieben.',
                  ),
                ),
              ),
              Expanded(child: _kartenFlaeche(context)),
              TextButton(
                onPressed: _attributionOeffnen,
                child: Text(widget.provider.attribution),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Abbrechen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(_position),
                        child: const Text('Position übernehmen'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
