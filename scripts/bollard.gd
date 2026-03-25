extends RigidBody2D
class_name Bollard
## A physics-driven bollard fighter. Rocks on its rounded base, extends/retracts,
## and uses momentum for attacks. Think of it as a metal post that fights by
## leaning, spinning, and launching itself.

# ── Exported Configuration ──────────────────────────────────────────────────
@export var player_id: int = 1          ## 1 = left player, 2 = right player
@export var is_ai: bool = false         ## When true, AI controls this bollard
@export var bollard_color: Color = Color("5a5a6e")  ## Base color (steel gray)
@export var accent_color: Color = Color("d4d4e0")   ## Reflective band color

# ── Dimensions ──────────────────────────────────────────────────────────────
## BASE_RADIUS: the rounded bottom that lets the bollard rock and roll.
## POST_HALF_WIDTH: half the width of the rectangular post section.
## MIN_HEIGHT / MAX_HEIGHT: how short/tall the post section can be.
const BASE_RADIUS := 22.0
const POST_HALF_WIDTH := 16.0
const MIN_HEIGHT := 6.0
const MAX_HEIGHT := 90.0

# ── Physics Tuning ──────────────────────────────────────────────────────────
const LEAN_TORQUE := 70000.0       ## Rotational force when leaning — GOOFY FAST
const EXTEND_SPEED := 6.0          ## How fast the bollard raises/lowers (per second)
const SELF_RIGHT_TORQUE := 0.0     ## No self-righting — full 360 spins always allowed
const ANGULAR_DAMP_AMOUNT := 1.5   ## Low damping so spins carry momentum
const LAUNCH_BOOST := 1400.0       ## Upward impulse when doing the launch trick
const KNOCKBACK_BASE := 300.0      ## Base knockback force on hit
const HIT_SPEED_THRESHOLD := 80.0  ## Minimum collision speed to deal damage
const DAMAGE_MULTIPLIER := 0.04    ## Converts collision speed to damage percentage

# ── Grab Settings ───────────────────────────────────────────────────────────
const MAX_GRAB_TIME := 2.0         ## Grab auto-releases after this many seconds
const GRAB_MIN_EXTEND := 0.5       ## Must be at least this extended to grab

# ── Runtime State ───────────────────────────────────────────────────────────
var extend_amount: float = 0.5     ## 0.0 = fully lowered, 1.0 = fully raised
var damage_percent: float = 0.0    ## Smash-style damage (higher = more knockback)
var stocks: int = 3                ## Lives remaining
var is_grabbing: bool = false
var grab_timer: float = 0.0
var grab_joint: PinJoint2D = null
var is_dead: bool = false
var prev_extend: float = 0.5       ## Previous frame's extend_amount (for launch detection)
var is_invincible: bool = false     ## Brief invincibility after respawn
var invincible_timer: float = 0.0
const INVINCIBLE_TIME := 1.5

# ── AI State ────────────────────────────────────────────────────────────────
var ai_target: Bollard = null
var ai_timer: float = 0.0
var ai_state: String = "idle"
var ai_action_duration: float = 0.5

# ── Input Action Names (built from player_id in _ready) ────────────────────
var act_lean_left: String
var act_lean_right: String
var act_raise: String
var act_lower: String
var act_grab: String

# ── Node References ─────────────────────────────────────────────────────────
@onready var body_shape: CollisionShape2D = $BodyShape
@onready var grab_area: Area2D = $GrabArea


