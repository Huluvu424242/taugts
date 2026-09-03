class AuswertungsFilter {
  const AuswertungsFilter({
    this.kategorieId,
    this.objektId,
    this.herkunftProfilId,
  });

  final String? kategorieId;
  final String? objektId;
  final String? herkunftProfilId;
}

class Durchschnittswert {
  const Durchschnittswert({
    required this.kriterium,
    required this.kriteriumVersion,
    required this.anzahl,
    required this.durchschnitt,
  });

  final String kriterium;
  final int kriteriumVersion;
  final int anzahl;
  final double durchschnitt;
}

class Zeitwert {
  const Zeitwert({
    required this.zeitpunkt,
    required this.wert,
    required this.beschreibung,
  });

  final DateTime zeitpunkt;
  final double wert;
  final String beschreibung;
}

class ErlebnisGruppe {
  const ErlebnisGruppe({
    required this.schluessel,
    required this.anzahl,
    required this.gesamtdauerMinuten,
  });

  final String schluessel;
  final int anzahl;
  final int gesamtdauerMinuten;
}

class AuswertungsUebersicht {
  const AuswertungsUebersicht({
    required this.bewertungsanzahl,
    required this.durchschnitte,
    required this.preisverlauf,
    required this.qualitaetsverlauf,
    required this.ortsverlauf,
    required this.erlebnisgruppen,
    required this.andrangBeobachtungen,
  });

  final int bewertungsanzahl;
  final List<Durchschnittswert> durchschnitte;
  final List<Zeitwert> preisverlauf;
  final List<Zeitwert> qualitaetsverlauf;
  final List<Zeitwert> ortsverlauf;
  final List<ErlebnisGruppe> erlebnisgruppen;
  final List<Zeitwert> andrangBeobachtungen;
}
