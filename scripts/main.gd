extends Node2D

# ── Arena Sprite Textures (swap these PNGs for custom art) ─────────────────
const TEX_PLATFORM := preload("res://sprites/arena/platform.png")
const TEX_ROCK := preload("res://sprites/arena/center_rock.png")


# ── Stage Layout ────────────────────────────────────────────────────────────
const BLAST_ZONE := Rect2(-1100, -900, 3480, 2500)
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
const WALL_HEIGHT := 160.0           # Lowered for shell toss bank shots
const WALL_LEFT_X := -30.0
const WALL_RIGHT_X := 1310.0
const WALL_Y := 340.0
const WALL_ANGLE_INWARD := 30.0     # Bottom edge angled inward by this many pixels

# ── HUD Constants ───────────────────────────────────────────────────────────
const P1_BAR_LEFT := 180.0
const P1_BAR_RIGHT := 540.0
const P2_BAR_LEFT := 740.0
const P2_BAR_RIGHT := 1100.0
const BAR_MAX_WIDTH := 360.0
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
	"snail you later",
	"out-snail'd",
]
const DOUBLE_DEATH_PHRASES := [
	"shellapalooza",
	"double shell",
	"well, one of you was supposed to stay on the stage",
	"double slime down",
	"un-snail-ievable",
]
const SHELL_KILL_PHRASES := [
	"shell happens",
	"incoming!",
	"shelled into oblivion",
]
const DEATH_PHRASE_DURATION := 2.5
const DOUBLE_DEATH_WINDOW := 0.5    # Seconds — deaths this close count as double

# ── Slime Trail ─────────────────────────────────────────────────────────────
const SLIME_LIFETIME := 4.0
const SLIME_INTERVAL := 0.08
const SLIME_MAX_DOTS := 200

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
var last_death_time: float = -999.0  # Engine time of last death (for double death detection)

# ── Hit Slomo + Shards + Ripple ────────────────────────────────────────────
const SLOMO_DURATION := 0.6         # Real-time seconds of slowdown
const SLOMO_SCALE := 0.4            # Time scale during slomo (40% speed)
const SHARD_DURATION := 0.4         # How long impact shards last
const SHARD_COUNT := 8              # Number of shards per impact
const SHARD_SPEED := 300.0          # Shard outward speed
const RIPPLE_DURATION := 0.5        # Screen ripple duration
var slomo_timer: float = 0.0
var impact_shards: Array = []       # [{node: Line2D, vel: Vector2, timer: float}]
var ripple_timer: float = 0.0
var ripple_center: Vector2 = Vector2.ZERO
var ripple_rect: ColorRect          # Screen-covering rect with ripple shader

# ── Select Screen State ─────────────────────────────────────────────────────
var select_active: bool = true          # Start on select screen
var select_phase: String = "p1_pick"    # "p1_pick", "p2_pick", or "stage"
var p1_char_index: int = 0              # 0=Blink, 1=Goopy, 2=Zappy, 3=Random
var p2_char_index: int = 0
var stage_index: int = 0                # 0=current, 1=random (placeholder)
var select_layer: CanvasLayer
var select_input_cooldown: float = 0.0  # Prevent rapid-fire navigation

const CHAR_NAMES := ["BLINK", "GOOPY", "ZAPPY", "RANDOM"]
const CHAR_COLORS := [
	Color(0.7, 0.35, 1.0),  # Blink — purple
	Color(0.3, 0.85, 0.3),  # Goopy — green
	Color(0.35, 0.7, 1.0),  # Zappy — blue
	Color(0.7, 0.7, 0.7),   # Random — gray
]
const CHAR_ABILITY1_DESC := [
	"Shell Toss + Teleport",
	"Slime Shell (tether + zip)",
	"Zap Shell (short range, fast)",
	"???",
]
const CHAR_ABILITY2_DESC := [
	"Phase Dash (through platforms)",
	"Goo Dash (charged, slime trail)",
	"Bolt Dash (snappy, x3)",
	"???",
]
const STAGE_NAMES := ["Meadow", "Oops, All Slab", "Random"]

# ── Stage State ─────────────────────────────────────────────────────────────
var current_stage: int = 0              # Index into STAGE_NAMES
var stage_extra_nodes: Array = []       # Nodes created for current stage (cleaned up on switch)

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


func _ready() -> void:
	# Higher physics tick rate prevents tunneling through ground/structures
	Engine.physics_ticks_per_second = 120
	pixel_font = load("res://fonts/PressStart2P-Regular.ttf")
	_setup_input()
	_setup_arena()
	_create_bar_polygons()
	_create_countdown_label()
	_create_death_phrase_label()

	# Camera — zoomed out for more recovery room
	$Camera2D.zoom = Vector2(0.80, 0.80)

	# Screen ripple effect overlay
	_setup_ripple_shader()

	# Slime colors per player
	player1.slime_color = Color(0.55, 0.75, 0.35, 0.6)
	player2.slime_color = Color(0.35, 0.65, 0.75, 0.6)

	player1.big_hit.connect(_on_big_hit)
	player2.big_hit.connect(_on_big_hit)
	player1.shards_only.connect(_on_shards_only)
	player2.shards_only.connect(_on_shards_only)
	player2.ai_target = player1
	# Auto-detect second controller: if connected, P2 is human
	if Input.get_connected_joypads().size() >= 2:
		player2.is_ai = false
		player2.ai_target = null
	game_over_label.visible = false
	controls_label.visible = true
	p1_effect.visible = false
	p2_effect.visible = false
	# Apply pixel font to all scene-based labels
	if pixel_font:
		for lbl in [game_over_label, controls_label, p1_stock_label, p2_stock_label, p1_effect, p2_effect]:
			lbl.add_theme_font_override("font", pixel_font)
		# Apply pixel font to scene-based "dmg." labels
		var p1_dmg_lbl: Label = $HUD/P1Group/P1DmgLabel
		var p2_dmg_lbl: Label = $HUD/P2Group/P2DmgLabel
		p1_dmg_lbl.add_theme_font_override("font", pixel_font)
		p2_dmg_lbl.add_theme_font_override("font", pixel_font)
		game_over_label.add_theme_font_size_override("font_size", 16)
		controls_label.add_theme_font_size_override("font_size", 8)
		p1_stock_label.add_theme_font_size_override("font_size", 10)
		p2_stock_label.add_theme_font_size_override("font_size", 10)
		p1_effect.add_theme_font_size_override("font_size", 14)
		p2_effect.add_theme_font_size_override("font_size", 14)

	# Start on select screen instead of jumping straight to countdown
	_create_select_screen()
	_show_select_screen()
	# Hide players until character select is done
	player1.visible = false
	player2.visible = false


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
	_create_corner_platforms()
	_setup_background()


