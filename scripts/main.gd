extends Node2D

# ── Stage Layout ────────────────────────────────────────────────────────────
const BLAST_ZONE := Rect2(-500, -800, 2280, 1900)
const SPAWN_P1 := Vector2(480, 478)
const SPAWN_P2 := Vector2(800, 478)
const RESPAWN_DELAY := 2.0

# ── HUD Constants ───────────────────────────────────────────────────────────
const P1_BAR_RIGHT := 270.0
const P1_BAR_LEFT := 70.0
const P2_BAR_LEFT := 1010.0
const P2_BAR_RIGHT := 1210.0
const BAR_MAX_WIDTH := 200.0
const EFFECT_DURATION := 1.0
const SHAKE_DURATION := 0.35
const SHAKE_INTENSITY := 4.0

# ── Node References ─────────────────────────────────────────────────────────
@onready var player1: Bollard = $Player1
@onready var player2: Bollard = $Player2
@onready var p1_group: Control = $HUD/P1Group
@onready var p2_group: Control = $HUD/P2Group
@onready var p1_bar_fill: ColorRect = $HUD/P1Group/P1BarFill
@onready var p2_bar_fill: ColorRect = $HUD/P2Group/P2BarFill
@onready var p1_effect: Label = $HUD/P1Group/P1Effect
@onready var p2_effect: Label = $HUD/P2Group/P2Effect
@onready var p1_stock_label: Label = $HUD/P1Group/P1Stocks
@onready var p2_stock_label: Label = $HUD/P2Group/P2Stocks
@onready var game_over_label: Label = $HUD/GameOver
@onready var controls_label: Label = $HUD/Controls

# ── Game State ──────────────────────────────────────────────────────────────
var game_active: bool = true
var controls_visible_timer: float = 0.0
var prev_p1_dmg: float = 0.0
var prev_p2_dmg: float = 0.0
var p1_effect_timer: float = 0.0
var p2_effect_timer: float = 0.0
var p1_shake_timer: float = 0.0
var p2_shake_timer: float = 0.0


func _ready() -> void:
	_setup_input()
	player1.global_position = SPAWN_P1
	player2.global_position = SPAWN_P2
	player2.ai_target = player1
	game_over_label.visible = false
	controls_label.visible = true
	p1_effect.visible = false
	p2_effect.visible = false


func _physics_process(delta: float) -> void:
	if not game_active:
		return
	_check_blast_zone(player1)
	_check_blast_zone(player2)
	_handle_respawn(player1, SPAWN_P1, delta)
	_handle_respawn(player2, SPAWN_P2, delta)
	_check_damage_effects(delta)
	_update_hud()

	controls_visible_timer += delta
	if controls_visible_timer > 8.0 and controls_label.visible:
		controls_label.visible = false


func _check_blast_zone(player: Bollard) -> void:
	if player.is_dead:
		return
	if not BLAST_ZONE.has_point(player.global_position):
		player.die()
		if player.stocks <= 0:
			_end_game(player)


