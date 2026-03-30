extends RigidBody2D
class_name Bollard

# ── Exported Configuration ──────────────────────────────────────────────────
enum CharacterType { BLINK, GOOPY, ZAPPY }

@export var player_id: int = 1
@export var is_ai: bool = false
@export var character_type: CharacterType = CharacterType.BLINK
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
# ── Charge Attack ───────────────────────────────────────────────────────────
const CHARGE_TIME := 0.3            # Seconds to reach full charge (fast for recovery)
const CHARGE_IMPULSE := 1800.0      # Impulse at full charge (strong recovery)
const CHARGE_DAMAGE := 20.0         # Damage dealt on charged hit
const CHARGE_HIT_RADIUS := 40.0     # Radius to detect hits during dash
const CHARGE_DASH_TIME := 0.35      # Duration of the dash (invulnerable burst)
const CHARGE_COOLDOWN := 1.0        # Cooldown after dash ends
const CHARGE_MAX_DASHES := 2        # Number of dashes before cooldown

# ── Shell Toss ──────────────────────────────────────────────────────────────
const SHELL_TOSS_SPEED := 1800.0    # Max speed of thrown shell (at full charge)
const SHELL_TOSS_MIN_SPEED := 600.0 # Min speed (quick tap)
const SHELL_TOSS_DAMAGE := 36.0     # Damage on hit
const SHELL_RETURN_TIME := 2.5      # Seconds before shell returns
const SHELL_TOSS_COOLDOWN := 0.5    # Brief cooldown after shell returns
const SHELL_GRAVITY := 400.0        # Gravity on thrown shell
const SHELL_BOUNCE := 0.6           # Bounce factor off surfaces
const SHELL_TOSS_CHARGE_TIME := 0.6 # Seconds to reach full toss charge
const SHELL_DEFLECT_BOOST := 1.5    # Speed multiplier when shell is deflected by a dash

# ── Parry (all characters) ─────────────────────────────────────────────────
const PARRY_DURATION := 0.25        # Invulnerability window
const PARRY_COOLDOWN := 0.8         # Cooldown after parry ends
const PARRY_RETRACT_SPEED := 12.0   # How fast body retracts into shell

# ── Blink: Phase Dash ──────────────────────────────────────────────────────
const PHASE_DASH_IMPULSE := 1400.0
const PHASE_DASH_TIME := 0.3
const PHASE_DASH_COOLDOWN := 0.8

# ── Goopy: Slime Tether + Goo Burst ────────────────────────────────────────
const TETHER_SPEED := 1600.0        # Tether projectile speed
const TETHER_MAX_LENGTH := 300.0    # Max tether reach
const TETHER_PULL_FORCE := 900.0    # Pull strength toward anchor
const TETHER_DURATION := 2.0        # How long tether lasts
const GOO_BURST_RADIUS := 120.0     # AoE radius
const GOO_BURST_DAMAGE := 25.0      # AoE damage
const GOO_BURST_KNOCKBACK := 600.0  # AoE knockback force
const GOO_BURST_COOLDOWN := 1.5

# ── Zappy: Spark Leap + Bolt Dash ──────────────────────────────────────────
const SPARK_LEAP_CHARGE_TIME := 0.5
const SPARK_LEAP_IMPULSE := 2200.0
const SPARK_LEAP_DAMAGE := 30.0
const SPARK_LEAP_HIT_RADIUS := 50.0
const BOLT_DASH_IMPULSE := 1200.0
const BOLT_DASH_TIME := 0.2
const BOLT_DASH_COOLDOWN := 0.6
const BOLT_DASH_MAX := 2            # Can double-tap

# ── Visual Constants ────────────────────────────────────────────────────────
const EYE_RADIUS := 5.5
const STALK_LENGTH := 22.0
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

# ── Aim Direction (shared by charge + toss) ────────────────────────────────
var aim_dir: Vector2 = Vector2.ZERO     # Current aim from WASD/stick
var last_aim_dir: Vector2 = Vector2(1.0, 0.0)  # Last non-zero aim (fallback for release)

# ── Charge Attack State ────────────────────────────────────────────────────
var is_charging: bool = false
var charge_amount: float = 0.0          # 0..1
var is_dashing: bool = false
var dash_timer: float = 0.0
var charge_cooldown: float = 0.0
var dashes_remaining: int = CHARGE_MAX_DASHES  # Resets after cooldown

# ── Hit Effect (slomo + flash) ─────────────────────────────────────────────
signal big_hit(impact_pos: Vector2, is_deflect: bool)

# ── Shell Toss State ──────────────────────────────────────────────────────
var shell_missing: bool = false         # True while shell is flying
var is_toss_charging: bool = false      # Holding toss to charge aim+power
var toss_charge_amount: float = 0.0     # 0..1
var shell_toss_pos: Vector2 = Vector2.ZERO
var shell_toss_vel: Vector2 = Vector2.ZERO
var shell_toss_timer: float = 0.0
var shell_toss_cooldown: float = 0.0
var shell_toss_hit: bool = false        # Already hit someone this throw
var shell_deflected: bool = false       # Shell was deflected back — can hit owner

