# Auswertungen

Die Auswertungen arbeiten vollständig offline auf den lokal gespeicherten historischen Datensätzen.

Taugt’s? zeigt Anzahl und zeitliche Verläufe von Bewertungen, Preisbeobachtungen nach Ort, Qualitätsbewertungen von Produkten, Ortsbewertungen sowie Erlebnisanzahl und -dauer nach Typ, Wochentag und Tageszeit. Filter auf Kategorie, konkretes Objekt und Herkunft werden von der Berechnungsschicht unterstützt.

Durchschnittswerte werden ausschließlich für fachliche Qualitätswertungen (`wertung`) derselben Kriterien-ID und derselben Kriterienversion gebildet. Fehlende Werte werden ausgelassen und niemals als Null eingesetzt. Preis, Intensität, Ja/Nein, Zahlenfelder, Auswahl und Freitext werden nicht in einen undurchsichtigen Gesamtwert eingerechnet.

Andrang beziehungsweise Auslastung wird ausschließlich aus dem ausdrücklich gespeicherten Kriterium **„Andrang / Auslastung“** übernommen. Uhrzeit und Wochentag sind nur Kontext. Angezeigte Zusammenhänge sind Beobachtungen und keine Aussage über Ursache und Wirkung.

Korrekturen verändern den bereits identifizierten Datensatz; gezählt werden stabile Bewertungs- und Erlebnis-IDs, nicht Bearbeitungsvorgänge.
