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
const SWING_FORCE := 5000.0        # Horizontal force when swinging while grabbed
const GRAB_ANGULAR_DAMP := 2.0     # Slight damp so swing is controllable

# ── Grab Settings ───────────────────────────────────────────────────────────
const MAX_GRAB_TIME := 2.0

# ── Visual Constants ────────────────────────────────────────────────────────
const EYE_COLOR := Color("E8C830")
const EYE_RADIUS := 5.5
const STALK_LENGTH := 14.0
const STALK_SPREAD := 7.0

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

# ── Grab State ──────────────────────────────────────────────────────────────
var is_grabbing: bool = false
var want_to_grab: bool = false
var grab_timer: float = 0.0
var grab_target: Node2D = null
var grab_joint: PinJoint2D = null

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
		queue_redraw()
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
	queue_redraw()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ INPUT                                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _process_input(delta: float) -> void:
	if is_grabbing and is_instance_valid(grab_joint):
		# SWING FROM ANCHOR: apply horizontal force at the body center.
		# The pin joint at the grab point converts this into a pendulum arc,
		# like swinging a yo-yo. The lean comes from the anchor, not the base.
		if Input.is_action_pressed(act_lean_left):
			apply_central_force(Vector2(-SWING_FORCE, 0))
		if Input.is_action_pressed(act_lean_right):
			apply_central_force(Vector2(SWING_FORCE, 0))
	else:
		# Normal lean: torque rotates the body around the base
		if Input.is_action_pressed(act_lean_left):
			apply_torque(-LEAN_TORQUE)
		if Input.is_action_pressed(act_lean_right):
			apply_torque(LEAN_TORQUE)

	# Extend/retract — locked while grabbing so the anchor doesn't slide
	if not is_grabbing:
		if Input.is_action_pressed(act_raise):
			extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
		if Input.is_action_pressed(act_lower):
			extend_amount = maxf(extend_amount - EXTEND_SPEED * delta, 0.0)

	# Grab — hold the button to enter "ready to grab" state
	want_to_grab = Input.is_action_pressed(act_grab)


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
# ║ GRAB                                                                      ║
# ║ Hold the grab button → "ready to grab". Any part of the body (post)     ║
# ║ that overlaps a surface or player triggers a grab. The anchor is at the  ║
# ║ contact point on the body. When grabbed, lean applies horizontal force   ║
# ║ that the pin joint converts into a pendulum swing — like a yo-yo.       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _try_grab() -> void:
	if is_grabbing:
		return
	# Check the grab area (covers the body/post)
	var bodies := grab_area.get_overlapping_bodies()
	for body in bodies:
		if body == self:
			continue
		if body is PhysicsBody2D:
			_start_grab(body)
			return
	# Also check direct body contacts (anything touching our collision shapes)
	for body in get_colliding_bodies():
		if body == self:
			continue
		if body is PhysicsBody2D:
			_start_grab(body)
			return


func _get_grab_anchor(target: PhysicsBody2D) -> Vector2:
	# Find the point on our body (post surface) closest to the target.
	# This becomes the anchor — the pivot for pendulum swing.
	var post_h := lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var hw := POST_HALF_WIDTH
	var local_target := to_local(target.global_position)
	# Clamp to post rectangle: x in [-hw, hw], y in [-post_h, 0]
	var clamped := Vector2(
		clampf(local_target.x, -hw, hw),
		clampf(local_target.y, -post_h, 0.0)
	)
	return to_global(clamped)


func _start_grab(target: PhysicsBody2D) -> void:
	is_grabbing = true
	grab_timer = 0.0
	grab_target = target

	var anchor := _get_grab_anchor(target)

	# Pin joint at the anchor point — the body's "hand" locks onto the target.
	# The snail swings freely under gravity from this point.
	grab_joint = PinJoint2D.new()
	grab_joint.node_a = get_path()
	grab_joint.node_b = target.get_path()
	grab_joint.softness = 0.0
	grab_joint.disable_collision = false
	add_child(grab_joint)
	grab_joint.global_position = anchor

	angular_damp = GRAB_ANGULAR_DAMP