func _move_platforms_inward() -> void:
	# Move floating horizontal platforms closer to center so there's a bigger gap
	# between them and the side walls
	$PlatformLeft.position.x = 320.0
	$PlatformRight.position.x = 960.0


func _setup_ripple_shader() -> void:
	ripple_rect = ColorRect.new()
	ripple_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Cover the full viewport
	ripple_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 center = vec2(0.5, 0.5);
uniform float time = 0.0;
uniform float active = 0.0;
uniform float duration = 0.5;
uniform float ripple_width = 0.20;
uniform float ripple_strength = 0.05;

void fragment() {
	vec2 uv = SCREEN_UV;
	if (active < 0.5) {
		COLOR = textureLod(screen_tex, uv, 0.0);
	} else {
		float dist = distance(uv, center);
		float progress = clamp(time / duration, 0.0, 1.0);
		float ring_pos = progress * 0.8;
		float ring_dist = abs(dist - ring_pos);
		float ring = smoothstep(ripple_width, 0.0, ring_dist);
		float fade = 1.0 - progress;
		vec2 dir = normalize(uv - center + vec2(0.001));
		vec2 offset = dir * ring * ripple_strength * fade;
		COLOR = textureLod(screen_tex, uv + offset, 0.0);
	}
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("center", Vector2(0.5, 0.5))
	mat.set_shader_parameter("time", 0.0)
	mat.set_shader_parameter("active", 0.0)
	mat.set_shader_parameter("duration", RIPPLE_DURATION)
	ripple_rect.material = mat
	# Add to a CanvasLayer so it renders over everything
	var ripple_layer := CanvasLayer.new()
	ripple_layer.layer = 100
	ripple_rect.visible = false  # Only visible during active ripple
	add_child(ripple_layer)
	ripple_layer.add_child(ripple_rect)


func _setup_background() -> void:
	var bg: ColorRect = $Background
	bg.color = Color(0.53, 0.81, 0.92)  # Light sky blue


func _setup_curved_ground() -> void:
	# Remove old ground children (rect shape + visuals from scene)
	for child in ground.get_children():
		child.queue_free()

	# Build curved top surface points (for collision)
	var top_points := PackedVector2Array()
	for i in GROUND_SEGMENTS + 1:
		var t := float(i) / float(GROUND_SEGMENTS) * 2.0 - 1.0
		var x := t * GROUND_HALF_WIDTH
		var y := -20.0 - GROUND_CURVE * t * t
		top_points.append(Vector2(x, y))

	var full_points := PackedVector2Array()
	full_points.append_array(top_points)
	full_points.append(Vector2(GROUND_HALF_WIDTH, 30.0))
	full_points.append(Vector2(-GROUND_HALF_WIDTH, 30.0))

	# Collision polygon (physics only)
	var col_poly := CollisionPolygon2D.new()
	col_poly.polygon = full_points
	ground.add_child(col_poly)

	# ── VISUAL: dirt body (Polygon2D matching the curved collision shape) ─
	var dirt_poly := Polygon2D.new()
	dirt_poly.polygon = full_points
	dirt_poly.color = Color(0.55, 0.36, 0.24)  # Warm brown dirt
	ground.add_child(dirt_poly)

	# ── VISUAL: grass strip (thin curved polygon on top of the dirt) ──────
	var grass_thickness := 6.0
	var grass_points := PackedVector2Array()
	# Top edge: offset upward from collision surface
	for i in GROUND_SEGMENTS + 1:
		grass_points.append(top_points[i] + Vector2(0, -grass_thickness))
	# Bottom edge: the collision surface itself (reversed order)
	for i in range(GROUND_SEGMENTS, -1, -1):
		grass_points.append(top_points[i])
	var grass_poly := Polygon2D.new()
	grass_poly.polygon = grass_points
	grass_poly.color = Color(0.35, 0.65, 0.25)  # Green grass
	grass_poly.z_index = 1
	ground.add_child(grass_poly)


func _setup_center_circle() -> void:
	center_circle.position = CENTER_CIRCLE_POS
	# Replace the scene's default visual
	var old_visual := center_circle.get_node_or_null("CenterVisual")
	if old_visual:
		old_visual.queue_free()

	# ── VISUAL: center rock sprite ────────────────────────────────────
	# Replace: swap sprites/arena/center_rock.png (64x64 circle)
	var rock_spr := Sprite2D.new()
	rock_spr.texture = TEX_ROCK
	var rock_scale := (CENTER_CIRCLE_RADIUS * 2.0) / TEX_ROCK.get_width()
	rock_spr.scale = Vector2(rock_scale, rock_scale)
	center_circle.add_child(rock_spr)


func _clay_platforms() -> void:
	# Restyle floating platforms with sprite
	for plat_info in [
		{node = $PlatformLeft, visual = "PlatLeftVisual"},
		{node = $PlatformRight, visual = "PlatRightVisual"}
	]:
		var plat: StaticBody2D = plat_info.node
		var old_vis = plat.get_node_or_null(plat_info.visual)
		if old_vis:
			old_vis.queue_free()

		# ── VISUAL: platform sprite ───────────────────────────────────
		# Replace: swap sprites/arena/platform.png (180x20)
		var plat_spr := Sprite2D.new()
		plat_spr.texture = TEX_PLATFORM
		var plat_sx: float = 180.0 / TEX_PLATFORM.get_width()
		var plat_sy: float = 16.0 / TEX_PLATFORM.get_height()
		plat_spr.scale = Vector2(plat_sx, plat_sy)
		plat.add_child(plat_spr)


func _create_wall(x_pos: float, wall_name: String) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = Vector2(x_pos, WALL_Y)
	add_child(wall)

	# Angled wall: top is straight, bottom edge angles inward toward stage
	var is_left := x_pos < 640.0
	var half_w := WALL_WIDTH * 0.5
	var half_h := WALL_HEIGHT * 0.5
	var inward: float = WALL_ANGLE_INWARD if is_left else -WALL_ANGLE_INWARD
	var poly_points := PackedVector2Array([
		Vector2(-half_w, -half_h),           # Top outer
		Vector2(half_w, -half_h),            # Top inner
		Vector2(half_w + inward, half_h),    # Bottom inner (angled toward stage)
		Vector2(-half_w + inward, half_h),   # Bottom outer (angled toward stage)
	])

	var col_poly := CollisionPolygon2D.new()
	col_poly.polygon = poly_points
	wall.add_child(col_poly)

	# ── VISUAL: wall polygon matching collision ──────────────────────
	var wall_visual := Polygon2D.new()
	wall_visual.polygon = poly_points
	wall_visual.color = Color(0.45, 0.35, 0.28)  # Dark brown wall
	wall.add_child(wall_visual)


func _create_corner_platforms() -> void:
	# Four corner platforms angled toward center circle, 1.5x central platform width
	var plat_width := 270.0  # 1.5x the 180px central platforms
	var plat_height := 14.0
	# 45° angles, flat side facing center, endpoints near screen edges
	var corners := [
		{"x": 145.0, "y": 155.0, "rot": PI / 4.0, "name": "CornerTopLeft"},
		{"x": 1135.0, "y": 155.0, "rot": -PI / 4.0, "name": "CornerTopRight"},
		{"x": 145.0, "y": 435.0, "rot": -PI / 4.0, "name": "CornerBottomLeft"},
		{"x": 1135.0, "y": 435.0, "rot": PI / 4.0, "name": "CornerBottomRight"},
	]
	for info in corners:
		var plat := StaticBody2D.new()
		plat.name = info.name
		plat.position = Vector2(info.x, info.y)
		plat.rotation = info.rot
		add_child(plat)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(plat_width, plat_height)
		shape.shape = rect
		shape.one_way_collision = true
		plat.add_child(shape)
		var plat_spr := Sprite2D.new()
		plat_spr.texture = TEX_PLATFORM
		var sx: float = plat_width / TEX_PLATFORM.get_width()
		var sy: float = plat_height / TEX_PLATFORM.get_height()
		plat_spr.scale = Vector2(sx, sy)
		plat.add_child(plat_spr)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ STAGE SYSTEM                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _apply_stage(idx: int) -> void:
	current_stage = idx
	# Clean up any extra stage nodes from previous stage
	for node in stage_extra_nodes:
		if is_instance_valid(node):
			node.queue_free()
	stage_extra_nodes.clear()

	var stage_name: String = STAGE_NAMES[idx]
	match stage_name:
		"Meadow":
			_setup_meadow_stage()
		"Oops, All Slab":
			_setup_slab_stage()

func _setup_meadow_stage() -> void:
	# Default stage — restore normal arena elements
	ground.visible = true
	center_circle.visible = true
	for child in ground.get_children():
		if child is CollisionPolygon2D:
			child.disabled = false
		if child is Polygon2D or child is ColorRect:
			child.visible = true
	for child in center_circle.get_children():
		if child is CollisionShape2D:
			child.disabled = false
	# Central platforms — keep same positions
	$PlatformLeft.position = Vector2(350, 330)
	$PlatformRight.position = Vector2(930, 330)
	$PlatformLeft.visible = true
	$PlatformRight.visible = true
	for child in $PlatformLeft.get_children():
		if child is CollisionShape2D:
			child.disabled = false
	for child in $PlatformRight.get_children():
		if child is CollisionShape2D:
			child.disabled = false
	# Hide walls (meadow has no walls)
	for wall_name in ["WallLeft", "WallRight"]:
		var node: Node = get_node_or_null(wall_name)
		if node:
			node.visible = false
			for child in node.get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.disabled = true
	# Show corner platforms
	for corner_name in ["CornerTopLeft", "CornerTopRight", "CornerBottomLeft", "CornerBottomRight"]:
		var node: Node = get_node_or_null(corner_name)
		if node:
			node.visible = true
			for child in node.get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.disabled = false
	$Background.color = Color(0.53, 0.81, 0.92)

func _setup_slab_stage() -> void:
	# Final Destination style: one flat platform, no walls or structures
	# Hide all normal arena geometry
	center_circle.visible = false
	for child in center_circle.get_children():
		if child is CollisionShape2D:
			child.disabled = true
	$PlatformLeft.visible = false
	$PlatformRight.visible = false
	for child in $PlatformLeft.get_children():
		if child is CollisionShape2D:
			child.disabled = true
	for child in $PlatformRight.get_children():
		if child is CollisionShape2D:
			child.disabled = true
	var slab_hide := ["WallLeft", "WallRight",
		"CornerTopLeft", "CornerTopRight", "CornerBottomLeft", "CornerBottomRight"]
	for name_str in slab_hide:
		var node: Node = get_node_or_null(name_str)
		if node:
			node.visible = false
			for child in node.get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.disabled = true
	# Hide original ground visuals but keep collision
	ground.visible = false
	for child in ground.get_children():
		if child is CollisionPolygon2D:
			child.disabled = true
		if child is Polygon2D:
			child.visible = false

	# Create flat slab ground
	var slab := StaticBody2D.new()
	slab.name = "Slab"
	slab.position = Vector2(640.0, GROUND_Y - 10.0)
	add_child(slab)
	stage_extra_nodes.append(slab)

	var slab_width := 1000.0  # 25% wider than 800
	var slab_height := 24.0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(slab_width, slab_height)
	col.shape = rect
	slab.add_child(col)

	# Light gray slab visual
	var slab_visual := Polygon2D.new()
	var hw := slab_width / 2.0
	var hh := slab_height / 2.0
	slab_visual.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh)])
	slab_visual.color = Color(0.18, 0.18, 0.2)  # Dark platform
	slab.add_child(slab_visual)

	# Light gray background (swapped with platform)
	$Background.color = Color(0.7, 0.7, 0.72)


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
	if pixel_font:
		countdown_label.add_theme_font_override("font", pixel_font)
	countdown_label.add_theme_font_size_override("font_size", 40)
	countdown_label.add_theme_color_override("font_color", Color(1, 1, 1))
	countdown_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	countdown_label.add_theme_constant_override("outline_size", 5)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.offset_left = 0.0
	countdown_label.offset_top = 200.0
	countdown_label.offset_right = 1280.0
	countdown_label.offset_bottom = 340.0
	countdown_label.visible = false
	$HUD.add_child(countdown_label)