# ── Parry State ─────────────────────────────────────────────────────────────
var is_parrying: bool = false
var parry_timer: float = 0.0
var parry_cooldown: float = 0.0

# ── Blink State ─────────────────────────────────────────────────────────────
var can_teleport_to_shell: bool = false  # True while shell is flying (press ability1 again)
var is_phase_dashing: bool = false
var phase_dash_timer: float = 0.0
var phase_dash_cooldown: float = 0.0

# ── Goopy State ─────────────────────────────────────────────────────────────
var tether_active: bool = false
var tether_anchor: Vector2 = Vector2.ZERO  # Where tether stuck to a surface
var tether_timer: float = 0.0
var goo_burst_cooldown: float = 0.0

# ── Zappy State ─────────────────────────────────────────────────────────────
var is_spark_charging: bool = false
var spark_charge_amount: float = 0.0
var is_bolt_dashing: bool = false
var bolt_dash_timer: float = 0.0
var bolt_dashes_remaining: int = BOLT_DASH_MAX
var bolt_dash_cooldown: float = 0.0

# ── Slime ───────────────────────────────────────────────────────────────────
var slime_color: Color = Color(0.5, 0.8, 0.3, 0.6)

# ── Blink State ─────────────────────────────────────────────────────────────
var is_blinking: bool = false
var blink_timer: float = 0.0
var next_blink_time: float = 3.0

# ── Eye Look State (replaces sine-wave nervous eyes) ──────────────────────
var eye_look_target: float = 0.0     # Where pupil wants to be (-1..1)
var eye_look_current: float = 0.0    # Smoothed current offset
var eye_look_hold_timer: float = 2.0 # Time left holding current gaze

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
var act_aim_up: String
var act_aim_down: String
var act_ability1: String   # Square / Q — character-specific
var act_ability2: String   # Cross / F — character-specific
var act_parry: String      # L1 / E — universal

# ── Node References ─────────────────────────────────────────────────────────
@onready var base_shape: CollisionShape2D = $BaseShape
@onready var post_shape: CollisionShape2D = $PostShape
var dome_shape: CollisionShape2D  # Created at runtime for dome cap

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
var spr_body_circle: Sprite2D    # Body-colored circle behind shell (visible when shell tossed)
var spr_thrown_shell: Sprite2D   # The shell projectile when tossed
var spr_thrown_spiral: Sprite2D  # Spiral overlay on thrown shell
# Blink lines drawn over eyes (Line2D since there's no blink sprite)
var blink_line_l: Line2D
var blink_line_r: Line2D


func _ready() -> void:
	var prefix := "p%d_" % player_id
	act_lean_left = prefix + "lean_left"
	act_lean_right = prefix + "lean_right"
	act_raise = prefix + "raise"
	act_lower = prefix + "lower"
	act_aim_up = prefix + "aim_up"
	act_aim_down = prefix + "aim_down"
	act_ability1 = prefix + "ability1"
	act_ability2 = prefix + "ability2"
	act_parry = prefix + "parry"

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
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE

	base_shape.shape = base_shape.shape.duplicate()
	post_shape.shape = post_shape.shape.duplicate()

	# Create dome collision shape at runtime (circle cap on top of body)
	dome_shape = CollisionShape2D.new()
	var dome_circle := CircleShape2D.new()
	dome_circle.radius = POST_HALF_WIDTH
	dome_shape.shape = dome_circle
	dome_shape.position = Vector2(0, -MIN_HEIGHT)
	add_child(dome_shape)

	# Disable the grab area (grab mechanic removed)
	$GrabArea.monitoring = false
	$GrabArea.monitorable = false

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
		_update_eye_look(delta)
		_update_sprites()
		return

	prev_extend = extend_amount

	if is_ai:
		_process_ai(delta)
	else:
		_process_input(delta)

	_update_collision_shape()
	_update_parry(delta)
	_update_charge(delta)
	_update_shell_toss(delta)
	_update_phase_dash(delta)
	_update_tether(delta)
	_update_bolt_dash(delta)
	_update_goo_burst_cooldown(delta)
	_check_launch()
	_update_invincibility(delta)
	_update_blink(delta)
	_update_eye_look(delta)
	_update_sprites()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ INPUT                                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _get_aim_dir() -> Vector2:
	# Build a 2D aim vector from WASD / left stick
	var aim := Vector2.ZERO
	if Input.is_action_pressed(act_lean_left):
		aim.x -= 1.0
	if Input.is_action_pressed(act_lean_right):
		aim.x += 1.0
	if Input.is_action_pressed(act_aim_up):
		aim.y -= 1.0
	if Input.is_action_pressed(act_aim_down):
		aim.y += 1.0
	return aim.normalized() if aim.length() > 0.1 else Vector2.ZERO


