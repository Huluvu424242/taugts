# Story #29 – Implementierungshinweise

Die Umsetzung verwendet bewusst den bestehenden zentralen Bewertungsweg. `ProduktErneutBewertenScreen` orchestriert lediglich Erlebniswahl, vorhandenes Positionsformular und vorhandenen Bewertungsbogen. Produktstammdaten werden nicht kopiert.

Ein neues Erlebnis wird zunächst als Entwurf mit aktuellem Datum und aktueller Uhrzeit vorbereitet. Erst wenn der Nutzer das bestehende Erlebnisformular speichert, entsteht ein lokaler Erlebniseintrag. Eine vorhandene Produktposition wird wiederverwendet; andernfalls wird das bestehende Positionsformular mit dem Produkt vorbelegt.
