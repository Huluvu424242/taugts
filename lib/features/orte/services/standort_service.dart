import 'package:geolocator/geolocator.dart';

class StandortErgebnis {
  const StandortErgebnis({
    required this.breitengrad,
    required this.laengengrad,
    this.genauigkeitMeter,
  });

  final double breitengrad;
  final double laengengrad;
  final double? genauigkeitMeter;
}

abstract interface class StandortService {
  Future<StandortErgebnis> aktuellenStandortErmitteln();
}

class GeolocatorStandortService implements StandortService {
  const GeolocatorStandortService();

  @override
  Future<StandortErgebnis> aktuellenStandortErmitteln() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const StandortAusnahme('Die Standortdienste sind ausgeschaltet.');
    }
    var berechtigung = await Geolocator.checkPermission();
    if (berechtigung == LocationPermission.denied) {
      berechtigung = await Geolocator.requestPermission();
    }
    if (berechtigung == LocationPermission.denied ||
        berechtigung == LocationPermission.deniedForever) {
      throw const StandortAusnahme(
          'Die Standortberechtigung wurde nicht erteilt.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return StandortErgebnis(
      breitengrad: position.latitude,
      laengengrad: position.longitude,
      genauigkeitMeter: position.accuracy,
    );
  }
}

class StandortAusnahme implements Exception {
  const StandortAusnahme(this.nachricht);

  final String nachricht;

  @override
  String toString() => nachricht;
}
