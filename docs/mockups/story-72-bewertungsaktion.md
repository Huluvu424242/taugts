# Story #72 – kompakte Bewertungsaktion

Die Produktzeile verwendet ein ineinandergeschobenes Downlike-/Uplike-Motiv. Es besteht ausschließlich aus Flutter-Material-Icons und benötigt kein zusätzliches Asset oder eine neue Lizenz.

```text
┌──────────────┐
│   👍         │
│ 👎           │
└──────────────┘
```

Das Motiv wird in einem 48 × 48 logischen Pixel großen Touch-Ziel dargestellt. Der nach unten gerichtete Daumen sitzt links unten, der nach oben gerichtete Daumen rechts oben. Dadurch bleiben beide Richtungen bei typischer Android-Größe einzeln erkennbar, bilden aber eine kompakte gemeinsame Bewertungsaktion.

Das Motiv trägt keine fachliche Bedeutung allein: Tooltip und semantischer Name lauten immer „<Produktname> bewerten“. Zusätzlich steht in der Produktzeile textlich „Bewertet“ beziehungsweise „Noch nicht bewertet“. Der Bewertungszustand wird daher weder nur über Farbe noch nur über die Iconform vermittelt.