func _create_death_phrase_label() -> void:
	death_phrase_label = Label.new()
	if pixel_font:
		death_phrase_label.add_theme_font_override("font", pixel_font)
	death_phrase_label.add_theme_font_size_override("font_size", 18)
	death_phrase_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
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
# ║ CHARACTER + STAGE SELECT SCREEN                                          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

var select_title_label: Label
var char_panels: Array = []          # [{bg: ColorRect, name_label: Label, desc_label: Label}]
var select_cursor_label: Label       # Arrow indicator below selected panel
var stage_label: Label
var select_hint_label: Label
var pixel_font: Font

func _create_select_screen() -> void:
	select_layer = CanvasLayer.new()
	select_layer.layer = 50
	add_child(select_layer)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.14, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	select_layer.add_child(bg)

	# Title
	select_title_label = _make_select_label("P1: CHOOSE YOUR SNAIL", 18, Color(1.0, 0.9, 0.3))
	select_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_title_label.offset_left = 0
	select_title_label.offset_top = 20
	select_title_label.offset_right = 1280
	select_title_label.offset_bottom = 60
	select_layer.add_child(select_title_label)

	# Character panels — 4 panels side by side (BLINK, GOOPY, ZAPPY, RANDOM)
	var panel_w := 270.0
	var panel_h := 360.0
	var panel_gap := 20.0
	var total_w := panel_w * 4.0 + panel_gap * 3.0
	var start_x := floorf((1280.0 - total_w) / 2.0)
	var panel_y := 80.0

	for ci in 4:
		var px := start_x + float(ci) * (panel_w + panel_gap)
		# Panel background
		var panel_bg := ColorRect.new()
		panel_bg.color = CHAR_COLORS[ci].darkened(0.7)
		panel_bg.offset_left = floorf(px)
		panel_bg.offset_top = panel_y
		panel_bg.offset_right = floorf(px + panel_w)
		panel_bg.offset_bottom = panel_y + panel_h
		select_layer.add_child(panel_bg)

		# Character name at top of panel
		var name_lbl := _make_select_label(CHAR_NAMES[ci], 14, CHAR_COLORS[ci])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.offset_left = floorf(px)
		name_lbl.offset_top = panel_y + 15
		name_lbl.offset_right = floorf(px + panel_w)
		name_lbl.offset_bottom = panel_y + 50
		select_layer.add_child(name_lbl)

		# Ability descriptions
		var desc_text: String = "SQ: " + CHAR_ABILITY1_DESC[ci] + "\nX: " + CHAR_ABILITY2_DESC[ci] + "\nL1: Parry"
		var desc_lbl := _make_select_label(desc_text, 7, Color(0.75, 0.75, 0.75))
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.offset_left = floorf(px) + 8
		desc_lbl.offset_top = panel_y + 200
		desc_lbl.offset_right = floorf(px + panel_w) - 8
		desc_lbl.offset_bottom = panel_y + panel_h - 10
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		select_layer.add_child(desc_lbl)

		char_panels.append({"bg": panel_bg, "name": name_lbl, "desc": desc_lbl, "x": floorf(px), "w": panel_w, "y": panel_y, "h": panel_h})

	# Cursor label — arrow below the currently selected panel
	select_cursor_label = _make_select_label("^", 14, Color(1.0, 0.9, 0.3))
	select_cursor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_cursor_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	select_cursor_label.add_theme_constant_override("outline_size", 3)
	select_layer.add_child(select_cursor_label)

	# Stage select label (shown after both pick)
	stage_label = _make_select_label("", 14, Color(1.0, 0.9, 0.3))
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.offset_left = 200
	stage_label.offset_top = 530
	stage_label.offset_right = 1080
	stage_label.offset_bottom = 570
	stage_label.visible = false
	select_layer.add_child(stage_label)

	# Hint label at bottom
	select_hint_label = _make_select_label("A/D choose  |  Q confirm  |  E back", 8, Color(0.45, 0.45, 0.45))
	select_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_hint_label.offset_left = 100
	select_hint_label.offset_top = 650
	select_hint_label.offset_right = 1180
	select_hint_label.offset_bottom = 680
	select_layer.add_child(select_hint_label)

