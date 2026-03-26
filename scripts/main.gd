extends Node2D

# ── Stage Layout ────────────────────────────────────────────────────────────
const BLAST_ZONE := Rect2(-500, -800, 2280, 1900)
const SPAWN_P1 := Vector2(480, 478)
const SPAWN_P2 := Vector2(800, 478)
const RESPAWN_DELAY := 2.0

# ── HUD Constants ───────────────────────────────────────────────────────────
const P1_BAR_LEFT := 240.0
const P1_BAR_RIGHT := 540.0
const P2_BAR_LEFT := 740.0
const P2_BAR_RIGHT := 1040.0
const BAR_MAX_WIDTH := 300.0
const BAR_INNER_TOP := 638.0    # Top edge at inner (center) side
const BAR_OUTER_TOP := 622.0    # Top edge at outer (screen edge) side
const BAR_BOTTOM := 660.0
const EFFECT_DURATION := 1.0
const SHAKE_DURATION := 0.35
const SHAKE_INTENSITY := 4.0

# ── Countdown Constants ────────────────────────────────────────────────────
const COUNTDOWN_DURATION := 3.0
const GO_LINGER := 0.8  # How long "GO!" stays visible after unfreeze

# ── Node References ─────────────────────────────────────────────────────────
@onready var player1: Bollard = $Player1
@onready var player2: Bollard = $Player2
@onready var p1_group: Control = $HUD/P1Group
@onready var p2_group: Control = $HUD/P2Group
@onready var p1_effect: Label = $HUD/P1Group/P1Effect
@onready var p2_effect: Label = $HUD/P2Group/P2Effect
@onready var p1_stock_label: Label = $HUD/P1Group/P1Stocks
@onready var p2_stock_label: Label = $HUD/P2Group/P2Stocks
@onready var game_over_label: Label = $HUD/GameOver
@onready var controls_label: Label = $HUD/Controls

# ── Bar Polygon2D (created at runtime) ──────────────────────────────────────
var p1_bar_bg: Polygon2D
var p1_bar_fill: Polygon2D
var p2_bar_bg: Polygon2D
var p2_bar_fill: Polygon2D

# ── Countdown Label (created at runtime) ───────────────────────────────────
var countdown_label: Label

# ── Game State ──────────────────────────────────────────────────────────────
var game_active: bool = false
var countdown_active: bool = true
var countdown_timer: float = 0.0
var controls_visible_timer: float = 0.0
var prev_p1_dmg: float = 0.0
var prev_p2_dmg: float = 0.0
var p1_effect_timer: float = 0.0
var p2_effect_timer: float = 0.0
var p1_shake_timer: float = 0.0
var p2_shake_timer: float = 0.0


func _ready() -> void:
	_setup_input()
	_create_bar_polygons()
	_create_countdown_label()
	player1.global_position = SPAWN_P1
	player2.global_position = SPAWN_P2
	player2.ai_target = player1
	game_over_label.visible = false
	controls_label.visible = true
	p1_effect.visible = false
	p2_effect.visible = false
	_start_countdown()


func _create_bar_polygons() -> void:
	p1_bar_bg = Polygon2D.new()
	p1_bar_bg.color = Color(0.15, 0.15, 0.15, 0.8)
	p1_bar_bg.polygon = PackedVector2Array([
		Vector2(P1_BAR_LEFT, BAR_OUTER_TOP),
		Vector2(P1_BAR_RIGHT, BAR_INNER_TOP),
		Vector2(P1_BAR_RIGHT, BAR_BOTTOM),
		Vector2(P1_BAR_LEFT, BAR_BOTTOM)])
	p1_group.add_child(p1_bar_bg)

	p1_bar_fill = Polygon2D.new()
	p1_bar_fill.color = Color(0.3, 0.8, 0.3)
	p1_group.add_child(p1_bar_fill)

	p2_bar_bg = Polygon2D.new()
	p2_bar_bg.color = Color(0.15, 0.15, 0.15, 0.8)
	p2_bar_bg.polygon = PackedVector2Array([
		Vector2(P2_BAR_LEFT, BAR_INNER_TOP),
		Vector2(P2_BAR_RIGHT, BAR_OUTER_TOP),
		Vector2(P2_BAR_RIGHT, BAR_BOTTOM),
		Vector2(P2_BAR_LEFT, BAR_BOTTOM)])
	p2_group.add_child(p2_bar_bg)

	p2_bar_fill = Polygon2D.new()
	p2_bar_fill.color = Color(0.3, 0.8, 0.3)
	p2_group.add_child(p2_bar_fill)


func _create_countdown_label() -> void:
	countdown_label = Label.new()
	countdown_label.add_theme_font_size_override("font_size", 72)
	countdown_label.add_theme_color_override("font_color", Color(1, 1, 1))
	countdown_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	countdown_label.add_theme_constant_override("shadow_offset_x", 3)
	countdown_label.add_theme_constant_override("shadow_offset_y", 3)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.offset_left = 340.0
	countdown_label.offset_top = 200.0
	countdown_label.offset_right = 940.0
	countdown_label.offset_bottom = 340.0
	countdown_label.visible = false
	$HUD.add_child(countdown_label)


func _start_countdown() -> void:
	countdown_active = true
	countdown_timer = 0.0
	game_active = false
	countdown_label.visible = true
	countdown_label.text = ""
	# Freeze both players
	player1.is_frozen = true
	player2.is_frozen = true