func _process_input(delta: float) -> void:
	# During any dash, no input — you're flying
	if is_dashing or is_phase_dashing or is_bolt_dashing:
		return

	# Read aim + lean
	aim_dir = _get_aim_dir()
	if aim_dir.length() > 0.1:
		last_aim_dir = aim_dir
	var lean_dir := aim_dir.x

	# ── Parry (all characters): quick retract + invulnerability ──────────
	if Input.is_action_just_pressed(act_parry) and parry_cooldown <= 0.0 and not is_parrying:
		_start_parry()
		return

	# ── Ability 1 (Square / Q) — character-specific ─────────────────────
	match character_type:
		CharacterType.BLINK:
			_input_blink_ability1(delta, lean_dir)
		CharacterType.GOOPY:
			_input_goopy_ability1(delta, lean_dir)
		CharacterType.ZAPPY:
			_input_zappy_ability1(delta, lean_dir)

	# ── Ability 2 (Cross / F) — character-specific ──────────────────────
	match character_type:
		CharacterType.BLINK:
			_input_blink_ability2(delta, lean_dir)
		CharacterType.GOOPY:
			_input_goopy_ability2(delta, lean_dir)
		CharacterType.ZAPPY:
			_input_zappy_ability2(delta, lean_dir)

	# If currently charging something, skip normal movement
	if is_charging or is_toss_charging or is_spark_charging:
		return

	# Normal movement — lean with left/right
	if lean_dir != 0.0:
		apply_torque(LEAN_TORQUE * lean_dir)

	# Raise/lower — stays where you leave it
	if Input.is_action_pressed(act_raise):
		extend_amount = minf(extend_amount + EXTEND_SPEED * delta, 1.0)
	if Input.is_action_pressed(act_lower):
		extend_amount = maxf(extend_amount - EXTEND_SPEED * delta, 0.0)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ PARRY (all characters)                                                   ║
# ║                                                                           ║
# ║ Quick retract into shell + brief invulnerability. Deflects projectiles.  ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _start_parry() -> void:
	is_parrying = true
	parry_timer = 0.0
	is_invincible = true
	invincible_timer = 0.0

func _update_parry(delta: float) -> void:
	if parry_cooldown > 0.0:
		parry_cooldown -= delta
	if not is_parrying:
		return
	parry_timer += delta
	# Retract body rapidly during parry
	extend_amount = maxf(extend_amount - PARRY_RETRACT_SPEED * delta, 0.0)
	if parry_timer >= PARRY_DURATION:
		is_parrying = false
		parry_cooldown = PARRY_COOLDOWN
		# Invincibility ends with parry (unless respawn invincibility is active)
		if invincible_timer < 0.1:
			is_invincible = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BLINK — Shell Toss + Teleport / Phase Dash                              ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _input_blink_ability1(delta: float, lean_dir: float) -> void:
	# Ability1: Shell toss (hold to charge, release to throw)
	# If shell is already flying, press again to teleport to it
	if shell_missing and can_teleport_to_shell and Input.is_action_just_pressed(act_ability1):
		_blink_teleport_to_shell()
		return
	if Input.is_action_pressed(act_ability1) and not shell_missing and shell_toss_cooldown <= 0.0:
		is_toss_charging = true
		toss_charge_amount = minf(toss_charge_amount + delta / SHELL_TOSS_CHARGE_TIME, 1.0)
		if lean_dir != 0.0:
			apply_torque(LEAN_TORQUE * lean_dir * 0.3)
	elif is_toss_charging:
		_fire_shell_toss()
		can_teleport_to_shell = true

func _input_blink_ability2(_delta: float, _lean_dir: float) -> void:
	# Ability2: Phase dash — short dash that passes through objects
	if Input.is_action_just_pressed(act_ability2) and phase_dash_cooldown <= 0.0:
		_start_phase_dash()

func _blink_teleport_to_shell() -> void:
	# Teleport snail to where the shell currently is
	var target := shell_toss_pos
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(rotation, target))
	global_position = target
	linear_velocity = shell_toss_vel * 0.3  # Keep some momentum from shell
	_return_shell()
	can_teleport_to_shell = false
	big_hit.emit(target, false)

func _start_phase_dash() -> void:
	var dash_dir := aim_dir
	if dash_dir.length() < 0.1:
		dash_dir = last_aim_dir
	is_phase_dashing = true
	phase_dash_timer = 0.0
	# Disable collision during phase dash
	base_shape.disabled = true
	post_shape.disabled = true
	if dome_shape:
		dome_shape.disabled = true
	apply_central_impulse(dash_dir * PHASE_DASH_IMPULSE)

func _update_phase_dash(delta: float) -> void:
	if phase_dash_cooldown > 0.0:
		phase_dash_cooldown -= delta
	if not is_phase_dashing:
		return
	phase_dash_timer += delta
	if phase_dash_timer >= PHASE_DASH_TIME:
		is_phase_dashing = false
		phase_dash_cooldown = PHASE_DASH_COOLDOWN
		# Re-enable collision
		_update_collision_shape()  # Restores shapes based on extend_amount
		base_shape.disabled = false


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ GOOPY — Slime Tether / Goo Burst                                        ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _input_goopy_ability1(_delta: float, _lean_dir: float) -> void:
	# Ability1: Fire a slime tether (sticks to surfaces, pull toward it)
	if tether_active:
		# While tether is active, holding ability1 pulls you toward the anchor
		if Input.is_action_pressed(act_ability1):
			var pull_dir: Vector2 = (tether_anchor - global_position).normalized()
			apply_central_force(pull_dir * TETHER_PULL_FORCE)
		return
	if Input.is_action_just_pressed(act_ability1):
		_fire_tether()

