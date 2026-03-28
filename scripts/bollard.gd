extends RigidBody2D
class_name Bollard

# ── Exported Configuration ──────────────────────────────────────────────────
@export var player_id: int = 1
@export var is_ai: bool = false
@export var bollard_color: Color = Color("B0A8C8")  ## Snail body color (light purple-gray)
@export var accent_color: Color = Color("A06830")    ## Shell color (warm brown)

# ── Dimensions ──────────────────────────────────────────────────────────────
const BASE_RADIUS := 22.0
const POST_HALF_WIDTH := 16.0
const MIN_HEIGHT := 2.0
const MAX_HEIGHT := 90.0

# ── Physics Tuning ──────────────────────────────────────────────────────────
const LEAN_TORQUE := 100000.0
const EXTEND_SPEED := 6.0
const ANGULAR_DAMP_AMOUNT := 1.5
const LAUNCH_BOOST := 300.0
const KNOCKBACK_BASE := 300.0
const HIT_SPEED_THRESHOLD := 80.0
const DAMAGE_MULTIPLIER := 0.04
const GRAB_LATCH_TIME := 0.3        # Seconds locked to surface before auto-fling
const GRAB_FLING_MULT := 2.2        # Velocity multiplier on release
const GRAB_RANGE := 120.0           # Max distance to latch onto a surface

# ── Visual Constants ────────────────────────────────────────────────────────
const EYE_RADIUS := 5.5
const STALK_LENGTH := 14.0
const STALK_SPREAD := 7.0

# ── Sprite Textures (preloaded — swap these PNGs for custom art) ──────────
const TEX_SHELL := preload("res://sprites/snail/shell.png")
const TEX_SPIRAL := preload("res://sprites/snail/shell_spiral.png")
const TEX_BODY := preload("res://sprites/snail/body.png")
const TEX_DOME := preload("res://sprites/snail/dome.png")
const TEX_EYE := preload("res://sprites/snail/eye.png")
const TEX_PUPIL := preload("res://sprites/snail/pupil.png")
const TEX_EYE_HL := preload("res://sprites/snail/eye_highlight.png")
const TEX_STALK := preload("res://sprites/snail/stalk.png")
const TEX_GRAB := preload("res://sprites/snail/grab_dot.png")

# ── Emerge Constants ────────────────────────────────────────────────────────
const EMERGE_DURATION := 0.6

# ── Runtime State ───────────────────────────────────────────────────────────
var extend_amount: float = 0.5
var damage_percent: float = 0.0
var stocks: int = 3
var is_dead: bool = false
var is_frozen: bool = false
var prev_extend: float = 0.5
var is_invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_TIME := 1.5

# ── Emerge State ────────────────────────────────────────────────────────────
var is_emerging: bool = false
var emerge_progress: float = 0.0

# ── Grab State (Latch and Fling) ───────────────────────────────────────────
var is_grabbing: bool = false
var want_to_grab: bool = false
var grab_timer: float = 0.0
var grab_target: Node2D = null          # What we latched to
var grab_anchor: Vector2 = Vector2.ZERO # World-space latch point on the surface
var grab_entry_vel: Vector2 = Vector2.ZERO  # Velocity when grab started

# ── Slime ───────────────────────────────────────────────────────────────────
var slime_color: Color = Color(0.5, 0.8, 0.3, 0.6)

# ── Blink State ─────────────────────────────────────────────────────────────
var is_blinking: bool = false
var blink_timer: float = 0.0
var next_blink_time: float = 3.0

# ── Nervous Eye State ──────────────────────────────────────────────────────
var nervous_timer: float = 0.0

# ── AI State ────────────────────────────────────────────────────────────────
var ai_target: Bollard = null
var ai_timer: float = 0.0
var ai_state: String = "idle"
var ai_action_duration: float = 0.5

# ── Input Action Names ─────────────────────────────────────────────────────
var act_lean_left: String
var act_lean_right: String
var act_raise: String
var act_lower: String
var act_grab: String

# ── Node References ─────────────────────────────────────────────────────────
@onready var base_shape: CollisionShape2D = $BaseShape
@onready var post_shape: CollisionShape2D = $PostShape
@onready var grab_area: Area2D = $GrabArea
@onready var grab_shape: CollisionShape2D = $GrabArea/GrabShape

