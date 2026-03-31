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
const EXTEND_SPEED := 8.0
const ANGULAR_DAMP_AMOUNT := 1.5
const LAUNCH_BOOST := 200.0
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

# ── Shell Toss (all characters) ────────────────────────────────────────────
const SHELL_TOSS_SPEED := 1800.0    # Max speed of thrown shell (at full charge)
const SHELL_TOSS_MIN_SPEED := 600.0 # Min speed (quick tap)
const SHELL_TOSS_DAMAGE := 36.0     # Damage on hit (Blink base)
const SHELL_RETURN_TIME := 2.5      # Seconds before shell returns
const SHELL_TOSS_COOLDOWN := 0.5    # Brief cooldown after shell returns
const SHELL_GRAVITY := 400.0        # Gravity on thrown shell
const SHELL_BOUNCE := 0.75          # Bounce factor off surfaces (firm bounces)
const SHELL_TOSS_CHARGE_TIME := 0.6 # Seconds to reach full toss charge
const SHELL_DEFLECT_BOOST := 1.5    # Speed multiplier when shell is deflected by a dash
const SHELL_PICKUP_RADIUS := 35.0   # Walk over shell to pick it up

# ── Parry (all characters) ─────────────────────────────────────────────────
const PARRY_DURATION := 0.25        # Invulnerability window
const PARRY_COOLDOWN := 0.8         # Cooldown after parry ends
const PARRY_RETRACT_SPEED := 12.0   # How fast body retracts into shell

# ── Blink: Phase Dash ──────────────────────────────────────────────────────
const PHASE_DASH_IMPULSE := 1400.0
const PHASE_DASH_TIME := 0.315       # 5% longer
const PHASE_DASH_COOLDOWN := 0.8

# ── Goopy: Slime Shell Toss + Tether Swing + Goo Dash ──────────────────────
const GOOPY_TOSS_KNOCKBACK_MULT := 0.3  # 30% of Blink's shell knockback
const GOOPY_ZIP_IMPULSE := 2200.0    # Impulse when zipping to shell
const GOOPY_SWING_PULL := 1200.0     # Looser swing force (lower = looser)
const GOOPY_TETHER_DURATION := 6.0   # Max tether swing time (long for strategic use)
const GOO_DASH_IMPULSE := 1785.0     # Max dash impulse (15% shorter)
const GOO_DASH_MIN_IMPULSE := 637.0  # Min dash impulse (15% shorter)
const GOO_DASH_CHARGE_TIME := 0.5    # Charge time for full dash
const GOO_DASH_TIME := 0.4           # Dash duration
const GOO_DASH_COOLDOWN := 0.8       # Cooldown
const GOO_DASH_DAMAGE := 15.0        # Knockback damage on hit
const GOO_DASH_KNOCKBACK := 400.0    # Knockback impulse on hit
const GOO_TRAIL_RADIUS := 18.0       # Goo puddle size
const GOO_TRAIL_DURATION := 3.0      # How long goo puddles last

# ── Zappy: Electric Shell Toss + 3x Bolt Dash ─────────────────────────────
const ZAPPY_TOSS_SPEED := 1200.0     # Fixed speed (unchargeable, 33% less range)
const ZAPPY_TOSS_DAMAGE := 7.2       # Light damage (nerfed 40%)
const ZAPPY_TOSS_KNOCKBACK := 120.0  # Light knockback (nerfed 40%)
const ZAPPY_TOSS_COOLDOWN := 0.4     # Short cooldown
const ZAPPY_TOSS_RETURN_TIME := 1.5  # Returns faster
const ZAPPY_TOSS_MAX_RANGE := 151.0  # Max distance before shell stops (10% shorter)
const BOLT_DASH_CHARGE_TIME := 0.08  # Near-instant charge for snappy feel
const BOLT_DASH_SPEED := 1800.0      # Fixed dash speed (pixels/sec)
const BOLT_DASH_DISTANCE := 200.0    # Fixed dash distance (pixels)
const BOLT_DASH_COOLDOWN := 1.0      # Slightly shorter cooldown
const BOLT_DASH_MAX := 3             # 3 electric dashes

# ── Visual Constants ────────────────────────────────────────────────────────
const EYE_RADIUS := 5.5
const STALK_LENGTH := 22.0
const STALK_SPREAD := 7.0

# ── Sprite Textures (preloaded — swap these PNGs for custom art) ──────────
const TEX_SHELL := preload("res://sprites/snail/shell.png")
const TEX_SPIRAL := preload("res://sprites/snail/shell_spiral.png")
const TEX_BODY := preload("res://sprites/snail/body.png")   # Body tile segment (tiles vertically)
const TEX_DOME := preload("res://sprites/snail/dome.png")
const BODY_TILE_HEIGHT := 8.0    # Display height of each body tile (pixels)
const BODY_MAX_TILES := 12       # Max tiles needed (MAX_HEIGHT / BODY_TILE_HEIGHT, rounded up)
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
var was_hit_by_shell: bool = false  # Set when hit by a shell toss (for death phrases)
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
var facing_right: bool = true           # Which way the snail is visually facing

# ── Charge Attack State ────────────────────────────────────────────────────
var is_charging: bool = false
var charge_amount: float = 0.0          # 0..1
var is_dashing: bool = false
var dash_timer: float = 0.0
var charge_cooldown: float = 0.0
var dashes_remaining: int = CHARGE_MAX_DASHES  # Resets after cooldown

# ── Hit Effect (slomo + flash) ─────────────────────────────────────────────
signal big_hit(impact_pos: Vector2, is_deflect: bool)
signal shards_only(impact_pos: Vector2)  # Visual shards without slomo (e.g. Blink teleport)

# ── Shell Toss State ──────────────────────────────────────────────────────
var shell_missing: bool = false         # True while shell is flying
var is_toss_charging: bool = false      # Holding toss to charge aim+power
var toss_charge_amount: float = 0.0     # 0..1
var shell_toss_pos: Vector2 = Vector2.ZERO
var shell_toss_vel: Vector2 = Vector2.ZERO
var shell_toss_origin: Vector2 = Vector2.ZERO  # Where the shell was thrown from
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
var blink_toss_used: bool = false        # Shell toss once per jump
var blink_teleport_used: bool = false    # Teleport once per jump
var blink_phase_used: bool = false       # Phase dash once per jump — resets on ground touch
var is_phase_dashing: bool = false
var phase_dash_timer: float = 0.0
var phase_dash_cooldown: float = 0.0

# ── Goopy State ─────────────────────────────────────────────────────────────
var goopy_tether_active: bool = false        # Tether between goopy and thrown shell
var goopy_tether_timer: float = 0.0
var is_goo_charging: bool = false            # Charging goo dash
var goo_charge_amount: float = 0.0
var is_goo_dashing: bool = false
var goo_dash_timer: float = 0.0
var goo_dash_cooldown: float = 0.0
var goo_trails: Array = []                   # [{pos: Vector2, timer: float}] — sticky puddles

