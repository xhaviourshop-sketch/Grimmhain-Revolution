# Übergabe: Totenreichkarten und Kartenschlucker (Version 1, 01.10.2026)

**Stand:** Branch `feature/night-ui-expansion`, PR #3, kein Merge nach `main`. Alle 80 Karten (119 Varianten) und der Kartenschlucker sind
im Kern, im Spielaufbau und im Cockpit umgesetzt. Matrix: `docs/role-migration/15-totenkarten-umsetzungsmatrix.md`.

**Wo ansetzen:**
- Regeln: `godot/core/rules/card_catalog.gd` (Stammdaten), `card_rules.gd` (Fenster, Ziehung, Tausch), `card_effects.gd` (Verteiler und Effekte),
  `card_fx_*.gd` (Familien), `card_hooks.gd` und `card_lynch.gd` (Eingriffe in Tod, Nacht und Hinrichtung), `swallower_rules.gd`.
- Oberfläche: `godot/app/session/card_view.gd`, `prompt_view.gd`, `cockpit_view.gd`; `godot/app/screens/cockpit/action_card.gd`,
  `cockpit_screen.gd`, `cockpit_text.gd`, `cockpit_layers.gd`.
- Tests: `godot/tests/unit/test_cards_*.gd`, `test_swallower.gd`, `godot/tests/ui/test_cards_ui*.gd`; Hilfsklasse `godot/tests/card_game.gd`.
- Texte: `godot/content/i18n/ui.de.po` und `ui.en.po` (`ui.card.*`, `ui.cards.*`, Regelbuch `ui.rulebook.c13.*`).

**Entscheidungen:** `docs/masterplan/DECISION-LOG.md`, Abschnitt „Totenreichkarten und Kartenschlucker: Umsetzung (01.10.2026)“.
KS-106 bis KS-110 sind bestätigt und mit `test_cards_decisions` abgesichert.

**Regeln beim Weiterarbeiten:**
- Neue Besitzer von `PendingPrompt` in den Fuzz-Generator (`test_role_interaction_fuzz.gd`) und in `test_resume_every_command` aufnehmen.
- Neue Kartenwirkung: Familie in `card_fx_*.gd`, Katalogeintrag, Texte DE/EN (`name`, `text`, `guide`), Test in der Familiendatei; die
  Sammeltests (`play_all`, `invalid`, `public`) laufen automatisch über den Katalog.
- Zustände, die nur durch Rollenspiel entstehen, in Tests direkt setzen und dann nur Speichern und Laden prüfen (kein Replay).
- Nach `.po`-Änderungen `--import` ausführen, sonst fehlen Übersetzungen in den UI-Tests.

**Nicht geprüft:** Tablet, Touch, visuelle Abnahme, Audio. Kein Beweis der Fehlerfreiheit aller Kartenkombinationen.