# ── Sprite Node References (created in _ready) ────────────────────────────
var spr_shell: Sprite2D
var spr_spiral: Sprite2D
var spr_body: Sprite2D
var spr_dome: Sprite2D
var spr_stalk_l: Sprite2D
var spr_stalk_r: Sprite2D
var spr_eye_l: Sprite2D
var spr_eye_r: Sprite2D
var spr_pupil_l: Sprite2D
var spr_pupil_r: Sprite2D
var spr_eye_hl_l: Sprite2D
var spr_eye_hl_r: Sprite2D
var spr_grab: Sprite2D
# Blink lines drawn over eyes (Line2D since there's no blink sprite)
var blink_line_l: Line2D
var blink_line_r: Line2D


func _ready() -> void:
	var prefix := "p%d_" % player_id
	act_lean_left = prefix + "lean_left"
	act_lean_right = prefix + "lean_right"
	act_raise = prefix + "raise"
	act_lower = prefix + "lower"
	act_grab = prefix + "grab"

	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

	if not physics_material_override:
		physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.6
	physics_material_override.bounce = 0.15

	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2(0, 0)
	mass = 2.0
	angular_damp = ANGULAR_DAMP_AMOUNT

	base_shape.shape = base_shape.shape.duplicate()
	post_shape.shape = post_shape.shape.duplicate()

	# Replace the grab area's circle with a rectangle covering the full body (post)
	grab_shape.shape = RectangleShape2D.new()

	next_blink_time = randf_range(1.5, 5.0)
	_setup_sprites()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_emerging:
		_update_emerge(delta)
		return

	if is_frozen:
		_update_collision_shape()
		_update_blink(delta)
		nervous_timer += delta
		_update_sprites()
		return

	prev_extend = extend_amount
	nervous_timer += delta

	if is_ai:
		_process_ai(delta)
	else:
		_process_input(delta)

	_update_collision_shape()
	_update_grab(delta)
	_check_launch()
	_update_invincibility(delta)
	_update_blink(delta)
	_update_sprites()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ INPUT                                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _process_input(delta: float) -> void:
	# Lean and extend always work (no special grab-mode controls)
	if Input.is_action_pressed(act_lean_left):
		apply_torque(-LEAN_TORQUE)
	if Input.is_action_pressed(act_lean_right):
		apply_torque(LEAN_TORQUE)
	if Input.is_action_pressed(act_raise):
		extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
	if Input.is_action_pressed(act_lower):
		extend_amount = maxf(extend_amount - EXTEND_SPEED * delta, 0.0)

	# Grab — single press triggers latch (not held)
	if Input.is_action_just_pressed(act_grab):
		want_to_grab = true


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ COLLISION SHAPE                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_collision_shape() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var rect: RectangleShape2D = post_shape.shape
	rect.size = Vector2(POST_HALF_WIDTH * 2.0, post_h)
	post_shape.position = Vector2(0, -post_h / 2.0)
	post_shape.disabled = extend_amount < 0.03

	# Grab area covers the full body (post), not just the tip
	var grab_rect := grab_shape.shape as RectangleShape2D
	if grab_rect:
		grab_rect.size = Vector2(POST_HALF_WIDTH * 2.0 + 12, maxf(post_h, 10.0))
	grab_area.position = Vector2(0, -post_h * 0.5)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ LAUNCH MECHANIC                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _check_launch() -> void:
	var extend_speed_now := extend_amount - prev_extend
	var upside_down: bool = cos(rotation) < -0.3
	if extend_speed_now > 0.08 and upside_down:
		var boost := LAUNCH_BOOST * extend_speed_now * 6.0
		apply_central_impulse(Vector2(0, -boost))


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ GRAB — Latch and Fling                                                   ║
# ║                                                                           ║
# ║ Press grab near a surface → latch to closest point on it. Your entry    ║
# ║ velocity is converted to angular momentum around the latch point.        ║
# ║ After ~0.3s you auto-release with the built-up swing velocity ×          ║
# ║ GRAB_FLING_MULT. No manual swing — it's purely momentum-based.          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _try_grab() -> void:
	if is_grabbing:
		return

	# Collect all candidate bodies from grab area overlaps + direct contacts
	var candidates: Array[PhysicsBody2D] = []
	for body in grab_area.get_overlapping_bodies():
		if body != self and body is PhysicsBody2D and body not in candidates:
			candidates.append(body)
	for body in get_colliding_bodies():
		if body != self and body is PhysicsBody2D and body not in candidates:
			candidates.append(body)

	# Rank by closest surface point (not body center — ground center is far away)
	var best_body: PhysicsBody2D = null
	var best_dist := 999999.0
	for body in candidates:
		var surface_pt := _closest_point_on_body(body)
		var d := global_position.distance_to(surface_pt)
		if d < best_dist:
			best_dist = d
			best_body = body

	if best_body:
		_start_grab(best_body)