# ── Platform Drop-Through ───────────────────────────────────────────────────
var drop_through_bodies: Array = []  # StaticBody2Ds we're temporarily ignoring
const DROP_THROUGH_TIME := 0.25      # Seconds to keep collision disabled

# ── Zappy State ─────────────────────────────────────────────────────────────
var is_bolt_charging: bool = false
var bolt_charge_amount: float = 0.0
var is_bolt_dashing: bool = false
var bolt_dash_timer: float = 0.0
var bolt_dashes_remaining: int = BOLT_DASH_MAX
var bolt_dash_cooldown: float = 0.0
var bolt_dash_dir: Vector2 = Vector2.ZERO
var bolt_dash_origin: Vector2 = Vector2.ZERO

# ── Slime ───────────────────────────────────────────────────────────────────
var slime_color: Color = Color(0.5, 0.8, 0.3, 0.6)

# ── Eye Blink Animation ─────────────────────────────────────────────────────
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
var spr_body_tiles: Array[Sprite2D] = []  # Tiling body segments
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
	# Reset Blink abilities when touching ground
	if character_type == CharacterType.BLINK and (blink_toss_used or blink_teleport_used or blink_phase_used):
		for body in get_colliding_bodies():
			if body is StaticBody2D:
				blink_toss_used = false
				blink_teleport_used = false
				blink_phase_used = false
				break
	_update_drop_through(delta)
	_update_parry(delta)
	_update_charge(delta)
	_update_shell_toss(delta)
	_update_phase_dash(delta)
	_update_goopy_tether(delta)
	_update_goopy_zip(delta)
	_update_goo_dash(delta)
	_update_goo_trails(delta)
	_update_bolt_dash(delta)
	_check_launch()
	_update_invincibility(delta)
	_update_blink(delta)
	_update_eye_look(delta)
	_update_sprites()


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ INPUT                                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _get_aim_dir() -> Vector2:
	# Try analog stick first (smooth aiming for controller)
	var joy_device := player_id - 1  # P1 = device 0, P2 = device 1
	var stick := Vector2(
		Input.get_joy_axis(joy_device, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(joy_device, JOY_AXIS_LEFT_Y))
	if stick.length() > 0.3:
		return stick.normalized()
	# Fallback to digital input (keyboard WASD / D-pad)
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
	if is_dashing or is_phase_dashing or is_bolt_dashing or is_goo_dashing:
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
	if is_charging or is_toss_charging or is_bolt_charging or is_goo_charging:
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
	SFX.play_sfx("parry")

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
# ║ PLATFORM DROP-THROUGH                                                    ║
# ║                                                                           ║
# ║ Hold down while on a one-way platform to fall through it.                ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _update_drop_through(delta: float) -> void:
	# Age and restore drop-through exceptions
	var i := drop_through_bodies.size() - 1
	while i >= 0:
		drop_through_bodies[i].timer -= delta
		if drop_through_bodies[i].timer <= 0.0:
			var body: StaticBody2D = drop_through_bodies[i].body
			if is_instance_valid(body):
				remove_collision_exception_with(body)
			drop_through_bodies.remove_at(i)
		i -= 1

	# Check if holding down while on a one-way platform
	var holding_down := false
	if is_ai:
		holding_down = false  # AI doesn't drop through
	else:
		holding_down = Input.is_action_pressed(act_aim_down)
	if not holding_down:
		return
	for body in get_colliding_bodies():
		if not (body is StaticBody2D):
			continue
		# Check if this body has a one-way collision shape
		var is_one_way := false
		for child in body.get_children():
			if child is CollisionShape2D and child.one_way_collision:
				is_one_way = true
				break
		if is_one_way:
			# Already dropping through this one?
			var already := false
			for dt in drop_through_bodies:
				if dt.body == body:
					already = true
					break
			if not already:
				add_collision_exception_with(body)
				drop_through_bodies.append({"body": body, "timer": DROP_THROUGH_TIME})


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BLINK — Shell Toss + Teleport / Phase Dash                              ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _input_blink_ability1(delta: float, lean_dir: float) -> void:
	# Ability1: Shell toss (hold to charge, release to throw) — once per jump
	# If shell is already flying, press again to teleport to it (once per jump)
	if shell_missing and can_teleport_to_shell and not blink_teleport_used and Input.is_action_just_pressed(act_ability1):
		_blink_teleport_to_shell()
		return
	if Input.is_action_pressed(act_ability1) and not shell_missing and shell_toss_cooldown <= 0.0 and not blink_toss_used:
		is_toss_charging = true
		toss_charge_amount = minf(toss_charge_amount + delta / SHELL_TOSS_CHARGE_TIME, 1.0)
		if lean_dir != 0.0:
			apply_torque(LEAN_TORQUE * lean_dir * 0.3)
	elif is_toss_charging:
		_fire_shell_toss()
		blink_toss_used = true
		can_teleport_to_shell = true

func _input_blink_ability2(_delta: float, _lean_dir: float) -> void:
	# Ability2: Phase dash — once per jump
	if Input.is_action_just_pressed(act_ability2) and phase_dash_cooldown <= 0.0 and not blink_phase_used:
		_start_phase_dash()
		blink_phase_used = true

const BLAST_ZONE := Rect2(-1100, -900, 3480, 2500)  # Must match main.gd

func _blink_teleport_to_shell() -> void:
	# Don't teleport if shell is outside the death box
	if not BLAST_ZONE.has_point(shell_toss_pos):
		return
	var target := shell_toss_pos
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(rotation, target))
	global_position = target
	linear_velocity = shell_toss_vel * 0.3  # Keep some momentum from shell
	SFX.play_sfx("blink_teleport")
	_return_shell()
	can_teleport_to_shell = false
	blink_teleport_used = true
	shards_only.emit(target)  # Shards but NO slomo

func _start_phase_dash() -> void:
	var dash_dir := aim_dir
	if dash_dir.length() < 0.1:
		dash_dir = last_aim_dir
	is_phase_dashing = true
	phase_dash_timer = 0.0
	SFX.play_sfx("dash_phase")
	# Add collision exceptions for non-ground structures (platforms, center rock, etc.)
	# Ground is NOT excluded — you can't phase through the ground
	_phase_set_exceptions(true)
	apply_central_impulse(dash_dir * PHASE_DASH_IMPULSE)

func _phase_set_exceptions(enable: bool) -> void:
	# Phase through non-ground StaticBody2D AND other players (RigidBody2D snails)
	var main_node := get_tree().current_scene
	if not main_node:
		return
	var ground_node: Node = main_node.get_node_or_null("Ground")
	var slab_node: Node = main_node.get_node_or_null("Slab")
	for child in main_node.get_children():
		if child == self:
			continue
		if child is StaticBody2D and child != ground_node and child != slab_node:
			if enable:
				add_collision_exception_with(child)
			else:
				remove_collision_exception_with(child)
		elif child is RigidBody2D and child != self and child.has_method("take_damage"):
			# Phase through opponents
			if enable:
				add_collision_exception_with(child)
			else:
				remove_collision_exception_with(child)
	# Also check for walls added at runtime
	for name_str in ["WallLeft", "WallRight"]:
		var wall: Node = main_node.get_node_or_null(name_str)
		if wall and wall is StaticBody2D:
			if enable:
				add_collision_exception_with(wall)
			else:
				remove_collision_exception_with(wall)

