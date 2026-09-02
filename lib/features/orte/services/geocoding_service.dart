import 'dart:convert';
import 'dart:io';

class Adressvorschlag {
  const Adressvorschlag({required this.name, required this.adresse});

  final String? name;
  final String adresse;
}

abstract interface class GeocodingService {
  Future<Adressvorschlag?> adresseVorschlagen({
    required double breitengrad,
    required double laengengrad,
  });
}

class GeocodingAusnahme implements Exception {
  const GeocodingAusnahme(this.nachricht);

  final String nachricht;

  @override
  String toString() => nachricht;
}

class NominatimGeocodingService implements GeocodingService {
  const NominatimGeocodingService();

  static const _host = 'nominatim.openstreetmap.org';

  @override
  Future<Adressvorschlag?> adresseVorschlagen({
    required double breitengrad,
    required double laengengrad,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.https(_host, '/reverse', {
        'format': 'jsonv2',
        'lat': breitengrad.toString(),
        'lon': laengengrad.toString(),
        'addressdetails': '1',
        'zoom': '18',
      });
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Taugts/0.1 (+https://github.com/Huluvu424242/taugts)',
      );
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'de');
      final response = await request.close();
      if (response.statusCode == HttpStatus.notFound) {
        return null;
      }
      if (response.statusCode != HttpStatus.ok) {
        throw const GeocodingAusnahme(
          'Der Adressdienst ist derzeit nicht verfügbar.',
        );
      }
      final body = await utf8.decoder.bind(response).join();
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw const GeocodingAusnahme(
          'Der Adressdienst hat eine unerwartete Antwort geliefert.',
        );
      }
      final adresse = (json['display_name'] as String?)?.trim();
      if (adresse == null || adresse.isEmpty) {
        return null;
      }
      final details = json['address'];
      String? name;
      if (details is Map<String, dynamic>) {
        for (final key in [
          'amenity',
          'shop',
          'tourism',
          'leisure',
          'building'
        ]) {
          final value = details[key];
          if (value is String && value.trim().isNotEmpty) {
            name = value.trim();
            break;
          }
        }
      }
      final displayName = json['name'];
      if (name == null &&
          displayName is String &&
          displayName.trim().isNotEmpty) {
        name = displayName.trim();
      }
      return Adressvorschlag(name: name, adresse: adresse);
    } on SocketException {
      throw const GeocodingAusnahme(
        'Keine Netzwerkverbindung. Der Ort kann trotzdem gespeichert werden.',
      );
    } on FormatException {
      throw const GeocodingAusnahme(
        'Der Adressdienst hat eine ungültige Antwort geliefert.',
      );
    } finally {
      client.close(force: true);
    }
  }
}