func _start_grab(target: PhysicsBody2D) -> void:
	is_grabbing = true
	grab_timer = 0.0
	grab_target = target
	grab_anchor = _closest_point_on_body(target)
	grab_entry_vel = linear_velocity


func _closest_point_on_body(body: PhysicsBody2D) -> Vector2:
	var best := body.global_position
	var best_dist := global_position.distance_to(best)

	for child in body.get_children():
		if not (child is CollisionShape2D) or child.disabled:
			continue
		var shape = child.shape
		var shape_pos = body.global_position + child.position.rotated(body.rotation)

		var candidate = global_position
		if shape is CircleShape2D:
			var cs: CircleShape2D = shape
			var dir = (global_position - shape_pos).normalized()
			candidate = shape_pos + dir * cs.radius
		elif shape is RectangleShape2D:
			var rs: RectangleShape2D = shape
			var half = rs.size * 0.5
			var local = global_position - shape_pos
			local.x = clampf(local.x, -half.x, half.x)
			local.y = clampf(local.y, -half.y, half.y)
			candidate = shape_pos + local

		var d = global_position.distance_to(candidate)
		if d < best_dist:
			best_dist = d
			best = candidate

	# Also handle CollisionPolygon2D (ground)
	for child in body.get_children():
		if not (child is CollisionPolygon2D):
			continue
		var poly = child.polygon
		for i in poly.size():
			var a = body.global_position + poly[i]
			var b = body.global_position + poly[(i + 1) % poly.size()]
			var candidate = _closest_point_on_segment(global_position, a, b)
			var d = global_position.distance_to(candidate)
			if d < best_dist:
				best_dist = d
				best = candidate

	return best


func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.001:
		return a
	var t := clampf((point - a).dot(ab) / len_sq, 0.0, 1.0)
	return a + ab * t


func _release_grab() -> void:
	if not is_grabbing:
		return
	is_grabbing = false
	grab_target = null


func _fling_release() -> void:
	# Calculate the tangential (swing) velocity from orbiting around the anchor
	var to_self := global_position - grab_anchor
	var dist := to_self.length()
	if dist > 1.0:
		var radial := to_self / dist
		# Tangent perpendicular to the radial direction
		var tangent := Vector2(-radial.y, radial.x)
		# Project current velocity onto tangent to get swing speed
		var swing_speed := linear_velocity.dot(tangent)
		# Fling in the tangential direction with multiplier
		var fling_vel := tangent * swing_speed * GRAB_FLING_MULT
		linear_velocity = fling_vel
	is_grabbing = false
	grab_target = null


func _update_grab(delta: float) -> void:
	if is_grabbing:
		if not is_instance_valid(grab_target):
			_release_grab()
			return
		grab_timer += delta

		# Track moving targets (e.g. other snails)
		if grab_target is RigidBody2D:
			grab_anchor += grab_target.linear_velocity * delta

		# Constrain to orbit: keep distance fixed, convert velocity to tangential
		var to_self := global_position - grab_anchor
		var dist := to_self.length()
		if dist > 1.0:
			var radial := to_self / dist
			var tangent := Vector2(-radial.y, radial.x)

			# On first frame, convert entry velocity to tangential orbit
			if grab_timer <= delta * 1.5:
				var tang_speed := grab_entry_vel.dot(tangent)
				linear_velocity = tangent * tang_speed

			# Keep snail at fixed radius from anchor (rope constraint)
			var orbit_radius := clampf(dist, 20.0, GRAB_RANGE)
			global_position = grab_anchor + radial * orbit_radius

			# Remove radial velocity component — only tangential remains
			var radial_vel := linear_velocity.dot(radial)
			linear_velocity -= radial * radial_vel

		# Auto-release after latch time with fling
		if grab_timer >= GRAB_LATCH_TIME:
			_fling_release()

	elif want_to_grab:
		_try_grab()
		want_to_grab = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ COMBAT                                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func take_damage(amount: float, knockback_dir: Vector2) -> void:
	if is_invincible:
		return
	damage_percent += amount
	var knockback_mult := 1.0 + damage_percent / 50.0
	apply_central_impulse(knockback_dir * KNOCKBACK_BASE * knockback_mult)