func _make_select_label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	if pixel_font:
		lbl.add_theme_font_override("font", pixel_font)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _show_select_screen() -> void:
	select_active = true
	select_phase = "p1_pick"
	p1_char_index = 0
	p2_char_index = 0
	stage_index = 0
	select_input_cooldown = 0.0
	select_layer.visible = true
	stage_label.visible = false
	_update_select_display()


func _update_select_display() -> void:
	stage_label.visible = false

	if select_phase == "p1_pick":
		select_title_label.text = "P1: CHOOSE YOUR SNAIL"
		select_title_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		# Highlight P1's current selection
		var cur := p1_char_index
		for ci in 4:
			var panel = char_panels[ci]
			panel.bg.color = CHAR_COLORS[ci].darkened(0.5) if ci == cur else CHAR_COLORS[ci].darkened(0.8)
		# Position cursor below selected panel
		var p = char_panels[cur]
		select_cursor_label.offset_left = p.x
		select_cursor_label.offset_right = p.x + p.w
		select_cursor_label.offset_top = p.y + p.h + 5
		select_cursor_label.offset_bottom = p.y + p.h + 30
		select_cursor_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		select_cursor_label.visible = true

	elif select_phase == "p2_pick":
		if player2.is_ai:
			select_title_label.text = "P1: CHOOSE P2's SNAIL"
		else:
			select_title_label.text = "P2: CHOOSE YOUR SNAIL"
		select_title_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		# Dim P1's locked-in choice, highlight P2's cursor
		var cur := p2_char_index
		for ci in 4:
			var panel = char_panels[ci]
			if ci == p1_char_index:
				# P1's locked panel — subtle highlight
				panel.bg.color = CHAR_COLORS[ci].darkened(0.55)
			elif ci == cur:
				panel.bg.color = CHAR_COLORS[ci].darkened(0.5)
			else:
				panel.bg.color = CHAR_COLORS[ci].darkened(0.8)
		var p = char_panels[cur]
		select_cursor_label.offset_left = p.x
		select_cursor_label.offset_right = p.x + p.w
		select_cursor_label.offset_top = p.y + p.h + 5
		select_cursor_label.offset_bottom = p.y + p.h + 30
		select_cursor_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		select_cursor_label.visible = true

	elif select_phase == "stage":
		select_title_label.text = "CHOOSE STAGE"
		select_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		stage_label.visible = true
		stage_label.text = "< " + STAGE_NAMES[stage_index] + " >"
		select_cursor_label.visible = false
		# Show both locked character panels
		for ci in 4:
			var panel = char_panels[ci]
			if ci == p1_char_index or ci == p2_char_index:
				panel.bg.color = CHAR_COLORS[ci].darkened(0.5)
			else:
				panel.bg.color = CHAR_COLORS[ci].darkened(0.8)