func _release_grab() -> void:
	if not is_grabbing:
		return
	is_grabbing = false
	grab_target = null
	angular_damp = ANGULAR_DAMP_AMOUNT
	if is_instance_valid(grab_joint):
		grab_joint.queue_free()
	grab_joint = null


func _update_grab(delta: float) -> void:
	if is_grabbing:
		if not is_instance_valid(grab_target) or not want_to_grab:
			_release_grab()
			return
		grab_timer += delta
		if grab_timer >= MAX_GRAB_TIME:
			_release_grab()
	elif want_to_grab:
		_try_grab()


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
		other.take_damage(dmg, dir)


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
	global_position = spawn_pos
	rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
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
	queue_redraw()
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
# ║ DRAWING — 3D claymation style                                            ║
# ║                                                                           ║
# ║ SPRITE TRANSITION GUIDE:                                                  ║
# ║ Each visual part is drawn in its own section, clearly labeled. To         ║
# ║ replace any part with a sprite:                                           ║
# ║   1. Create a PNG at the listed size for that part                        ║
# ║   2. Add a Sprite2D child to the Bollard scene (bollard.tscn)            ║
# ║   3. Assign your PNG as the texture                                       ║
# ║   4. Set the Sprite2D position to match the "origin" noted below          ║
# ║   5. Comment out the _draw_* call for that part                           ║
# ║                                                                           ║
# ║ PARTS:                                                                    ║
# ║   Shell  — 64x64 circle, origin (0, 0)                                   ║
# ║   Body   — 32 x post_h rect, origin (0, 0), extends upward (neg Y)       ║
# ║   Dome   — 32x16 semicircle, sits on top of body                         ║
# ║   Stalks — two 3px lines from dome top to eye positions                   ║
# ║   Eyes   — 12x12 circles at stalk tips                                    ║
# ║   Grab   — 8x8 red dot at tip (only when grabbing)                       ║
# ║                                                                           ║
# ║ Light direction: top-left (consistent across all elements)                ║
# ╚══════════════════════════════════════════════════════════════════════════╝

# ── Clay Drawing Helpers ──────────────────────────────────────────────────
# These create the 3D claymation look with layered shading.
# Each one can be replaced by a single Sprite2D with a painted texture.

func _draw_clay_sphere(center: Vector2, radius: float, base_color: Color) -> void:
	# Drop shadow (offset down-right from light source at top-left)
	draw_circle(center + Vector2(2.5, 3.5), radius * 1.02, base_color.darkened(0.4))
	# Base sphere
	draw_circle(center, radius, base_color)
	# Inner light layer (slight shift toward light)
	draw_circle(center + Vector2(-1, -1), radius * 0.88, base_color.lightened(0.06))
	# Highlight blob (top-left where light hits)
	draw_circle(center + Vector2(-radius * 0.25, -radius * 0.28), radius * 0.45,
				base_color.lightened(0.18))
	# Specular spot (sharp bright point)
	draw_circle(center + Vector2(-radius * 0.2, -radius * 0.3), radius * 0.12,
				base_color.lightened(0.38))


func _draw_clay_cylinder(rect: Rect2, base_color: Color) -> void:
	# Drop shadow
	draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size), base_color.darkened(0.4))
	# Base fill
	draw_rect(rect, base_color)
	# Left edge shadow (away from light)
	var edge_w := maxf(rect.size.x * 0.12, 2.0)
	draw_rect(Rect2(rect.position, Vector2(edge_w, rect.size.y)),
			  base_color.darkened(0.15))
	# Right edge shadow (wrap-around)
	draw_rect(Rect2(Vector2(rect.end.x - edge_w, rect.position.y), Vector2(edge_w, rect.size.y)),
			  base_color.darkened(0.08))
	# Center-left highlight (where light hits the cylinder)
	var hl_x := rect.position.x + rect.size.x * 0.28
	var hl_w := rect.size.x * 0.28
	draw_rect(Rect2(hl_x, rect.position.y + 1, hl_w, rect.size.y - 2),
			  base_color.lightened(0.12))
	# Bright specular strip
	var sp_x := rect.position.x + rect.size.x * 0.32
	var sp_w := rect.size.x * 0.08
	draw_rect(Rect2(sp_x, rect.position.y + 3, sp_w, rect.size.y - 6),
			  base_color.lightened(0.22))