func _on_body_entered(body: Node) -> void:
	if is_invincible:
		return
	if not (body is RigidBody2D) or body == self or not body.has_method("take_damage"):
		return
	var other: RigidBody2D = body as RigidBody2D
	var rel_vel: Vector2 = linear_velocity - other.linear_velocity
	var impact: float = rel_vel.length()
	if impact > HIT_SPEED_THRESHOLD:
		var my_speed: float = linear_velocity.length()
		var other_speed: float = other.linear_velocity.length()
		var total: float = my_speed + other_speed
		if total < 1.0:
			return
		var my_ratio: float = my_speed / total
		var dmg: float = impact * DAMAGE_MULTIPLIER * my_ratio * 2.0
		var dir: Vector2 = (other.global_position - global_position).normalized()
		# Shell blocks damage — if we're hitting the other snail's shell
		# (base area), the hit is deflected and no damage is dealt.
		if other.has_method("is_shell_hit") and other.is_shell_hit(global_position):
			return
		other.take_damage(dmg, dir)


func is_shell_hit(attacker_pos: Vector2) -> bool:
	# Check if the attacker hit our shell (base) area.
	# The shell sits at our origin. If the attacker's position in our local
	# space is near the base and not up along the post, it's a shell hit.
	var local := to_local(attacker_pos)
	var post_h := lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	# Shell zone: y is in the lower 30% of the body (near base) and within shell radius
	return local.y > -post_h * 0.3 and local.length() < BASE_RADIUS * 1.8


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ RESPAWN / DEATH / EMERGE                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func die() -> void:
	stocks -= 1
	is_dead = true

func start_emerge(spawn_pos: Vector2) -> void:
	is_dead = false
	is_emerging = true
	emerge_progress = 0.0
	is_frozen = false
	visible = true
	# Teleport RigidBody2D properly: reset via PhysicsServer so the engine
	# doesn't fight the position change
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	var body_rid := get_rid()
	PhysicsServer2D.body_set_state(body_rid, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, spawn_pos))
	global_position = spawn_pos
	rotation = 0.0
	extend_amount = 0.0
	damage_percent = 0.0
	want_to_grab = false
	_release_grab()
	is_invincible = true
	invincible_timer = 0.0

func _update_emerge(delta: float) -> void:
	emerge_progress = minf(emerge_progress + delta / EMERGE_DURATION, 1.0)
	extend_amount = lerpf(0.0, 0.5, emerge_progress)
	_update_collision_shape()
	_update_blink(delta)
	nervous_timer += delta
	_update_sprites()
	if emerge_progress >= 1.0:
		is_emerging = false

func respawn(spawn_pos: Vector2) -> void:
	start_emerge(spawn_pos)

