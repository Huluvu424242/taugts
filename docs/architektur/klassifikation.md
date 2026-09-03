# Klassifikation und Schlagwörter

Taugt’s? behandelt strukturierte Klassifikation und freie Schlagwörter als getrennte fachliche Dimensionen.

- **Kategorien** bleiben hierarchische, strukturierte Zuordnungen im `KategorieRepository`; ein Produkt oder Ort kann mehreren Kategorien zugeordnet sein.
- **Herkunft** und **Hersteller** sind eigenständige Merkmale und werden nicht aus Tags abgeleitet.
- **Eigenschaften** werden als benannte Schlüssel-Wert-Merkmale geführt und können später erweitert werden, ohne vorhandene Bewertungen umzuschreiben.
- **Tags** sind freie Suchbegriffe. Sie werden für die Eindeutigkeit nach Trim, Leerraum und Groß-/Kleinschreibung normalisiert, der erste eingegebene Anzeigetext bleibt erhalten.

Das Entfernen oder Ändern von Klassifikationsdaten verändert keine Erlebnisse, Preise oder Bewertungen. Die Tabellen besitzen deshalb bewusst keine löschenden Beziehungen zu historischen Bewertungsdaten.
