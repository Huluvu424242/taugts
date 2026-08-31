abstract final class SupportKontexte {
  static const appStart = 'App-Start';
  static const startseite = 'Startseite';
  static const profil = 'Mein Profil';
  static const produkteVerwalten = 'Produkte verwalten';
  static const produktAuswaehlen = 'Produkt auswählen';
  static const produktErfassen = 'Produkt erfassen';
  static const produktBearbeiten = 'Produkt bearbeiten';
  static const orteVerwalten = 'Orte verwalten';
  static const ortAuswaehlen = 'Ort auswählen';
  static const ortErfassen = 'Ort erfassen';
  static const ortBearbeiten = 'Ort bearbeiten';
  static const bewertungsentwuerfe = 'Erlebnisse verwalten';
  static const bewertungErfassen = 'Bewertung erfassen – Getränk in Gaststätte';
  static const bewertungsentwurfBearbeiten =
      'Bewertungsentwurf bearbeiten – Getränk in Gaststätte';
  static const getraenkBewertung = 'Getränk bewerten';
  static const kriterienVerwalten = 'Bewertungskriterien verwalten';
  static const ueberDialog = 'Über-Dialog';
  static const barrierefreiheitserklaerung = 'Barrierefreiheitserklärung';

  static String produktFormular({required bool bearbeiten}) =>
      bearbeiten ? produktBearbeiten : produktErfassen;

  static String ortFormular({required bool bearbeiten}) =>
      bearbeiten ? ortBearbeiten : ortErfassen;

  static String produkte({required bool zurAuswahl}) =>
      zurAuswahl ? produktAuswaehlen : produkteVerwalten;

  static String orte({required bool zurAuswahl}) =>
      zurAuswahl ? ortAuswaehlen : orteVerwalten;

  static String erlebnis({required bool entwurfBearbeiten}) =>
      entwurfBearbeiten ? bewertungsentwurfBearbeiten : bewertungErfassen;

  static String erlebnisGrunddaten({
    required String typ,
    required bool bearbeiten,
  }) =>
      bearbeiten ? '$typ bearbeiten' : '$typ registrieren';
}
