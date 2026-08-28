# Taugt’s? – fachliche Anforderungen und Storyliste

## 1. Produktidee

**Bewerter** ist eine lokal arbeitende Flutter-App zur strukturierten Erfassung, Bewertung und späteren Kategorisierung beliebiger Dinge und Orte.

Die erste Ausbaustufe konzentriert sich auf Getränke – insbesondere Bier – sowie auf die Orte und Situationen, in denen diese Getränke konsumiert oder gekauft werden. Das fachliche Modell soll jedoch von Anfang an so allgemein gestaltet sein, dass später beispielsweise Lebensmittel, Restaurants, Geschäfte, Produkte, Dienstleistungen, Veranstaltungen oder andere bewertbare Dinge ergänzt werden können.

Die App verfolgt dabei folgende Grundprinzipien:

- Alle fachlichen Nutzerdaten werden lokal auf dem Gerät gespeichert.
- Es gibt keinen verpflichtenden Benutzeraccount und keine Cloud-Synchronisation.
- Datenaustausch zwischen Personen oder Geräten erfolgt über eine menschenlesbare Exportdatei.
- Bewertungen, Stammdaten und Bewertungskriterien sind voneinander getrennt.
- Bereits erfasste Dinge können beliebig oft und von unterschiedlichen Personen bewertet werden.
- Bewertungskriterien sind erweiterbar und dürfen je Kategorie unterschiedlich sein.
- Sensoren und Gerätefunktionen wie Kamera, Barcode-Scanner und Standort dürfen die Erfassung komfortabler machen.
- Netzwerkzugriffe sind optional und dienen ausschließlich der bewussten Anreicherung von Daten, beispielsweise über OpenStreetMap. Die lokal gespeicherten Daten bleiben die maßgebliche Datenbasis.
- Die Architektur soll eine spätere ausgefeilte Kategorisierung und Taxonomie ermöglichen, ohne das MVP unnötig kompliziert zu machen.

---

# 2. Fachliches Grundmodell

## 2.1 Bewertbares Objekt

Ein **bewertbares Objekt** ist etwas, über das Stammdaten gespeichert und Bewertungen abgegeben werden können.

Beispiele:

- Bier
- anderes Getränk
- Gaststätte
- Bar
- Geschäft
- später beliebige weitere Dinge

Jedes Objekt besitzt mindestens:

- interne stabile UUID
- Objekttyp
- Name
- Erstellungszeitpunkt
- letzter Änderungszeitpunkt
- optionale Beschreibung
- optionale Schlagwörter
- optionale externe Identifikatoren

Objekte dürfen unabhängig von Bewertungen existieren.

---

## 2.2 Produkt

Ein Produkt ist ein bewertbares Objekt, das gekauft oder konsumiert werden kann.

Für Bier sollen mindestens folgende optionale Stammdaten vorgesehen werden:

- Name
- Marke
- Brauerei bzw. Hersteller
- Biersorte
- Alkoholgehalt
- Herkunftsland
- Herkunftsort
- Gebindeart, z. B. Flasche, Dose, Fass
- Nennfüllmenge
- Barcode / GTIN / EAN
- Freitextnotizen

Die meisten Stammdaten sind optional. Eine Bewertung darf bereits gespeichert werden, wenn beispielsweise zunächst nur Barcode und Bewertung bekannt sind.

---

## 2.3 Ort

Ein Ort ist ein bewertbares Objekt und kann beispielsweise sein:

- Gaststätte
- Kneipe
- Bar
- Restaurant
- Biergarten
- Geschäft
- Supermarkt
- privater Ort
- sonstiger Ort

Ein Ort kann folgende Daten enthalten:

- Name
- Ortstyp
- Straße
- Hausnummer
- Postleitzahl
- Ort
- Land
- geografische Breite
- geografische Länge
- optionale OpenStreetMap-Referenz
- Freitextnotizen

Die Koordinaten und Adressdaten dürfen manuell, über den Gerätestandort oder über eine Kartenansicht erfasst werden.

---

## 2.4 Erlebnis / Konsumvorgang

Ein **Erlebnis** beschreibt den konkreten Vorgang, bei dem etwas bewertet wurde.

Beispiele:

- „Ich habe am 28.08.2026 in Kneipe X ein Bier Y vom Fass getrunken.“
- „Ich habe Bier Y im Supermarkt gekauft und später zu Hause getrunken.“

Ein Erlebnis enthält mindestens:

- stabile UUID
- Datum und Uhrzeit
- bewertetes Objekt
- optionalen Ort
- optionalen Kaufort
- optionalen Konsumort
- optionalen Preis
- optionale Menge
- optionale Darreichungs- bzw. Gebindeart
- optionale Notiz
- eine oder mehrere Bewertungen
- Herkunftsinformationen des Datensatzes

Dadurch können dasselbe Bier und dieselbe Gaststätte mehrfach zu unterschiedlichen Zeitpunkten bewertet werden.

---

