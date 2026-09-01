# Story #29 – Bekanntes Produkt erneut bewerten

## Einstieg aus Suche / Produktliste

```text
┌────────────────────────────────────┐
│ Produkte                       ⋮    │
│ [ Produkte suchen             ]    │
│                                    │
│ Testbier              [★+] [↶]     │
│ Marke                              │
└────────────────────────────────────┘
```

`★+` startet **Erneut bewerten**, `↶` öffnet den Verlauf. Dieselbe Aktion steht im Produktformular und im Produktverlauf zur Verfügung.

## Erlebnis wählen

```text
┌────────────────────────────────────┐
│ Erneut bewerten                ⋮    │
│ Testbier                           │
│                                    │
│ [ + Neues Erlebnis registrieren ] │
│                                    │
│ Vorhandenes Erlebnis               │
│ ┌────────────────────────────────┐ │
│ │ Restaurantbesuch       31.08.  │ │
│ │ Einkauf                 01.09.  │ │
│ └────────────────────────────────┘ │
└────────────────────────────────────┘
```

Bei einem neuen Erlebnis werden Datum und Uhrzeit mit dem aktuellen Zeitpunkt vorbelegt. Der Nutzer kann im bestehenden Erlebnisformular Ort und Zeit ändern. Abbruch vor dem Speichern erzeugt keinen Datensatz.

## Position und Bewertung

Nach der Erlebniswahl wird das vorhandene Produkt als Position wiederverwendet. Existiert die Position bereits im Erlebnis, wird sie nicht dupliziert. Andernfalls öffnet das bestehende Positionsformular mit vorbelegtem Produkt; dort werden Anzahl und ein neuer Preis erfasst. Danach öffnet der bestehende Bewertungsbogen. Frühere Bewertungen und Preisbeobachtungen bleiben unverändert.

## Zustände

- **Laden:** zugänglich beschrifteter Fortschrittsindikator.
- **Leer:** Hinweis, dass noch kein vorhandenes Erlebnis existiert; neues Erlebnis bleibt erreichbar.
- **Fehler:** verständlicher Fehlertext mit erneutem Ladeversuch beziehungsweise Snackbar bei Fehlern der Vorbereitung.
- **Abbruch:** kein unvollständiger Bewertungsdatensatz; ein vom Nutzer gespeichertes neues Erlebnis darf als Entwurf bestehen bleiben.
