import 'package:taugts/features/bewertungen/models/fachmodelle.dart';

enum Suchziel { produkte, orte, erlebnisse, historie }

enum Historienart {
  produktbewertung,
  gaststaettenbewertung,
  geschaeftsbewertung,
  preisbeobachtung,
}

class Suchfilter {
  const Suchfilter({
    this.ziel = Suchziel.produkte,
    this.text = '',
    this.kategorieId,
    this.ortId,
    this.produktId,
    this.herkunftProfilId,
    this.erlebnistyp,
    this.erlebnisstatus,
    this.historienart,
    this.von,
    this.bis,
    this.tageszeitVonMinute,
    this.tageszeitBisMinute,
  });

  final Suchziel ziel;
  final String text;
  final String? kategorieId;
  final String? ortId;
  final String? produktId;
  final String? herkunftProfilId;
  final Erlebnistyp? erlebnistyp;
  final Erlebnisstatus? erlebnisstatus;
  final Historienart? historienart;
  final DateTime? von;
  final DateTime? bis;
  final int? tageszeitVonMinute;
  final int? tageszeitBisMinute;

  bool get hatAktiveFilter =>
      text.trim().isNotEmpty ||
      kategorieId != null ||
      ortId != null ||
      produktId != null ||
      herkunftProfilId != null ||
      erlebnistyp != null ||
      erlebnisstatus != null ||
      historienart != null ||
      von != null ||
      bis != null ||
      tageszeitVonMinute != null ||
      tageszeitBisMinute != null;
}

class Suchtreffer {
  const Suchtreffer({
    required this.id,
    required this.art,
    required this.titel,
    required this.untertitel,
    this.erlebnisId,
    this.produktId,
    this.ortId,
    this.zeitpunkt,
  });

  final String id;
  final Suchziel art;
  final String titel;
  final String untertitel;
  final String? erlebnisId;
  final String? produktId;
  final String? ortId;
  final DateTime? zeitpunkt;
}