func _update_select_screen(delta: float) -> void:
	if not select_active:
		return

	select_input_cooldown -= delta
	if select_input_cooldown > 0.0:
		return

	match select_phase:
		"p1_pick":
			_handle_p1_pick_input()
		"p2_pick":
			_handle_p2_pick_input()
		"stage":
			_handle_stage_select_input()


func _handle_p1_pick_input() -> void:
	# P1 navigates with left/right, confirms with ability1
	if Input.is_action_just_pressed("p1_lean_left"):
		p1_char_index = (p1_char_index - 1 + 4) % 4
		select_input_cooldown = 0.15
		_update_select_display()
		return
	if Input.is_action_just_pressed("p1_lean_right"):
		p1_char_index = (p1_char_index + 1) % 4
		select_input_cooldown = 0.15
		_update_select_display()
		return
	if Input.is_action_just_pressed("p1_ability1"):
		select_phase = "p2_pick"
		select_input_cooldown = 0.2
		_update_select_display()


func _handle_p2_pick_input() -> void:
	# P2 picks — if AI, P1 controls with same left/right + ability1
	# If human, P2 uses their own controls
	var use_p1_controls := player2.is_ai
	var left_action: String = "p1_lean_left" if use_p1_controls else "p2_lean_left"
	var right_action: String = "p1_lean_right" if use_p1_controls else "p2_lean_right"
	var confirm_action: String = "p1_ability1" if use_p1_controls else "p2_ability1"
	var back_action: String = "p1_parry" if use_p1_controls else "p2_parry"

	if Input.is_action_just_pressed(left_action):
		p2_char_index = (p2_char_index - 1 + 4) % 4
		select_input_cooldown = 0.15
		_update_select_display()
		return
	if Input.is_action_just_pressed(right_action):
		p2_char_index = (p2_char_index + 1) % 4
		select_input_cooldown = 0.15
		_update_select_display()
		return
	if Input.is_action_just_pressed(confirm_action):
		select_phase = "stage"
		select_input_cooldown = 0.2
		_update_select_display()
		return
	# Back to P1 pick
	if Input.is_action_just_pressed(back_action):
		select_phase = "p1_pick"
		select_input_cooldown = 0.2
		_update_select_display()


func _handle_stage_select_input() -> void:
	if Input.is_action_just_pressed("p1_lean_left"):
		stage_index = (stage_index - 1 + STAGE_NAMES.size()) % STAGE_NAMES.size()
		select_input_cooldown = 0.15
		_update_select_display()
	elif Input.is_action_just_pressed("p1_lean_right"):
		stage_index = (stage_index + 1) % STAGE_NAMES.size()
		select_input_cooldown = 0.15
		_update_select_display()
	# Confirm stage with ability1 or ability2
	if Input.is_action_just_pressed("p1_ability1") or Input.is_action_just_pressed("p1_ability2"):
		_confirm_selections()
	# Go back with parry
	if Input.is_action_just_pressed("p1_parry"):
		select_phase = "p2_pick"
		stage_label.visible = false
		select_input_cooldown = 0.2
		_update_select_display()


