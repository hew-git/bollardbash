extends Node2D

# ── Stage Layout ────────────────────────────────────────────────────────────
const BLAST_ZONE := Rect2(-500, -800, 2280, 1900)
const SPAWN_P1 := Vector2(450, 478)
const SPAWN_P2 := Vector2(830, 478)
const RESPAWN_DELAY := 2.0

# ── Arena Geometry ──────────────────────────────────────────────────────────
const GROUND_HALF_WIDTH := 495.0   # 990 total (10% less than 1100)
const GROUND_CURVE := 10.0         # Edges raised 10px above center
const GROUND_SEGMENTS := 20
const GROUND_Y := 520.0
const CENTER_CIRCLE_POS := Vector2(640, 190)
const CENTER_CIRCLE_RADIUS := 30.0
const WALL_WIDTH := 20.0
const WALL_HEIGHT := 200.0
const WALL_LEFT_X := 30.0
const WALL_RIGHT_X := 1250.0
const WALL_Y := 300.0

# ── HUD Constants ───────────────────────────────────────────────────────────
const P1_BAR_LEFT := 240.0
const P1_BAR_RIGHT := 540.0
const P2_BAR_LEFT := 740.0
const P2_BAR_RIGHT := 1040.0
const BAR_MAX_WIDTH := 300.0
const BAR_INNER_TOP := 638.0
const BAR_OUTER_TOP := 622.0
const BAR_BOTTOM := 660.0
const EFFECT_DURATION := 1.0
const SHAKE_DURATION := 0.35
const SHAKE_INTENSITY := 4.0

# ── Countdown ───────────────────────────────────────────────────────────────
const GO_LINGER := 0.8

# ── Death Phrases ───────────────────────────────────────────────────────────
const DEATH_PHRASES := [
	"you just got SLIMED, son",
	"get shellacked",
	"mollusk up, buddy",
	"looks like slime time is over",
	"more like escar-GONE",
	"you ooze, you lose",
]
const DEATH_PHRASE_DURATION := 2.5

# ── Slime Trail ─────────────────────────────────────────────────────────────
const SLIME_LIFETIME := 4.0
const SLIME_INTERVAL := 0.08
const SLIME_MAX_DOTS := 400

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
@onready var ground: StaticBody2D = $Ground
@onready var center_circle: StaticBody2D = $CenterCircle

# ── Bar Polygon2D (created at runtime) ──────────────────────────────────────
var p1_bar_bg: Polygon2D
var p1_bar_fill: Polygon2D
var p2_bar_bg: Polygon2D
var p2_bar_fill: Polygon2D

# ── Countdown Label (created at runtime) ───────────────────────────────────
var countdown_label: Label

# ── Death Phrase Label ──────────────────────────────────────────────────────
var death_phrase_label: Label
var death_phrase_timer: float = 0.0

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

# ── Slime State ─────────────────────────────────────────────────────────────
var slime_dots: Array = []   # [{pos: Vector2, color: Color, age: float}]
var p1_slime_timer: float = 0.0
var p2_slime_timer: float = 0.0


func _ready() -> void:
	_setup_input()
	_setup_arena()
	_create_bar_polygons()
	_create_countdown_label()
	_create_death_phrase_label()

	# Camera — slight zoom out to see wall platforms
	$Camera2D.zoom = Vector2(0.92, 0.92)

	# Slime colors per player
	player1.slime_color = Color(0.55, 0.75, 0.35, 0.6)
	player2.slime_color = Color(0.35, 0.65, 0.75, 0.6)

	player2.ai_target = player1
	game_over_label.visible = false
	controls_label.visible = true
	p1_effect.visible = false
	p2_effect.visible = false
	_start_countdown()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ ARENA SETUP — curved ground, platforms, walls                            ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _setup_arena() -> void:
	_setup_curved_ground()
	_setup_center_circle()
	_move_platforms_inward()
	_clay_platforms()
	_create_wall(WALL_LEFT_X, "WallLeft")
	_create_wall(WALL_RIGHT_X, "WallRight")
	_setup_background()


func _move_platforms_inward() -> void:
	# Move floating horizontal platforms closer to center so there's a bigger gap
	# between them and the side walls
	$PlatformLeft.position.x = 320.0
	$PlatformRight.position.x = 960.0