func _update_phase_dash(delta: float) -> void:
	if phase_dash_cooldown > 0.0:
		phase_dash_cooldown -= delta
	if not is_phase_dashing:
		return
	phase_dash_timer += delta
	if phase_dash_timer >= PHASE_DASH_TIME:
		is_phase_dashing = false
		phase_dash_cooldown = PHASE_DASH_COOLDOWN
		# Remove collision exceptions
		_phase_set_exceptions(false)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ GOOPY — Slime Tether / Goo Burst                                        ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _input_goopy_ability1(delta: float, lean_dir: float) -> void:
	# Ability1: Slime shell toss — toss shell with tether, then zip or swing
	if shell_missing and goopy_tether_active:
		# Press Square again to zip to shell
		if Input.is_action_just_pressed(act_ability1):
			_goopy_zip_to_shell()
			return
		return
	if Input.is_action_pressed(act_ability1) and not shell_missing and shell_toss_cooldown <= 0.0:
		is_toss_charging = true
		toss_charge_amount = minf(toss_charge_amount + delta / SHELL_TOSS_CHARGE_TIME, 1.0)
		if lean_dir != 0.0:
			apply_torque(LEAN_TORQUE * lean_dir * 0.3)
	elif is_toss_charging:
		_fire_shell_toss()
		goopy_tether_active = true
		goopy_tether_timer = 0.0

func _input_goopy_ability2(delta: float, lean_dir: float) -> void:
	# Ability2: Chargeable goo dash — hold to charge, release to dash
	# Circle/B cancels goopy tether swing
	if goopy_tether_active and Input.is_action_just_pressed(act_ability2):
		_goopy_release_tether()
		return
	if Input.is_action_pressed(act_ability2) and goo_dash_cooldown <= 0.0 and not is_goo_dashing:
		is_goo_charging = true
		goo_charge_amount = minf(goo_charge_amount + delta / GOO_DASH_CHARGE_TIME, 1.0)
		extend_amount = maxf(extend_amount - EXTEND_SPEED * 1.5 * delta, 0.0)
		if lean_dir != 0.0:
			apply_torque(LEAN_TORQUE * lean_dir * 0.3)
	elif is_goo_charging:
		_start_goo_dash()

var is_goopy_zipping: bool = false     # True while zipping to shell (big hit)

func _goopy_zip_to_shell() -> void:
	var dir: Vector2 = (shell_toss_pos - global_position).normalized()
	apply_central_impulse(dir * GOOPY_ZIP_IMPULSE)
	is_goopy_zipping = true
	SFX.play_sfx("goopy_zip")
	# Tether stays visible — separate from the 6s tether timer
	# Zip ends when goopy reaches shell or touches a surface/player

func _goopy_release_tether() -> void:
	goopy_tether_active = false
	goopy_tether_timer = 0.0

func _update_goopy_zip(_delta: float) -> void:
	if not is_goopy_zipping:
		return
	queue_redraw()  # Keep tether line drawing
	# End zip when reaching shell
	var dist_to_shell := global_position.distance_to(shell_toss_pos)
	if dist_to_shell < SHELL_PICKUP_RADIUS:
		is_goopy_zipping = false
		_goopy_release_tether()
		return
	# End zip on contact with surface or player — check colliding bodies
	for body in get_colliding_bodies():
		if body == self:
			continue
		if body is StaticBody2D:
			# Hit a surface — end zip and release tether
			is_goopy_zipping = false
			_goopy_release_tether()
			return
		if body is RigidBody2D and body.has_method("take_damage"):
			var dir: Vector2 = (body.global_position - global_position).normalized()
			# Shell blocks the zip hit
			if body.has_method("is_shell_hit") and body.is_shell_hit(global_position):
				linear_velocity = linear_velocity.reflect(dir) * 0.5
				is_goopy_zipping = false
				_goopy_release_tether()
				return
			# Hit a player's body — big hit!
			body.take_damage(GOO_DASH_DAMAGE * 1.5, dir)
			var impact_force := linear_velocity.length() * 2.5
			body.apply_central_impulse(dir * impact_force)
			var hit_pos: Vector2 = (global_position + body.global_position) * 0.5
			big_hit.emit(hit_pos, false)
			is_goopy_zipping = false
			_goopy_release_tether()
			return

func _update_goopy_tether(delta: float) -> void:
	if not goopy_tether_active or not shell_missing:
		goopy_tether_active = false
		return
	# During zip, the tether stays but we don't count toward the 6s timer
	if is_goopy_zipping:
		return
	goopy_tether_timer += delta
	queue_redraw()
	# Only pull toward shell AFTER shell has hit a surface (not while flying)
	if shell_toss_hit:
		var to_shell: Vector2 = (shell_toss_pos - global_position)
		var dist := to_shell.length()
		if dist > 30.0:
			var dir := to_shell.normalized()
			apply_central_force(dir * GOOPY_SWING_PULL)
	# Auto-release after duration
	if goopy_tether_timer >= GOOPY_TETHER_DURATION:
		_goopy_release_tether()

var goo_dash_was_full_charge: bool = false  # Track if dash was fully charged

func _start_goo_dash() -> void:
	if goo_charge_amount < 0.1:
		is_goo_charging = false
		goo_charge_amount = 0.0
		return
	goo_dash_was_full_charge = goo_charge_amount >= 0.85
	is_goo_charging = false
	SFX.play_sfx("dash_goo")
	var dash_dir := aim_dir
	if dash_dir.length() < 0.1:
		dash_dir = last_aim_dir
	is_goo_dashing = true
	goo_dash_timer = 0.0
	var impulse := lerpf(GOO_DASH_MIN_IMPULSE, GOO_DASH_IMPULSE, goo_charge_amount)
	linear_velocity = Vector2.ZERO
	apply_central_impulse(dash_dir * impulse)
	goo_charge_amount = 0.0

func _update_goo_dash(delta: float) -> void:
	if goo_dash_cooldown > 0.0:
		goo_dash_cooldown -= delta
	if not is_goo_dashing:
		return
	goo_dash_timer += delta
	# Leave goo puddles along the path
	goo_trails.append({"pos": global_position, "timer": GOO_TRAIL_DURATION})
	# Check for dash hits
	_check_goo_dash_hits()
	if goo_dash_timer >= GOO_DASH_TIME:
		is_goo_dashing = false
		goo_dash_cooldown = GOO_DASH_COOLDOWN

