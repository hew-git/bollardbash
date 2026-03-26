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

# ── Grab Settings ───────────────────────────────────────────────────────────
const MAX_GRAB_TIME := 2.0

# ── Visual Constants ────────────────────────────────────────────────────────
const EYE_COLOR := Color("E8C830")
const EYE_RADIUS := 5.5
const STALK_LENGTH := 14.0
const STALK_SPREAD := 7.0

# ── Runtime State ───────────────────────────────────────────────────────────
var extend_amount: float = 0.5
var damage_percent: float = 0.0
var stocks: int = 3
var is_dead: bool = false
var prev_extend: float = 0.5
var is_invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_TIME := 1.5

# ── Grab State ──────────────────────────────────────────────────────────────
var is_grabbing: bool = false
var grab_timer: float = 0.0
var grab_target: Node2D = null
var grab_joint: PinJoint2D = null

# ── Blink State ─────────────────────────────────────────────────────────────
var is_blinking: bool = false
var blink_timer: float = 0.0
var next_blink_time: float = 3.0

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

	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2(0, 0)
	mass = 2.0
	angular_damp = ANGULAR_DAMP_AMOUNT

	base_shape.shape = base_shape.shape.duplicate()
	post_shape.shape = post_shape.shape.duplicate()

	# Randomize first blink so both snails don't blink in sync
	next_blink_time = randf_range(1.5, 5.0)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	prev_extend = extend_amount

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
# ║ COLLISION SHAPE                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_collision_shape() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var rect: RectangleShape2D = post_shape.shape
	rect.size = Vector2(POST_HALF_WIDTH * 2.0, post_h)
	post_shape.position = Vector2(0, -post_h / 2.0)
	post_shape.disabled = extend_amount < 0.03
	grab_area.position = Vector2(0, -post_h)


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
# ║ GRAB — rigid PinJoint at the tip                                         ║
# ║ Surfaces: tip locks to the surface, snail hangs/swings from it          ║
# ║ Players: other player is stuck to the grabber's tip                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _try_grab() -> void:
	if is_grabbing:
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
	grab_target = target

	# Create a rigid pin joint at the tip position.
	# This locks the tip to the target surface/body.
	grab_joint = PinJoint2D.new()
	grab_joint.node_a = get_path()
	grab_joint.node_b = target.get_path()
	grab_joint.softness = 0.0  # Completely rigid — tip is LOCKED
	grab_joint.disable_collision = false
	add_child(grab_joint)
	grab_joint.global_position = grab_area.global_position


func _release_grab() -> void:
	if not is_grabbing:
		return
	is_grabbing = false
	grab_target = null
	if is_instance_valid(grab_joint):
		grab_joint.queue_free()
	grab_joint = null


func _update_grab(delta: float) -> void:
	if not is_grabbing:
		return
	if not is_instance_valid(grab_target):
		_release_grab()
		return
	grab_timer += delta
	if grab_timer >= MAX_GRAB_TIME:
		_release_grab()


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
# ║ BLINK                                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_blink(delta: float) -> void:
	blink_timer += delta
	if is_blinking:
		# Blink lasts 0.15 seconds
		if blink_timer > 0.15:
			is_blinking = false
			blink_timer = 0.0
			next_blink_time = randf_range(2.0, 6.0)
	else:
		if blink_timer > next_blink_time:
			is_blinking = true
			blink_timer = 0.0


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ DRAWING — snail with shell, body, eye stalks                             ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _draw() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var hw := POST_HALF_WIDTH

	# Invincibility flash
	var shell_c := accent_color
	var body_c := bollard_color
	if is_invincible and fmod(invincible_timer * 10.0, 2.0) > 1.0:
		shell_c = accent_color.lightened(0.5)
		body_c = bollard_color.lightened(0.5)

	# ── SHELL (base circle) ──────────────────────────────────────────────
	# Main shell body
	draw_circle(Vector2.ZERO, BASE_RADIUS, shell_c)

	# Shell spiral lines — concentric arcs at staggered angles
	var spiral_off := Vector2(-2, 2)
	for i in 5:
		var r: float = BASE_RADIUS * (0.78 - i * 0.14)
		if r > 3.0:
			var sa: float = 0.4 + i * 1.1
			var ea: float = sa + 2.8 - i * 0.3
			draw_arc(spiral_off, r, sa, ea, 16, shell_c.darkened(0.18), 1.5, true)

	# Shell highlight (shiny spot)
	draw_circle(Vector2(-6, -6), BASE_RADIUS * 0.22, shell_c.lightened(0.25))

	# Shell opening (dark hole where body emerges)
	if post_h > 5.0:
		draw_circle(Vector2(0, -BASE_RADIUS * 0.35), hw * 0.75, shell_c.darkened(0.4))

	# ── SNAIL BODY ───────────────────────────────────────────────────────
	if post_h > 3.0:
		# Main body rectangle
		draw_rect(Rect2(-hw, -post_h, hw * 2.0, post_h), body_c)

		# Body sheen (lighter stripe down the center)
		var sheen_w: float = hw * 0.35
		draw_rect(Rect2(-sheen_w, -post_h + 3, sheen_w * 2.0, post_h - 6),
				  body_c.lightened(0.12))

	# Rounded tip of body (dome)
	var dome_pts := PackedVector2Array()
	var tip_y := -post_h
	for i in 17:
		var angle := float(i) / 16.0 * PI
		dome_pts.append(Vector2(cos(angle) * hw, tip_y - sin(angle) * hw))
	if dome_pts.size() >= 3:
		draw_colored_polygon(dome_pts, body_c.lightened(0.06))

	# ── EYE STALKS (purely visual — no collision) ────────────────────────
	var dome_top_y: float = tip_y - hw  # Very top of dome

	var left_eye := Vector2(-STALK_SPREAD, dome_top_y - STALK_LENGTH)
	var right_eye := Vector2(STALK_SPREAD, dome_top_y - STALK_LENGTH)

	# Stalks (thin lines from dome top)
	var stalk_c: Color = body_c.darkened(0.05)
	draw_line(Vector2(-3, dome_top_y + 2), left_eye, stalk_c, 2.5)
	draw_line(Vector2(3, dome_top_y + 2), right_eye, stalk_c, 2.5)

	if is_blinking:
		# Closed eyes — horizontal lines
		draw_line(left_eye + Vector2(-4, 0), left_eye + Vector2(4, 0), Color.BLACK, 2.5)
		draw_line(right_eye + Vector2(-4, 0), right_eye + Vector2(4, 0), Color.BLACK, 2.5)
	else:
		# Eyeballs (yellow)
		draw_circle(left_eye, EYE_RADIUS, EYE_COLOR)
		draw_circle(right_eye, EYE_RADIUS, EYE_COLOR)
		# Pupils (black)
		draw_circle(left_eye, EYE_RADIUS * 0.45, Color.BLACK)
		draw_circle(right_eye, EYE_RADIUS * 0.45, Color.BLACK)
		# Highlights (white sparkle)
		draw_circle(left_eye + Vector2(-1.5, -1.5), 1.8, Color.WHITE)
		draw_circle(right_eye + Vector2(-1.5, -1.5), 1.8, Color.WHITE)

	# ── GRAB INDICATOR ───────────────────────────────────────────────────
	if is_grabbing and is_instance_valid(grab_target):
		draw_circle(Vector2(0, tip_y), 4.0, Color.RED)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ AI                                                                       ║
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
	apply_torque(LEAN_TORQUE * dir * 0.5)
	extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
	if not is_grabbing:
		_try_grab()
