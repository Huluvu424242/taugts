import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:taugts/core/support/external_url_service.dart';
import 'package:taugts/features/orte/presentation/ort_karte_screen.dart';

class _ExternalUrlGateway implements ExternalUrlGateway {
  String? geoeffneteUrl;

  @override
  Future<void> oeffnen(String url) async => geoeffneteUrl = url;
}

void main() {
  testWidgets('zeigt vorhandene Position und übernimmt eine Kartenauswahl', (
    tester,
  ) async {
    LatLng? uebernommen;
    final gateway = _ExternalUrlGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              uebernommen = await Navigator.of(context).push<LatLng>(
                MaterialPageRoute(
                  builder: (_) => OrtKarteScreen(
                    ausgangsposition: const LatLng(50.8323, 12.9253),
                    externalUrlGateway: gateway,
                    kartenFlaecheBuilder:
                        (context, position, positionGeaendert) => Center(
                      child: FilledButton(
                        onPressed: () =>
                            positionGeaendert(const LatLng(50.9, 13.1)),
                        child: Text(
                          'Testkarte ${position.latitude}, ${position.longitude}',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: const Text('Karte öffnen'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Karte öffnen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('50.832300, 12.925300'), findsOneWidget);
    expect(find.text('© OpenStreetMap-Mitwirkende'), findsOneWidget);

    await tester.tap(find.textContaining('Testkarte'));
    await tester.pumpAndSettle();
    expect(find.textContaining('50.900000, 13.100000'), findsOneWidget);

    await tester.tap(find.text('© OpenStreetMap-Mitwirkende'));
    await tester.pump();
    expect(gateway.geoeffneteUrl, 'https://www.openstreetmap.org/copyright');

    await tester.tap(find.text('Position übernehmen'));
    await tester.pumpAndSettle();
    expect(uebernommen?.latitude, 50.9);
    expect(uebernommen?.longitude, 13.1);
  });
}