func _check_goo_dash_hits() -> void:
	# Use both colliding bodies AND shape query for reliable hit detection
	var targets: Array = []
	for body in get_colliding_bodies():
		if body == self or not (body is RigidBody2D):
			continue
		if body.has_method("take_damage"):
			targets.append(body)
	var space := get_world_2d().direct_space_state
	var shape_q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = CHARGE_HIT_RADIUS
	shape_q.shape = circle
	shape_q.transform = Transform2D(0.0, global_position)
	shape_q.exclude = [get_rid()]
	var hits := space.intersect_shape(shape_q, 4)
	for hit in hits:
		var col = hit.collider
		if col is RigidBody2D and col.has_method("take_damage") and col != self:
			if not targets.has(col):
				targets.append(col)
	for body in targets:
		var dir: Vector2 = (body.global_position - global_position).normalized()
		# Shell blocks goo dash
		if body.has_method("is_shell_hit") and body.is_shell_hit(global_position):
			continue
		var dmg := GOO_DASH_DAMAGE
		var kb := GOO_DASH_KNOCKBACK
		if goo_dash_was_full_charge:
			dmg *= 1.5
			kb *= 1.5
		body.take_damage(dmg, dir)
		body.apply_central_impulse(dir * kb)
		if goo_dash_was_full_charge:
			var hit_pos: Vector2 = (global_position + body.global_position) * 0.5
			big_hit.emit(hit_pos, false)

func _update_goo_trails(delta: float) -> void:
	# Age trails, apply gravity so they fall to ground, slow enemies in goo
	var space := get_world_2d().direct_space_state
	var i := goo_trails.size() - 1
	while i >= 0:
		goo_trails[i].timer -= delta
		if goo_trails[i].timer <= 0.0:
			goo_trails.remove_at(i)
			i -= 1
			continue
		# Apply gravity to goo
		if not goo_trails[i].get("grounded", false):
			var goo_pos: Vector2 = goo_trails[i].pos
			var below := goo_pos + Vector2(0, 400.0 * delta)
			var query := PhysicsRayQueryParameters2D.create(goo_pos, goo_pos + Vector2(0, 20.0))
			query.exclude = [get_rid()]
			var result := space.intersect_ray(query)
			if result:
				goo_trails[i].pos = result.position - Vector2(0, 2.0)
				goo_trails[i].grounded = true
			else:
				goo_trails[i].pos = below
		i -= 1
	if goo_trails.is_empty():
		return
	for trail in goo_trails:
		var shape_query := PhysicsShapeQueryParameters2D.new()
		var circle := CircleShape2D.new()
		circle.radius = GOO_TRAIL_RADIUS * 2.0
		shape_query.shape = circle
		shape_query.transform = Transform2D(0.0, trail.pos)
		shape_query.exclude = [get_rid()]
		var hits := space.intersect_shape(shape_query, 4)
		for hit in hits:
			var collider = hit.collider
			if collider is RigidBody2D and collider != self and collider.has_method("take_damage"):
				collider.apply_central_force(-collider.linear_velocity * 3.0)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ ZAPPY — Spark Leap / Electric Bolt Dash                                 ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _input_zappy_ability1(_delta: float, _lean_dir: float) -> void:
	# Ability1: Electric shell toss — short-range, unchargeable, fast cooldown
	if Input.is_action_just_pressed(act_ability1) and not shell_missing and shell_toss_cooldown <= 0.0:
		_fire_zappy_shell_toss()

func _input_zappy_ability2(delta: float, lean_dir: float) -> void:
	# Ability2: 3x Bolt Dash — snappy charge, release to dash
	if Input.is_action_pressed(act_ability2) and bolt_dash_cooldown <= 0.0 and bolt_dashes_remaining > 0:
		is_bolt_charging = true
		bolt_charge_amount = minf(bolt_charge_amount + delta / BOLT_DASH_CHARGE_TIME, 1.0)
		extend_amount = maxf(extend_amount - EXTEND_SPEED * 3.0 * delta, 0.0)
		if lean_dir != 0.0:
			apply_torque(LEAN_TORQUE * lean_dir * 0.3)
	elif is_bolt_charging:
		_start_bolt_dash()

func _fire_zappy_shell_toss() -> void:
	# Instant throw — no charging, fixed speed, short range
	is_toss_charging = false
	shell_missing = true
	shell_toss_hit = false
	shell_deflected = false
	shell_toss_timer = 0.0
	shell_toss_pos = global_position
	shell_toss_origin = global_position
	var toss_dir := aim_dir
	if toss_dir.length() < 0.1:
		toss_dir = last_aim_dir
	shell_toss_vel = toss_dir * ZAPPY_TOSS_SPEED
	toss_charge_amount = 0.0

func _start_bolt_dash() -> void:
	if bolt_charge_amount < 0.15:
		is_bolt_charging = false
		bolt_charge_amount = 0.0
		return
	is_bolt_charging = false
	is_bolt_dashing = true
	bolt_dash_timer = 0.0
	SFX.play_sfx("dash_bolt")
	bolt_dashes_remaining -= 1
	bolt_dash_dir = aim_dir
	if bolt_dash_dir.length() < 0.1:
		bolt_dash_dir = last_aim_dir
	bolt_dash_dir = bolt_dash_dir.normalized()
	bolt_dash_origin = global_position
	# Zero current momentum and set fixed velocity
	linear_velocity = bolt_dash_dir * BOLT_DASH_SPEED
	bolt_charge_amount = 0.0

func _update_bolt_dash(delta: float) -> void:
	if bolt_dash_cooldown > 0.0:
		bolt_dash_cooldown -= delta
		if bolt_dash_cooldown <= 0.0:
			bolt_dashes_remaining = BOLT_DASH_MAX
	if not is_bolt_dashing:
		return
	bolt_dash_timer += delta
	# Maintain fixed velocity (override physics)
	linear_velocity = bolt_dash_dir * BOLT_DASH_SPEED
	# Check for hits — ends dash on contact
	_check_charge_hits()
	# Stop after fixed distance or if dash was ended by hit
	var traveled := bolt_dash_origin.distance_to(global_position)
	if not is_bolt_dashing or traveled >= BOLT_DASH_DISTANCE:
		is_bolt_dashing = false
		linear_velocity = bolt_dash_dir * BOLT_DASH_SPEED * 0.15  # Small residual
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
	if extend_speed_now > 0.05 and upside_down:
		var boost := LAUNCH_BOOST * extend_speed_now * 8.0
		apply_central_impulse(Vector2(0, -boost))


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ CHARGE ATTACK                                                            ║
# ║                                                                           ║
# ║ Hold charge + lean direction to build up power (0.3s to full).           ║
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
	SFX.play_sfx("dash")
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
	linear_velocity = Vector2.ZERO
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
	# Use both colliding bodies AND a shape query to catch high-speed tunneling
	var targets: Array = []
	for body in get_colliding_bodies():
		if body == self or not (body is RigidBody2D):
			continue
		if body.has_method("take_damage"):
			targets.append(body)
	# Shape query for nearby opponents (catches tunneling misses)
	var space := get_world_2d().direct_space_state
	var shape_q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = CHARGE_HIT_RADIUS
	shape_q.shape = circle
	shape_q.transform = Transform2D(0.0, global_position)
	shape_q.exclude = [get_rid()]
	var hits := space.intersect_shape(shape_q, 4)
	for hit in hits:
		var col = hit.collider
		if col is RigidBody2D and col.has_method("take_damage") and col != self:
			if not targets.has(col):
				targets.append(col)
	for body in targets:
		var dir: Vector2 = (body.global_position - global_position).normalized()
		# Shell blocks charge too
		if body.has_method("is_shell_hit") and body.is_shell_hit(global_position):
			linear_velocity = linear_velocity.reflect(dir) * 0.5
			_end_any_dash()
			return
		var dash_dmg := CHARGE_DAMAGE
		var impact_force := linear_velocity.length() * 3.0
		# Zappy bolt dash: 40% less impact
		if character_type == CharacterType.ZAPPY and is_bolt_dashing:
			dash_dmg *= 0.6
			impact_force *= 0.6
		body.take_damage(dash_dmg, dir)
		body.apply_central_impulse(dir * impact_force)
		var hit_pos: Vector2 = (global_position + body.global_position) * 0.5
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
	shell_toss_origin = global_position
	# Direction from aim; fallback to last aimed direction
	var toss_dir := aim_dir
	if toss_dir.length() < 0.1:
		toss_dir = last_aim_dir
	# Speed scales with charge amount
	var speed := lerpf(SHELL_TOSS_MIN_SPEED, SHELL_TOSS_SPEED, toss_charge_amount)
	shell_toss_vel = toss_dir * speed
	toss_charge_amount = 0.0
	SFX.play_sfx("shell_toss")