## 2.5 Bewertung

Eine Bewertung gehört immer zu einem konkreten Erlebnis und zu einem bewertbaren Objekt.

Beispiel:

Ein Kneipenbesuch kann gleichzeitig enthalten:

- Bewertung des getrunkenen Bieres
- Bewertung der Gaststätte

Beide Bewertungen sind getrennte Datensätze.

Eine Bewertung enthält:

- stabile UUID
- Referenz auf das bewertete Objekt
- Referenz auf das Erlebnis
- Gesamtwertung
- Einzelbewertungen nach Kriterien
- optionale Freitextnotiz
- Erstellungs- und Änderungszeitpunkt
- Herkunft der Bewertung

---

## 2.6 Bewertungskriterium

Bewertungskriterien sind konfigurierbare Stammdaten.

Ein Kriterium besitzt mindestens:

- stabile UUID
- Name
- Beschreibung
- gültige Objektkategorien
- Eingabetyp
- Einheit bzw. Skalenbeschreibung
- Aktiv/Inaktiv
- Sortierreihenfolge

Unterstützte Eingabetypen sollen mindestens sein:

- Wertungsskala, z. B. 1–5 Sterne
- Intensitätsskala, z. B. „nicht bitter“ bis „sehr bitter“
- Ja/Nein
- Zahl
- Auswahlwert
- Freitext

Dadurch werden objektive Eigenschaften und subjektive Qualitätsurteile nicht vermischt.

Beispiel:

- **Bitterkeit** = Intensitätseigenschaft
- **Geschmack** = Qualitätsbewertung
- **Menge** = objektiver Zahlenwert des Erlebnisses
- **Preis-Leistung** = Qualitätsbewertung
- **Preis** = objektiver Geldbetrag

---

# 3. Vordefinierte Bewertungskriterien

## 3.1 Bier / Getränk

Die App soll initial sinnvolle Kriterien mitliefern:

### Qualitätsbewertungen

- Gesamturteil
- Geschmack
- Geruch / Aroma
- Frische / Qualität
- Preis-Leistung
- Serviertemperatur
- Präsentation

### Eigenschaften / Intensitäten

- Bitterkeit
- Süße
- Säure
- Körper / Vollmundigkeit
- Kohlensäure

### Beschreibende Angaben

- Farbe
- Klarheit / Trübung

Benutzer dürfen Kriterien ergänzen, deaktivieren und sortieren.

---

## 3.2 Gaststätte / Gastronomiebetrieb

Vordefinierte Kriterien:

- Gesamturteil
- Service
- Freundlichkeit
- Sauberkeit / Hygiene
- Atmosphäre
- Getränkeauswahl
- Speiseauswahl
- Preis-Leistung
- Lautstärke / Ruhe
- Wartezeit

Später können weitere Kriterien wie Barrierefreiheit ergänzt werden.

---

# 4. Epic: Bier in einer Gaststätte erfassen und bewerten

## Story 4.1 – Neues Erlebnis starten

**Als Nutzer möchte ich während eines Gaststättenbesuchs schnell einen neuen Bewertungsvorgang starten, damit die Erfassung die eigentliche Situation möglichst wenig unterbricht.**

Akzeptanzkriterien:

- Auf der Startseite existiert eine gut erreichbare Aktion „Jetzt bewerten“.
- Der Nutzer kann „Getränk in Gaststätte“ auswählen.
- Datum und Uhrzeit werden automatisch vorbelegt.
- Noch nicht benötigte Detailfelder dürfen übersprungen werden.
- Ein unfertiger Vorgang kann als Entwurf lokal gespeichert werden.

---

## Story 4.2 – Aktuellen Standort übernehmen

**Als Nutzer möchte ich meinen aktuellen Standort übernehmen, damit ich die Gaststätte nicht vollständig manuell erfassen muss.**

Akzeptanzkriterien:

- Die App kann nach ausdrücklicher Zustimmung den aktuellen Gerätestandort abfragen.
- Der Nutzer kann die Standortberechtigung ablehnen und trotzdem vollständig manuell weiterarbeiten.
- Breiten- und Längengrad können lokal gespeichert werden.
- Die App zeigt die Genauigkeit der ermittelten Position an, sofern das Betriebssystem diese bereitstellt.
- Der Standort kann anschließend manuell korrigiert werden.
- Die App benötigt kein permanentes Hintergrund-Tracking.

---

## Story 4.3 – Ort auf einer Karte auswählen

**Als Nutzer möchte ich meinen Standort auf einer OpenStreetMap-Karte sehen und korrigieren können, damit die Gaststätte dem richtigen Ort zugeordnet wird.**

Akzeptanzkriterien:

- Eine Kartenansicht kann die aktuelle Position darstellen.
- Der Nutzer kann einen Marker verschieben bzw. einen Punkt auf der Karte auswählen.
- Kartenmaterial wird mit der notwendigen OpenStreetMap-Attribution angezeigt.
- Eine Netzwerkverbindung ist nur für das Laden von Kartenmaterial bzw. optionale Geokodierung notwendig.
- Ist kein Netz vorhanden, muss die Erfassung weiterhin mit Koordinaten oder manueller Adresse möglich sein.
- Ein vorhandener Ort kann anstelle einer Neuerfassung ausgewählt werden.

---

## Story 4.4 – Adresse aus Koordinaten vorschlagen

**Als Nutzer möchte ich zu einer Position einen Adressvorschlag erhalten, damit die Erfassung schneller geht.**

Akzeptanzkriterien:

- Die Funktion ist optional.
- Das Ergebnis wird nur als Vorschlag betrachtet.
- Der Nutzer bestätigt oder korrigiert Name und Adresse vor dem Speichern.
- Ein Fehler oder fehlendes Netz verhindert das Speichern des Erlebnisses nicht.
- Die technische Umsetzung muss die Nutzungsbedingungen des eingesetzten Geocoding-Dienstes berücksichtigen.

---

## Story 4.5 – Gaststätte erfassen oder auswählen

**Als Nutzer möchte ich eine vorhandene Gaststätte auswählen oder eine neue anlegen, damit mehrere Besuche derselben Lokalität zusammengeführt werden können.**

Akzeptanzkriterien:

- Orte können nach Name und Entfernung gesucht werden.
- Nahe vorhandene Orte werden bevorzugt angeboten.
- Vor dem Anlegen eines neuen Ortes wird auf mögliche Dubletten hingewiesen.
- Eine Dublette kann bewusst trotzdem angelegt werden.
- Änderungen an Stammdaten verändern historische Bewertungen nicht.

---

## Story 4.6 – Getränk erfassen oder auswählen

**Als Nutzer möchte ich ein bereits bekanntes Bier auswählen oder ein neues Bier anlegen.**

Akzeptanzkriterien:

- Suche nach Name, Marke und Barcode ist möglich.
- Stammdaten dürfen unvollständig gespeichert werden.
- Fehlende Stammdaten können jederzeit später ergänzt werden.
- Dasselbe Produkt kann beliebig oft bewertet werden.

---

## Story 4.7 – Bier bewerten

**Als Nutzer möchte ich mein Getränk nach vordefinierten und eigenen Kriterien bewerten.**

Akzeptanzkriterien:

- Die aktiven Kriterien für Getränke werden angezeigt.
- Nicht jedes Kriterium muss beantwortet werden.
- Eine Gesamtwertung kann unabhängig von Einzelkriterien vergeben werden.
- Einzelwerte werden nicht automatisch zu einer Gesamtwertung verrechnet, solange der Nutzer dies nicht ausdrücklich konfiguriert.
- Freitextnotizen sind möglich.

---

## Story 4.8 – Gaststätte im selben Vorgang bewerten

**Als Nutzer möchte ich während derselben Erfassung zusätzlich die Gaststätte bewerten.**

Akzeptanzkriterien:

- Bier- und Gaststättenbewertung bleiben getrennte Datensätze.
- Beide Bewertungen verweisen auf dasselbe Erlebnis.
- Eine der beiden Bewertungen darf ausgelassen werden.
- Bereits vorhandene frühere Bewertungen der Gaststätte werden nicht überschrieben.

---

# 5. Epic: Bier aus dem Handel erfassen und bewerten

## Story 5.1 – Barcode scannen

**Als Nutzer möchte ich den Barcode eines Bieres mit der Kamera scannen, damit ich das Produkt schnell identifizieren kann.**

Akzeptanzkriterien:

- Die Kamera wird nur nach Zustimmung verwendet.
- EAN-/GTIN-Barcodes können gelesen werden.
- Der erkannte Code wird vor Verwendung angezeigt.
- Der Barcode kann alternativ manuell eingegeben werden.
- Das Scannen erfordert keine externe Produktdatenbank und funktioniert grundsätzlich lokal.
- Existiert bereits ein Produkt mit diesem Barcode, wird es vorgeschlagen.

---

## Story 5.2 – Unbekannten Barcode erfassen

**Als Nutzer möchte ich auch einen noch unbekannten Barcode sofort bewerten können, ohne zuerst alle Produktdaten einzugeben.**

Akzeptanzkriterien:

- Aus dem Barcode kann ein minimales Produkt angelegt werden.
- Produktname und weitere Stammdaten dürfen leer bleiben.
- Die App kennzeichnet unvollständige Produkte.
- Stammdaten können später ergänzt werden.
- Bereits erfasste Bewertungen bleiben mit dem ergänzten Produkt verknüpft.

---

## Story 5.3 – Kauf und Konsum unterscheiden

**Als Nutzer möchte ich Kauf- und Konsumort getrennt erfassen können, weil ich ein Bier beispielsweise im Supermarkt kaufe und zu Hause trinke.**

Akzeptanzkriterien:

- Ein Erlebnis kann einen Kaufort und einen davon abweichenden Konsumort besitzen.
- Preis und gekaufte Menge können dem Kauf zugeordnet werden.
- Die Bewertung wird dem Konsumvorgang zugeordnet.
- Beide Ortsangaben sind optional.
- „Zu Hause“ kann als privater lokaler Ort gespeichert werden, ohne eine Adresse speichern zu müssen.

---

## Story 5.4 – Produktdaten nachträglich ergänzen

**Als Nutzer möchte ich fehlende Informationen zu einem bereits bewerteten Bier später ergänzen.**

Akzeptanzkriterien:

- Produkte mit unvollständigen Stammdaten können gefiltert werden.
- Änderungen werden allen verknüpften Erlebnissen zugänglich.
- Historische Erlebnisdaten wie Preis oder ausgeschenkte Menge bleiben unverändert.
- Ein Barcode kann einem bestehenden Produkt nachträglich zugeordnet werden.

---

# 6. Epic: Bewertungskriterien verwalten

## Story 6.1 – Eigene Kriterien anlegen

**Als Nutzer möchte ich eigene Bewertungskriterien definieren.**

Akzeptanzkriterien:

- Name, Beschreibung und Eingabetyp können festgelegt werden.
- Ein Kriterium kann für eine oder mehrere Objektarten gelten.
- Die Reihenfolge kann verändert werden.
- Kriterien können deaktiviert werden.

---

## Story 6.2 – Kriterien sicher ändern

**Als Nutzer möchte ich Kriterien ändern können, ohne historische Bewertungen unbrauchbar zu machen.**

Akzeptanzkriterien:

- Bereits verwendete Kriterien behalten eine stabile ID.
- Das Löschen eines bereits verwendeten Kriteriums erfolgt fachlich als Deaktivierung.
- Historische Bewertungen bleiben lesbar.
- Änderungen an Skalentyp oder Bedeutung eines bereits verwendeten Kriteriums müssen verhindert oder versioniert werden.

---

## Story 6.3 – Kriteriensets pro Kategorie

**Als Nutzer möchte ich je Kategorie unterschiedliche Kriterien verwenden können.**

Beispiele:

- Bier
- Wein
- Kaffee
- Gaststätte
- Supermarkt

Akzeptanzkriterien:

- Kategorien können Kriterien zugeordnet bekommen.
- Gemeinsame Kriterien dürfen in mehreren Kategorien verwendet werden.
- Neu angelegte Unterkategorien können ein Kriterienset übernehmen.

---

# 7. Epic: Daten durchsuchen und auswerten

## Story 7.1 – Erfasste Dinge suchen

**Als Nutzer möchte ich meine Produkte und Orte schnell wiederfinden.**

Suche mindestens nach:

- Name
- Marke
- Kategorie
- Barcode
- Schlagwort
- Ort

---

## Story 7.2 – Bewertungsverlauf anzeigen

**Als Nutzer möchte ich alle Bewertungen eines Objekts chronologisch sehen.**

Akzeptanzkriterien:

- Datum, Ort und Gesamtwertung werden in einer Übersicht dargestellt.
- Einzelbewertungen können geöffnet werden.
- Eigene und importierte Bewertungen sind unterscheidbar.
- Mehrere Bewertungen desselben Nutzers und Objekts bleiben erhalten.

---

## Story 7.3 – Eigene und fremde Bewertungen unterscheiden

**Als Nutzer möchte ich erkennen, von wem eine Bewertung stammt.**

Akzeptanzkriterien:

- Jede Bewertung besitzt eine Herkunftskennung.
- Die lokale Installation besitzt ein vom Nutzer benennbares Profil.
- Ein Profil benötigt keinen Onlineaccount.
- Importierte Profile werden lokal gespeichert.
- Der Nutzer kann nach Herkunft filtern.

---

# 8. Epic: Kategorien und spätere Taxonomie

## Story 8.1 – Einfache Kategorien

**Als Nutzer möchte ich Dinge Kategorien zuordnen.**

Initiale Beispiele:

- Getränk
  - Bier
- Ort
  - Gastronomie
  - Geschäft

Akzeptanzkriterien:

- Kategorien besitzen stabile IDs.
- Kategorien dürfen hierarchisch aufgebaut sein.
- Ein Objekt kann mindestens einer Kategorie zugeordnet werden.
- Kategorien können ergänzt werden.

---

## Story 8.2 – Mehrfachklassifikation vorbereiten

Das Datenmodell soll darauf vorbereitet sein, ein Objekt später über mehrere Dimensionen einzuordnen.

Beispiel Bier:

- Typ: Getränk → Bier → IPA
- Herkunft: Deutschland → Sachsen
- Hersteller: Brauerei X
- Eigenschaften: alkoholfrei, naturtrüb

Dafür sollen Kategorien, Tags und Stammdaten fachlich getrennt bleiben.

---

## Story 8.3 – Keine freie Textstruktur als alleinige Taxonomie

Freie Schlagwörter sind sinnvoll, dürfen aber die strukturierte Kategorisierung nicht ersetzen.