func _setup_background() -> void:
	# Warm diorama backdrop — like a tabletop clay set
	var bg: ColorRect = $Background
	bg.color = Color(0.62, 0.78, 0.88)  # Slightly warmer sky

	# Add a floor-colored rect behind the ground area for depth
	var floor_bg := ColorRect.new()
	floor_bg.z_index = -9
	floor_bg.offset_left = -600.0
	floor_bg.offset_top = 480.0
	floor_bg.offset_right = 1880.0
	floor_bg.offset_bottom = 1300.0
	floor_bg.color = Color(0.42, 0.33, 0.26)  # Warm brown table surface
	add_child(floor_bg)

	# Horizon line accent — where sky meets table
	var horizon := ColorRect.new()
	horizon.z_index = -8
	horizon.offset_left = -600.0
	horizon.offset_top = 470.0
	horizon.offset_right = 1880.0
	horizon.offset_bottom = 490.0
	horizon.color = Color(0.52, 0.43, 0.36)
	add_child(horizon)


func _setup_curved_ground() -> void:
	# Remove old ground children (rect shape + visuals)
	for child in ground.get_children():
		child.queue_free()

	# ── CLAY GROUND COLORS ──
	var dirt_base := Color(0.42, 0.30, 0.22)     # Warm brown clay dirt
	var dirt_shadow := dirt_base.darkened(0.35)
	var dirt_highlight := dirt_base.lightened(0.12)
	var grass_base := Color(0.45, 0.68, 0.32)     # Bright green clay grass
	var grass_shadow := grass_base.darkened(0.2)
	var grass_highlight := grass_base.lightened(0.15)

	# Build curved top surface points
	var top_points := PackedVector2Array()
	for i in GROUND_SEGMENTS + 1:
		var t := float(i) / float(GROUND_SEGMENTS) * 2.0 - 1.0  # -1 to 1
		var x := t * GROUND_HALF_WIDTH
		var y := -20.0 - GROUND_CURVE * t * t  # Edges higher than center
		top_points.append(Vector2(x, y))

	# Full polygon: top curve + bottom flat
	var full_points := PackedVector2Array()
	full_points.append_array(top_points)
	full_points.append(Vector2(GROUND_HALF_WIDTH, 30.0))
	full_points.append(Vector2(-GROUND_HALF_WIDTH, 30.0))

	# Collision polygon
	var col_poly := CollisionPolygon2D.new()
	col_poly.polygon = full_points
	ground.add_child(col_poly)

	# Drop shadow (offset down-right, behind everything)
	var shadow_points := PackedVector2Array()
	for pt in full_points:
		shadow_points.append(pt + Vector2(4, 5))
	var shadow := Polygon2D.new()
	shadow.polygon = shadow_points
	shadow.color = dirt_shadow
	ground.add_child(shadow)

	# Base dirt body
	var dirt := Polygon2D.new()
	dirt.polygon = full_points
	dirt.color = dirt_base
	ground.add_child(dirt)

	# Dirt highlight strip (top area, lighter like light hitting the surface)
	var hl_points := PackedVector2Array()
	for i in GROUND_SEGMENTS + 1:
		var t := float(i) / float(GROUND_SEGMENTS) * 2.0 - 1.0
		var x := t * GROUND_HALF_WIDTH
		var y := -20.0 - GROUND_CURVE * t * t
		hl_points.append(Vector2(x, y))
	for i in range(GROUND_SEGMENTS, -1, -1):
		var t := float(i) / float(GROUND_SEGMENTS) * 2.0 - 1.0
		var x := t * GROUND_HALF_WIDTH
		var y := -20.0 - GROUND_CURVE * t * t + 8.0  # 8px below top
		hl_points.append(Vector2(x, y))
	var hl := Polygon2D.new()
	hl.polygon = hl_points
	hl.color = dirt_highlight
	ground.add_child(hl)

	# Grass layer — thick clay strip along the top curve
	var grass_top := PackedVector2Array()
	var grass_bot := PackedVector2Array()
	for i in GROUND_SEGMENTS + 1:
		var t := float(i) / float(GROUND_SEGMENTS) * 2.0 - 1.0
		var x := t * GROUND_HALF_WIDTH
		var y := -20.0 - GROUND_CURVE * t * t
		grass_top.append(Vector2(x, y - 4.0))
		grass_bot.append(Vector2(x, y + 4.0))
	var grass_poly := PackedVector2Array()
	grass_poly.append_array(grass_top)
	for i in range(grass_bot.size() - 1, -1, -1):
		grass_poly.append(grass_bot[i])

	# Grass shadow (slightly offset)
	var grass_shadow_poly := PackedVector2Array()
	for pt in grass_poly:
		grass_shadow_poly.append(pt + Vector2(2, 2.5))
	var g_shadow := Polygon2D.new()
	g_shadow.polygon = grass_shadow_poly
	g_shadow.color = grass_shadow
	ground.add_child(g_shadow)

	# Grass base
	var g_base := Polygon2D.new()
	g_base.polygon = grass_poly
	g_base.color = grass_base
	ground.add_child(g_base)

	# Grass highlight line (top edge catches the light)
	var g_hl := Line2D.new()
	g_hl.points = grass_top
	g_hl.width = 2.5
	g_hl.default_color = grass_highlight
	ground.add_child(g_hl)

	# Rounded end caps (small clay circles at ground edges for sculpted look)
	var left_edge := top_points[0]
	var right_edge := top_points[top_points.size() - 1]
	for edge_pt in [left_edge, right_edge]:
		_make_clay_circle_group(ground, edge_pt, 8.0, dirt_base)
		_make_clay_circle_group(ground, edge_pt + Vector2(0, -2), 5.0, grass_base)


