# Reverse Geocoding

## Zweck

Die optionale Funktion wandelt vom Nutzer bereits erfasste Koordinaten in einen Vorschlag für Name und Adresse um. Sie gehört ausdrücklich nicht zur Offline-Kernfunktion und wird ausschließlich durch die Aktion **„Adresse aus Koordinaten vorschlagen“** gestartet.

## Provider und Kapselung

Die Präsentation verwendet ausschließlich die Schnittstelle `GeocodingService`. Die aktuelle Implementierung `NominatimGeocodingService` nutzt die öffentliche Reverse-Geocoding-API von OpenStreetMap Nominatim. Dadurch kann der Provider später ausgetauscht werden, ohne das Ortsformular an ein bestimmtes HTTP-Protokoll zu koppeln.

## Datenschutz

Bei einem Aufruf werden Breitengrad und Längengrad an `nominatim.openstreetmap.org` übertragen. Es findet keine automatische, periodische oder im Hintergrund laufende Übertragung statt. Orte vom Typ **Privater Ort** werden von der Online-Anreicherung ausgeschlossen, damit exakte private Positionen nicht versehentlich übertragen werden. Die manuelle Eingabe und das Speichern bleiben unabhängig vom Online-Dienst verfügbar.

## Nutzungsbedingungen und Rate Limits

Die öffentliche Nominatim-Instanz ist ein gemeinschaftlich betriebener Dienst und darf nicht für hohe oder automatisierte Last verwendet werden. Taugt’s? löst pro bewusster Nutzeraktion genau eine Reverse-Geocoding-Anfrage aus, führt kein Bulk-Geocoding durch und setzt einen identifizierbaren `User-Agent` mit Projekt-URL. Bei wachsender Nutzung ist vor einer höheren Abfragerate ein eigener beziehungsweise alternativer Provider zu prüfen.

Maßgeblich sind die jeweils aktuellen Nominatim Usage Policies und die OpenStreetMap-Nutzungsbedingungen. Der Dienst und die daraus stammenden Vorschläge werden in der Oberfläche als **OpenStreetMap/Nominatim** kenntlich gemacht.

## Fehlerbehandlung

Netzwerkfehler, Providerfehler, ungültige Antworten und fehlende Treffer werden als verständliche Meldung ausgegeben. Sie blockieren weder die manuelle Ortsbearbeitung noch das Speichern. Ein Vorschlag verändert Name oder Adresse erst nach ausdrücklicher Bestätigung und bleibt danach editierbar.
