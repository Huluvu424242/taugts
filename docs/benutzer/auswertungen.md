# Auswertungen

Die Auswertungen arbeiten vollständig offline auf den lokal gespeicherten historischen Datensätzen.

Taugt’s? zeigt Anzahl und zeitliche Verläufe von Bewertungen, Preisbeobachtungen nach Ort, Qualitätsbewertungen von Produkten, Ortsbewertungen sowie Erlebnisanzahl und -dauer nach Typ, Wochentag und Tageszeit. Filter auf Kategorie, konkretes Objekt und Herkunft werden von der Berechnungsschicht unterstützt.

Durchschnittswerte werden ausschließlich für fachliche Qualitätswertungen (`wertung`) derselben Kriterien-ID und derselben Kriterienversion gebildet. Fehlende Werte werden ausgelassen und niemals als Null eingesetzt. Preis, Intensität, Ja/Nein, Zahlenfelder, Auswahl und Freitext werden nicht in einen undurchsichtigen Gesamtwert eingerechnet.

## Excel-Export

Über **Exportieren** wird eine `.xlsx`-Datei mit den aktuell lokal vorhandenen Qualitätswertungen erzeugt und über den Systemdialog gespeichert. Die Erzeugung erfolgt vollständig lokal; es werden keine Daten an einen Cloud-Dienst übertragen. Der Dateiname folgt dem Muster `taugts-statistik-YYYY-MM-DD.xlsx`.

Die Arbeitsmappe enthält drei Tabellenblätter:

- **Produktbewertungen:** Eine Zeile entspricht einem Produkt. Für jeden Ort gibt es die drei Spalten **Beste Bewertung**, **Schlechteste Bewertung** und **Durchschnitt**. Fehlende Produkt-/Ort-Kombinationen bleiben leer. Beste Werte sind zusätzlich grün, schlechteste rot hinterlegt; die Bedeutung ist immer auch textlich in der Spaltenüberschrift angegeben.
- **Ortsbewertungen:** Eine Zeile entspricht einem Ort. Ausgegeben werden beste, schlechteste und durchschnittliche Qualitätswertung des Orts. Auch hier werden beste und schlechteste Werte zusätzlich grün beziehungsweise rot hervorgehoben.
- **Ortsverlauf:** Für jede gespeicherte Ortsbewertung wird aus ihren Qualitätswertungen ein Durchschnittswert für den damaligen Zeitpunkt gebildet. Die Tabelle enthält die zugrunde liegenden Zeitpunkte und Werte und zusätzlich ein Liniendiagramm mit einer Linie je Ort. Ein Punkt beschreibt damit den historischen Gesamtstand einer einzelnen Ortsbewertung; Kriterienversionen bleiben Bestandteil dieses jeweiligen historischen Bewertungsstands und werden nicht als eigenständige Zeitreihe vermischt.

In den Excel-Kennzahlen werden ausschließlich numerische Kriterien vom Eingabetyp **Wertung** berücksichtigt. Intensität, Ja/Nein, Zahl, Auswahl und Freitext werden nicht eingerechnet. Bei Produktbewertungen wird der Ort des zugehörigen Erlebnisses verwendet; Bewertungen ohne gespeicherten Ort erscheinen unter **Ohne Ort**. Der aktuelle Auswertungsbildschirm bietet derzeit keine vom Nutzer gesetzten Exportfilter, deshalb umfasst der Export den vollständigen lokal gespeicherten auswertbaren Datenbestand.

Sind noch keine Qualitätswertungen vorhanden, wird keine irreführende leere Statistik gespeichert. Ein abgebrochener Speicherdialog wird als Abbruch und nicht als Fehler gemeldet. Bei einem technischen Fehler bleiben die lokalen Daten unverändert und der Export kann erneut versucht werden.

Andrang beziehungsweise Auslastung wird ausschließlich aus dem ausdrücklich gespeicherten Kriterium **„Andrang / Auslastung“** übernommen. Uhrzeit und Wochentag sind nur Kontext. Angezeigte Zusammenhänge sind Beobachtungen und keine Aussage über Ursache und Wirkung.

Korrekturen verändern den bereits identifizierten Datensatz; gezählt werden stabile Bewertungs- und Erlebnis-IDs, nicht Bearbeitungsvorgänge.
