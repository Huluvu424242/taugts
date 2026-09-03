enum KlassifikationsDimension { herkunft, hersteller, eigenschaft }

class ObjektKlassifikation {
  const ObjektKlassifikation({
    required this.objektId,
    this.tags = const <String>{},
    this.herkunft,
    this.hersteller,
    this.eigenschaften = const <String, String>{},
  });

  final String objektId;
  final Set<String> tags;
  final String? herkunft;
  final String? hersteller;
  final Map<String, String> eigenschaften;
}