func _update_shell_toss(delta: float) -> void:
	if shell_toss_cooldown > 0.0:
		shell_toss_cooldown -= delta

	if not shell_missing:
		return

	shell_toss_timer += delta

	# Shell sticks on contact for Goopy, or after max range for Zappy
	var shell_stuck := (shell_toss_hit and (character_type == CharacterType.GOOPY or character_type == CharacterType.ZAPPY))

	if not shell_stuck:
		# Apply gravity
		shell_toss_vel.y += SHELL_GRAVITY * delta
		var prev_pos := shell_toss_pos
		shell_toss_pos += shell_toss_vel * delta

		# Bounce off surfaces using raycast
		var space := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(prev_pos, shell_toss_pos)
		query.exclude = [get_rid()]
		var result := space.intersect_ray(query)
		if result:
			# Pass through one-way platforms from below (like snails do)
			# Goopy's shell does NOT pass through — he needs to grapple to platforms
			var skip_bounce := false
			if character_type != CharacterType.GOOPY and result.collider is StaticBody2D:
				var hit_body: StaticBody2D = result.collider
				for child in hit_body.get_children():
					if child is CollisionShape2D and child.one_way_collision:
						if shell_toss_vel.y < 0.0:
							skip_bounce = true
						break
			if not skip_bounce:
				shell_toss_pos = result.position + result.normal * (BASE_RADIUS * 0.8)
				# Proper bounce: reflect velocity off the surface normal
				shell_toss_vel = shell_toss_vel.reflect(result.normal) * SHELL_BOUNCE
				# Ensure minimum bounce speed to prevent getting stuck
				if shell_toss_vel.length() < 80.0 and character_type != CharacterType.GOOPY:
					shell_toss_vel = shell_toss_vel.normalized() * 80.0
				SFX.play_sfx_varied("shell_bounce", 0.8, 1.2, 0.6)
				# Goopy shell sticks to surfaces
				if character_type == CharacterType.GOOPY:
					shell_toss_vel = Vector2.ZERO
					shell_toss_hit = true

	# Zappy max range: stop shell after traveling max distance
	if character_type == CharacterType.ZAPPY and not shell_toss_hit:
		var travel_dist := shell_toss_origin.distance_to(shell_toss_pos)
		if travel_dist >= ZAPPY_TOSS_MAX_RANGE:
			shell_toss_vel = Vector2.ZERO
			shell_toss_hit = true

	# Shell pickup: owner walks over their thrown shell to recover it
	var dist_to_shell := global_position.distance_to(shell_toss_pos)
	if dist_to_shell < SHELL_PICKUP_RADIUS and shell_toss_timer > 0.15:
		_return_shell()
		return

	# Check hit on snails
	if not shell_toss_hit:
		var space2 := get_world_2d().direct_space_state
		var shape_query := PhysicsShapeQueryParameters2D.new()
		var circle := CircleShape2D.new()
		circle.radius = BASE_RADIUS
		shape_query.shape = circle
		shape_query.transform = Transform2D(0.0, shell_toss_pos)
		if not shell_deflected:
			shape_query.exclude = [get_rid()]
		var hits := space2.intersect_shape(shape_query, 4)
		for hit in hits:
			var collider = hit.collider
			if not (collider is RigidBody2D) or not collider.has_method("take_damage"):
				continue
			var target_body: RigidBody2D = collider
			if target_body == self and not shell_deflected:
				continue
			# DEFLECT: if the target is dashing OR parrying, they smack the shell back
			var is_target_dashing := false
			var is_target_parrying := false
			if target_body is Bollard:
				var target_snail: Bollard = target_body
				is_target_dashing = target_snail.is_dashing
				is_target_parrying = target_snail.is_parrying
			if is_target_dashing or is_target_parrying:
				var deflect_dir: Vector2 = (global_position - shell_toss_pos).normalized()
				var deflect_speed := shell_toss_vel.length() * SHELL_DEFLECT_BOOST
				shell_toss_vel = deflect_dir * deflect_speed
				shell_deflected = true
				shell_toss_timer = 0.0
				if character_type == CharacterType.GOOPY:
					_goopy_release_tether()
				big_hit.emit(shell_toss_pos, true)
				break
			# Shell area blocks thrown shells — bounce off
			if target_body.has_method("is_shell_hit") and target_body.is_shell_hit(shell_toss_pos):
				shell_toss_vel = shell_toss_vel.reflect((shell_toss_pos - target_body.global_position).normalized()) * SHELL_BOUNCE
				break
			var dir: Vector2 = (target_body.global_position - shell_toss_pos).normalized()
			# Per-character damage and knockback
			var dmg := SHELL_TOSS_DAMAGE
			var kb_mult := 1.0
			match character_type:
				CharacterType.BLINK:
					dmg = SHELL_TOSS_DAMAGE * 0.9  # 10% softer
					kb_mult = 0.9
				CharacterType.GOOPY:
					dmg = SHELL_TOSS_DAMAGE * 0.3  # 30% of Blink
					kb_mult = 0.3
				CharacterType.ZAPPY:
					dmg = ZAPPY_TOSS_DAMAGE
					kb_mult = 0.0  # Use fixed knockback below
			target_body.take_damage(dmg, dir)
			if target_body is Bollard:
				(target_body as Bollard).was_hit_by_shell = true
			if character_type == CharacterType.ZAPPY:
				target_body.apply_central_impulse(dir * ZAPPY_TOSS_KNOCKBACK)
			else:
				var shell_impact := shell_toss_vel.length() * 2.0 * kb_mult
				target_body.apply_central_impulse(dir * shell_impact)
			big_hit.emit(shell_toss_pos, false)
			if character_type == CharacterType.GOOPY:
				# Goopy shell sticks where it hit
				shell_toss_vel = Vector2.ZERO
				shell_toss_hit = true
			elif character_type == CharacterType.ZAPPY:
				# Zappy shell reflects off players and keeps going
				shell_toss_vel = shell_toss_vel.reflect(dir) * 0.85
				shell_toss_origin = shell_toss_pos  # Reset range tracking
			else:
				shell_toss_hit = true
				shell_toss_vel = -shell_toss_vel * 0.3
			break

	# Return shell after time expires (Zappy returns faster)
	var return_time := SHELL_RETURN_TIME
	if character_type == CharacterType.ZAPPY:
		return_time = ZAPPY_TOSS_RETURN_TIME
	if shell_toss_timer >= return_time:
		_return_shell()