func _update_countdown(delta: float) -> void:
	countdown_timer += delta

	if countdown_timer < 1.0:
		countdown_label.text = "es"
		countdown_label.add_theme_font_size_override("font_size", 64)
		countdown_label.add_theme_color_override("font_color", Color(1, 1, 1))
	elif countdown_timer < 2.0:
		countdown_label.text = "car"
		countdown_label.add_theme_font_size_override("font_size", 64)
		countdown_label.add_theme_color_override("font_color", Color(1, 1, 1))
	elif countdown_timer < COUNTDOWN_DURATION:
		countdown_label.text = "GO!"
		countdown_label.add_theme_font_size_override("font_size", 96)
		countdown_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
		# Unfreeze players the moment GO appears
		if player1.is_frozen:
			player1.is_frozen = false
			player2.is_frozen = false
			game_active = true
	else:
		# Countdown fully done — hide label
		countdown_active = false
		countdown_label.visible = false


func _physics_process(delta: float) -> void:
	if countdown_active:
		_update_countdown(delta)
		# Still update HUD during countdown
		_update_hud()
		controls_visible_timer += delta
		if controls_visible_timer > 8.0 and controls_label.visible:
			controls_label.visible = false
		return

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
	_start_countdown()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and not game_active and not countdown_active:
			_restart_game()
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ DAMAGE EFFECTS + SHAKE                                                  ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _check_damage_effects(delta: float) -> void:
	var d1 := player1.damage_percent
	var d2 := player2.damage_percent

	if d1 > prev_p1_dmg + 0.1:
		p1_shake_timer = SHAKE_DURATION
	if d2 > prev_p2_dmg + 0.1:
		p2_shake_timer = SHAKE_DURATION

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

	if p1_effect_timer > 0.0:
		p1_effect_timer -= delta
		if p1_effect_timer <= 0.0:
			p1_effect.visible = false
	if p2_effect_timer > 0.0:
		p2_effect_timer -= delta
		if p2_effect_timer <= 0.0:
			p2_effect.visible = false

	if p1_shake_timer > 0.0:
		p1_shake_timer -= delta
	if p2_shake_timer > 0.0:
		p2_shake_timer -= delta


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ HUD — trapezoid damage bars + stocks + shake                            ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_hud() -> void:
	# P1 bar fills RIGHT to LEFT (toward screen edge = taller side)
	var p1_pct := clampf(player1.damage_percent / 150.0, 0.0, 1.0)
	if p1_pct > 0.005:
		var fill_left: float = P1_BAR_RIGHT - p1_pct * BAR_MAX_WIDTH
		var t_left: float = (fill_left - P1_BAR_LEFT) / BAR_MAX_WIDTH
		var top_at_left: float = lerpf(BAR_OUTER_TOP, BAR_INNER_TOP, t_left)
		p1_bar_fill.polygon = PackedVector2Array([
			Vector2(fill_left, top_at_left),
			Vector2(P1_BAR_RIGHT, BAR_INNER_TOP),
			Vector2(P1_BAR_RIGHT, BAR_BOTTOM),
			Vector2(fill_left, BAR_BOTTOM)])
		p1_bar_fill.color = _damage_color(player1.damage_percent)
	else:
		p1_bar_fill.polygon = PackedVector2Array()

	# P2 bar fills LEFT to RIGHT (toward screen edge = taller side)
	var p2_pct := clampf(player2.damage_percent / 150.0, 0.0, 1.0)
	if p2_pct > 0.005:
		var fill_right: float = P2_BAR_LEFT + p2_pct * BAR_MAX_WIDTH
		var t_right: float = (fill_right - P2_BAR_LEFT) / BAR_MAX_WIDTH
		var top_at_right: float = lerpf(BAR_INNER_TOP, BAR_OUTER_TOP, t_right)
		p2_bar_fill.polygon = PackedVector2Array([
			Vector2(P2_BAR_LEFT, BAR_INNER_TOP),
			Vector2(fill_right, top_at_right),
			Vector2(fill_right, BAR_BOTTOM),
			Vector2(P2_BAR_LEFT, BAR_BOTTOM)])
		p2_bar_fill.color = _damage_color(player2.damage_percent)
	else:
		p2_bar_fill.polygon = PackedVector2Array()

	# Stocks
	p1_stock_label.text = _stock_display(player1.stocks)
	p2_stock_label.text = _stock_display(player2.stocks)

	# Shake
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

	# Controller P1: left stick = spin, right stick = extend/lower
	_add_joy_axis("p1_lean_left",  JOY_AXIS_LEFT_X, -1.0, 0)
	_add_joy_axis("p1_lean_right", JOY_AXIS_LEFT_X,  1.0, 0)
	_add_joy_axis("p1_raise",      JOY_AXIS_RIGHT_Y, -1.0, 0)
	_add_joy_axis("p1_lower",      JOY_AXIS_RIGHT_Y,  1.0, 0)
	_add_joy_button("p1_grab",     JOY_BUTTON_RIGHT_SHOULDER, 0)
	_add_joy_button("p1_grab",     JOY_BUTTON_A, 0)

	_add_key("p2_lean_left",  KEY_LEFT)
	_add_key("p2_lean_right", KEY_RIGHT)
	_add_key("p2_raise",      KEY_UP)
	_add_key("p2_lower",      KEY_DOWN)
	_add_key("p2_grab",       KEY_SLASH)

	# Controller P2: left stick = spin, right stick = extend/lower
	_add_joy_axis("p2_lean_left",  JOY_AXIS_LEFT_X, -1.0, 1)
	_add_joy_axis("p2_lean_right", JOY_AXIS_LEFT_X,  1.0, 1)
	_add_joy_axis("p2_raise",      JOY_AXIS_RIGHT_Y, -1.0, 1)
	_add_joy_axis("p2_lower",      JOY_AXIS_RIGHT_Y,  1.0, 1)
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
