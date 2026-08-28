class Profil {
  const Profil({
    required this.id,
    required this.erstelltAm,
    required this.geaendertAm,
    this.anzeigename,
  });

  final String id;
  final String? anzeigename;
  final DateTime erstelltAm;
  final DateTime geaendertAm;

  Profil mitAnzeigename(String? wert, DateTime geaendertAm) => Profil(
        id: id,
        anzeigename: wert,
        erstelltAm: erstelltAm,
        geaendertAm: geaendertAm,
      );
}