func _confirm_selections() -> void:
	# Resolve RANDOM picks (index 3 → random 0..2)
	var p1_final: int = p1_char_index if p1_char_index < 3 else randi() % 3
	var p2_final: int = p2_char_index if p2_char_index < 3 else randi() % 3
	# Apply character types
	player1.character_type = p1_final as Bollard.CharacterType
	player2.character_type = p2_final as Bollard.CharacterType
	# Set character-themed colors
	var char_body_colors: Array[Color] = [
		Color("B080E0"),  # Blink — purple
		Color("80D080"),  # Goopy — green
		Color("70B8E8"),  # Zappy — blue
	]
	var char_accent_colors: Array[Color] = [
		Color("6020A0"),  # Blink — deep purple
		Color("306828"),  # Goopy — deep green
		Color("2060A0"),  # Zappy — deep blue
	]
	player1.bollard_color = char_body_colors[p1_final]
	player1.accent_color = char_accent_colors[p1_final]
	# If P2 picked the same character, lighten their colors so they're distinguishable
	if p2_final == p1_final:
		player2.bollard_color = char_body_colors[p2_final].lightened(0.25)
		player2.accent_color = char_accent_colors[p2_final].lightened(0.25)
	else:
		player2.bollard_color = char_body_colors[p2_final]
		player2.accent_color = char_accent_colors[p2_final]
	# Update shell sprite tints to match new colors
	player1.update_shell_colors()
	player2.update_shell_colors()
	# Apply stage — resolve "Random" first
	var final_stage := stage_index
	if STAGE_NAMES[final_stage] == "Random":
		# Pick a random non-Random stage
		final_stage = randi() % (STAGE_NAMES.size() - 1)
	_apply_stage(final_stage)
	# Hide select screen, start the game
	select_active = false
	select_layer.visible = false
	player1.visible = true
	player2.visible = true
	_start_countdown()


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
		countdown_label.add_theme_font_size_override("font_size", 40)
		countdown_label.add_theme_color_override("font_color", Color(1, 1, 1))
	elif countdown_timer < 3.0:
		countdown_label.text = "escar.."
		countdown_label.add_theme_font_size_override("font_size", 40)
		countdown_label.add_theme_color_override("font_color", Color(1, 1, 1))
	elif countdown_timer < 3.0 + GO_LINGER:
		countdown_label.text = "escarGO!"
		countdown_label.add_theme_font_size_override("font_size", 40)
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
	# Select screen runs its own update
	if select_active:
		_update_select_screen(delta)
		return

	# Slomo + impact effects always update regardless of game state
	_update_slomo_and_flashes(delta)

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
# ║ HIT SLOMO + IMPACT FLASH                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _on_big_hit(impact_pos: Vector2, is_deflect: bool = false) -> void:
	# Don't trigger effects during select screen or countdown
	if select_active or not game_active:
		return
	# Trigger slowmo
	slomo_timer = SLOMO_DURATION
	Engine.time_scale = SLOMO_SCALE

	# Deflect shards: neon green and 50% wider; normal: white
	var shard_color: Color = Color(0.2, 1.0, 0.3, 1.0) if is_deflect else Color(1.0, 1.0, 1.0, 1.0)
	var shard_width: float = 3.75 if is_deflect else 2.5

	# Spawn shards shooting outward from impact point
	for s_i in SHARD_COUNT:
		var angle := (float(s_i) / float(SHARD_COUNT)) * TAU + randf_range(-0.2, 0.2)
		var dir := Vector2(cos(angle), sin(angle))
		var shard := Line2D.new()
		shard.width = shard_width
		shard.default_color = shard_color
		shard.z_index = 10
		# Shard is a short line segment starting at impact
		var start_pos := impact_pos + dir * 4.0
		shard.add_point(start_pos)
		shard.add_point(start_pos + dir * 12.0)
		shard.top_level = true
		add_child(shard)
		impact_shards.append({
			"node": shard, "vel": dir * SHARD_SPEED * randf_range(0.7, 1.3),
			"timer": SHARD_DURATION, "origin": impact_pos})

	# Trigger screen ripple
	ripple_timer = RIPPLE_DURATION
	ripple_center = impact_pos
	if ripple_rect and ripple_rect.material:
		ripple_rect.visible = true
		var mat: ShaderMaterial = ripple_rect.material
		# Convert world pos to UV (0..1) relative to camera view
		var cam: Camera2D = $Camera2D
		var screen_size := get_viewport().get_visible_rect().size
		var cam_pos := cam.global_position
		var zoom := cam.zoom
		var world_tl := cam_pos - screen_size / (2.0 * zoom)
		var world_size := screen_size / zoom
		var uv := (impact_pos - world_tl) / world_size
		mat.set_shader_parameter("center", uv)
		mat.set_shader_parameter("time", 0.0)
		mat.set_shader_parameter("active", 1.0)


func _on_shards_only(impact_pos: Vector2) -> void:
	if select_active or not game_active:
		return
	# Spawn shards (purple for Blink teleport) but NO slomo and NO ripple
	var shard_color := Color(0.7, 0.3, 1.0, 1.0)
	for s_i in SHARD_COUNT:
		var angle := (float(s_i) / float(SHARD_COUNT)) * TAU + randf_range(-0.2, 0.2)
		var dir := Vector2(cos(angle), sin(angle))
		var shard := Line2D.new()
		shard.width = 2.5
		shard.default_color = shard_color
		shard.z_index = 10
		var start_pos := impact_pos + dir * 4.0
		shard.add_point(start_pos)
		shard.add_point(start_pos + dir * 12.0)
		shard.top_level = true
		add_child(shard)
		impact_shards.append({
			"node": shard, "vel": dir * SHARD_SPEED * randf_range(0.7, 1.3),
			"timer": SHARD_DURATION, "origin": impact_pos})


func _update_slomo_and_flashes(delta: float) -> void:
	# Slomo uses unscaled delta to count down in real time
	if slomo_timer > 0.0:
		var real_delta := delta / maxf(Engine.time_scale, 0.01)
		slomo_timer -= real_delta
		if slomo_timer <= 0.0:
			Engine.time_scale = 1.0

	# Update impact shards (fly outward + fade)
	var i := impact_shards.size() - 1
	while i >= 0:
		var real_dt := delta / maxf(Engine.time_scale, 0.01)
		var sh_time: float = impact_shards[i].timer
		sh_time -= real_dt
		impact_shards[i].timer = sh_time
		if sh_time <= 0.0:
			impact_shards[i].node.queue_free()
			impact_shards.remove_at(i)
		else:
			# Move shard outward
			var vel: Vector2 = impact_shards[i].vel
			var n: Line2D = impact_shards[i].node
			for p_i in n.get_point_count():
				n.set_point_position(p_i, n.get_point_position(p_i) + vel * real_dt)
			# Fade out
			var progress: float = 1.0 - sh_time / SHARD_DURATION
			var c := n.default_color
			c.a = lerpf(1.0, 0.0, progress)
			n.default_color = c
			# Shards slow down over time
			impact_shards[i].vel = vel * 0.95
		i -= 1

	# Update screen ripple shader
	if ripple_timer > 0.0:
		var real_dt := delta / maxf(Engine.time_scale, 0.01)
		ripple_timer -= real_dt
		if ripple_rect and ripple_rect.material:
			var mat: ShaderMaterial = ripple_rect.material
			var elapsed := RIPPLE_DURATION - ripple_timer
			mat.set_shader_parameter("time", elapsed)
			if ripple_timer <= 0.0:
				mat.set_shader_parameter("active", 0.0)
				ripple_rect.visible = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BLAST ZONE / RESPAWN                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _check_blast_zone(player: Bollard) -> void:
	if player.is_dead:
		return
	if not BLAST_ZONE.has_point(player.global_position):
		# Death slime splash at the point they crossed the boundary
		_spawn_death_slime(player)
		player.die()
		if player.stocks <= 0:
			_end_game(player)
		else:
			# Check for double death (both died within a short window)
			var now := Time.get_ticks_msec() / 1000.0
			var is_double := (now - last_death_time) < DOUBLE_DEATH_WINDOW
			last_death_time = now
			_show_death_phrase(is_double, player.was_hit_by_shell)
			player.was_hit_by_shell = false