func _update_invincibility(delta: float) -> void:
	if not is_invincible:
		return
	invincible_timer += delta
	if invincible_timer >= INVINCIBLE_TIME:
		is_invincible = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BLINK                                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_blink(delta: float) -> void:
	blink_timer += delta
	if is_blinking:
		if blink_timer > 0.15:
			is_blinking = false
			blink_timer = 0.0
			next_blink_time = randf_range(2.0, 6.0)
	else:
		if blink_timer > next_blink_time:
			is_blinking = true
			blink_timer = 0.0


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ SPRITE SYSTEM                                                            ║
# ║                                                                           ║
# ║ All visuals use Sprite2D nodes with PNG textures from sprites/snail/.    ║
# ║ To replace any part with custom art:                                     ║
# ║   1. Open the PNG listed for that part in sprites/snail/                 ║
# ║   2. Paint your replacement at the same pixel size                       ║
# ║   3. Save — the game picks it up automatically on next run               ║
# ║                                                                           ║
# ║ Snail sprites use self_modulate for per-player coloring.                 ║
# ║ Shell uses accent_color, body/dome/stalks use bollard_color.             ║
# ║                                                                           ║
# ║ PARTS AND FILES:                                                          ║
# ║   shell.png          48x48  — shell sphere                               ║
# ║   shell_spiral.png   48x48  — spiral overlay (drawn on top of shell)     ║
# ║   body.png           32x90  — body cylinder (stretched vertically)       ║
# ║   dome.png           32x18  — dome cap on top of body                    ║
# ║   stalk.png           4x16  — eye stalk (used twice)                     ║
# ║   eye.png            12x12  — eyeball (used twice)                       ║
# ║   pupil.png           8x8   — pupil (used twice)                        ║
# ║   eye_highlight.png   6x6   — white reflection dot (used twice)         ║
# ║   grab_dot.png       10x10  — red grab indicator                        ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _setup_sprites() -> void:
	# Shell (bottom layer, behind body)
	spr_shell = _make_sprite(TEX_SHELL, Vector2.ZERO, -1)
	spr_shell.self_modulate = accent_color
	# Scale shell sprite to match BASE_RADIUS
	var shell_scale := (BASE_RADIUS * 2.0) / TEX_SHELL.get_width()
	spr_shell.scale = Vector2(shell_scale, shell_scale)

	spr_spiral = _make_sprite(TEX_SPIRAL, Vector2.ZERO, -1)
	spr_spiral.self_modulate = accent_color.darkened(0.15)
	spr_spiral.scale = Vector2(shell_scale, shell_scale)

	# Body (stretches vertically)
	spr_body = _make_sprite(TEX_BODY, Vector2.ZERO, 0)
	spr_body.self_modulate = bollard_color

	# Dome (on top of body)
	spr_dome = _make_sprite(TEX_DOME, Vector2.ZERO, 0)
	spr_dome.self_modulate = bollard_color

	# Stalks
	spr_stalk_l = _make_sprite(TEX_STALK, Vector2.ZERO, 1)
	spr_stalk_l.self_modulate = bollard_color
	spr_stalk_r = _make_sprite(TEX_STALK, Vector2.ZERO, 1)
	spr_stalk_r.self_modulate = bollard_color

	# Eyes
	spr_eye_l = _make_sprite(TEX_EYE, Vector2.ZERO, 2)
	spr_eye_r = _make_sprite(TEX_EYE, Vector2.ZERO, 2)

	# Pupils
	spr_pupil_l = _make_sprite(TEX_PUPIL, Vector2.ZERO, 3)
	spr_pupil_r = _make_sprite(TEX_PUPIL, Vector2.ZERO, 3)

	# Eye highlights
	spr_eye_hl_l = _make_sprite(TEX_EYE_HL, Vector2.ZERO, 4)
	spr_eye_hl_r = _make_sprite(TEX_EYE_HL, Vector2.ZERO, 4)

	# Grab indicator
	spr_grab = _make_sprite(TEX_GRAB, Vector2.ZERO, 5)
	spr_grab.visible = false

	# Blink lines (Line2D since they're just flat lines)
	blink_line_l = Line2D.new()
	blink_line_l.width = 2.5
	blink_line_l.default_color = Color.BLACK
	blink_line_l.z_index = 3
	blink_line_l.visible = false
	add_child(blink_line_l)

	blink_line_r = Line2D.new()
	blink_line_r.width = 2.5
	blink_line_r.default_color = Color.BLACK
	blink_line_r.z_index = 3
	blink_line_r.visible = false
	add_child(blink_line_r)


