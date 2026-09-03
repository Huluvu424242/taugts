# Kategorie-Kriteriensets

Bewertungskriterien werden weiterhin zentral versioniert. Eine Kategorie speichert nur ihre Regel und geordnete Referenzen auf Kriterien.

Die wirksame Auswahl entsteht deterministisch in dieser Reihenfolge:

1. Die Produkt- oder Ortsart liefert ein Standardset als Fallback.
2. Regeln der Kategorien werden vom Wurzelknoten bis zur konkreten Kategorie angewendet.
3. `erweitern` behält das bisher wirksame Set und ergänzt explizite Kriterien.
4. `ersetzen` verwirft das bisher wirksame Set und verwendet anschließend nur die expliziten Kriterien der betreffenden Kategorie und ihrer nachfolgenden Erweiterungen.
5. Derselbe Kriterien-Datensatz darf von mehreren Kategorien referenziert werden.

Die Oberfläche weist Standard-, geerbte und explizite Quellen textlich aus. Für Gastronomie und Geschäfte bleiben eigene Fallbacksets vorhanden; das Geschäftsset enthält insbesondere Andrang/Auslastung und Wartezeit.

Historische Bewertungen werden durch spätere Regeländerungen nicht neu berechnet. Beim Speichern kopiert das bestehende Bewertungsrepository Name, Beschreibung, Eingabetyp, Reihenfolge, Kriterienversion und Auswahlskala in den Bewertungsdatensatz. Damit bleibt die damalige Bedeutung lesbar. Die Kriterienset-Regeln besitzen zusätzlich eine eigene Version, um Änderungen des wirksamen Sets nachvollziehbar zu machen.