func _input_goopy_ability2(_delta: float, _lean_dir: float) -> void:
	# Ability2: Goo burst — AoE damage + knockback around self
	if Input.is_action_just_pressed(act_ability2) and goo_burst_cooldown <= 0.0:
		_goo_burst()

func _fire_tether() -> void:
	var tether_dir := aim_dir
	if tether_dir.length() < 0.1:
		tether_dir = last_aim_dir
	# Raycast to find anchor point
	var space := get_world_2d().direct_space_state
	var end_pos := global_position + tether_dir * TETHER_MAX_LENGTH
	var query := PhysicsRayQueryParameters2D.create(global_position, end_pos)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	if result:
		tether_active = true
		tether_anchor = result.position
		tether_timer = 0.0
	# If no surface hit, tether doesn't activate

func _update_tether(delta: float) -> void:
	if not tether_active:
		return
	tether_timer += delta
	# Tether breaks after duration or if too far
	var dist := global_position.distance_to(tether_anchor)
	if tether_timer >= TETHER_DURATION or dist > TETHER_MAX_LENGTH * 1.5:
		tether_active = false

func _goo_burst() -> void:
	goo_burst_cooldown = GOO_BURST_COOLDOWN
	# AoE: find all nearby bodies and damage/knockback them
	var space := get_world_2d().direct_space_state
	var shape_query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GOO_BURST_RADIUS
	shape_query.shape = circle
	shape_query.transform = Transform2D(0.0, global_position)
	shape_query.exclude = [get_rid()]
	var hits := space.intersect_shape(shape_query, 8)
	var hit_any := false
	for hit in hits:
		var collider = hit.collider
		if collider is RigidBody2D and collider.has_method("take_damage") and collider != self:
			var dir: Vector2 = (collider.global_position - global_position).normalized()
			collider.take_damage(GOO_BURST_DAMAGE, dir)
			collider.apply_central_impulse(dir * GOO_BURST_KNOCKBACK)
			hit_any = true
	# Deflect any in-flight shells in range
	# (handled by the shell toss update checking for goo burst)
	if hit_any:
		big_hit.emit(global_position, false)

func _update_goo_burst_cooldown(delta: float) -> void:
	if goo_burst_cooldown > 0.0:
		goo_burst_cooldown -= delta


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ ZAPPY — Spark Leap / Electric Bolt Dash                                 ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _input_zappy_ability1(delta: float, lean_dir: float) -> void:
	# Ability1: Spark Leap — hold to charge, release for big electric dash
	if Input.is_action_pressed(act_ability1) and charge_cooldown <= 0.0:
		is_spark_charging = true
		spark_charge_amount = minf(spark_charge_amount + delta / SPARK_LEAP_CHARGE_TIME, 1.0)
		extend_amount = maxf(extend_amount - EXTEND_SPEED * 2.0 * delta, 0.0)
		if lean_dir != 0.0:
			apply_torque(LEAN_TORQUE * lean_dir * 0.3)
	elif is_spark_charging:
		_start_spark_leap()

func _input_zappy_ability2(_delta: float, _lean_dir: float) -> void:
	# Ability2: Electric Bolt Dash — instant short dash, can double
	if Input.is_action_just_pressed(act_ability2) and bolt_dash_cooldown <= 0.0 and bolt_dashes_remaining > 0:
		_start_bolt_dash()

func _start_spark_leap() -> void:
	if spark_charge_amount < 0.15:
		is_spark_charging = false
		spark_charge_amount = 0.0
		return
	is_spark_charging = false
	is_dashing = true
	dash_timer = 0.0
	var dash_dir := aim_dir
	if dash_dir.length() < 0.1:
		dash_dir = last_aim_dir
	var impulse_strength := SPARK_LEAP_IMPULSE * spark_charge_amount
	# Airborne boost
	var on_ground := false
	for body in get_colliding_bodies():
		if body is StaticBody2D:
			on_ground = true
			break
	if not on_ground:
		impulse_strength *= 1.75
	apply_central_impulse(dash_dir * impulse_strength)
	spark_charge_amount = 0.0

func _start_bolt_dash() -> void:
	var dash_dir := aim_dir
	if dash_dir.length() < 0.1:
		dash_dir = last_aim_dir
	is_bolt_dashing = true
	bolt_dash_timer = 0.0
	bolt_dashes_remaining -= 1
	apply_central_impulse(dash_dir * BOLT_DASH_IMPULSE)