func _spawn_death_slime(player: Bollard) -> void:
	# Big burst of slime at the edge of the visible screen where the player exited
	var cam: Camera2D = $Camera2D
	var screen_size := get_viewport().get_visible_rect().size
	var cam_pos := cam.global_position
	var zoom := cam.zoom
	var half_view := screen_size / (2.0 * zoom)
	# Visible world bounds
	var view_left := cam_pos.x - half_view.x
	var view_right := cam_pos.x + half_view.x
	var view_top := cam_pos.y - half_view.y
	var view_bottom := cam_pos.y + half_view.y
	# Clamp death position to the visible screen edge
	var pos := player.global_position
	pos.x = clampf(pos.x, view_left + 20.0, view_right - 20.0)
	pos.y = clampf(pos.y, view_top + 20.0, view_bottom - 20.0)
	var splash_count := 30
	for s_i in splash_count:
		var offset := Vector2(randf_range(-80.0, 80.0), randf_range(-60.0, 60.0))
		var dot_pos := pos + offset
		var c := player.slime_color
		c.a = 0.8
		slime_dots.append({"pos": dot_pos, "color": c, "age": 0.0})
	# Cap total dots
	while slime_dots.size() > SLIME_MAX_DOTS:
		slime_dots.pop_front()
	queue_redraw()


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

func _show_death_phrase(is_double: bool = false, shell_kill: bool = false) -> void:
	if is_double:
		death_phrase_label.text = DOUBLE_DEATH_PHRASES[randi() % DOUBLE_DEATH_PHRASES.size()]
	elif shell_kill:
		# Shell kills can pull from normal phrases OR shell-specific phrases
		var combined: Array = DEATH_PHRASES + SHELL_KILL_PHRASES
		death_phrase_label.text = combined[randi() % combined.size()]
	else:
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
	var winner_name: String = "Player 1" if loser == player2 else ("Player 2 (AI)" if player2.is_ai else "Player 2")
	game_over_label.text = winner_name + " WINS!\n\nPress T to restart"
	game_over_label.visible = true

func _restart_game(go_to_select: bool = true) -> void:
	Engine.time_scale = 1.0
	slomo_timer = 0.0
	ripple_timer = 0.0
	if ripple_rect and ripple_rect.material:
		ripple_rect.visible = false
		ripple_rect.material.set_shader_parameter("active", 0.0)
		ripple_rect.material.set_shader_parameter("time", 0.0)
	# Clean up any lingering shards
	for sh in impact_shards:
		sh.node.queue_free()
	impact_shards.clear()
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
	last_death_time = -999.0
	# Clear slime
	slime_dots.clear()
	queue_redraw()
	# Hard-reset BOTH players before countdown starts — stocks reset to 3,
	# dead players revive, alive players teleport to spawn
	var spawns: Array[Vector2] = [SPAWN_P1, SPAWN_P2]
	var players: Array[Bollard] = [player1, player2]
	for i in players.size():
		var p: Bollard = players[i]
		p.stocks = 3
		p.is_dead = false
		p.is_frozen = false
		p.is_emerging = false
		p.is_charging = false
		p.charge_amount = 0.0
		p.is_dashing = false
		p.charge_cooldown = 0.0
		p.dashes_remaining = p.CHARGE_MAX_DASHES
		p.is_toss_charging = false
		p.toss_charge_amount = 0.0
		p.shell_missing = false
		p.shell_deflected = false
		p.shell_toss_cooldown = 0.0
		p.is_parrying = false
		p.parry_cooldown = 0.0
		p.is_phase_dashing = false
		p.phase_dash_cooldown = 0.0
		p.can_teleport_to_shell = false
		p.blink_toss_used = false
		p.blink_teleport_used = false
		p.blink_phase_used = false
		p.goopy_tether_active = false
		p.goopy_tether_timer = 0.0
		p.is_goo_charging = false
		p.goo_charge_amount = 0.0
		p.is_goo_dashing = false
		p.goo_dash_cooldown = 0.0
		p.goo_trails.clear()
		p.is_bolt_charging = false
		p.bolt_charge_amount = 0.0
		p.is_bolt_dashing = false
		p.bolt_dash_cooldown = 0.0
		p.bolt_dashes_remaining = p.BOLT_DASH_MAX
		for dt in p.drop_through_bodies:
			if is_instance_valid(dt.body):
				p.remove_collision_exception_with(dt.body)
		p.drop_through_bodies.clear()
		p.damage_percent = 0.0
		p.extend_amount = 0.5
		p.linear_velocity = Vector2.ZERO
		p.angular_velocity = 0.0
		# Teleport RigidBody2D via PhysicsServer so the engine respects it
		PhysicsServer2D.body_set_state(p.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, spawns[i]))
		p.global_position = spawns[i]
		p.rotation = 0.0
		p.is_invincible = false
		if p.has_meta("respawn_timer"):
			p.remove_meta("respawn_timer")
	if go_to_select:
		player1.visible = false
		player2.visible = false
		_show_select_screen()
	else:
		player1.visible = true
		player2.visible = true
		_start_countdown()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T and not countdown_active and not select_active:
			_restart_game()
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		# P key toggles P2 between AI and human
		if event.keycode == KEY_P:
			_toggle_p2_ai()
	# Controller: Select/Back button to restart
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_BACK and not countdown_active and not select_active:
			_restart_game()
	# If P2 is AI and we get any input from controller device 1, switch to human
	if player2.is_ai and event.device == 1:
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			_toggle_p2_ai()
			if select_active:
				_update_select_display()