func _setup_center_circle() -> void:
	center_circle.position = CENTER_CIRCLE_POS
	# Replace the scene's default visual with a clay-styled one
	var old_visual := center_circle.get_node_or_null("CenterVisual")
	if old_visual:
		old_visual.queue_free()

	var stone_color := Color(0.50, 0.44, 0.38)  # Warm stone clay
	var r := CENTER_CIRCLE_RADIUS

	# Shadow circle
	var shadow := _make_circle_polygon(Vector2(3, 4), r + 2, stone_color.darkened(0.4))
	center_circle.add_child(shadow)

	# Base stone
	var base := _make_circle_polygon(Vector2.ZERO, r, stone_color)
	center_circle.add_child(base)

	# Inner highlight (top-left)
	var hl := _make_circle_polygon(Vector2(-3, -3), r * 0.75, stone_color.lightened(0.1))
	center_circle.add_child(hl)

	# Specular spot
	var spec := _make_circle_polygon(Vector2(-r * 0.25, -r * 0.3), r * 0.25, stone_color.lightened(0.25))
	center_circle.add_child(spec)

	# Dark ring (sculpted groove)
	var ring := _make_ring_polygon(Vector2.ZERO, r * 0.85, r * 0.9, stone_color.darkened(0.2))
	center_circle.add_child(ring)


func _clay_platforms() -> void:
	# Restyle the floating platforms with clay block look
	for plat_info in [
		{node = $PlatformLeft, visual = "PlatLeftVisual"},
		{node = $PlatformRight, visual = "PlatRightVisual"}
	]:
		var plat: StaticBody2D = plat_info.node
		var old_vis = plat.get_node_or_null(plat_info.visual)
		if old_vis:
			old_vis.queue_free()

		var wood_color := Color(0.44, 0.32, 0.24)  # Warm brown clay wood
		var hw := 90.0
		var hh := 8.0

		# Shadow
		var shadow := Polygon2D.new()
		shadow.polygon = PackedVector2Array([
			Vector2(-hw + 3, -hh + 3), Vector2(hw + 3, -hh + 3),
			Vector2(hw + 3, hh + 3), Vector2(-hw + 3, hh + 3)])
		shadow.color = wood_color.darkened(0.4)
		plat.add_child(shadow)

		# Base block
		var base := Polygon2D.new()
		base.polygon = PackedVector2Array([
			Vector2(-hw, -hh), Vector2(hw, -hh),
			Vector2(hw, hh), Vector2(-hw, hh)])
		base.color = wood_color
		plat.add_child(base)

		# Top highlight strip
		var top_hl := Polygon2D.new()
		top_hl.polygon = PackedVector2Array([
			Vector2(-hw + 2, -hh), Vector2(hw - 2, -hh),
			Vector2(hw - 2, -hh + 3), Vector2(-hw + 2, -hh + 3)])
		top_hl.color = wood_color.lightened(0.15)
		plat.add_child(top_hl)

		# Bottom shadow strip
		var bot_sh := Polygon2D.new()
		bot_sh.polygon = PackedVector2Array([
			Vector2(-hw + 2, hh - 2), Vector2(hw - 2, hh - 2),
			Vector2(hw - 2, hh), Vector2(-hw + 2, hh)])
		bot_sh.color = wood_color.darkened(0.15)
		plat.add_child(bot_sh)

		# Center specular line
		var spec := Polygon2D.new()
		spec.polygon = PackedVector2Array([
			Vector2(-hw * 0.6, -hh + 2), Vector2(hw * 0.3, -hh + 2),
			Vector2(hw * 0.3, -hh + 4), Vector2(-hw * 0.6, -hh + 4)])
		spec.color = wood_color.lightened(0.22)
		plat.add_child(spec)

		# Rounded end caps
		for xdir in [-1.0, 1.0]:
			_make_clay_circle_group(plat, Vector2(xdir * hw, 0), hh, wood_color)