func _return_shell() -> void:
	shell_missing = false
	shell_deflected = false
	SFX.play_sfx("shell_pickup")
	if character_type == CharacterType.GOOPY:
		goopy_tether_active = false
		is_goopy_zipping = false
	var cd := SHELL_TOSS_COOLDOWN
	if character_type == CharacterType.ZAPPY:
		cd = ZAPPY_TOSS_COOLDOWN
	shell_toss_cooldown = cd


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ COMBAT                                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════╝

const SHELLLESS_DAMAGE_MULT := 1.5    # 50% more damage when shell-less

func take_damage(amount: float, knockback_dir: Vector2) -> void:
	if is_invincible:
		return
	# Shell-less = extra vulnerable. With shell attached, normal damage applies
	# (shell AREA protection is handled by is_shell_hit() at the call site)
	if shell_missing:
		amount *= SHELLLESS_DAMAGE_MULT
	if amount <= 0.0:
		var knockback_mult := 1.0 + damage_percent / 50.0
		apply_central_impulse(knockback_dir * KNOCKBACK_BASE * knockback_mult * 0.3)
		return
	damage_percent += amount
	var knockback_mult := 1.0 + damage_percent / 50.0
	apply_central_impulse(knockback_dir * KNOCKBACK_BASE * knockback_mult)
	SFX.play_sfx_varied("hit")

func _is_in_any_dash() -> bool:
	return is_dashing or is_phase_dashing or is_bolt_dashing or is_goo_dashing

func _on_body_entered(body: Node) -> void:
	if is_invincible:
		return
	if not (body is RigidBody2D) or body == self or not body.has_method("take_damage"):
		return
	var other: RigidBody2D = body as RigidBody2D
	# If the other snail is dashing, they have hit immunity — don't damage them
	if other is Bollard and (other as Bollard)._is_in_any_dash():
		return
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
		# Parry deflect: if the target is parrying, the attack bounces back to us
		if other is Bollard and (other as Bollard).is_parrying:
			var reverse_dir: Vector2 = -dir
			take_damage(dmg, reverse_dir)
			apply_central_impulse(reverse_dir * KNOCKBACK_BASE * 2.0)
			var hit_pos := (global_position + other.global_position) * 0.5
			big_hit.emit(hit_pos, true)
			SFX.play_sfx("parry_deflect")
			_end_any_dash()
			return
		# Dashing into another snail = big hit (same impact as shell toss)
		if is_dashing or is_bolt_dashing:
			dmg = maxf(dmg, CHARGE_DAMAGE)
			var impact_force := linear_velocity.length() * 3.0
			# Zappy bolt dash: 40% less impact
			if is_bolt_dashing and character_type == CharacterType.ZAPPY:
				dmg *= 0.6
				impact_force *= 0.6
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
	SFX.play_sfx("ko")

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
	was_hit_by_shell = false
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
	blink_toss_used = false
	blink_teleport_used = false
	blink_phase_used = false
	goopy_tether_active = false
	goopy_tether_timer = 0.0
	is_goo_charging = false
	goo_charge_amount = 0.0
	is_goo_dashing = false
	goo_dash_was_full_charge = false
	goo_dash_cooldown = 0.0
	is_goopy_zipping = false
	goo_trails.clear()
	is_bolt_charging = false
	bolt_charge_amount = 0.0
	is_bolt_dashing = false
	bolt_dash_cooldown = 0.0
	bolt_dashes_remaining = BOLT_DASH_MAX
	bolt_dash_dir = Vector2.ZERO
	bolt_dash_origin = Vector2.ZERO
	# Clear drop-through exceptions
	for dt in drop_through_bodies:
		if is_instance_valid(dt.body):
			remove_collision_exception_with(dt.body)
	drop_through_bodies.clear()

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
# ║   body.png           32x90  — body tile segment (tiles vertically)       ║
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

	# Body tiles (stack vertically instead of stretching)
	for i in BODY_MAX_TILES:
		var tile := _make_sprite(TEX_BODY, Vector2.ZERO, 0)
		tile.self_modulate = bollard_color
		tile.visible = false
		spr_body_tiles.append(tile)

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


func update_shell_colors() -> void:
	# Call after changing accent_color to update thrown shell sprite tints
	spr_shell.self_modulate = accent_color
	spr_spiral.self_modulate = accent_color.darkened(0.15)
	spr_thrown_shell.self_modulate = accent_color
	spr_thrown_spiral.self_modulate = accent_color.darkened(0.15)