func _make_sprite(tex: Texture2D, pos: Vector2, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.z_index = z
	add_child(s)
	return s


func _update_sprites() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var hw := POST_HALF_WIDTH

	# ── Invincibility flash ──────────────────────────────────────────────
	var flash := is_invincible and fmod(invincible_timer * 10.0, 2.0) > 1.0
	var shell_c := accent_color.lightened(0.5) if flash else accent_color
	var body_c := bollard_color.lightened(0.5) if flash else bollard_color

	# ── SHELL ────────────────────────────────────────────────────────────
	spr_shell.self_modulate = shell_c
	spr_spiral.self_modulate = shell_c.darkened(0.15)

	# ── BODY (stretch vertically) ────────────────────────────────────────
	spr_body.visible = post_h > 3.0
	if post_h > 3.0:
		var body_sx: float = (hw * 2.0) / TEX_BODY.get_width()
		var body_sy: float = post_h / TEX_BODY.get_height()
		spr_body.scale = Vector2(body_sx, body_sy)
		# Anchor at bottom, extend upward: offset so bottom edge is at y=0
		spr_body.position = Vector2(0, -post_h * 0.5)
		spr_body.self_modulate = body_c

	# ── DOME ─────────────────────────────────────────────────────────────
	# Dome sits on top of body: flat bottom on body top, curve faces up
	var tip_y := -post_h
	var dome_sx: float = (hw * 2.0) / TEX_DOME.get_width()
	var dome_sy: float = (hw) / TEX_DOME.get_height()
	spr_dome.scale = Vector2(dome_sx, dome_sy)
	# Position: dome center is half its scaled height above the body top
	var dome_h: float = TEX_DOME.get_height() * dome_sy
	spr_dome.position = Vector2(0, tip_y - dome_h * 0.5)
	spr_dome.self_modulate = body_c

	# ── STALKS ───────────────────────────────────────────────────────────
	# Stalks extend from dome top to eye positions — no gap
	var dome_top_y: float = tip_y - dome_h
	var left_eye_pos := Vector2(-STALK_SPREAD, dome_top_y - STALK_LENGTH)
	var right_eye_pos := Vector2(STALK_SPREAD, dome_top_y - STALK_LENGTH)

	# Stalk base starts inside the dome (2px overlap) so there's no gap
	var stalk_base_y := dome_top_y + 2.0
	var stalk_total_l := stalk_base_y - left_eye_pos.y
	var stalk_total_r := stalk_base_y - right_eye_pos.y
	spr_stalk_l.position = Vector2(-STALK_SPREAD, (stalk_base_y + left_eye_pos.y) * 0.5)
	spr_stalk_r.position = Vector2(STALK_SPREAD, (stalk_base_y + right_eye_pos.y) * 0.5)
	spr_stalk_l.self_modulate = body_c
	spr_stalk_r.self_modulate = body_c
	spr_stalk_l.scale = Vector2(1.0, stalk_total_l / TEX_STALK.get_height())
	spr_stalk_r.scale = Vector2(1.0, stalk_total_r / TEX_STALK.get_height())

	# ── EYES + PUPILS ────────────────────────────────────────────────────
	var nervousness: float = clampf(damage_percent / 100.0, 0.0, 1.5)
	var eye_shift_speed: float = 4.0 + nervousness * 10.0
	var eye_shift_amount: float = nervousness * 2.8
	var pupil_offset_x: float = sin(nervous_timer * eye_shift_speed) * eye_shift_amount

	if is_blinking:
		spr_eye_l.visible = false
		spr_eye_r.visible = false
		spr_pupil_l.visible = false
		spr_pupil_r.visible = false
		spr_eye_hl_l.visible = false
		spr_eye_hl_r.visible = false
		blink_line_l.visible = true
		blink_line_r.visible = true
		blink_line_l.points = PackedVector2Array([
			left_eye_pos + Vector2(-5, 0), left_eye_pos + Vector2(5, 0)])
		blink_line_r.points = PackedVector2Array([
			right_eye_pos + Vector2(-5, 0), right_eye_pos + Vector2(5, 0)])
	else:
		spr_eye_l.visible = true
		spr_eye_r.visible = true
		spr_pupil_l.visible = true
		spr_pupil_r.visible = true
		spr_eye_hl_l.visible = true
		spr_eye_hl_r.visible = true
		blink_line_l.visible = false
		blink_line_r.visible = false

		spr_eye_l.position = left_eye_pos
		spr_eye_r.position = right_eye_pos

		spr_pupil_l.position = left_eye_pos + Vector2(pupil_offset_x, 0)
		spr_pupil_r.position = right_eye_pos + Vector2(pupil_offset_x, 0)

		spr_eye_hl_l.position = left_eye_pos + Vector2(-1.2 + pupil_offset_x * 0.5, -1.2)
		spr_eye_hl_r.position = right_eye_pos + Vector2(-1.2 + pupil_offset_x * 0.5, -1.2)

	# ── GRAB INDICATOR ──────────────────────────────────────────────────
	spr_grab.visible = is_grabbing and is_instance_valid(grab_target)
	if spr_grab.visible:
		spr_grab.position = Vector2(0, tip_y)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ AI                                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _process_ai(delta: float) -> void:
	if ai_target == null or not is_instance_valid(ai_target) or ai_target.is_dead:
		want_to_grab = false
		extend_amount = move_toward(extend_amount, 0.5, EXTEND_SPEED * 0.5 * delta)
		return
	ai_timer += delta
	match ai_state:
		"idle":
			if ai_timer > ai_action_duration:
				_ai_pick_action()
		"approach":
			_ai_approach(delta)
			if ai_timer > ai_action_duration:
				_ai_pick_action()
		"attack":
			_ai_attack(delta)
			if ai_timer > ai_action_duration:
				ai_state = "idle"
				ai_timer = 0.0
				ai_action_duration = randf_range(0.3, 0.8)
		"lower_spin":
			_ai_lower_spin(delta)
			if ai_timer > ai_action_duration:
				ai_state = "launch"
				ai_timer = 0.0
				ai_action_duration = 0.3
		"launch":
			extend_amount = minf(extend_amount + EXTEND_SPEED * 2.0 * delta, 1.0)
			if ai_timer > ai_action_duration:
				_ai_pick_action()
		"retreat":
			_ai_retreat(delta)
			if ai_timer > ai_action_duration:
				_ai_pick_action()
		"grab_attempt":
			_ai_grab_attempt(delta)
			if ai_timer > ai_action_duration:
				want_to_grab = false
				_release_grab()
				_ai_pick_action()

func _ai_pick_action() -> void:
	ai_timer = 0.0
	var abs_dist := absf(ai_target.global_position.x - global_position.x)
	var roll := randf()
	if damage_percent > 100.0 and roll < 0.25:
		ai_state = "retreat"
		ai_action_duration = randf_range(0.5, 1.5)
	elif abs_dist > 250.0:
		ai_state = "approach"
		ai_action_duration = randf_range(0.5, 2.0)
	elif roll < 0.12:
		ai_state = "lower_spin"
		ai_action_duration = randf_range(0.4, 0.8)
	elif roll < 0.25:
		ai_state = "grab_attempt"
		ai_action_duration = randf_range(0.5, 1.5)
	elif roll < 0.65:
		ai_state = "attack"
		ai_action_duration = randf_range(0.3, 1.0)
	else:
		ai_state = "approach"
		ai_action_duration = randf_range(0.3, 0.8)

func _ai_approach(delta: float) -> void:
	var dir := signf(ai_target.global_position.x - global_position.x)
	apply_torque(LEAN_TORQUE * dir)
	extend_amount = move_toward(extend_amount, 0.6, EXTEND_SPEED * 0.5 * delta)

func _ai_attack(delta: float) -> void:
	var dir := signf(ai_target.global_position.x - global_position.x)
	apply_torque(LEAN_TORQUE * 1.5 * dir)
	extend_amount = minf(extend_amount + EXTEND_SPEED * 1.5 * delta, 1.0)

func _ai_lower_spin(delta: float) -> void:
	extend_amount = maxf(extend_amount - EXTEND_SPEED * 2.0 * delta, 0.0)
	apply_torque(LEAN_TORQUE * 2.0)

func _ai_retreat(delta: float) -> void:
	var dir := -signf(ai_target.global_position.x - global_position.x)
	apply_torque(LEAN_TORQUE * dir * 0.8)
	extend_amount = move_toward(extend_amount, 0.3, EXTEND_SPEED * delta)

func _ai_grab_attempt(delta: float) -> void:
	var dir := signf(ai_target.global_position.x - global_position.x)
	if not is_grabbing:
		# Approach target and trigger grab
		apply_torque(LEAN_TORQUE * dir * 0.5)
		extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
		want_to_grab = true