func _ready() -> void:
	# Build input action names: "p1_lean_left", "p2_raise", etc.
	var prefix := "p%d_" % player_id
	act_lean_left = prefix + "lean_left"
	act_lean_right = prefix + "lean_right"
	act_raise = prefix + "raise"
	act_lower = prefix + "lower"
	act_grab = prefix + "grab"

	# Enable contact monitoring so body_entered fires
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

	# Physics material: moderate friction for rolling, slight bounce
	if not physics_material_override:
		physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.6
	physics_material_override.bounce = 0.15

	# CRITICAL: Move center of mass to the base contact point.
	# By default Godot puts it at the center of the capsule, which makes the
	# bollard impossibly top-heavy — gravity torque (~160,000) dwarfs any lean
	# torque we can apply. With center of mass at the base, gravity creates ZERO
	# toppling torque, and we control stability entirely via self-righting torque.
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2(0, 0)  # At the base contact point
	mass = 2.0  # Lighter = more responsive to torques

	# Angular damping prevents the bollard from spinning out of control.
	angular_damp = ANGULAR_DAMP_AMOUNT


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	prev_extend = extend_amount

	if is_ai:
		_process_ai(delta)
	else:
		_process_input(delta)

	# Self-righting torque: simulates a weighted base pulling the bollard upright.
	# Scales with extend_amount so:
	#   - Lowered (extend=0): NO self-righting → spins freely for launch trick
	#   - Raised (extend=1): FULL self-righting → stable and controllable
	var tilt := sin(rotation)
	apply_torque(-tilt * SELF_RIGHT_TORQUE * extend_amount)

	_update_collision_shape()
	_update_grab(delta)
	_check_launch()
	_update_invincibility(delta)
	queue_redraw()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ INPUT                                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _process_input(delta: float) -> void:
	# Lean: applies torque so the bollard tips and rolls on its round base
	if Input.is_action_pressed(act_lean_left):
		apply_torque(-LEAN_TORQUE)
	if Input.is_action_pressed(act_lean_right):
		apply_torque(LEAN_TORQUE)

	# Raise / Lower: smoothly changes the bollard's height
	if Input.is_action_pressed(act_raise):
		extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
	if Input.is_action_pressed(act_lower):
		extend_amount = maxf(extend_amount - EXTEND_SPEED * delta, 0.0)

	# Grab: hold to grab, release to let go
	if Input.is_action_just_pressed(act_grab):
		_try_grab()
	if Input.is_action_just_released(act_grab):
		_release_grab()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ COLLISION SHAPE — dynamically resize as bollard extends/retracts         ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_collision_shape() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var total_h: float = post_h + BASE_RADIUS * 2.0

	# Resize the capsule
	var capsule: CapsuleShape2D = body_shape.shape
	capsule.radius = BASE_RADIUS
	capsule.height = total_h

	# Position so the BASE CIRCLE CENTER is at local (0, 0).
	# The bottom cap center aligns with the origin — this makes the bollard
	# rotate around its base, not some point below it.
	# Ground contact is at local y = +BASE_RADIUS (below origin).
	body_shape.position = Vector2(0, BASE_RADIUS - total_h / 2.0)

	# Move the grab detection area to the tip of the bollard
	grab_area.position = Vector2(0, BASE_RADIUS - total_h)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ LAUNCH MECHANIC                                                          ║
# ║ Lower the bollard → spin upside-down → extend rapidly → LAUNCH!         ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _check_launch() -> void:
	var extend_speed_now := extend_amount - prev_extend

	# Check if roughly upside-down: cos(rotation) < 0 means the top points downward
	var upside_down: bool = cos(rotation) < -0.3

	# If extending rapidly while upside-down, boost upward
	if extend_speed_now > 0.08 and upside_down:
		var boost := LAUNCH_BOOST * extend_speed_now * 6.0
		apply_central_impulse(Vector2(0, -boost))


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ GRAB MECHANIC                                                           ║
# ║ When raised, the tip of the bollard can grab other players or surfaces.  ║
# ║ Grab lasts up to MAX_GRAB_TIME seconds. Useful for throwing opponents    ║
# ║ or grabbing ledges for recovery.                                         ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _try_grab() -> void:
	if extend_amount < GRAB_MIN_EXTEND or is_grabbing:
		return

	var bodies := grab_area.get_overlapping_bodies()
	for body in bodies:
		if body == self:
			continue
		if body is PhysicsBody2D:
			_start_grab(body)
			return


func _start_grab(target: PhysicsBody2D) -> void:
	is_grabbing = true
	grab_timer = 0.0

	# Create a temporary pin joint connecting our tip to the target
	grab_joint = PinJoint2D.new()
	grab_joint.disable_collision = false
	grab_joint.node_a = get_path()
	grab_joint.node_b = target.get_path()
	grab_joint.softness = 0.8
	add_child(grab_joint)
	grab_joint.global_position = grab_area.global_position


func _release_grab() -> void:
	if not is_grabbing:
		return
	is_grabbing = false
	if is_instance_valid(grab_joint):
		grab_joint.queue_free()
	grab_joint = null


func _update_grab(delta: float) -> void:
	if not is_grabbing:
		return
	grab_timer += delta
	# Auto-release after time limit
	if grab_timer >= MAX_GRAB_TIME:
		_release_grab()
	# Also release if bollard retracts too much
	if extend_amount < GRAB_MIN_EXTEND * 0.5:
		_release_grab()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ COMBAT — Smash-style damage percentage and knockback                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func take_damage(amount: float, knockback_dir: Vector2) -> void:
	if is_invincible:
		return
	damage_percent += amount
	# Knockback scales with accumulated damage — low damage = barely move,
	# high damage = fly across the screen
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
		var dmg: float = impact * DAMAGE_MULTIPLIER
		var dir: Vector2 = (other.global_position - global_position).normalized()
		other.take_damage(dmg, dir)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ RESPAWN / DEATH                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func die() -> void:
	stocks -= 1
	is_dead = true