Die spätere Taxonomie soll insbesondere ermöglichen:

- hierarchische Kategorien
- Synonyme
- Zusammenführung doppelter Kategorien
- Mehrfachzuordnungen
- Umbenennung ohne Verlust historischer Daten

---

# 9. Epic: Export

## Story 9.1 – Gesamtdaten exportieren

**Als Nutzer möchte ich meine lokalen Daten in eine Datei exportieren, damit ich sie sichern oder an andere Personen weitergeben kann.**

### Empfohlenes Format

Für das primäre Austauschformat wird **JSON** empfohlen.

Begründung:

- hierarchische Daten lassen sich sauber darstellen
- UUIDs und Beziehungen sind eindeutig abbildbar
- optionale Felder sind problemlos möglich
- Kategorien und Kriterien können gemeinsam exportiert werden
- spätere Schemaerweiterungen sind einfacher als bei CSV
- die Datei bleibt textbasiert und prinzipiell menschenlesbar

CSV kann später zusätzlich für Tabellenexporte und Auswertungen angeboten werden, sollte aber nicht das vollständige Austauschformat sein.

---

## Story 9.2 – Versioniertes Exportformat

Jede Exportdatei enthält mindestens:

- Formatkennung
- Schemaversion
- Exportzeitpunkt
- erzeugende App-Version
- Profilinformationen
- Objekte
- Orte
- Erlebnisse
- Bewertungen
- Bewertungskriterien
- Kategorien

Beispiel einer Formatkennung:

`bewerter-export`

Die Schemaversion darf unabhängig von der App-Version weiterentwickelt werden.

---

## Story 9.3 – Stabile IDs exportieren

Alle relevanten Datensätze müssen ihre UUID behalten.

Dadurch kann beim späteren Import unterschieden werden zwischen:

- exakt demselben Datensatz
- einer veränderten Version desselben Datensatzes
- demselben realen Produkt mit anderem Datensatz
- einer zusätzlichen Bewertung desselben Produkts

---

## Story 9.4 – Export teilen oder speichern

Die App soll die Flutter-/Betriebssystem-Funktionen zum Speichern und Teilen einer Datei verwenden können.

Mögliche Ziele:

- lokaler Dateispeicher
- Messenger
- E-Mail
- andere installierte Apps

Die App selbst benötigt dafür keinen eigenen Server.

---

# 10. Epic: Import

## 10.1 Grundsatz

Ein Import besteht fachlich aus vier Phasen:

1. Datei auswählen
2. Datei validieren und analysieren
3. Änderungen und Konflikte als Vorschau anzeigen
4. Import nach gewählter Strategie durchführen

Es dürfen vor der Bestätigung keine bestehenden Daten verändert werden.

---

## Story 10.2 – Exportdatei validieren

**Als Nutzer möchte ich vor dem Import wissen, ob eine Datei gültig und kompatibel ist.**

Zu prüfen sind mindestens:

- gültiges JSON
- bekannte Formatkennung
- unterstützte Schemaversion
- erforderliche IDs
- referenzielle Konsistenz
- gültige Datentypen
- unbekannte oder beschädigte Datensätze

Eine ungültige Datei darf den lokalen Datenbestand nicht teilweise verändern.

---

## Story 10.3 – Importvorschau anzeigen

Die Vorschau zeigt mindestens:

- neue Objekte
- neue Orte
- neue Bewertungen
- neue Kriterien
- neue Kategorien
- unveränderte bereits vorhandene Datensätze
- veränderte Datensätze mit identischer ID
- mögliche fachliche Dubletten

---

# 11. Duplikate und Konflikte

## 11.1 Technisches Duplikat

Ein **technisches Duplikat** liegt vor, wenn derselbe stabile Datensatz bereits lokal vorhanden ist.

Primäres Merkmal:

- identische UUID

Beispiele:

- dieselbe Bewertung wurde bereits früher importiert
- derselbe Export wird ein zweites Mal importiert

---

## 11.2 Fachliche Dublette

Eine **fachliche Dublette** bedeutet, dass zwei unterschiedliche IDs wahrscheinlich dasselbe reale Objekt beschreiben.

Beispiele:

- zwei Bierobjekte mit demselben Barcode
- zwei Gaststätten mit gleichem Namen und nahezu identischen Koordinaten
- zwei Produkte mit gleichem Namen, Marke und Hersteller

Fachliche Dubletten dürfen nicht automatisch ohne nachvollziehbare Regel zusammengeführt werden.

---

## 11.3 Kein Duplikat

Folgendes ist ausdrücklich **kein** Duplikat:

- zwei unterschiedliche Bewertungen desselben Bieres
- Bewertungen desselben Bieres durch unterschiedliche Personen
- mehrere Besuche derselben Gaststätte
- erneute Bewertung desselben Objekts zu einem späteren Zeitpunkt

---

# 12. Importstrategien

## Story 12.1 – Lokalen Datenbestand durch Import ersetzen

