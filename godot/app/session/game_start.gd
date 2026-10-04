class_name GameStart
extends RefCounted
## Schmaler Übergang vom Setup-Entwurf zur Partie: baut aus `PlayerSetup.prepare_start()` (verteilt im Modus „zufällig“ jetzt)
## genau einen StartGame-Befehl und reicht ihn über GameSession an den Regelkern. Keine eigene
## Regelprüfung: Annahme oder Ablehnung entscheidet allein der Regelkern.
##
## Zuordnung: immer `assignment = "manual"` mit der im Setup festgelegten Rolle je Personen-ID und
## den ausdrücklich gewählten Scheinrollen (`appearances`). Beim Start wird nicht erneut gemischt,
## auch wenn die Verteilung im Setup zufällig entstand (Modus „App verteilt zufällig“).
## Die Rollenaufdeckung ist keine Setup-Option mehr (DI-01): Der Regelkern leitet die Wiederbelebungsrunde
## beim Start aus der Besetzung ab; der Befehl trägt keine Aufdeckungsangabe.
## Seed: ein neuer Wert aus `PlayerSetup.seed_source` (Standard AppPlatform.initial_seed, in Tests
## fest). round_id: nur aus dem Seed abgeleitet (`round_id_for`), damit gleiche Eingaben denselben
## Befehl ergeben.

const ROUND_ID_PREFIX := "grimmhain-round:"


## Startet die Partie aus dem Setup. Bei Annahme ist der Entwurf verbraucht und wird verworfen,
## sodass derselbe Entwurf keine zweite Partie starten kann. Bei Ablehnung (Setup unvollständig
## oder Regelkern) bleiben Namen und Rollenwahl und die Sitzung unverändert (im Modus „zufällig“ steht danach die Zuordnung im Entwurf).
## Ergebnis: {ok: bool, error: StringName}.
static func start(session: GameSession, setup: PlayerSetup) -> Dictionary:
	var data := setup.prepare_start()
	if not data.ok:
		return {"ok": false, "error": data.error}
	var seed_value := int(setup.seed_source.call())
	var result := session.submit(build_command(data.details, seed_value))
	if not result.ok:
		return {"ok": false, "error": result.error}
	setup.reset()
	return {"ok": true, "error": &""}


## StartGame-Befehl aus reinen Startdaten (siehe `PlayerSetup.start_data`) und Seed.
static func build_command(data: Dictionary, seed_value: int) -> Command:
	var payload := {
		"round_id": round_id_for(seed_value),
		"seed": seed_value,
		"assignment": "manual",
		"players": data["players"],
		"seat_order": data["seat_order"],
		"roles": data["roles"],
	}
	if not (data["appearances"] as Dictionary).is_empty():
		payload["appearances"] = data["appearances"]
	if bool(data.get("death_cards", false)):
		payload["death_cards"] = true
	return Command.start_game(payload)


## round_id im UUID-Format (8-4-4-4-12 Hex-Zeichen): die ersten 32 Zeichen von
## SHA-256("grimmhain-round:<seed>"). Deterministisch; verschiedene Seeds ergeben praktisch
## immer verschiedene IDs.
static func round_id_for(seed_value: int) -> String:
	var h := (ROUND_ID_PREFIX + str(seed_value)).sha256_text()
	return "%s-%s-%s-%s-%s" % [h.substr(0, 8), h.substr(8, 4), h.substr(12, 4), h.substr(16, 4), h.substr(20, 12)]
