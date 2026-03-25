extends Node2D
## Main game controller. Manages input setup, blast zone KOs, respawning,
## game flow, and HUD updates.

# ── Stage Layout ────────────────────────────────────────────────────────────
## Blast zone: if a bollard leaves this rectangle, they lose a stock.
## It's intentionally much larger than the visible area so players "fly off screen."
const BLAST_ZONE := Rect2(-400, -700, 1824, 1500)

## Spawn positions — ground surface is at y=400, bollard origin is at the
## base circle center (22px above ground contact), so spawn y = 400 - 22 = 378
const SPAWN_P1 := Vector2(400, 378)
const SPAWN_P2 := Vector2(624, 378)

## Delay before a KO'd player respawns
const RESPAWN_DELAY := 2.0

# ── Node References ─────────────────────────────────────────────────────────
@onready var player1: Bollard = $Player1
@onready var player2: Bollard = $Player2
@onready var p1_damage_label: Label = $HUD/P1Panel/P1VBox/P1Damage
@onready var p2_damage_label: Label = $HUD/P2Panel/P2VBox/P2Damage
@onready var p1_stock_label: Label = $HUD/P1Panel/P1VBox/P1Stocks
@onready var p2_stock_label: Label = $HUD/P2Panel/P2VBox/P2Stocks
@onready var game_over_label: Label = $HUD/GameOver
@onready var controls_label: Label = $HUD/Controls

# ── Game State ──────────────────────────────────────────────────────────────
var game_active: bool = true
var controls_visible_timer: float = 0.0


func _ready() -> void:
	_setup_input()
	player1.global_position = SPAWN_P1
	player2.global_position = SPAWN_P2
	player2.ai_target = player1
	game_over_label.visible = false
	controls_label.visible = true


func _physics_process(delta: float) -> void:
	if not game_active:
		return

	_check_blast_zone(player1)
	_check_blast_zone(player2)
	_handle_respawn(player1, SPAWN_P1, delta)
	_handle_respawn(player2, SPAWN_P2, delta)
	_update_hud()

	# Auto-hide controls hint after 8 seconds
	controls_visible_timer += delta
	if controls_visible_timer > 8.0 and controls_label.visible:
		controls_label.visible = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BLAST ZONE — KO when a player flies off the stage                       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _check_blast_zone(player: Bollard) -> void:
	if player.is_dead:
		return
	if not BLAST_ZONE.has_point(player.global_position):
		player.die()
		if player.stocks <= 0:
			_end_game(player)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ RESPAWN                                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _handle_respawn(player: Bollard, spawn_pos: Vector2, delta: float) -> void:
	if not player.is_dead or player.stocks <= 0:
		return

	# Track respawn timer via metadata on the node
	if not player.has_meta("respawn_timer"):
		player.set_meta("respawn_timer", 0.0)
		player.visible = false
		# Stop all motion while dead
		player.linear_velocity = Vector2.ZERO
		player.angular_velocity = 0.0

	var t: float = player.get_meta("respawn_timer") + delta
	player.set_meta("respawn_timer", t)

	if t >= RESPAWN_DELAY:
		player.remove_meta("respawn_timer")
		player.visible = true
		player.respawn(spawn_pos)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ GAME FLOW                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _end_game(loser: Bollard) -> void:
	game_active = false
	var winner_name := "Player 1" if loser == player2 else "Player 2 (AI)"
	game_over_label.text = winner_name + " WINS!\n\nPress R to restart"
	game_over_label.visible = true


func _restart_game() -> void:
	game_active = true
	game_over_label.visible = false
	controls_label.visible = true
	controls_visible_timer = 0.0
	for p: Bollard in [player1, player2]:
		p.stocks = 3
		p.visible = true
		if p.has_meta("respawn_timer"):
			p.remove_meta("respawn_timer")
	player1.respawn(SPAWN_P1)
	player2.respawn(SPAWN_P2)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and not game_active:
			_restart_game()
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ HUD                                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_hud() -> void:
	p1_damage_label.text = "%d%%" % int(player1.damage_percent)
	p2_damage_label.text = "%d%%" % int(player2.damage_percent)

	# Show stocks as filled/empty circles
	p1_stock_label.text = _stock_display(player1.stocks)
	p2_stock_label.text = _stock_display(player2.stocks)

	# Color the damage text: white → yellow → red as damage increases
	p1_damage_label.modulate = _damage_color(player1.damage_percent)
	p2_damage_label.modulate = _damage_color(player2.damage_percent)


func _stock_display(count: int) -> String:
	var s := ""
	for i in 3:
		s += "O " if i < count else "X "
	return s.strip_edges()


func _damage_color(pct: float) -> Color:
	if pct < 50.0:
		return Color.WHITE
	elif pct < 100.0:
		return Color.YELLOW
	elif pct < 150.0:
		return Color.ORANGE
	else:
		return Color.RED


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ INPUT SETUP — register all actions programmatically                      ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _setup_input() -> void:
	# Player 1: WASD to move, E to grab
	_add_key("p1_lean_left",  KEY_A)
	_add_key("p1_lean_right", KEY_D)
	_add_key("p1_raise",      KEY_W)
	_add_key("p1_lower",      KEY_S)
	_add_key("p1_grab",       KEY_E)

	# Player 2: Arrow keys + / (slash) to grab
	# (Used for local multiplayer — AI ignores these)
	_add_key("p2_lean_left",  KEY_LEFT)
	_add_key("p2_lean_right", KEY_RIGHT)
	_add_key("p2_raise",      KEY_UP)
	_add_key("p2_lower",      KEY_DOWN)
	_add_key("p2_grab",       KEY_SLASH)


func _add_key(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action_name, ev)