**Als Nutzer möchte ich meinen gesamten lokalen Datenbestand verwerfen und durch den Import ersetzen können.**

Akzeptanzkriterien:

- Die App weist ausdrücklich auf Datenverlust hin.
- Vor dem Löschen wird optional ein Sicherungsexport angeboten.
- Erst nach Bestätigung wird der lokale fachliche Datenbestand ersetzt.
- App-Einstellungen müssen nicht zwingend Teil dieses Austauschs sein.

Diese Strategie entspricht fachlich „Alle eigenen Einträge löschen und anschließend alles importieren“.

---

## Story 12.2 – Import bevorzugen

**Als Nutzer möchte ich alle neuen Datensätze übernehmen und bei identischen IDs die importierte Version bevorzugen.**

Regeln:

- neue Datensätze → hinzufügen
- identische und gleiche Datensätze → überspringen
- identische UUID mit unterschiedlichen Daten → Importversion verwenden
- zusätzliche Bewertungen desselben Objekts → hinzufügen
- mögliche fachliche Dubletten → nicht stillschweigend überschreiben

---

## Story 12.3 – Lokal vorhandene Daten bevorzugen

**Als Nutzer möchte ich neue Datensätze übernehmen, vorhandene Datensätze aber nicht überschreiben.**

Regeln:

- neue Datensätze → hinzufügen
- identische UUID → lokale Version behalten
- zusätzliche Bewertungen → hinzufügen
- fachliche Dubletten → nach gewählter Dublettenregel behandeln

Dies entspricht dem gewünschten Verhalten „importieren und zu importierende Duplikate verwerfen“.

---

## Story 12.4 – Konflikte einzeln entscheiden

**Als Nutzer möchte ich bei Konflikten für jeden Datensatz entscheiden können.**

Je Konflikt sind abhängig vom Datentyp mögliche Aktionen:

- lokale Version behalten
- importierte Version übernehmen
- beide behalten
- Datensätze zusammenführen
- Datensatz nicht importieren

„Beide behalten“ ist nur möglich, wenn daraus kein Identitätswiderspruch entsteht.

---

## Story 12.5 – Entscheidung auf weitere Konflikte anwenden

Bei manueller Konfliktlösung soll optional angeboten werden:

- „Für alle Konflikte dieses Typs anwenden“
- „Für alle weiteren identischen Datensätze anwenden“

Dadurch bleibt ein großer Import bedienbar.

---

## Story 12.6 – Fachliche Dubletten zusammenführen

**Als Nutzer möchte ich zwei Datensätze, die dasselbe reale Objekt beschreiben, zusammenführen können.**

Beispiel:

Lokales Bier:

- UUID A
- Barcode 123
- Name „Beispiel Pils“

Importiertes Bier:

- UUID B
- Barcode 123
- Brauerei „Beispielbräu“

Nach Zusammenführung:

- ein kanonisches lokales Produkt
- Name und Brauerei vorhanden
- alle Bewertungen beider Datensätze zeigen auf das zusammengeführte Produkt
- die frühere externe ID bleibt als Alias/Herkunftsreferenz erhalten, damit spätere Importe wieder erkannt werden

---

## Story 12.7 – Import atomar durchführen

Der Import muss fachlich transaktional erfolgen.

Das bedeutet:

- entweder wird der bestätigte Import vollständig durchgeführt
- oder bei einem Fehler wird der vorherige Zustand wiederhergestellt

Ein halb importierter Datenbestand ist zu vermeiden.

---

## Story 12.8 – Importprotokoll

Nach dem Import zeigt die App:

- Anzahl hinzugefügter Datensätze
- Anzahl aktualisierter Datensätze
- Anzahl übersprungener Datensätze
- Anzahl zusammengeführter Dubletten
- Anzahl Fehler

Das Protokoll kann lokal eingesehen werden.

---

# 13. Herkunft und Austausch zwischen Personen

## Story 13.1 – Lokales Profil

Beim ersten Start erzeugt die App eine zufällige stabile Profil-ID.

Optional kann der Nutzer einen Anzeigenamen vergeben.

Beispiel:

- Profil-ID: UUID
- Anzeigename: „Huluvu“

Die Profil-ID dient ausschließlich zur Herkunftskennzeichnung der Daten und setzt kein Onlinekonto voraus.

---

## Story 13.2 – Herkunft importierter Bewertungen erhalten

Beim Import darf eine fremde Bewertung nicht zu einer eigenen Bewertung werden.

Gespeichert werden mindestens:

- ursprüngliche Profil-ID
- Anzeigename zum Zeitpunkt des Exports
- ursprüngliche Datensatz-ID

Dadurch können später mehrere Personen dasselbe Objekt bewerten und ihre Ergebnisse getrennt ausgewertet werden.

---

# 14. Datenschutz und Berechtigungen

## Story 14.1 – Berechtigungen nur bei Bedarf

Berechtigungen werden erst angefordert, wenn die jeweilige Funktion verwendet wird.