func _update_sprites() -> void:
	var post_h: float = lerpf(MIN_HEIGHT, MAX_HEIGHT, extend_amount)
	var hw := POST_HALF_WIDTH

	# ── Invincibility flash ──────────────────────────────────────────────
	var flash := is_invincible and fmod(invincible_timer * 10.0, 2.0) > 1.0
	var shell_c: Color = accent_color.lightened(0.5) if flash else accent_color
	var body_c: Color = bollard_color.lightened(0.5) if flash else bollard_color

	# ── CHARGE / ABILITY VISUALS ─────────────────────────────────────────
	var body_shake_x := 0.0
	if is_charging and charge_amount > 0.1:
		body_shake_x = randf_range(-charge_amount * 3.0, charge_amount * 3.0)
		body_c = body_c.lerp(Color(1.0, 0.3, 0.2), charge_amount * 0.5)
		shell_c = shell_c.lerp(Color(1.0, 0.5, 0.2), charge_amount * 0.4)
	if is_toss_charging and toss_charge_amount > 0.1:
		body_shake_x = randf_range(-toss_charge_amount * 2.0, toss_charge_amount * 2.0)
		shell_c = shell_c.lerp(Color(1.0, 0.8, 0.2), toss_charge_amount * 0.5)
	if is_goo_charging and goo_charge_amount > 0.1:
		body_shake_x = randf_range(-goo_charge_amount * 2.5, goo_charge_amount * 2.5)
		body_c = body_c.lerp(Color(0.2, 0.9, 0.3), goo_charge_amount * 0.5)
		shell_c = shell_c.lerp(Color(0.3, 1.0, 0.4), goo_charge_amount * 0.4)
	if is_bolt_charging and bolt_charge_amount > 0.1:
		body_shake_x = randf_range(-bolt_charge_amount * 3.5, bolt_charge_amount * 3.5)
		body_c = body_c.lerp(Color(0.3, 0.8, 1.0), bolt_charge_amount * 0.6)
		shell_c = shell_c.lerp(Color(0.5, 0.9, 1.0), bolt_charge_amount * 0.5)
	if is_dashing:
		body_c = Color(1.0, 0.4, 0.2)
		shell_c = Color(1.0, 0.6, 0.2)
	if is_phase_dashing:
		body_c = Color(0.6, 0.3, 1.0, 0.4)  # Ghostly purple, semi-transparent
		shell_c = Color(0.7, 0.4, 1.0, 0.4)
	if is_bolt_dashing:
		body_c = Color(0.3, 0.9, 1.0)  # Electric blue
		shell_c = Color(0.5, 1.0, 1.0)
	if is_goo_dashing:
		body_c = Color(0.3, 0.9, 0.2)  # Bright green
		shell_c = Color(0.4, 1.0, 0.3)
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
	var shell_scale := (BASE_RADIUS * 2.0) / TEX_SHELL.get_width()
	spr_shell.scale = Vector2(shell_scale * face_sign, shell_scale)
	spr_spiral.scale = Vector2(shell_scale * face_sign, shell_scale)

	# ── THROWN SHELL (world-space projectile) ─────────────────────────────
	spr_thrown_shell.visible = shell_missing
	spr_thrown_spiral.visible = shell_missing
	if shell_missing:
		spr_thrown_shell.global_position = shell_toss_pos
		spr_thrown_spiral.global_position = shell_toss_pos
		# Zappy electrified shell: pulsing blue glow when stuck in place
		if character_type == CharacterType.ZAPPY and shell_toss_hit:
			var pulse := (sin(shell_toss_timer * 12.0) + 1.0) * 0.5
			spr_thrown_shell.self_modulate = accent_color.lerp(Color(0.4, 0.85, 1.0), pulse * 0.7)
			spr_thrown_spiral.self_modulate = accent_color.darkened(0.15).lerp(Color(0.3, 0.7, 1.0), pulse * 0.7)
		else:
			spr_thrown_shell.self_modulate = accent_color
			spr_thrown_spiral.self_modulate = accent_color.darkened(0.15)
		# Spin the thrown shell
		spr_thrown_shell.rotation += 8.0 * get_physics_process_delta_time()
		spr_thrown_spiral.rotation = spr_thrown_shell.rotation

	# ── FACING DIRECTION ─────────────────────────────────────────────────
	if last_aim_dir.x > 0.1:
		facing_right = true
	elif last_aim_dir.x < -0.1:
		facing_right = false
	var face_sign: float = 1.0 if facing_right else -1.0

	# ── BODY (tiling segments) ───────────────────────────────────────────
	var tile_sx: float = (hw * 2.0) / TEX_BODY.get_width()
	var tile_sy: float = BODY_TILE_HEIGHT / TEX_BODY.get_height()
	var tiles_needed: int = ceili(post_h / BODY_TILE_HEIGHT) if post_h > 3.0 else 0
	tiles_needed = mini(tiles_needed, BODY_MAX_TILES)
	for i in BODY_MAX_TILES:
		if i < tiles_needed:
			var tile := spr_body_tiles[i]
			tile.visible = true
			# Stack from bottom (y=0) upward; each tile's center is offset
			var tile_bottom_y: float = -float(i) * BODY_TILE_HEIGHT
			tile.position = Vector2(body_shake_x, tile_bottom_y - BODY_TILE_HEIGHT * 0.5)
			tile.scale = Vector2(tile_sx * face_sign, tile_sy)
			tile.self_modulate = body_c
		else:
			spr_body_tiles[i].visible = false
	# Clip the topmost tile if body height isn't a perfect multiple
	if tiles_needed > 0:
		var remainder := fmod(post_h, BODY_TILE_HEIGHT)
		if remainder > 0.01:
			var top_tile := spr_body_tiles[tiles_needed - 1]
			var clip_sy: float = remainder / TEX_BODY.get_height()
			top_tile.scale = Vector2(tile_sx * face_sign, clip_sy)
			var tile_bottom_y: float = -float(tiles_needed - 1) * BODY_TILE_HEIGHT
			top_tile.position = Vector2(body_shake_x, tile_bottom_y - remainder * 0.5)

	# ── DOME ─────────────────────────────────────────────────────────────
	# Dome sits on top of body: flat bottom on body top, curve faces up
	var tip_y := -post_h
	var dome_sx: float = (hw * 2.0) / TEX_DOME.get_width()
	var dome_sy: float = (hw) / TEX_DOME.get_height()
	spr_dome.scale = Vector2(dome_sx * face_sign, dome_sy)
	# Position: dome center is half its scaled height above the body top
	var dome_h: float = TEX_DOME.get_height() * dome_sy
	spr_dome.position = Vector2(body_shake_x, tip_y - dome_h * 0.5)
	spr_dome.self_modulate = body_c

	# ── STALKS ───────────────────────────────────────────────────────────
	# Stalks extend from dome top to eye positions — no gap
	var dome_top_y: float = tip_y - dome_h
	var left_eye_pos := Vector2(-STALK_SPREAD + body_shake_x, dome_top_y - STALK_LENGTH)
	var right_eye_pos := Vector2(STALK_SPREAD + body_shake_x, dome_top_y - STALK_LENGTH)

	# Stalk base starts inside the dome (2px overlap) so there's no gap
	var stalk_base_y := dome_top_y + 2.0
	var stalk_total_l := stalk_base_y - left_eye_pos.y
	var stalk_total_r := stalk_base_y - right_eye_pos.y
	spr_stalk_l.position = Vector2(-STALK_SPREAD + body_shake_x, (stalk_base_y + left_eye_pos.y) * 0.5)
	spr_stalk_r.position = Vector2(STALK_SPREAD + body_shake_x, (stalk_base_y + right_eye_pos.y) * 0.5)
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

	# Character ability visuals need redraw
	if character_type == CharacterType.GOOPY:
		queue_redraw()
	if character_type == CharacterType.ZAPPY and (is_bolt_dashing or shell_missing):
		queue_redraw()