func _draw_clay_dome(center_x: float, top_y: float, radius: float, base_color: Color) -> void:
	# Shadow dome
	var shadow_pts := PackedVector2Array()
	for i in 17:
		var angle := float(i) / 16.0 * PI
		shadow_pts.append(Vector2(center_x + cos(angle) * radius + 2.5,
								  top_y - sin(angle) * radius + 3.5))
	if shadow_pts.size() >= 3:
		draw_colored_polygon(shadow_pts, base_color.darkened(0.4))
	# Base dome
	var pts := PackedVector2Array()
	for i in 17:
		var angle := float(i) / 16.0 * PI
		pts.append(Vector2(center_x + cos(angle) * radius, top_y - sin(angle) * radius))
	if pts.size() >= 3:
		draw_colored_polygon(pts, base_color.lightened(0.04))
	# Highlight on dome (top-left)
	var hl_pts := PackedVector2Array()
	for i in 9:
		var angle := float(i) / 8.0 * PI
		var r := radius * 0.55
		hl_pts.append(Vector2(center_x - radius * 0.15 + cos(angle) * r,
							  top_y - sin(angle) * r - radius * 0.1))
	if hl_pts.size() >= 3:
		draw_colored_polygon(hl_pts, base_color.lightened(0.16))
	# Specular dot
	draw_circle(Vector2(center_x - radius * 0.2, top_y - radius * 0.55),
				radius * 0.15, base_color.lightened(0.32))