Beispiele:

- Kamera → Barcode scannen
- Standort → aktuellen Standort verwenden
- Dateizugriff bzw. System-Dateiauswahl → Import/Export

---

## Story 14.2 – App ohne Standort nutzbar

Die App muss vollständig nutzbar bleiben, wenn der Nutzer keine Standortberechtigung erteilt.

---

## Story 14.3 – Standortdaten bewusst speichern

Vor dem Speichern eines exakten privaten Standortes muss klar erkennbar sein, welche Standortdaten gespeichert werden.

Für private Orte soll es möglich sein:

- gar keine Koordinaten zu speichern
- nur eine grobe Ortsbezeichnung zu verwenden
- einen Namen wie „Zu Hause“ ohne Adresse zu speichern

---

# 15. Offline-First-Verhalten

## Story 15.1 – Kernfunktionen vollständig offline

Folgende Funktionen müssen ohne Internet funktionieren:

- Produkte anlegen
- Orte manuell anlegen
- Barcode scannen
- Bewertungen erfassen
- Stammdaten bearbeiten
- Suchen
- Kategorien verwalten
- Export
- Import

---

## Story 15.2 – Online-Anreicherung optional

Internetabhängige Funktionen müssen als Komfortfunktionen behandelt werden.

Beispiele:

- Laden von OpenStreetMap-Kacheln
- Reverse Geocoding
- spätere optionale externe Produktdatensuche

Ein Ausfall solcher Dienste darf die lokale Datenerfassung nicht verhindern.

---

# 16. Bedienkonzept

## Story 16.1 – Mobile First

Die wichtigsten Aktionen sollen mit wenigen Interaktionen erreichbar sein.

Startseite beispielsweise:

- Jetzt bewerten
- Barcode scannen
- Dinge
- Orte
- Bewertungen
- Suche
- Import / Export
- Einstellungen

---

## Story 16.2 – Progressive Erfassung

Der Nutzer soll nicht gezwungen werden, bei einer spontanen Bewertung vollständige Stammdaten einzutragen.

Prinzip:

**erst bewerten – später vervollständigen**

Pflichtfelder werden deshalb auf das fachlich notwendige Minimum reduziert.

---

## Story 16.3 – Entwürfe

Begonnene Erfassungen können als Entwurf gespeichert und später fortgesetzt werden.

---

## Story 16.4 – Schnelle Wiederholungsbewertung

Bei bereits bekannten Produkten soll eine neue Bewertung ohne erneute Stammdateneingabe möglich sein.

---

# 17. Lokale technische Datenhaltung – fachliche Leitplanken

Für die Implementierung wird eine echte lokale strukturierte Datenbank empfohlen.

Warum nicht einfach die JSON-Datei direkt als Arbeitsdatenbank verwenden:

- viele Beziehungen zwischen Objekten
- Suche und Filter
- wiederholte Bewertungen
- Kategorien
- Dublettenerkennung
- atomare Importe
- Migrationen

Die JSON-Datei soll deshalb **Austauschformat**, nicht primärer Datenspeicher sein.

Die konkrete Flutter-Datenbanktechnologie ist eine Architekturentscheidung. Das fachliche Modell soll nicht von einem bestimmten Datenbankpaket abhängen.

---

# 18. Anforderungen an das Austauschformat

Das JSON-Schema soll folgende Eigenschaften besitzen:

- UTF-8
- stabile UUIDs
- explizite Schemaversion
- ISO-8601-Zeitstempel
- Dezimalwerte eindeutig definiert
- Beziehungen über IDs statt impliziter Reihenfolge
- unbekannte optionale Felder sollen nach Möglichkeit toleriert werden
- Exportreihenfolge darf keine fachliche Bedeutung besitzen
- Import alter unterstützter Schemaversionen soll über Migrationen möglich sein

Eine spätere formale JSON-Schema-Datei ist sinnvoll.

---

# 19. Nicht-funktionale Anforderungen

## Story 19.1 – Barrierefreiheit

- ausreichende Touch-Ziele
- Unterstützung großer Schrift
- Screenreader-kompatible Beschriftungen
- Informationen nicht ausschließlich über Farbe vermitteln
- ausreichende Kontraste
- verständliche Fehlertexte

---

## Story 19.2 – Testbarkeit

Fachlogik soll möglichst unabhängig von Flutter-Widgets implementiert werden.

Besonders automatisiert testbar sein müssen:

- Bewertungskriterien
- Datenvalidierung
- Dublettenerkennung
- Merge-Regeln
- Importstrategien
- Schema-Migrationen

---

## Story 19.3 – Nachvollziehbarkeit

Automatische Entscheidungen, insbesondere beim Zusammenführen importierter Daten, müssen für den Nutzer nachvollziehbar sein.

---

## Story 19.4 – Keine stille Datenvernichtung

Lösch-, Ersetzungs- und Merge-Aktionen dürfen nicht unbemerkt historische Bewertungen vernichten.

