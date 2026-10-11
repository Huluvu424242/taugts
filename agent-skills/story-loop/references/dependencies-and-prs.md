# Abhängigkeiten, Branches und PRs

- Projektharness und Branchschutz haben Vorrang. Normalfall: eigener Branch und ein PR pro Story.
- Unabhängige PRs gehen gegen den projektspezifischen Zielbranch; abhängige PRs dürfen als Kette gegen Vorgänger-Arbeitsbranches zielen.
- Jeder PR dokumentiert Story/Issue, unmittelbaren Vorgänger (falls vorhanden), den gewählten Base-Branch, Tests und Risiko. Im Abschlussbericht die unterste-zuerst-Merge-Reihenfolge angeben.
- In einem gestapelten PR-Diff können bis zum Merge des Vorgängers dessen Änderungen sichtbar sein. Nicht als unabhängigen PR missverstehen.
- Keine automatische Übernahme oder Merges, auch nicht bei vollständig grüner CI. Ein `Closes #…`-Verweis darf das Issue erst bei künftigem Merge schließen.
- Bei neuer Änderung am Vorgängerbranch Nachfolger auf Veralten, Konflikte und neu nötige Prüfungen untersuchen; niemals einen alten grünen SHA als Beleg für den neuen Stand verwenden.
- Bestehende erfolgreiche PRs nicht unnötig rebasen, verändern, retargeten oder synchronisieren. Keine fremden Änderungen überschreiben, keine Force-Pushes ohne explizite Harness-Freigabe.
- Ist die Zuordnung Story↔PR uneindeutig, nicht duplizieren oder raten. Betroffene Story mit Befund zurückstellen.