func _draw() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var hw := POST_HALF_WIDTH

	# Invincibility flash
	var shell_c := accent_color
	var body_c := bollard_color
	if is_invincible and fmod(invincible_timer * 10.0, 2.0) > 1.0:
		shell_c = accent_color.lightened(0.5)
		body_c = bollard_color.lightened(0.5)

	# ── PART: SHELL ─────────────────────────────────────────────────────
	# 3D clay sphere with spiral grooves
	# Sprite size: 64x64, origin: (0, 0)
	_draw_clay_sphere(Vector2.ZERO, BASE_RADIUS, shell_c)

	# Spiral grooves (sculpted lines in the clay)
	var spiral_off := Vector2(-2, 2)
	for i in 5:
		var r: float = BASE_RADIUS * (0.78 - i * 0.14)
		if r > 3.0:
			var sa: float = 0.4 + i * 1.1
			var ea: float = sa + 2.8 - i * 0.3
			# Dark groove
			draw_arc(spiral_off, r, sa, ea, 16, shell_c.darkened(0.25), 2.0, true)
			# Light edge next to groove (raised clay catching light)
			draw_arc(spiral_off + Vector2(-0.5, -0.5), r - 0.8, sa, ea, 16,
					 shell_c.lightened(0.08), 0.8, true)

	# Shell opening (dark hole where body emerges)
	if post_h > 5.0:
		var open_pos := Vector2(0, -BASE_RADIUS * 0.35)
		draw_circle(open_pos, hw * 0.8, shell_c.darkened(0.5))
		draw_circle(open_pos + Vector2(-1, -1), hw * 0.7, shell_c.darkened(0.35))

	# ── PART: BODY (cylinder) ───────────────────────────────────────────
	# 3D clay cylinder that extends/retracts
	# Sprite: 32 x [variable height], origin: (0, 0), extends upward
	if post_h > 3.0:
		_draw_clay_cylinder(Rect2(-hw, -post_h, hw * 2.0, post_h), body_c)

	# ── PART: DOME (top cap) ────────────────────────────────────────────
	# 3D clay hemisphere on top of body
	# Sprite size: 32x16, sits at top of body
	var tip_y := -post_h
	_draw_clay_dome(0.0, tip_y, hw, body_c)

	# ── PART: EYE STALKS ───────────────────────────────────────────────
	# Clay rods extending from dome top
	# Could be replaced with two small Sprite2Ds
	var dome_top_y: float = tip_y - hw
	var left_eye := Vector2(-STALK_SPREAD, dome_top_y - STALK_LENGTH)
	var right_eye := Vector2(STALK_SPREAD, dome_top_y - STALK_LENGTH)

	var stalk_dark: Color = body_c.darkened(0.12)
	var stalk_light: Color = body_c.lightened(0.08)
	# Dark side of stalk (right side, away from light)
	draw_line(Vector2(-2, dome_top_y + 2), left_eye + Vector2(1, 0), stalk_dark, 3.5)
	draw_line(Vector2(4, dome_top_y + 2), right_eye + Vector2(1, 0), stalk_dark, 3.5)
	# Light side of stalk (left side, toward light)
	draw_line(Vector2(-4, dome_top_y + 2), left_eye + Vector2(-1, 0), stalk_light, 1.5)
	draw_line(Vector2(2, dome_top_y + 2), right_eye + Vector2(-1, 0), stalk_light, 1.5)

	# ── PART: EYES ──────────────────────────────────────────────────────
	# 3D clay spheres with pupils
	# Sprite size: 12x12 each, positioned at stalk tips
	var nervousness: float = clampf(damage_percent / 100.0, 0.0, 1.5)
	var eye_shift_speed: float = 4.0 + nervousness * 10.0
	var eye_shift_amount: float = nervousness * 2.8
	var pupil_offset_x: float = sin(nervous_timer * eye_shift_speed) * eye_shift_amount

	if is_blinking:
		# Closed eyes — thick clay lines
		draw_line(left_eye + Vector2(-5, 1), left_eye + Vector2(5, 1), body_c.darkened(0.2), 3.0)
		draw_line(left_eye + Vector2(-4, 0), left_eye + Vector2(4, 0), Color.BLACK, 2.0)
		draw_line(right_eye + Vector2(-5, 1), right_eye + Vector2(5, 1), body_c.darkened(0.2), 3.0)
		draw_line(right_eye + Vector2(-4, 0), right_eye + Vector2(4, 0), Color.BLACK, 2.0)
	else:
		# Eyeball spheres (3D clay look)
		for eye_pos in [left_eye, right_eye]:
			# Shadow
			draw_circle(eye_pos + Vector2(1.5, 2.0), EYE_RADIUS + 0.5, EYE_COLOR.darkened(0.45))
			# Base eye
			draw_circle(eye_pos, EYE_RADIUS, EYE_COLOR)
			# Inner light
			draw_circle(eye_pos + Vector2(-0.5, -0.5), EYE_RADIUS * 0.8, EYE_COLOR.lightened(0.1))
			# Highlight
			draw_circle(eye_pos + Vector2(-1.5, -2.0), EYE_RADIUS * 0.35, EYE_COLOR.lightened(0.3))

		# Pupils (dark clay dots with white reflection)
		var pupil_off := Vector2(pupil_offset_x, 0)
		for eye_pos in [left_eye, right_eye]:
			draw_circle(eye_pos + pupil_off, EYE_RADIUS * 0.5, Color(0.08, 0.06, 0.06))
			# Pupil highlight (like a glass marble reflection)
			draw_circle(eye_pos + Vector2(-1.2 + pupil_offset_x * 0.5, -1.2),
						EYE_RADIUS * 0.18, Color(1, 1, 1, 0.9))

	# ── PART: GRAB INDICATOR ────────────────────────────────────────────
	if is_grabbing and is_instance_valid(grab_target):
		draw_circle(Vector2(0, tip_y + 1), 5.0, Color(0.8, 0.1, 0.1, 0.4))
		draw_circle(Vector2(0, tip_y), 4.0, Color(0.9, 0.2, 0.15))


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ AI                                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _process_ai(delta: float) -> void:
	if ai_target == null or not is_instance_valid(ai_target) or ai_target.is_dead:
		want_to_grab = false
		extend_amount = move_toward(extend_amount, 0.5, EXTEND_SPEED * 0.5 * delta)
		return
	want_to_grab = (ai_state == "grab_attempt")
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
	if is_grabbing and is_instance_valid(grab_joint):
		apply_central_force(Vector2(SWING_FORCE * dir, 0))
	else:
		apply_torque(LEAN_TORQUE * dir * 0.5)
	if not is_grabbing:
		extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