func _update_bolt_dash(delta: float) -> void:
	if bolt_dash_cooldown > 0.0:
		bolt_dash_cooldown -= delta
		if bolt_dash_cooldown <= 0.0:
			bolt_dashes_remaining = BOLT_DASH_MAX
	if not is_bolt_dashing:
		return
	bolt_dash_timer += delta
	_check_charge_hits()  # Bolt dash can hit things
	if bolt_dash_timer >= BOLT_DASH_TIME:
		is_bolt_dashing = false
		if bolt_dashes_remaining <= 0:
			bolt_dash_cooldown = BOLT_DASH_COOLDOWN


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ COLLISION SHAPE                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_collision_shape() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var rect: RectangleShape2D = post_shape.shape
	rect.size = Vector2(POST_HALF_WIDTH * 2.0, post_h)
	post_shape.position = Vector2(0, -post_h / 2.0)
	post_shape.disabled = extend_amount < 0.03

	# Dome cap sits on top of the post
	if dome_shape:
		dome_shape.position = Vector2(0, -post_h)
		dome_shape.disabled = extend_amount < 0.03


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
# ║ CHARGE ATTACK                                                            ║
# ║                                                                           ║
# ║ Hold charge + lean direction to build up power (0.8s to full).           ║
# ║ Release to dash in that direction. Full charge = big impulse + damage.   ║
# ║ During dash you're briefly invulnerable.                                 ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _start_charge_dash() -> void:
	if charge_amount < 0.15:
		is_charging = false
		charge_amount = 0.0
		return
	is_charging = false
	is_dashing = true
	dash_timer = 0.0
	dashes_remaining -= 1
	# Dash in aimed direction; fallback to last aimed direction
	var dash_dir := aim_dir
	if dash_dir.length() < 0.1:
		dash_dir = last_aim_dir
	var impulse_strength := CHARGE_IMPULSE * charge_amount
	# Airborne boost: 2x impulse when not touching ground (recovery mechanic)
	var on_ground := false
	for body in get_colliding_bodies():
		if body is StaticBody2D:
			on_ground = true
			break
	if not on_ground:
		impulse_strength *= 1.75
	apply_central_impulse(dash_dir * impulse_strength)
	charge_amount = 0.0


func _update_charge(delta: float) -> void:
	if charge_cooldown > 0.0:
		charge_cooldown -= delta
		if charge_cooldown <= 0.0:
			dashes_remaining = CHARGE_MAX_DASHES

	if is_dashing:
		dash_timer += delta
		_check_charge_hits()
		if dash_timer >= CHARGE_DASH_TIME:
			is_dashing = false
			# Only start cooldown when all dashes used
			if dashes_remaining <= 0:
				charge_cooldown = CHARGE_COOLDOWN


func _check_charge_hits() -> void:
	for body in get_colliding_bodies():
		if body == self or not (body is RigidBody2D):
			continue
		if not body.has_method("take_damage"):
			continue
		var dist := global_position.distance_to(body.global_position)
		if dist < CHARGE_HIT_RADIUS:
			var dir := (body.global_position - global_position).normalized()
			# Shell blocks charge too
			if body.has_method("is_shell_hit") and body.is_shell_hit(global_position):
				# Bounce off the shell
				linear_velocity = linear_velocity.bounce(dir) * 0.5
				_end_any_dash()
				return
			body.take_damage(CHARGE_DAMAGE, dir)
			# Billiard-style impact: big extra knockback on target
			if body is RigidBody2D:
				var impact_force := linear_velocity.length() * 3.0
				body.apply_central_impulse(dir * impact_force)
			# Slomo + flash
			var hit_pos := (global_position + body.global_position) * 0.5
			big_hit.emit(hit_pos, false)
			_end_any_dash()
			return

func _end_any_dash() -> void:
	if is_dashing:
		is_dashing = false
		if dashes_remaining <= 0:
			charge_cooldown = CHARGE_COOLDOWN
	if is_bolt_dashing:
		is_bolt_dashing = false
		if bolt_dashes_remaining <= 0:
			bolt_dash_cooldown = BOLT_DASH_COOLDOWN


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ SHELL TOSS                                                               ║
# ║                                                                           ║
# ║ Press toss to throw your shell as a projectile. It arcs with gravity,   ║
# ║ bounces off surfaces, and damages the opponent on hit. While the shell   ║
# ║ is gone you have no shell shield — is_shell_hit() returns false.         ║
# ║ Shell returns after a few seconds.                                       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _fire_shell_toss() -> void:
	# Called when toss button is released after charging
	is_toss_charging = false
	shell_missing = true
	shell_toss_hit = false
	shell_deflected = false
	shell_toss_timer = 0.0
	shell_toss_pos = global_position
	# Direction from aim; fallback to last aimed direction
	var toss_dir := aim_dir
	if toss_dir.length() < 0.1:
		toss_dir = last_aim_dir
	# Speed scales with charge amount
	var speed := lerpf(SHELL_TOSS_MIN_SPEED, SHELL_TOSS_SPEED, toss_charge_amount)
	shell_toss_vel = toss_dir * speed
	toss_charge_amount = 0.0