func _toggle_p2_ai() -> void:
	player2.is_ai = not player2.is_ai
	if player2.is_ai:
		player2.ai_target = player1
	else:
		player2.ai_target = null


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

	if not slime_dots.is_empty():
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
			# Place slime at bottom of shell (ground contact point)
			var pos := player.global_position + Vector2(0, player.BASE_RADIUS * 0.85)
			slime_dots.append({"pos": pos, "color": player.slime_color, "age": 0.0})
			# Cap total dots
			if slime_dots.size() > SLIME_MAX_DOTS:
				slime_dots.pop_front()
			break


func _draw() -> void:
	# Slime dots — flat colored ellipses (no texture lookup = much cheaper)
	for dot in slime_dots:
		var alpha := clampf(1.0 - dot.age / SLIME_LIFETIME, 0.0, 1.0) * 0.55
		var c := Color(dot.color.r, dot.color.g, dot.color.b, alpha)
		var w := 14.0
		var h := 5.0
		draw_rect(Rect2(dot.pos.x - w * 0.5, dot.pos.y - h * 0.5, w, h), c)


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

	# Shake — intensity scales with damage (1x at 0%, up to 3x at 150%+)
	if p1_shake_timer > 0.0:
		var p1_mult := 1.0 + 2.0 * clampf(player1.damage_percent / 150.0, 0.0, 1.0)
		var p1_s := SHAKE_INTENSITY * p1_mult
		p1_group.position = Vector2(
			randf_range(-p1_s, p1_s),
			randf_range(-p1_s, p1_s))
	else:
		p1_group.position = Vector2.ZERO

	if p2_shake_timer > 0.0:
		var p2_mult := 1.0 + 2.0 * clampf(player2.damage_percent / 150.0, 0.0, 1.0)
		var p2_s := SHAKE_INTENSITY * p2_mult
		p2_group.position = Vector2(
			randf_range(-p2_s, p2_s),
			randf_range(-p2_s, p2_s))
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
	# P1 keyboard: WASD = directional (lean + aim), Q=ability1, F=ability2, E=parry
	_add_key("p1_lean_left",  KEY_A)
	_add_key("p1_lean_right", KEY_D)
	_add_key("p1_aim_up",     KEY_W)
	_add_key("p1_aim_down",   KEY_S)
	_add_key("p1_ability1",   KEY_Q)
	_add_key("p1_ability2",   KEY_F)
	_add_key("p1_parry",      KEY_E)
	_add_key("p1_raise",      KEY_R)
	_add_key("p1_lower",      KEY_C)

	# P1 controller: L-Stick = lean/aim, R-Stick = raise/lower
	# Square/X = ability1, Cross/A = ability2, L1/LB = parry
	_add_joy_axis("p1_lean_left",  JOY_AXIS_LEFT_X, -1.0, 0)
	_add_joy_axis("p1_lean_right", JOY_AXIS_LEFT_X,  1.0, 0)
	_add_joy_axis("p1_aim_up",     JOY_AXIS_LEFT_Y, -1.0, 0)
	_add_joy_axis("p1_aim_down",   JOY_AXIS_LEFT_Y,  1.0, 0)
	_add_joy_axis("p1_raise",      JOY_AXIS_RIGHT_Y, -1.0, 0)
	_add_joy_axis("p1_lower",      JOY_AXIS_RIGHT_Y,  1.0, 0)
	_add_joy_button("p1_ability1", JOY_BUTTON_X, 0)       # Square / X
	_add_joy_button("p1_ability2", JOY_BUTTON_A, 0)       # Cross / A
	_add_joy_button("p1_parry",    JOY_BUTTON_LEFT_SHOULDER, 0)  # L1 / LB

	# P2 keyboard: Arrows = directional, Shift=ability1, .=ability2, /=parry
	_add_key("p2_lean_left",  KEY_LEFT)
	_add_key("p2_lean_right", KEY_RIGHT)
	_add_key("p2_aim_up",     KEY_UP)
	_add_key("p2_aim_down",   KEY_DOWN)
	_add_key("p2_ability1",   KEY_SHIFT)
	_add_key("p2_ability2",   KEY_PERIOD)
	_add_key("p2_parry",      KEY_SLASH)
	_add_key("p2_raise",      KEY_PAGEUP)
	_add_key("p2_lower",      KEY_PAGEDOWN)

	# P2 controller: same layout as P1, device 1
	_add_joy_axis("p2_lean_left",  JOY_AXIS_LEFT_X, -1.0, 1)
	_add_joy_axis("p2_lean_right", JOY_AXIS_LEFT_X,  1.0, 1)
	_add_joy_axis("p2_aim_up",     JOY_AXIS_LEFT_Y, -1.0, 1)
	_add_joy_axis("p2_aim_down",   JOY_AXIS_LEFT_Y,  1.0, 1)
	_add_joy_axis("p2_raise",      JOY_AXIS_RIGHT_Y, -1.0, 1)
	_add_joy_axis("p2_lower",      JOY_AXIS_RIGHT_Y,  1.0, 1)
	_add_joy_button("p2_ability1", JOY_BUTTON_X, 1)       # Square / X
	_add_joy_button("p2_ability2", JOY_BUTTON_A, 1)       # Cross / A
	_add_joy_button("p2_parry",    JOY_BUTTON_LEFT_SHOULDER, 1)  # L1 / LB

	for action in ["p1_lean_left", "p1_lean_right", "p1_aim_up", "p1_aim_down",
					"p2_lean_left", "p2_lean_right", "p2_aim_up", "p2_aim_down",
					"p1_raise", "p1_lower", "p2_raise", "p2_lower"]:
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
