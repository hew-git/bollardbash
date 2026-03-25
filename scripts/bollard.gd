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
const BASE_RADIUS := 22.0
const POST_HALF_WIDTH := 16.0
const MIN_HEIGHT := 2.0          ## Nearly invisible when fully retracted
const MAX_HEIGHT := 90.0

# ── Physics Tuning ──────────────────────────────────────────────────────────
const LEAN_TORQUE := 100000.0      ## GOOFY spin force
const EXTEND_SPEED := 6.0
const SELF_RIGHT_TORQUE := 0.0     ## No self-righting — full 360 spins always
const ANGULAR_DAMP_AMOUNT := 1.5   ## Low damping so spins carry momentum
const LAUNCH_BOOST := 400.0        ## Moderate upward boost — a usable jump, not a blast-off
const KNOCKBACK_BASE := 300.0
const HIT_SPEED_THRESHOLD := 80.0
const DAMAGE_MULTIPLIER := 0.04

# ── Grab Settings ───────────────────────────────────────────────────────────
const MAX_GRAB_TIME := 2.0

# ── Runtime State ───────────────────────────────────────────────────────────
var extend_amount: float = 0.5
var damage_percent: float = 0.0
var stocks: int = 3
var is_grabbing: bool = false
var grab_timer: float = 0.0
var grab_joint: PinJoint2D = null
var is_dead: bool = false
var prev_extend: float = 0.5
var is_invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_TIME := 1.5

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

	# Center of mass at the base circle center (origin) — zero gravity torque
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2(0, 0)
	mass = 2.0

	angular_damp = ANGULAR_DAMP_AMOUNT

	# Make shapes unique so two instanced bollards don't share the same shape
	base_shape.shape = base_shape.shape.duplicate()
	post_shape.shape = post_shape.shape.duplicate()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	prev_extend = extend_amount

	if is_ai:
		_process_ai(delta)
	else:
		_process_input(delta)

	# Self-righting (currently 0 — full spin allowed)
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
	if Input.is_action_pressed(act_lean_left):
		apply_torque(-LEAN_TORQUE)
	if Input.is_action_pressed(act_lean_right):
		apply_torque(LEAN_TORQUE)

	if Input.is_action_pressed(act_raise):
		extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
	if Input.is_action_pressed(act_lower):
		extend_amount = maxf(extend_amount - EXTEND_SPEED * delta, 0.0)

	if Input.is_action_just_pressed(act_grab):
		_try_grab()
	if Input.is_action_just_released(act_grab):
		_release_grab()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ COLLISION SHAPE — two shapes: circle base + rectangle post               ║
# ║ Only the visible portion of the bollard collides with the world.         ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_collision_shape() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)

	# Base circle stays at origin — always active, always the same size
	# (BaseShape position is already Vector2.ZERO)

	# Post rectangle: only as tall as the current extension
	var rect: RectangleShape2D = post_shape.shape
	rect.size = Vector2(POST_HALF_WIDTH * 2.0, post_h)
	# Center the rectangle on the visible post area (extends upward from origin)
	post_shape.position = Vector2(0, -post_h / 2.0)

	# Disable post collision when nearly fully retracted (just the base ball)
	post_shape.disabled = extend_amount < 0.03

	# Grab area follows the tip of the bollard at any extension
	grab_area.position = Vector2(0, -post_h)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ LAUNCH MECHANIC                                                          ║
# ║ Lower → spin upside-down → extend = jump into the air                   ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _check_launch() -> void:
	var extend_speed_now := extend_amount - prev_extend
	var upside_down: bool = cos(rotation) < -0.3

	if extend_speed_now > 0.08 and upside_down:
		# Moderate boost — enough for a useful jump, not a KO blast
		var boost := LAUNCH_BOOST * extend_speed_now * 6.0
		apply_central_impulse(Vector2(0, -boost))


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ GRAB MECHANIC                                                           ║
# ║ Works at ANY extension. Grabs players AND surfaces (platforms/ground).   ║
# ║ The grab point is at the tip. If you retract while grabbing, the joint   ║
# ║ pulls your body toward the grabbed thing.                                ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _try_grab() -> void:
	if is_grabbing:
		return

	# Check for any overlapping physics body (other bollards, platforms, ground)
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

	grab_joint = PinJoint2D.new()
	grab_joint.disable_collision = false
	grab_joint.node_a = get_path()
	grab_joint.node_b = target.get_path()
	grab_joint.softness = 0.5
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
	if grab_timer >= MAX_GRAB_TIME:
		_release_grab()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ COMBAT — Smash-style damage percentage and knockback                     ║
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
	is_invincible = true
	invincible_timer = 0.0


func _update_invincibility(delta: float) -> void:
	if not is_invincible:
		return
	invincible_timer += delta
	if invincible_timer >= INVINCIBLE_TIME:
		is_invincible = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ DRAWING — procedural bollard visual                                      ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _draw() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var hw := POST_HALF_WIDTH

	var draw_color := bollard_color
	if is_invincible and fmod(invincible_timer * 10.0, 2.0) > 1.0:
		draw_color = bollard_color.lightened(0.5)

	# ── Base circle at origin (the rotation pivot, sits on the ground) ──
	draw_circle(Vector2.ZERO, BASE_RADIUS, draw_color.darkened(0.25))

	# ── Post body extends upward from origin ──
	var rect_top := -post_h
	if post_h > 3.0:
		draw_rect(Rect2(-hw, rect_top, hw * 2.0, post_h), draw_color)

	# ── Dome on top ──
	var dome_pts := PackedVector2Array()
	for i in 17:
		var angle := float(i) / 16.0 * PI
		dome_pts.append(Vector2(cos(angle) * hw, rect_top - sin(angle) * hw))
	if dome_pts.size() >= 3:
		draw_colored_polygon(dome_pts, draw_color.lightened(0.12))

	# ── Reflective safety band ──
	if post_h > 25.0:
		var band_y := lerpf(0.0, rect_top, 0.6)
		draw_rect(Rect2(-hw - 1, band_y - 3, hw * 2.0 + 2, 6), accent_color)

	# ── Second band for taller bollards ──
	if post_h > 60.0:
		var band_y2 := lerpf(0.0, rect_top, 0.3)
		draw_rect(Rect2(-hw - 1, band_y2 - 3, hw * 2.0 + 2, 6), accent_color.darkened(0.1))

	# ── Grab indicator ──
	if is_grabbing:
		draw_circle(Vector2(0, rect_top - hw), 5.0, Color.RED)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ AI — Simple state-machine opponent                                       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _process_ai(delta: float) -> void:
	if ai_target == null or not is_instance_valid(ai_target) or ai_target.is_dead:
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
				_release_grab()
				_ai_pick_action()


func _ai_pick_action() -> void:
	ai_timer = 0.0
	var dist_x := ai_target.global_position.x - global_position.x
	var abs_dist := absf(dist_x)
	var roll := randf()

	if damage_percent > 100.0 and roll < 0.25:
		ai_state = "retreat"
		ai_action_duration = randf_range(0.5, 1.5)
	elif abs_dist > 200.0:
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
	apply_torque(LEAN_TORQUE * dir * 0.5)
	extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
	if not is_grabbing:
		_try_grab()