func respawn(pos: Vector2) -> void:
	is_dead = false
	damage_percent = 0.0
	extend_amount = 0.5
	global_position = pos
	rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_release_grab()
	# Brief invincibility after respawn
	is_invincible = true
	invincible_timer = 0.0


func _update_invincibility(delta: float) -> void:
	if not is_invincible:
		return
	invincible_timer += delta
	if invincible_timer >= INVINCIBLE_TIME:
		is_invincible = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ DRAWING — procedural bollard visual (no sprites needed)                  ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _draw() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var total_h: float = post_h + BASE_RADIUS * 2.0
	var hw := POST_HALF_WIDTH

	# ── Invincibility flash ──
	var draw_color := bollard_color
	if is_invincible and fmod(invincible_timer * 10.0, 2.0) > 1.0:
		draw_color = bollard_color.lightened(0.5)

	# ── Base circle at origin (this IS the rotation pivot) ──
	draw_circle(Vector2.ZERO, BASE_RADIUS, draw_color.darkened(0.25))

	# ── Post body extends upward from origin ──
	# The base circle covers the lower portion, so the post visually
	# emerges from the top of the base.
	var rect_top := -post_h
	if post_h > 2.0:
		draw_rect(Rect2(-hw, rect_top, hw * 2.0, post_h), draw_color)

	# ── Dome on top (semicircle cap) ──
	var dome_pts := PackedVector2Array()
	for i in 17:
		var angle := float(i) / 16.0 * PI
		dome_pts.append(Vector2(cos(angle) * hw, rect_top - sin(angle) * hw))
	if dome_pts.size() >= 3:
		draw_colored_polygon(dome_pts, draw_color.lightened(0.12))

	# ── Reflective safety band ──
	if post_h > 25.0:
		var band_y := lerpf(0.0, rect_top, 0.6)
		draw_rect(
			Rect2(-hw - 1, band_y - 3, hw * 2.0 + 2, 6),
			accent_color
		)

	# ── Second band (lower) for taller bollards ──
	if post_h > 60.0:
		var band_y2 := lerpf(0.0, rect_top, 0.3)
		draw_rect(
			Rect2(-hw - 1, band_y2 - 3, hw * 2.0 + 2, 6),
			accent_color.darkened(0.1)
		)

	# ── Grab indicator (red dot at tip when grabbing) ──
	if is_grabbing:
		draw_circle(Vector2(0, rect_top - hw), 5.0, Color.RED)

	# ── Damage percentage text above the bollard ──
	# (drawn in world space — rotates with the bollard, which looks funny and fits
	# the silly vibe. The HUD shows the "real" readable percentage.)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ AI — Simple state-machine opponent                                       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _process_ai(delta: float) -> void:
	if ai_target == null or not is_instance_valid(ai_target) or ai_target.is_dead:
		# Just idle if no valid target
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
			# Rapidly extend to trigger the launch mechanic
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
				_release_grab()
				_ai_pick_action()


func _ai_pick_action() -> void:
	ai_timer = 0.0
	var dist_x := ai_target.global_position.x - global_position.x
	var abs_dist := absf(dist_x)
	var roll := randf()

	# High damage → sometimes retreat
	if damage_percent > 100.0 and roll < 0.25:
		ai_state = "retreat"
		ai_action_duration = randf_range(0.5, 1.5)
	# Far away → approach
	elif abs_dist > 200.0:
		ai_state = "approach"
		ai_action_duration = randf_range(0.5, 2.0)
	# Close enough for combat
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
	# Rapidly extend for an uppercut-style hit
	extend_amount = minf(extend_amount + EXTEND_SPEED * 1.5 * delta, 1.0)


func _ai_lower_spin(delta: float) -> void:
	# Lower and spin fast — preparation for launch
	extend_amount = maxf(extend_amount - EXTEND_SPEED * 2.0 * delta, 0.0)
	apply_torque(LEAN_TORQUE * 2.0)


func _ai_retreat(delta: float) -> void:
	var dir := -signf(ai_target.global_position.x - global_position.x)
	apply_torque(LEAN_TORQUE * dir * 0.8)
	extend_amount = move_toward(extend_amount, 0.3, EXTEND_SPEED * delta)


func _ai_grab_attempt(delta: float) -> void:
	var dir := signf(ai_target.global_position.x - global_position.x)
	apply_torque(LEAN_TORQUE * dir * 0.5)
	extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
	if not is_grabbing and extend_amount > GRAB_MIN_EXTEND:
		_try_grab()