---

# 20. Empfohlener MVP-Zuschnitt

Für eine erste tatsächlich nutzbare Version wird folgende Reihenfolge empfohlen.

## MVP 1 – Lokales Bewerten

1. lokales Datenmodell
2. lokales Profil
3. Produkte anlegen
4. Orte anlegen
5. Erlebnis erfassen
6. Bier bewerten
7. Gaststätte bewerten
8. Bewertungsverlauf anzeigen
9. Bewertungskriterien konfigurieren

## MVP 2 – Gerätesensoren

10. Barcode scannen
11. GPS-Position übernehmen
12. Kartenansicht mit OpenStreetMap
13. optionale Adressauflösung

## MVP 3 – Austausch

14. JSON-Exportschema
15. Export
16. Importvalidierung
17. Importvorschau
18. Konflikterkennung
19. drei globale Importstrategien
20. manuelle Konfliktlösung
21. fachliche Dubletten zusammenführen

## MVP 4 – Kategorisierung

22. hierarchische Kategorien
23. Tags
24. Kriteriensets je Kategorie
25. Filter und Auswertungen

---

# 21. Spätere Ausbaustufen

Das Modell soll Erweiterungen ermöglichen, ohne diese bereits im MVP umsetzen zu müssen.

Mögliche spätere Funktionen:

- Fotos zu Produkten oder Erlebnissen
- OCR von Etiketten
- externe Produktdatenbanken
- Favoriten
- Bestenlisten
- statistische Auswertungen
- Durchschnittswerte nach Person
- Preisentwicklung
- Kartenansicht aller besuchten Orte
- Bewertung nach Kontext, z. B. „zum Essen“ oder „im Sommer“
- Vergleich mehrerer Produkte
- frei definierbare Objektarten
- frei definierbare Eigenschaften je Objektart
- komplexere Taxonomien
- Zusammenführung und Aufspaltung von Kategorien
- anonymisierte Exportprofile
- selektiver Export bestimmter Kategorien, Zeiträume oder Personen
- verschlüsselte Exportdateien
- lokale Anhänge wie Fotos in einem optionalen Archivformat

---

# 22. Architekturleitplanken für Flutter

Die folgenden Punkte sind keine festen Paketvorgaben, sondern Leitplanken für die spätere technische Umsetzung:

- Flutter als UI-Framework.
- Domainlogik unabhängig von Widgets halten.
- Repository-Abstraktion zwischen Fachlogik und lokaler Datenbank.
- Import/Export als eigener Anwendungsdienst.
- Dubletten- und Merge-Logik ohne UI-Abhängigkeit.
- GPS nur bei aktiver Benutzeraktion.
- Kamera nur während des Barcode-Scans.
- Karten- und Geocoding-Funktionen über abstrahierte Provider, damit der Anbieter austauschbar bleibt.
- Keine fachliche Abhängigkeit von Google Play Services.
- Android und iOS als primäre mobile Plattformen.
- Datenbankmigrationen von Beginn an berücksichtigen.
- UUIDs nicht aus fachlich veränderlichen Feldern wie Namen oder Barcode ableiten.
- Import niemals direkt gegen UI-Modelle implementieren.
- Konfliktanalyse zunächst vollständig berechnen und erst danach Änderungen persistieren.

---

# 23. Technische Machbarkeit ausgewählter Gerätefunktionen

Die vorgesehenen Funktionen sind mit Flutter grundsätzlich gut umsetzbar:

- **Standort:** Zugriff auf GPS bzw. die Standortdienste des Betriebssystems.
- **Barcode:** Kamera-basierter Scan von EAN/GTIN und weiteren Barcodes.
- **OpenStreetMap:** Darstellung einer OSM-basierten Karte über einen Flutter-Kartenclient.
- **Reverse Geocoding:** optional über einen geeigneten OSM-/Nominatim-kompatiblen Dienst.
- **Dateien:** Import und Export über die systemeigenen Datei- und Teilen-Dialoge.

Bei öffentlichen OpenStreetMap-Diensten müssen Attribution, Nutzungsbedingungen und insbesondere Einschränkungen öffentlicher Geocoding-Server berücksichtigt werden. Deshalb sollte der Geocoding-Provider technisch austauschbar sein.

---

# 24. Fachliche Kernentscheidung

Das wichtigste Modellierungsprinzip der App lautet:

> **Ein Ding ist nicht seine Bewertung.**

Ein Bier ist ein dauerhaftes Objekt.  
Ein Kneipenbesuch ist ein Erlebnis.  
Die Bewertung beschreibt die persönliche Einschätzung dieses Objekts in diesem Erlebnis.  
Eine andere Person, ein anderer Zeitpunkt oder ein anderer Ort erzeugt deshalb normalerweise eine weitere Bewertung und keinen Konflikt.

Diese Trennung bildet zugleich die Grundlage für später mögliche Auswertungen, Importe, Kategorisierung und Vergleiche.
