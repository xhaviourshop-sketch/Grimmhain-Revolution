class_name Phase
extends RefCounted
## Spielphasen (03 §4.3) und Unterzustände des Tages.

const SETUP := &"SETUP"
const NIGHT := &"NIGHT"
const DAWN_RESOLUTION := &"DAWN_RESOLUTION"
const DAY := &"DAY"
const GAME_OVER := &"GAME_OVER"

const ALL: Array[StringName] = [SETUP, NIGHT, DAWN_RESOLUTION, DAY, GAME_OVER]

## Tages-Unterzustände. AFTERMATH (Reaktionen) folgt mit der Reaktionswarteschlange (B-06).
## ENDED markiert „Tag beendet, nächste Nacht darf beginnen“ bis StartNight.
const DAY_NONE := &""
const DAY_DISCUSSION := &"DISCUSSION"
const DAY_NOMINATION := &"NOMINATION"
const DAY_EXECUTION_DECIDED := &"EXECUTION_DECIDED"
const DAY_ENDED := &"ENDED"

const ALL_DAY_STEPS: Array[StringName] = [DAY_NONE, DAY_DISCUSSION, DAY_NOMINATION, DAY_EXECUTION_DECIDED, DAY_ENDED]
