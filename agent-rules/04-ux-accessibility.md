# UX und Barrierefreiheit

Barrierefreiheit ist Bestandteil jeder einzelnen GUI-Story und keine ausschließlich nachgelagerte Querschnittsaufgabe. Eine spätere Barrierefreiheitsstory dient der systematischen Gesamtprüfung und Vervollständigung, darf aber nicht als Begründung verwendet werden, um ohne Spezialwerkzeuge umsetzbare Grundlagen zu verschieben.

## In jeder GUI-Story sofort verpflichtend

Die folgenden Anforderungen müssen zusammen mit dem jeweiligen Screen geplant, implementiert und soweit automatisierbar getestet werden. Eine GUI-Story darf ohne sie nicht als fachlich fertig gemeldet oder geschlossen werden:

- Interaktive Elemente erhalten verständliche sichtbare Bezeichnungen oder eindeutige semantische Beschriftungen. Symbolschaltflächen erhalten insbesondere einen verständlichen Tooltip beziehungsweise ein Semantics-Label.
- Touch-Ziele werden ausreichend groß ausgelegt; primäre Aktionen bleiben mit Abstand zu Bildschirmrand, Systemgesten, Bildschirmtastatur und temporären Meldungen erreichbar.
- Layouts verwenden scroll- und umbruchfähige Strukturen. Große Systemschrift und kleine Android-Bildschirme dürfen keine Kerninhalte abschneiden, überlagern oder Aktionen unerreichbar machen.
- Information wird nie ausschließlich über Farbe, Position, Form oder ein unbeschriftetes Symbol vermittelt.
- Lade-, Leer-, Erfolgs- und Fehlerzustände werden verständlich und semantisch wahrnehmbar umgesetzt. Fortschrittsanzeigen erhalten einen zugänglichen Zweck; leere Zustände bieten eine sinnvolle nächste Aktion; behebbare Fehler bieten einen erneuten Versuch.
- Nutzereingaben und Entwürfe bleiben bei Validierungs-, Persistenz- und Navigationsfehlern erhalten.
- Validierungsfehler erscheinen am Feld und zusätzlich in einem fokussierbaren Fehlersammler am Inhaltsanfang. Dessen Einträge führen zum zugehörigen Feld.
- Nach fehlgeschlagener Validierung werden eine kurze wahrnehmbare Meldung sowie Fokus und Scrollposition zum Fehlersammler beziehungsweise ersten Fehler bewegt.
- Erfolgreiche, fehlgeschlagene und noch laufende Aktionen erhalten eine verständliche Rückmeldung; deaktivierte Aktionen bleiben in ihrem Zustand erklärbar.
- Fokusreihenfolge und Tastaturaktivierung werden bereits in der Widgetstruktur sinnvoll angelegt. Offensichtliche Fokusfallen und ausschließlich gestenbasierte Bedienwege sind unzulässig.
- Eingabefelder erhalten fachlich begründete Maximallängen. Zeichenzähler und barrierefreie Grenzrückmeldung werden in der jeweiligen Story konkretisiert.
- In scrollbaren oder lazy aufgebauten Formularen darf die vollständige fachliche Validierung nicht ausschließlich von `FormState.validate()` oder aktuell gemounteten `FormField`-Widgets abhängen. Außerhalb des Viewports liegende Felder können aus dem Widgetbaum entfernt sein. Die Speicherlogik prüft daher alle relevanten Controller- beziehungsweise Modellwerte unabhängig vom Sichtbereich; Feldvalidatoren dienen zusätzlich der lokalen Fehleranzeige. Widgettests lösen die Speicheraktion auch vom Formularende aus und weisen nach, dass Fehler in nicht sichtbaren Feldern erkannt werden.
- Widgettests für lazy aufgebaute Scrollbereiche unterscheiden verbindlich zwischen Sichtbarkeit und Existenz im Widgetbaum: `ensureVisible()` darf nur für bereits gemountete Widgets verwendet werden. Kann das Ziel außerhalb des Viewports noch nicht aufgebaut sein, muss der Test den zugehörigen `Scrollable` mit `scrollUntilVisible()`, kontrollierten Drag-Schritten oder einem gleichwertigen Verfahren scrollen, bis das Ziel erzeugt und sichtbar ist. Erst danach darf der Finder dereferenziert oder das Widget aktiviert werden.
- Wird ein Fehlersammler am Anfang eines lazy aufgebauten Formulars erst nach der Validierung eingefügt, darf die Navigation nicht allein von dessen `BuildContext` oder `GlobalKey.currentContext` abhängen: Das Ziel kann außerhalb des Viewports noch ungemountet sein. Das Formular steuert seinen Scrollbereich über einen `ScrollController` zunächst an den Anfang, wartet den Aufbau des folgenden Frames ab und setzt erst danach den Fokus auf den Fehlersammler.
- Für diese Grundlagen werden passende Widget- und Semantiktests ergänzt, soweit Flutter sie automatisiert prüfen kann.

Fehlendes Flutter-SDK, fehlender Emulator oder fehlendes Testgerät rechtfertigen nicht das Weglassen dieser Implementierungen. Nicht ausführbare Prüfungen werden benannt, die zugrunde liegenden Anforderungen aber trotzdem im Code umgesetzt.

## Gebündelt prüfbare Querschnittsanforderungen

Folgende Prüfungen dürfen in einer eigenen Barrierefreiheitsstory über alle bis dahin vorhandenen Screens gebündelt werden, weil sie reale Plattformen, Assistenztechnik oder eine konsistente Gesamtschau benötigen:

- manuelle Bedienung der vollständigen Kernabläufe mit TalkBack auf Android,
- manuelle Prüfung extremer Systemschriftgrößen und Display-Skalierungen auf repräsentativen Geräten,
- durchgängige Tastatur- und Fokusprüfung unter Windows und Linux,
- systematische Kontrastmessung aller verwendeten Farbkombinationen und Zustände,
- Prüfung der Screenreader-Reihenfolge, Live-Regionen und gesprochenen Rückmeldungen im realen Zusammenspiel,
- Prüfung auf konsistente Navigation und unerwartete Fokusverluste über Screen-Grenzen hinweg,
- dauerhaft erreichbare Barrierefreiheitserklärung und abschließende dokumentierte Prüfliste vor dem ersten öffentlichen Release.

Eine gebündelte Prüfung darf neue Befunde erzeugen und Nachbesserungen verlangen. Sie ersetzt weder die sofortigen Anforderungen noch deren Prüfung innerhalb der jeweiligen GUI-Story.
