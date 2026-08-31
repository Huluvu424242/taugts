# OpenStreetMap-Karte

Die Karte ist eine ausschließlich durch Nutzeraktion geöffnete Online-
Komfortfunktion. Ohne Netzwerk bleiben Adresse und Koordinaten vollständig
manuell erfassbar und speicherbar.

## Provider und Datenschutz

Standardmäßig werden Kartenkacheln direkt von `tile.openstreetmap.org` geladen.
Dabei erhält der Dienst technisch die IP-Adresse und den abgefragten
Kartenausschnitt. Die App sendet keine Profil-, Bewertungs- oder Produktdaten.
Private Positionen werden erst übertragen, wenn der Nutzer die Karte bewusst
öffnet. Die Providerkonfiguration ist in `KartenProvider` gekapselt und kann
ausgetauscht werden.

Für den öffentlichen OSM-Kachelserver gelten die jeweils aktuellen Tile Usage
Policies und Kapazitätsgrenzen. Taugt’s? setzt einen eindeutigen User-Agent,
zeigt die OpenStreetMap-Attribution dauerhaft und bietet keinen massenhaften
Download oder Offline-Kachelcache an.

## Plattformprüfung

`flutter_map` und `latlong2` verwenden Flutter beziehungsweise reines Dart und
sind für Android, Windows und Linux geeignet. Android bleibt die Referenz; auf
Windows und Linux ist vor einer Veröffentlichung zusätzlich die Interaktion
mit Maus, Tastatur und hoher Skalierung manuell zu prüfen.