func _update_shell_toss(delta: float) -> void:
	if shell_toss_cooldown > 0.0:
		shell_toss_cooldown -= delta

	if not shell_missing:
		return

	shell_toss_timer += delta

	# Apply gravity
	shell_toss_vel.y += SHELL_GRAVITY * delta
	var prev_pos := shell_toss_pos
	shell_toss_pos += shell_toss_vel * delta

	# Bounce off surfaces: raycast from previous to new position (prevents tunneling)
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(prev_pos, shell_toss_pos)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	if result:
		# Place shell at hit point, offset by normal so it doesn't embed
		shell_toss_pos = result.position + result.normal * (BASE_RADIUS * 0.5)
		shell_toss_vel = shell_toss_vel.bounce(result.normal) * SHELL_BOUNCE

	# Safety: if shell is somehow inside geometry, push it out
	var overlap_query := PhysicsShapeQueryParameters2D.new()
	var shell_circle := CircleShape2D.new()
	shell_circle.radius = BASE_RADIUS * 0.4
	overlap_query.shape = shell_circle
	overlap_query.transform = Transform2D(0.0, shell_toss_pos)
	overlap_query.exclude = [get_rid()]
	overlap_query.collide_with_bodies = true
	overlap_query.collide_with_areas = false
	var overlaps := space.intersect_shape(overlap_query, 4)
	for overlap in overlaps:
		var collider = overlap.collider
		if collider is StaticBody2D:
			# Push shell out along the direction from collider to shell
			var push_dir: Vector2 = (shell_toss_pos - collider.global_position).normalized()
			shell_toss_pos += push_dir * 4.0
			# Also bounce velocity away from the surface
			if shell_toss_vel.dot(push_dir) < 0.0:
				shell_toss_vel = shell_toss_vel.bounce(push_dir) * SHELL_BOUNCE
			break

	# Check hit on snails
	if not shell_toss_hit:
		var shape_query := PhysicsShapeQueryParameters2D.new()
		var circle := CircleShape2D.new()
		circle.radius = BASE_RADIUS
		shape_query.shape = circle
		shape_query.transform = Transform2D(0.0, shell_toss_pos)
		# After deflect, shell can hit its owner (no exclude)
		if not shell_deflected:
			shape_query.exclude = [get_rid()]
		var hits := space.intersect_shape(shape_query, 4)
		for hit in hits:
			var collider = hit.collider
			if not (collider is RigidBody2D) or not collider.has_method("take_damage"):
				continue
			var target_body: RigidBody2D = collider
			# Skip self only if shell hasn't been deflected
			if target_body == self and not shell_deflected:
				continue
			# DEFLECT: if the target is dashing, they smack the shell back
			var is_target_dashing := false
			if target_body is Bollard:
				var target_snail: Bollard = target_body
				is_target_dashing = target_snail.is_dashing
			if is_target_dashing:
				# Deflect shell back toward thrower at boosted speed
				var deflect_dir: Vector2 = (global_position - shell_toss_pos).normalized()
				var deflect_speed := shell_toss_vel.length() * SHELL_DEFLECT_BOOST
				shell_toss_vel = deflect_dir * deflect_speed
				shell_deflected = true
				# Reset timer so the shell doesn't vanish immediately
				shell_toss_timer = 0.0
				# Slomo + flash on the deflect (green shards)
				big_hit.emit(shell_toss_pos, true)
				break
			var dir: Vector2 = (target_body.global_position - shell_toss_pos).normalized()
			target_body.take_damage(SHELL_TOSS_DAMAGE, dir)
			# Billiard-style impact: shell transfers momentum
			var shell_impact := shell_toss_vel.length() * 2.0
			target_body.apply_central_impulse(dir * shell_impact)
			# Slomo + flash
			big_hit.emit(shell_toss_pos, false)
			shell_toss_hit = true
			shell_toss_vel = -shell_toss_vel * 0.3
			break

	# Return shell after time expires
	if shell_toss_timer >= SHELL_RETURN_TIME:
		_return_shell()


func _return_shell() -> void:
	shell_missing = false
	shell_deflected = false
	shell_toss_cooldown = SHELL_TOSS_COOLDOWN


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
		# Dashing into another snail = big hit (same impact as shell toss)
		if is_dashing or is_bolt_dashing:
			dmg = maxf(dmg, CHARGE_DAMAGE)
			var impact_force := linear_velocity.length() * 3.0
			other.apply_central_impulse(dir * impact_force)
			var hit_pos := (global_position + other.global_position) * 0.5
			big_hit.emit(hit_pos, false)
			if is_dashing:
				is_dashing = false
				if dashes_remaining <= 0:
					charge_cooldown = CHARGE_COOLDOWN
			if is_bolt_dashing:
				is_bolt_dashing = false
				if bolt_dashes_remaining <= 0:
					bolt_dash_cooldown = BOLT_DASH_COOLDOWN
		other.take_damage(dmg, dir)


func is_shell_hit(attacker_pos: Vector2) -> bool:
	# No shell = no shield
	if shell_missing:
		return false
	# Check if the attacker hit our shell (base) area.
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
	is_charging = false
	charge_amount = 0.0
	is_dashing = false
	charge_cooldown = 0.0
	dashes_remaining = CHARGE_MAX_DASHES
	is_toss_charging = false
	toss_charge_amount = 0.0
	shell_missing = false
	shell_deflected = false
	shell_toss_cooldown = 0.0
	is_invincible = true
	invincible_timer = 0.0
	# Reset character ability state
	is_parrying = false
	parry_cooldown = 0.0
	is_phase_dashing = false
	phase_dash_cooldown = 0.0
	can_teleport_to_shell = false
	tether_active = false
	goo_burst_cooldown = 0.0
	is_spark_charging = false
	spark_charge_amount = 0.0
	is_bolt_dashing = false
	bolt_dash_cooldown = 0.0
	bolt_dashes_remaining = BOLT_DASH_MAX