func _draw() -> void:
	# Goopy tether line (shell to body while shell is flying)
	if goopy_tether_active and shell_missing and character_type == CharacterType.GOOPY:
		var target_pos := to_local(shell_toss_pos)
		if target_pos.length() > 5.0:
			var tether_color := Color(0.3, 0.85, 0.2, 0.85)
			draw_line(Vector2.ZERO, target_pos, tether_color, 4.0)
			var perp := Vector2(-target_pos.y, target_pos.x).normalized() * 2.0
			draw_line(perp, target_pos + perp, Color(0.5, 0.95, 0.3, 0.5), 2.0)
			draw_line(-perp, target_pos - perp, Color(0.5, 0.95, 0.3, 0.5), 2.0)

	# Goopy goo trail puddles
	if character_type == CharacterType.GOOPY and not goo_trails.is_empty():
		for trail in goo_trails:
			var local_pos: Vector2 = to_local(trail.pos)
			var trail_alpha: float = clampf(trail.timer / GOO_TRAIL_DURATION, 0.0, 1.0) * 0.7
			draw_circle(local_pos, GOO_TRAIL_RADIUS, Color(0.35, 0.8, 0.2, trail_alpha))
			draw_circle(local_pos, GOO_TRAIL_RADIUS * 0.5, Color(0.5, 0.9, 0.3, trail_alpha * 0.8))

	# Zappy electric beam between body and shell
	if shell_missing and character_type == CharacterType.ZAPPY:
		var shell_local := to_local(shell_toss_pos)
		# Jagged electric beam
		var beam_segs := 6
		var prev_pt := Vector2.ZERO
		for seg_i in beam_segs:
			var t: float = float(seg_i + 1) / float(beam_segs)
			var pt := shell_local * t
			if seg_i < beam_segs - 1:
				var perp := Vector2(-shell_local.y, shell_local.x).normalized()
				pt += perp * randf_range(-8.0, 8.0)
			draw_line(prev_pt, pt, Color(0.3, 0.7, 1.0, 0.7), 2.0)
			draw_line(prev_pt, pt, Color(1.0, 1.0, 0.5, 0.3), 1.0)
			prev_pt = pt

	# Zappy bolt dash — electric sparks trailing behind
	if is_bolt_dashing and character_type == CharacterType.ZAPPY:
		for spark_i in 4:
			var offset := Vector2(randf_range(-15.0, 15.0), randf_range(-15.0, 15.0))
			var spark_end := offset + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
			draw_line(offset, spark_end, Color(0.4, 0.9, 1.0, 0.8), 2.0)
			draw_line(offset, spark_end, Color(1.0, 1.0, 1.0, 0.5), 0.8)


# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ AI                                                                       ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _process_ai(delta: float) -> void:
	if ai_target == null or not is_instance_valid(ai_target) or ai_target.is_dead:
		extend_amount = move_toward(extend_amount, 0.5, EXTEND_SPEED * 0.5 * delta)
		ai_state = "idle"
		ai_timer = 0.0
		ai_action_duration = 0.0  # Immediately pick action when target returns
		return
	ai_timer += delta
	# Keep AI from fully retracting and laying down during idle
	if ai_state == "idle":
		extend_amount = move_toward(extend_amount, 0.5, EXTEND_SPEED * 0.5 * delta)
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
				ai_action_duration = randf_range(0.15, 0.4)
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
				if is_bolt_charging:
					_start_bolt_dash()
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

func _ai_near_edge() -> bool:
	# Returns true if AI is close to the left or right edge of the arena
	return global_position.x < 80.0 or global_position.x > 1200.0

func _ai_edge_safe_dir() -> float:
	# Direction toward center to avoid rolling off edges
	var dir := signf(ai_target.global_position.x - global_position.x)
	if global_position.x < 80.0 and dir < 0.0:
		return 1.0  # Don't roll further left
	if global_position.x > 1200.0 and dir > 0.0:
		return -1.0  # Don't roll further right
	return dir

func _ai_approach(delta: float) -> void:
	var dir := _ai_edge_safe_dir()
	apply_torque(LEAN_TORQUE * dir)
	extend_amount = move_toward(extend_amount, 0.6, EXTEND_SPEED * 0.5 * delta)

func _ai_attack(delta: float) -> void:
	var dir := _ai_edge_safe_dir()
	apply_torque(LEAN_TORQUE * 1.5 * dir)
	extend_amount = minf(extend_amount + EXTEND_SPEED * 1.5 * delta, 1.0)

func _ai_lower_spin(delta: float) -> void:
	extend_amount = maxf(extend_amount - EXTEND_SPEED * 2.0 * delta, 0.0)
	apply_torque(LEAN_TORQUE * 2.0)

func _ai_retreat(delta: float) -> void:
	var dir := -signf(ai_target.global_position.x - global_position.x)
	# Don't retreat off the edge
	if global_position.x < 80.0 and dir < 0.0:
		dir = 1.0
	elif global_position.x > 1200.0 and dir > 0.0:
		dir = -1.0
	apply_torque(LEAN_TORQUE * dir * 0.8)
	extend_amount = move_toward(extend_amount, 0.3, EXTEND_SPEED * delta)

func _ai_charge_attack(delta: float) -> void:
	var dir := signf(ai_target.global_position.x - global_position.x)
	aim_dir = Vector2(dir, randf_range(-0.3, 0.0)).normalized()
	last_aim_dir = aim_dir
	apply_torque(LEAN_TORQUE * dir * 0.3)
	match character_type:
		CharacterType.ZAPPY:
			is_bolt_charging = true
			bolt_charge_amount = minf(bolt_charge_amount + delta / BOLT_DASH_CHARGE_TIME, 1.0)
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
				if can_teleport_to_shell and not blink_teleport_used:
					_blink_teleport_to_shell()
				return
			if shell_toss_cooldown > 0.0 or blink_toss_used:
				return
			toss_charge_amount = randf_range(0.4, 1.0)
			_fire_shell_toss()
			blink_toss_used = true
			can_teleport_to_shell = true
		CharacterType.GOOPY:
			if shell_missing:
				if goopy_tether_active and randf() < 0.5:
					_goopy_zip_to_shell()
				return
			if shell_toss_cooldown > 0.0:
				return
			toss_charge_amount = randf_range(0.3, 0.8)
			_fire_shell_toss()
			goopy_tether_active = true
			goopy_tether_timer = 0.0
		CharacterType.ZAPPY:
			if shell_missing or shell_toss_cooldown > 0.0:
				return
			_fire_zappy_shell_toss()

func _ai_ability2() -> void:
	var dir := signf(ai_target.global_position.x - global_position.x)
	aim_dir = Vector2(dir, randf_range(-0.3, 0.1)).normalized()
	last_aim_dir = aim_dir
	match character_type:
		CharacterType.BLINK:
			if phase_dash_cooldown <= 0.0 and not blink_phase_used:
				_start_phase_dash()
				blink_phase_used = true
		CharacterType.GOOPY:
			if goo_dash_cooldown <= 0.0 and not is_goo_dashing:
				goo_charge_amount = randf_range(0.3, 1.0)
				_start_goo_dash()
		CharacterType.ZAPPY:
			# AI just charges briefly then dashes
			if bolt_dash_cooldown <= 0.0 and bolt_dashes_remaining > 0:
				bolt_charge_amount = randf_range(0.5, 1.0)
				_start_bolt_dash()
