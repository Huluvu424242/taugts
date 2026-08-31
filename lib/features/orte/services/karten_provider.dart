class KartenProvider {
  const KartenProvider({
    required this.kachelUrl,
    required this.attribution,
    required this.attributionUrl,
  });

  final String kachelUrl;
  final String attribution;
  final String attributionUrl;

  static const openStreetMap = KartenProvider(
    kachelUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap-Mitwirkende',
    attributionUrl: 'https://www.openstreetmap.org/copyright',
  );
}