func _update_emerge(delta: float) -> void:
	emerge_progress = minf(emerge_progress + delta / EMERGE_DURATION, 1.0)
	extend_amount = lerpf(0.0, 0.5, emerge_progress)
	_update_collision_shape()
	_update_blink(delta)
	_update_eye_look(delta)
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
# ║ EYE BLINK (animation)                                                    ║
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


func _update_eye_look(delta: float) -> void:
	eye_look_hold_timer -= delta
	if eye_look_hold_timer <= 0.0:
		# Pick new gaze direction: left, center, or right
		var roll := randf()
		if roll < 0.25:
			eye_look_target = 0.0
		elif roll < 0.625:
			eye_look_target = 1.0
		else:
			eye_look_target = -1.0
		# Hold duration: shorter when more damaged (more nervous)
		var nervousness := clampf(damage_percent / 100.0, 0.0, 1.5)
		var min_hold := lerpf(1.5, 0.15, nervousness)
		var max_hold := lerpf(3.5, 0.5, nervousness)
		eye_look_hold_timer = randf_range(min_hold, max_hold)
	# Smoothly move pupils toward target — faster when more damaged
	var nervousness := clampf(damage_percent / 100.0, 0.0, 1.5)
	var move_speed := 4.0 + nervousness * 10.0
	eye_look_current = move_toward(eye_look_current, eye_look_target, move_speed * delta)


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
# ║   (grab_dot.png      10x10  — unused, grab removed)                     ║
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

	# Body circle — body-colored circle behind shell, visible when shell is tossed
	var body_circle_scale := (BASE_RADIUS * 1.7) / TEX_SHELL.get_width()
	spr_body_circle = _make_sprite(TEX_SHELL, Vector2.ZERO, -2)
	spr_body_circle.self_modulate = bollard_color
	spr_body_circle.scale = Vector2(body_circle_scale, body_circle_scale)

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

	# Thrown shell (global coords — not attached to snail body)
	spr_thrown_shell = Sprite2D.new()
	spr_thrown_shell.texture = TEX_SHELL
	spr_thrown_shell.self_modulate = accent_color
	var ts_scale := (BASE_RADIUS * 2.0) / TEX_SHELL.get_width()
	spr_thrown_shell.scale = Vector2(ts_scale, ts_scale)
	spr_thrown_shell.z_index = 5
	spr_thrown_shell.top_level = true  # Positioned in world space
	spr_thrown_shell.visible = false
	add_child(spr_thrown_shell)

	spr_thrown_spiral = Sprite2D.new()
	spr_thrown_spiral.texture = TEX_SPIRAL
	spr_thrown_spiral.self_modulate = accent_color.darkened(0.15)
	spr_thrown_spiral.scale = Vector2(ts_scale, ts_scale)
	spr_thrown_spiral.z_index = 5
	spr_thrown_spiral.top_level = true
	spr_thrown_spiral.visible = false
	add_child(spr_thrown_spiral)

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
	var shell_c: Color = accent_color.lightened(0.5) if flash else accent_color
	var body_c: Color = bollard_color.lightened(0.5) if flash else bollard_color

	# ── CHARGE / ABILITY VISUALS ─────────────────────────────────────────
	if is_charging and charge_amount > 0.1:
		var shake := charge_amount * 3.0
		spr_body.position.x += randf_range(-shake, shake)
		body_c = body_c.lerp(Color(1.0, 0.3, 0.2), charge_amount * 0.5)
		shell_c = shell_c.lerp(Color(1.0, 0.5, 0.2), charge_amount * 0.4)
	if is_toss_charging and toss_charge_amount > 0.1:
		var shake := toss_charge_amount * 2.0
		spr_body.position.x += randf_range(-shake, shake)
		shell_c = shell_c.lerp(Color(1.0, 0.8, 0.2), toss_charge_amount * 0.5)
	if is_spark_charging and spark_charge_amount > 0.1:
		var shake := spark_charge_amount * 3.5
		spr_body.position.x += randf_range(-shake, shake)
		body_c = body_c.lerp(Color(0.3, 0.8, 1.0), spark_charge_amount * 0.6)
		shell_c = shell_c.lerp(Color(0.5, 0.9, 1.0), spark_charge_amount * 0.5)
	if is_dashing:
		body_c = Color(1.0, 0.4, 0.2)
		shell_c = Color(1.0, 0.6, 0.2)
	if is_phase_dashing:
		body_c = Color(0.6, 0.3, 1.0, 0.4)  # Ghostly purple, semi-transparent
		shell_c = Color(0.7, 0.4, 1.0, 0.4)
	if is_bolt_dashing:
		body_c = Color(0.3, 0.9, 1.0)  # Electric blue
		shell_c = Color(0.5, 1.0, 1.0)
	if is_parrying:
		shell_c = Color(1.0, 1.0, 0.6)  # Bright shield flash
		body_c = body_c.lerp(Color(1.0, 1.0, 0.8), 0.5)

	# ── BODY CIRCLE (behind shell — visible when shell is tossed) ────────
	spr_body_circle.self_modulate = body_c

	# ── SHELL ────────────────────────────────────────────────────────────
	spr_shell.visible = not shell_missing
	spr_spiral.visible = not shell_missing
	spr_shell.self_modulate = shell_c
	spr_spiral.self_modulate = shell_c.darkened(0.15)

	# ── THROWN SHELL (world-space projectile) ─────────────────────────────
	spr_thrown_shell.visible = shell_missing
	spr_thrown_spiral.visible = shell_missing
	if shell_missing:
		spr_thrown_shell.global_position = shell_toss_pos
		spr_thrown_spiral.global_position = shell_toss_pos
		# Spin the thrown shell
		spr_thrown_shell.rotation += 8.0 * get_physics_process_delta_time()
		spr_thrown_spiral.rotation = spr_thrown_shell.rotation

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
	var eye_shift_amount: float = 2.0 + clampf(damage_percent / 100.0, 0.0, 1.5) * 2.5
	var pupil_offset_x: float = eye_look_current * eye_shift_amount

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

	# Tether needs redraw every frame
	if character_type == CharacterType.GOOPY:
		queue_redraw()

