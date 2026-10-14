extends UiTestCase
## Absturz im Web-Export: Nachts kam der erste Fledermausschwarm vor jeder Tagesansicht, die Flugwurzel fehlte noch und die
## Hauptschleife brach ab (Bedienung tot, Musik lief weiter). Der Schwarm muss nachts aus dem Wartezeit-Timer starten können.


func test_first_flock_can_start_at_night_without_a_day_view() -> void:
	var life := VillageLife.new()
	life.map = VillageMap.new()
	life.night = true
	life.enabled = true
	life.reduced = false
	tree.root.add_child(life)
	_spawned.append(life)
	await frames(2)
	life._on_timer()
	assert_true(life._flock_active(), "Schwarm läuft in der Nacht, ohne dass vorher ein Tag gezeigt wurde")
	assert_true(life._flock_root != null and life._bat_frames.size() == 6, "Flugwurzel und Fledermaus-Bilder sind aufgebaut")