func _create_wall(x_pos: float, wall_name: String) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = Vector2(x_pos, WALL_Y)
	add_child(wall)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WALL_WIDTH, WALL_HEIGHT)
	shape.shape = rect
	wall.add_child(shape)

	var hw := WALL_WIDTH / 2.0
	var hh := WALL_HEIGHT / 2.0
	var wall_color := Color(0.50, 0.42, 0.36)  # Warm stone clay

	# Drop shadow
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-hw + 4, -hh + 4), Vector2(hw + 4, -hh + 4),
		Vector2(hw + 4, hh + 4), Vector2(-hw + 4, hh + 4)])
	shadow.color = wall_color.darkened(0.4)
	wall.add_child(shadow)

	# Base block
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh)])
	base.color = wall_color
	wall.add_child(base)

	# Left edge shadow (away from light)
	var left_sh := Polygon2D.new()
	left_sh.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(-hw + 3, -hh),
		Vector2(-hw + 3, hh), Vector2(-hw, hh)])
	left_sh.color = wall_color.darkened(0.15)
	wall.add_child(left_sh)

	# Right edge shadow
	var right_sh := Polygon2D.new()
	right_sh.polygon = PackedVector2Array([
		Vector2(hw - 2, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(hw - 2, hh)])
	right_sh.color = wall_color.darkened(0.08)
	wall.add_child(right_sh)

	# Center-left highlight strip (where light hits)
	var hl := Polygon2D.new()
	var hl_x := -hw + WALL_WIDTH * 0.28
	var hl_w := WALL_WIDTH * 0.28
	hl.polygon = PackedVector2Array([
		Vector2(hl_x, -hh + 2), Vector2(hl_x + hl_w, -hh + 2),
		Vector2(hl_x + hl_w, hh - 2), Vector2(hl_x, hh - 2)])
	hl.color = wall_color.lightened(0.12)
	wall.add_child(hl)

	# Specular thin strip
	var sp := Polygon2D.new()
	var sp_x := -hw + WALL_WIDTH * 0.32
	var sp_w := WALL_WIDTH * 0.08
	sp.polygon = PackedVector2Array([
		Vector2(sp_x, -hh + 5), Vector2(sp_x + sp_w, -hh + 5),
		Vector2(sp_x + sp_w, hh - 5), Vector2(sp_x, hh - 5)])
	sp.color = wall_color.lightened(0.22)
	wall.add_child(sp)

	# Rounded top cap
	_make_clay_circle_group(wall, Vector2(0, -hh), hw, wall_color)
	# Rounded bottom cap
	_make_clay_circle_group(wall, Vector2(0, hh), hw, wall_color)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ CLAY SHAPE HELPERS + SPRITE TRANSITION GUIDE                            ║
# ║                                                                          ║
# ║ All arena elements use layered Polygon2D shapes for a 3D clay look.     ║
# ║ To replace any arena piece with a sprite:                                ║
# ║   1. Create a PNG at the noted size below                                ║
# ║   2. Add a Sprite2D child to the relevant StaticBody2D node              ║
# ║   3. Assign your PNG as the texture                                      ║
# ║   4. Remove/comment the Polygon2D creation code for that piece           ║
# ║                                                                          ║
# ║ ARENA PARTS:                                                             ║
# ║   Ground      — ~990x50, origin at Ground node (640, 520)               ║
# ║   Grass strip — ~990x8, sits on top edge of ground                      ║
# ║   Walls       — 20x200 each, at (30, 300) and (1250, 300)              ║
# ║   Platforms   — 180x16 each, at (~320, 330) and (~960, 330)            ║
# ║   Center rock — 60x60 circle, at (640, 190)                             ║
# ║   Background  — full screen, sky + table surface                        ║
# ║                                                                          ║
# ║ Light direction: top-left (consistent with bollard.gd)                  ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _make_clay_circle_group(parent: Node, center: Vector2, radius: float, base_color: Color) -> void:
	var shadow := _make_circle_polygon(center + Vector2(2, 2.5), radius, base_color.darkened(0.35))
	parent.add_child(shadow)
	var base := _make_circle_polygon(center, radius, base_color)
	parent.add_child(base)
	var hl := _make_circle_polygon(center + Vector2(-radius * 0.2, -radius * 0.25), radius * 0.5, base_color.lightened(0.15))
	parent.add_child(hl)


func _make_circle_polygon(center: Vector2, radius: float, color: Color, segments: int = 16) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in segments:
		var angle := float(i) / float(segments) * TAU
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = color
	return poly


func _make_ring_polygon(center: Vector2, inner_r: float, outer_r: float, color: Color, segments: int = 24) -> Polygon2D:
	# Approximate a ring as a series of quads
	var pts := PackedVector2Array()
	for i in segments:
		var angle := float(i) / float(segments) * TAU
		pts.append(center + Vector2(cos(angle), sin(angle)) * outer_r)
	for i in range(segments - 1, -1, -1):
		var angle := float(i) / float(segments) * TAU
		pts.append(center + Vector2(cos(angle), sin(angle)) * inner_r)
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = color
	return poly


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ HUD SETUP                                                                ║
# ╚══════════════════════════════════════════════════════════════════════════╝

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
	countdown_label.add_theme_font_size_override("font_size", 80)
	countdown_label.add_theme_color_override("font_color", Color(1, 1, 1))
	countdown_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	countdown_label.add_theme_constant_override("shadow_offset_x", 3)
	countdown_label.add_theme_constant_override("shadow_offset_y", 3)
	countdown_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	countdown_label.add_theme_constant_override("outline_size", 4)
	# Left-aligned so letters stay in place as text grows
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.offset_left = 440.0
	countdown_label.offset_top = 200.0
	countdown_label.offset_right = 900.0
	countdown_label.offset_bottom = 320.0
	countdown_label.visible = false
	$HUD.add_child(countdown_label)


func _create_death_phrase_label() -> void:
	death_phrase_label = Label.new()
	death_phrase_label.add_theme_font_size_override("font_size", 46)
	death_phrase_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	death_phrase_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	death_phrase_label.add_theme_constant_override("shadow_offset_x", 3)
	death_phrase_label.add_theme_constant_override("shadow_offset_y", 3)
	death_phrase_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	death_phrase_label.add_theme_constant_override("outline_size", 4)
	death_phrase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_phrase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_phrase_label.offset_left = 240.0
	death_phrase_label.offset_top = 130.0
	death_phrase_label.offset_right = 1040.0
	death_phrase_label.offset_bottom = 190.0
	death_phrase_label.visible = false
	$HUD.add_child(death_phrase_label)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ COUNTDOWN — "escarGO!" syllable reveal                                   ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _start_countdown() -> void:
	countdown_active = true
	countdown_timer = 0.0
	game_active = false
	countdown_label.visible = true
	countdown_label.text = ""
	# Players load in IMMEDIATELY — visible and emerging from ground right away
	for p: Bollard in [player1, player2]:
		p.visible = true
		p.is_dead = false
	player1.start_emerge(SPAWN_P1)
	player2.start_emerge(SPAWN_P2)
	# Freeze after emerge — they can't move until "escarGO!"
	player1.is_frozen = true
	player2.is_frozen = true


func _update_countdown(delta: float) -> void:
	countdown_timer += delta

	if countdown_timer < 1.0:
		# Players emerging, no text yet
		countdown_label.text = ""
	elif countdown_timer < 2.0:
		countdown_label.text = "es.."
		countdown_label.add_theme_font_size_override("font_size", 80)
		countdown_label.add_theme_color_override("font_color", Color(1, 1, 1))
	elif countdown_timer < 3.0:
		countdown_label.text = "escar.."
		countdown_label.add_theme_font_size_override("font_size", 80)
		countdown_label.add_theme_color_override("font_color", Color(1, 1, 1))
	elif countdown_timer < 3.0 + GO_LINGER:
		countdown_label.text = "escarGO!"
		countdown_label.add_theme_font_size_override("font_size", 80)
		countdown_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
		# Unfreeze players the moment escarGO! appears
		if player1.is_frozen:
			player1.is_frozen = false
			player2.is_frozen = false
			game_active = true
	else:
		countdown_active = false
		countdown_label.visible = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ MAIN LOOP                                                                ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _physics_process(delta: float) -> void:
	if countdown_active:
		_update_countdown(delta)
		_update_hud()
		controls_visible_timer += delta
		if controls_visible_timer > 8.0 and controls_label.visible:
			controls_label.visible = false
		return

	if not game_active:
		_update_death_phrase(delta)
		return

	_check_blast_zone(player1)
	_check_blast_zone(player2)
	_handle_respawn(player1, SPAWN_P1, delta)
	_handle_respawn(player2, SPAWN_P2, delta)
	_check_damage_effects(delta)
	_update_hud()
	_update_death_phrase(delta)
	_update_slime(delta)

	controls_visible_timer += delta
	if controls_visible_timer > 8.0 and controls_label.visible:
		controls_label.visible = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BLAST ZONE / RESPAWN                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _check_blast_zone(player: Bollard) -> void:
	if player.is_dead:
		return
	if not BLAST_ZONE.has_point(player.global_position):
		player.die()
		_show_death_phrase()
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
		player.start_emerge(spawn_pos)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ DEATH PHRASES                                                            ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _show_death_phrase() -> void:
	death_phrase_label.text = DEATH_PHRASES[randi() % DEATH_PHRASES.size()]
	death_phrase_label.visible = true
	death_phrase_timer = DEATH_PHRASE_DURATION


func _update_death_phrase(delta: float) -> void:
	if death_phrase_timer > 0.0:
		death_phrase_timer -= delta
		if death_phrase_timer <= 0.0:
			death_phrase_label.visible = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ GAME OVER / RESTART                                                      ║
# ╚══════════════════════════════════════════════════════════════════════════╝

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
	death_phrase_label.visible = false
	death_phrase_timer = 0.0
	# Clear slime
	slime_dots.clear()
	queue_redraw()
	# Hard-reset BOTH players before countdown starts
	for p: Bollard in [player1, player2]:
		p.stocks = 3
		p.is_dead = false
		p.is_frozen = false
		p.is_emerging = false
		p.is_grabbing = false
		p.want_to_grab = false
		p.damage_percent = 0.0
		p.extend_amount = 0.5
		p.linear_velocity = Vector2.ZERO
		p.angular_velocity = 0.0
		p.rotation = 0.0
		p.visible = true
		p.is_invincible = false
		if p.has_meta("respawn_timer"):
			p.remove_meta("respawn_timer")
	_start_countdown()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R and not countdown_active:
			_restart_game()
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ SLIME TRAIL                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_slime(delta: float) -> void:
	_try_add_slime(player1, delta)
	_try_add_slime(player2, delta)

	# Age and remove old dots
	var i := slime_dots.size() - 1
	while i >= 0:
		slime_dots[i].age += delta
		if slime_dots[i].age >= SLIME_LIFETIME:
			slime_dots.remove_at(i)
		i -= 1

	queue_redraw()

var _slime_timers := {}

func _try_add_slime(player: Bollard, delta: float) -> void:
	if player.is_dead or player.is_frozen or player.is_emerging:
		return

	var pid := player.player_id
	if not _slime_timers.has(pid):
		_slime_timers[pid] = 0.0
	_slime_timers[pid] += delta
	if _slime_timers[pid] < SLIME_INTERVAL:
		return
	_slime_timers[pid] = 0.0

	# Check if touching any static body (surface)
	for body in player.get_colliding_bodies():
		if body is StaticBody2D:
			var pos := player.global_position
			slime_dots.append({"pos": pos, "color": player.slime_color, "age": 0.0})
			# Cap total dots
			if slime_dots.size() > SLIME_MAX_DOTS:
				slime_dots.pop_front()
			break


func _draw() -> void:
	for dot in slime_dots:
		var alpha := clampf(1.0 - dot.age / SLIME_LIFETIME, 0.0, 1.0) * 0.5
		var c := Color(dot.color.r, dot.color.g, dot.color.b, alpha)
		# Clay-style slime: shadow + base + highlight
		draw_circle(dot.pos + Vector2(1.5, 1.5), 5.5, Color(0, 0, 0, alpha * 0.25))
		draw_circle(dot.pos, 5.0, c)
		draw_circle(dot.pos + Vector2(-1.2, -1.2), 2.5, Color(c.r + 0.1, c.g + 0.1, c.b + 0.1, alpha * 0.6))


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
	# P1 bar fills RIGHT to LEFT
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

	# P2 bar fills LEFT to RIGHT
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