func _draw() -> void:
	# Goopy tether line
	if tether_active and character_type == CharacterType.GOOPY:
		var local_anchor := to_local(tether_anchor)
		draw_line(Vector2.ZERO, local_anchor, Color(0.4, 0.85, 0.3, 0.8), 3.0)
		draw_circle(local_anchor, 5.0, Color(0.4, 0.85, 0.3, 0.9))


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
		"charge_attack":
			_ai_charge_attack(delta)
			if ai_timer > ai_action_duration:
				if is_charging:
					_start_charge_dash()
				if is_spark_charging:
					_start_spark_leap()
				_ai_pick_action()
		"shell_toss":
			_ai_shell_toss()
			_ai_pick_action()
		"ability2":
			_ai_ability2()
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
	elif roll < 0.08:
		ai_state = "lower_spin"
		ai_action_duration = randf_range(0.4, 0.8)
	elif roll < 0.26:
		# Use ability1 based on character type
		match character_type:
			CharacterType.BLINK:
				ai_state = "shell_toss"
				ai_action_duration = 0.1
			CharacterType.GOOPY:
				ai_state = "shell_toss"  # Fires tether (reuses toss slot)
				ai_action_duration = 0.1
			CharacterType.ZAPPY:
				ai_state = "charge_attack"
				ai_action_duration = randf_range(0.8, 1.5)
	elif roll < 0.34:
		ai_state = "ability2"
		ai_action_duration = 0.1
	elif roll < 0.55:
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

func _ai_charge_attack(delta: float) -> void:
	var dir := signf(ai_target.global_position.x - global_position.x)
	aim_dir = Vector2(dir, randf_range(-0.3, 0.0)).normalized()
	last_aim_dir = aim_dir
	apply_torque(LEAN_TORQUE * dir * 0.3)
	match character_type:
		CharacterType.ZAPPY:
			is_spark_charging = true
			spark_charge_amount = minf(spark_charge_amount + delta / SPARK_LEAP_CHARGE_TIME, 1.0)
		_:
			is_charging = true
			charge_amount = minf(charge_amount + delta / CHARGE_TIME, 1.0)

func _ai_shell_toss() -> void:
	var dir := signf(ai_target.global_position.x - global_position.x)
	aim_dir = Vector2(dir, randf_range(-0.5, 0.1)).normalized()
	last_aim_dir = aim_dir
	match character_type:
		CharacterType.BLINK:
			if shell_missing:
				# Teleport to shell if it's flying
				if can_teleport_to_shell:
					_blink_teleport_to_shell()
				return
			if shell_toss_cooldown > 0.0:
				return
			toss_charge_amount = randf_range(0.4, 1.0)
			_fire_shell_toss()
			can_teleport_to_shell = true
		CharacterType.GOOPY:
			if not tether_active:
				_fire_tether()
		_:
			if shell_missing or shell_toss_cooldown > 0.0:
				return
			toss_charge_amount = randf_range(0.4, 1.0)
			_fire_shell_toss()

func _ai_ability2() -> void:
	var dir := signf(ai_target.global_position.x - global_position.x)
	aim_dir = Vector2(dir, randf_range(-0.3, 0.1)).normalized()
	last_aim_dir = aim_dir
	match character_type:
		CharacterType.BLINK:
			if phase_dash_cooldown <= 0.0:
				_start_phase_dash()
		CharacterType.GOOPY:
			if goo_burst_cooldown <= 0.0:
				_goo_burst()
		CharacterType.ZAPPY:
			if bolt_dash_cooldown <= 0.0 and bolt_dashes_remaining > 0:
				_start_bolt_dash()