func _handle_respawn(player: Bollard, spawn_pos: Vector2, delta: float) -> void:
	if not player.is_dead or player.stocks <= 0:
		return
	if not player.has_meta("respawn_timer"):
		player.set_meta("respawn_timer", 0.0)
		player.visible = false
		player.linear_velocity = Vector2.ZERO
		player.angular_velocity = 0.0
	var t: float = player.get_meta("respawn_timer") + delta
	player.set_meta("respawn_timer", t)
	if t >= RESPAWN_DELAY:
		player.remove_meta("respawn_timer")
		player.visible = true
		player.respawn(spawn_pos)


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
	prev_p1_dmg = 0.0
	prev_p2_dmg = 0.0
	p1_effect.visible = false
	p2_effect.visible = false
	p1_shake_timer = 0.0
	p2_shake_timer = 0.0
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
# ║ DAMAGE EFFECTS + SHAKE                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _check_damage_effects(delta: float) -> void:
	var d1 := player1.damage_percent
	var d2 := player2.damage_percent

	# Detect ANY new damage → trigger shake
	if d1 > prev_p1_dmg + 0.1:
		p1_shake_timer = SHAKE_DURATION
	if d2 > prev_p2_dmg + 0.1:
		p2_shake_timer = SHAKE_DURATION

	# Threshold popups
	if d1 >= 100.0 and prev_p1_dmg < 100.0:
		p1_effect.text = "CRITICAL!"
		p1_effect.visible = true
		p1_effect_timer = EFFECT_DURATION
	elif d1 >= 50.0 and prev_p1_dmg < 50.0:
		p1_effect.text = "OOF!"
		p1_effect.visible = true
		p1_effect_timer = EFFECT_DURATION

	if d2 >= 100.0 and prev_p2_dmg < 100.0:
		p2_effect.text = "CRITICAL!"
		p2_effect.visible = true
		p2_effect_timer = EFFECT_DURATION
	elif d2 >= 50.0 and prev_p2_dmg < 50.0:
		p2_effect.text = "OOF!"
		p2_effect.visible = true
		p2_effect_timer = EFFECT_DURATION

	prev_p1_dmg = d1
	prev_p2_dmg = d2

	# Tick effect timers
	if p1_effect_timer > 0.0:
		p1_effect_timer -= delta
		if p1_effect_timer <= 0.0:
			p1_effect.visible = false
	if p2_effect_timer > 0.0:
		p2_effect_timer -= delta
		if p2_effect_timer <= 0.0:
			p2_effect.visible = false

	# Tick shake timers
	if p1_shake_timer > 0.0:
		p1_shake_timer -= delta
	if p2_shake_timer > 0.0:
		p2_shake_timer -= delta


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ HUD — damage bars + stocks + shake                                      ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_hud() -> void:
	# P1 bar fills RIGHT to LEFT
	var p1_fill_w: float = (player1.damage_percent / 100.0) * BAR_MAX_WIDTH
	p1_bar_fill.offset_right = P1_BAR_RIGHT
	p1_bar_fill.offset_left = P1_BAR_RIGHT - p1_fill_w
	p1_bar_fill.color = _damage_color(player1.damage_percent)

	# P2 bar fills LEFT to RIGHT
	var p2_fill_w: float = (player2.damage_percent / 100.0) * BAR_MAX_WIDTH
	p2_bar_fill.offset_left = P2_BAR_LEFT
	p2_bar_fill.offset_right = P2_BAR_LEFT + p2_fill_w
	p2_bar_fill.color = _damage_color(player2.damage_percent)

	# Stocks
	p1_stock_label.text = _stock_display(player1.stocks)
	p2_stock_label.text = _stock_display(player2.stocks)

	# Shake — offset the entire HUD group
	if p1_shake_timer > 0.0:
		p1_group.position = Vector2(
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY),
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY))
	else:
		p1_group.position = Vector2.ZERO

	if p2_shake_timer > 0.0:
		p2_group.position = Vector2(
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY),
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY))
	else:
		p2_group.position = Vector2.ZERO


func _stock_display(count: int) -> String:
	var s := ""
	for i in 3:
		s += "O " if i < count else "X "
	return s.strip_edges()


func _damage_color(pct: float) -> Color:
	if pct < 40.0:
		return Color(0.3, 0.8, 0.3)
	elif pct < 80.0:
		return Color(0.9, 0.8, 0.2)
	elif pct < 120.0:
		return Color(0.9, 0.5, 0.1)
	else:
		return Color(0.9, 0.15, 0.15)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ INPUT SETUP — keyboard + controller                                      ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _setup_input() -> void:
	_add_key("p1_lean_left",  KEY_A)
	_add_key("p1_lean_right", KEY_D)
	_add_key("p1_raise",      KEY_W)
	_add_key("p1_lower",      KEY_S)
	_add_key("p1_grab",       KEY_E)

	_add_joy_axis("p1_lean_left",  JOY_AXIS_LEFT_X, -1.0, 0)
	_add_joy_axis("p1_lean_right", JOY_AXIS_LEFT_X,  1.0, 0)
	_add_joy_axis("p1_raise",      JOY_AXIS_LEFT_Y, -1.0, 0)
	_add_joy_axis("p1_lower",      JOY_AXIS_LEFT_Y,  1.0, 0)
	_add_joy_button("p1_grab",     JOY_BUTTON_RIGHT_SHOULDER, 0)
	_add_joy_button("p1_grab",     JOY_BUTTON_A, 0)

	_add_key("p2_lean_left",  KEY_LEFT)
	_add_key("p2_lean_right", KEY_RIGHT)
	_add_key("p2_raise",      KEY_UP)
	_add_key("p2_lower",      KEY_DOWN)
	_add_key("p2_grab",       KEY_SLASH)

	_add_joy_axis("p2_lean_left",  JOY_AXIS_LEFT_X, -1.0, 1)
	_add_joy_axis("p2_lean_right", JOY_AXIS_LEFT_X,  1.0, 1)
	_add_joy_axis("p2_raise",      JOY_AXIS_LEFT_Y, -1.0, 1)
	_add_joy_axis("p2_lower",      JOY_AXIS_LEFT_Y,  1.0, 1)
	_add_joy_button("p2_grab",     JOY_BUTTON_RIGHT_SHOULDER, 1)
	_add_joy_button("p2_grab",     JOY_BUTTON_A, 1)

	for action in ["p1_lean_left", "p1_lean_right", "p1_raise", "p1_lower",
					"p2_lean_left", "p2_lean_right", "p2_raise", "p2_lower"]:
		InputMap.action_set_deadzone(action, 0.3)

func _add_key(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action_name, ev)

func _add_joy_axis(action_name: String, axis: int, direction: float, device: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = direction
	ev.device = device
	InputMap.action_add_event(action_name, ev)

func _add_joy_button(action_name: String, button: int, device: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = device
	InputMap.action_add_event(action_name, ev)
