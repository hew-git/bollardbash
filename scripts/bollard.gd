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
const BASE_RADIUS := 24.0
const POST_HALF_WIDTH := 16.0
const MIN_HEIGHT := 2.0
const MAX_HEIGHT := 90.0

# ── Health ─────────────────────────────────────────────────────────────────
const MAX_HIT_POINTS := 5
const DAMAGE_SHELLED := 1         # HP lost when hit WITH shell on
const DAMAGE_UNSHELLED := 2       # HP lost when hit WITHOUT shell (exposed)

# ── Physics Tuning ──────────────────────────────────────────────────────────
const LEAN_TORQUE := 80000.0
const EXTEND_SPEED := 8.0
const ANGULAR_DAMP_AMOUNT := 2.5
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
const SHELL_TOSS_SPEED := 1680.0    # Max speed of thrown shell (at full charge)
const SHELL_TOSS_MIN_SPEED := 630.0 # Min speed (quick tap)
const SHELL_TOSS_DAMAGE := 36.0     # Damage on hit (Blink base)
const SHELL_RETURN_TIME := 2.5      # Seconds before shell returns
const SHELL_TOSS_COOLDOWN := 0.5    # Brief cooldown after shell returns
const SHELL_GRAVITY := 400.0        # Gravity on thrown shell
const SHELL_BOUNCE := 0.82           # Bounce factor off surfaces
const SHELL_TOSS_CHARGE_TIME := 0.6 # Seconds to reach full toss charge
const SHELL_DEFLECT_BOOST := 1.5    # Speed multiplier when shell is deflected by a dash
const SHELL_PICKUP_RADIUS := 35.0   # Walk over shell to pick it up

# ── Parry (all characters) ─────────────────────────────────────────────────
const PARRY_DURATION := 0.25        # Invulnerability window
const PARRY_COOLDOWN := 0.8         # Cooldown after parry ends
const PARRY_RETRACT_SPEED := 12.0   # How fast body retracts into shell

# ── Blink: Phase Dash ──────────────────────────────────────────────────────
const PHASE_DASH_IMPULSE := 1190.0   # Dash impulse
const PHASE_DASH_TIME := 0.27        # 15% shorter
const PHASE_DASH_COOLDOWN := 0.8

# ── Goopy: Slime Shell Toss + Tether Swing + Goo Dash ──────────────────────
const GOOPY_TOSS_KNOCKBACK_MULT := 0.3  # 30% of Blink's shell knockback
const GOOPY_ZIP_IMPULSE := 3300.0    # Impulse when zipping to shell (strong pull)
const GOOPY_SWING_PULL := 1200.0     # Looser swing force (lower = looser)
const GOOPY_TETHER_DURATION := 6.0   # Max tether swing time (long for strategic use)
const GOO_DASH_IMPULSE := 1785.0     # Max dash impulse
const GOO_DASH_MIN_IMPULSE := 637.0  # Min dash impulse
const GOO_DASH_CHARGE_TIME := 0.5    # Charge time for full dash
const GOO_DASH_TIME := 0.4           # Dash duration
const GOO_DASH_COOLDOWN := 0.8       # Cooldown
const GOO_DASH_DAMAGE := 15.0        # Knockback damage on hit
const GOO_DASH_KNOCKBACK := 400.0    # Knockback impulse on hit
const GOO_TRAIL_RADIUS := 18.0       # Goo puddle size
const GOO_TRAIL_DURATION := 3.0      # How long goo puddles last

# ── Zappy: Electric Shell Toss + 3x Bolt Dash ─────────────────────────────
const ZAPPY_TOSS_SPEED := 1200.0     # Fixed speed (unchargeable, short range)
const ZAPPY_TOSS_DAMAGE := 7.2       # Light damage
const ZAPPY_TOSS_KNOCKBACK := 108.0  # Light knockback
const ZAPPY_TOSS_COOLDOWN := 0.4     # Short cooldown
const ZAPPY_TOSS_RETURN_TIME := 1.5  # Returns faster
const ZAPPY_TOSS_MAX_RANGE := 151.0  # Max distance before shell stops
const BOLT_DASH_CHARGE_TIME := 0.08  # Near-instant charge for snappy feel
const BOLT_DASH_SPEED := 2250.0      # Fixed dash speed (pixels/sec)
const BOLT_DASH_DISTANCE := 425.0    # Fixed dash distance (pixels)
const BOLT_DASH_COOLDOWN := 1.0      # Slightly shorter cooldown
const BOLT_DASH_MAX := 3             # 3 electric dashes

# ── Visual Constants ────────────────────────────────────────────────────────
const SPRITE_SCALE := 2.0       # All art rendered at 2x for pixel-perfect look
const NECK_TILE_HEIGHT := 8.0   # Display height of each neck tile (4px art * 2x scale)
const NECK_MAX_TILES := 12      # Max tiles needed (MAX_HEIGHT / NECK_TILE_HEIGHT, rounded up)

# ── Sprite Textures ─────────────────────────────────────────────────────────
# Per-character textures (loaded dynamically in _ready based on character_type)
var TEX_SHELL: Texture2D
var TEX_INNER_BODY: Texture2D
var TEX_NECK: Texture2D
var TEX_HEAD: Texture2D
# Palette-swap shader (replaces self_modulate for key-color recoloring)
const PALETTE_SHADER := preload("res://shaders/palette_swap.gdshader")
# ── Emerge Constants ────────────────────────────────────────────────────────
const EMERGE_DURATION := 0.6

# ── Runtime State ───────────────────────────────────────────────────────────
var extend_amount: float = 0.5
var hit_points: int = MAX_HIT_POINTS
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
var _saved_collision_mask: int = 0

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

# ── Anti-tunneling (floor glitch prevention) ────────────────────────────────
var _prev_global_pos: Vector2 = Vector2.ZERO


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
var spr_neck_tiles: Array[Sprite2D] = []  # Tiling neck segments
var spr_head: Sprite2D
var spr_body_circle: Sprite2D    # Body-colored circle behind shell (visible when shell tossed)
var spr_thrown_shell: Sprite2D   # The shell projectile when tossed


func _load_character_sprites() -> void:
	var folder: String
	match character_type:
		CharacterType.BLINK: folder = "blink"
		CharacterType.GOOPY: folder = "goopy"
		CharacterType.ZAPPY: folder = "zappy"
	var base_path := "res://sprites/snail/%s/" % folder
	TEX_SHELL = load(base_path + "shell.png")
	TEX_INNER_BODY = load(base_path + "inner_body.png")
	TEX_NECK = load(base_path + "neck.png")
	TEX_HEAD = load(base_path + "head.png")


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
	physics_material_override.friction = 0.85
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

	_load_character_sprites()
	_setup_sprites()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Anti-tunneling: detect if snail teleported through floor since last frame
	# Skip during emerge, invincibility, and phase dash (intentionally passing through)
	if _prev_global_pos.y > 0.0 and not is_emerging and not is_phase_dashing:
		var dy := global_position.y - _prev_global_pos.y
		var expected_dy := maxf(linear_velocity.y * delta, 0.0)
		if dy > expected_dy + 80.0 and dy > 60.0:
			global_position.y = _prev_global_pos.y
			linear_velocity.y = 0.0

	if is_emerging:
		_update_emerge(delta)
		_prev_global_pos = global_position
		return

	if is_frozen:
		_update_collision_shape()
		_update_sprites()
		_prev_global_pos = global_position
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
			if body is StaticBody2D or body is TileMapLayer:
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
	_update_sprites()
	_prev_global_pos = global_position


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
	extend_amount = 0.0
	SFX.play_sfx("dash_phase")
	# Add collision exceptions for non-ground structures (platforms, center rock, etc.)
	# Ground is NOT excluded — you can't phase through the ground
	_phase_set_exceptions(true)
	apply_central_impulse(dash_dir * PHASE_DASH_IMPULSE)

func _phase_set_exceptions(enable: bool) -> void:
	# Phase through EVERYTHING by disabling collision mask entirely
	# This works universally with StaticBody2D, TileMapLayer, and other players
	if enable:
		_saved_collision_mask = collision_mask
		collision_mask = 0
	else:
		collision_mask = _saved_collision_mask

func _update_phase_dash(delta: float) -> void:
	if phase_dash_cooldown > 0.0:
		phase_dash_cooldown -= delta
	if not is_phase_dashing:
		return
	phase_dash_timer += delta
	# Check for hits on enemy players during the dash
	_check_charge_hits()
	if phase_dash_timer >= PHASE_DASH_TIME:
		is_phase_dashing = false
		phase_dash_cooldown = PHASE_DASH_COOLDOWN
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
			if body is Bollard and (body as Bollard).is_dead:
				continue
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
	extend_amount = 0.0
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
	if goo_dash_timer >= GOO_DASH_TIME or _is_dash_blocked():
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
		if body is Bollard and (body as Bollard).is_dead:
			continue
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

var _goo_shape_query: PhysicsShapeQueryParameters2D
var _goo_circle: CircleShape2D
var _goo_slow_tick: float = 0.0

func _update_goo_trails(delta: float) -> void:
	var i := goo_trails.size() - 1
	while i >= 0:
		goo_trails[i].timer -= delta
		if goo_trails[i].timer <= 0.0:
			goo_trails.remove_at(i)
			i -= 1
			continue
		if not goo_trails[i].get("grounded", false):
			var goo_pos: Vector2 = goo_trails[i].pos
			var below := goo_pos + Vector2(0, 400.0 * delta)
			var query := PhysicsRayQueryParameters2D.create(goo_pos, goo_pos + Vector2(0, 20.0))
			query.exclude = [get_rid()]
			var result := get_world_2d().direct_space_state.intersect_ray(query)
			if result:
				goo_trails[i].pos = result.position - Vector2(0, 2.0)
				goo_trails[i].grounded = true
			else:
				goo_trails[i].pos = below
		i -= 1
	if goo_trails.is_empty():
		return
	# Slow enemies in goo — check every 0.15s instead of every frame
	_goo_slow_tick += delta
	if _goo_slow_tick < 0.15:
		return
	_goo_slow_tick = 0.0
	if _goo_shape_query == null:
		_goo_shape_query = PhysicsShapeQueryParameters2D.new()
		_goo_circle = CircleShape2D.new()
		_goo_circle.radius = GOO_TRAIL_RADIUS * 2.0
		_goo_shape_query.shape = _goo_circle
	var space := get_world_2d().direct_space_state
	_goo_shape_query.exclude = [get_rid()]
	for trail in goo_trails:
		_goo_shape_query.transform = Transform2D(0.0, trail.pos)
		var hits := space.intersect_shape(_goo_shape_query, 4)
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
	extend_amount = 0.0
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
	# Stop after fixed distance, hitting something, or dash ended by player hit
	var traveled := bolt_dash_origin.distance_to(global_position)
	if not is_bolt_dashing or traveled >= BOLT_DASH_DISTANCE or _is_dash_blocked():
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
	extend_amount = 0.0
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
		if dash_timer >= CHARGE_DASH_TIME or _is_dash_blocked():
			is_dashing = false
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
		if body is Bollard and (body as Bollard).is_dead:
			continue
		var dir: Vector2 = (body.global_position - global_position).normalized()
		# Parry deflects dash
		if body is Bollard and (body as Bollard).is_parrying:
			linear_velocity = linear_velocity.reflect(dir) * 0.5
			var hit_pos: Vector2 = (global_position + body.global_position) * 0.5
			big_hit.emit(hit_pos, true)
			SFX.play_sfx("parry_deflect")
			_end_any_dash()
			return
		# Dashing target = mutual immunity
		if body is Bollard and (body as Bollard)._is_in_any_dash():
			continue
		var impact_force := linear_velocity.length() * 3.0
		if character_type == CharacterType.ZAPPY and is_bolt_dashing:
			impact_force *= 0.54
		body.take_damage(0.0, dir)
		body.apply_central_impulse(dir * impact_force)
		var hit_pos: Vector2 = (global_position + body.global_position) * 0.5
		big_hit.emit(hit_pos, false)
		_end_any_dash()
		return

func _is_dash_blocked() -> bool:
	# Check if dashing into a wall or platform — end dash if so
	# Phase dash is NEVER blocked — it phases through everything (timer-only)
	if is_phase_dashing:
		return false
	# Give a brief grace period (first few frames) so dashes can start from ground
	if is_dashing and dash_timer < 0.08:
		return false
	if is_bolt_dashing and bolt_dash_timer < 0.08:
		return false
	if is_goo_dashing and goo_dash_timer < 0.08:
		return false
	for body in get_colliding_bodies():
		if body is StaticBody2D or body is TileMapLayer:
			return true
	return false

func _end_any_dash() -> void:
	if is_dashing:
		is_dashing = false
		if dashes_remaining <= 0:
			charge_cooldown = CHARGE_COOLDOWN
	if is_phase_dashing:
		is_phase_dashing = false
		phase_dash_cooldown = PHASE_DASH_COOLDOWN
		_phase_set_exceptions(false)
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
	# Direction from aim; fallback to last aimed direction
	var toss_dir := aim_dir
	if toss_dir.length() < 0.1:
		toss_dir = last_aim_dir
	# Offset start position along aim direction so shell clears the player's body
	# This prevents the shell from starting inside a surface when aiming into ground
	shell_toss_pos = global_position + toss_dir * (BASE_RADIUS * 0.6)
	shell_toss_origin = shell_toss_pos
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
		# Cap max velocity to prevent tunneling
		if shell_toss_vel.length() > 1500.0:
			shell_toss_vel = shell_toss_vel.normalized() * 1500.0
		var move := shell_toss_vel * delta
		var shell_radius := BASE_RADIUS * 0.5  # Visual bounce radius (smaller than physics)

		# Shape-cast: sweep a circle along the movement path
		var space := get_world_2d().direct_space_state
		var motion_params := PhysicsShapeQueryParameters2D.new()
		var circle := CircleShape2D.new()
		circle.radius = shell_radius
		motion_params.shape = circle
		motion_params.transform = Transform2D(0.0, shell_toss_pos)
		motion_params.motion = move
		motion_params.exclude = [get_rid()]
		motion_params.collision_mask = 0xFFFFFFFF
		motion_params.collide_with_bodies = true
		motion_params.margin = 1.0
		var cast_result := space.cast_motion(motion_params)
		# cast_result = [safe_fraction, unsafe_fraction]
		# safe_fraction: how far along 'move' we can go without collision
		var safe_frac: float = cast_result[0]
		var hit_surface := safe_frac < 1.0

		if hit_surface:
			# Move to the safe position (just before contact)
			shell_toss_pos += move * safe_frac
			# Find the collision normal using a rest query at the contact point
			motion_params.transform = Transform2D(0.0, shell_toss_pos)
			motion_params.motion = Vector2.ZERO
			var rest := space.get_rest_info(motion_params)
			var bounce_normal := Vector2.UP  # fallback
			var skip_bounce := false
			if rest.size() > 0:
				bounce_normal = rest.normal
				# Pass through one-way platforms from below (except Goopy)
				if character_type != CharacterType.GOOPY and rest.collider_id > 0:
					var collider_obj = instance_from_id(rest.collider_id)
					if collider_obj is StaticBody2D:
						for child in collider_obj.get_children():
							if child is CollisionShape2D and child.one_way_collision:
								if shell_toss_vel.y < 0.0:
									skip_bounce = true
								break
			if skip_bounce:
				# Pass through — continue full movement
				shell_toss_pos += move * (1.0 - safe_frac)
			else:
				# Push out from surface
				shell_toss_pos += bounce_normal * 4.0
				# Reflect velocity off the surface normal
				shell_toss_vel = shell_toss_vel.reflect(bounce_normal) * SHELL_BOUNCE
				# Arcade-y: enforce minimum bounce speed so shells stay lively
				if shell_toss_vel.length() < 200.0:
					shell_toss_vel = shell_toss_vel.normalized() * 200.0
				SFX.play_sfx_varied("shell_bounce", 0.8, 1.2, 0.6)
				# Goopy shell sticks to surfaces
				if character_type == CharacterType.GOOPY:
					shell_toss_vel = Vector2.ZERO
					shell_toss_hit = true
		else:
			# No collision from cast_motion — apply full movement
			shell_toss_pos += move
			# Fallback overlap check: cast_motion can miss TileMapLayer bodies
			# If the shell ended up inside a solid, bounce it back out
			motion_params.transform = Transform2D(0.0, shell_toss_pos)
			motion_params.motion = Vector2.ZERO
			var rest := space.get_rest_info(motion_params)
			if rest.size() > 0:
				var collider_obj = instance_from_id(rest.collider_id) if rest.collider_id > 0 else null
				var is_stage_body := collider_obj is StaticBody2D or collider_obj is TileMapLayer
				if is_stage_body:
					shell_toss_pos -= move  # Undo the move
					shell_toss_pos += rest.normal * 4.0
					shell_toss_vel = shell_toss_vel.reflect(rest.normal) * SHELL_BOUNCE
					if shell_toss_vel.length() < 200.0:
						shell_toss_vel = shell_toss_vel.normalized() * 200.0
					SFX.play_sfx_varied("shell_bounce", 0.8, 1.2, 0.6)
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
			if target_body is Bollard and (target_body as Bollard).is_dead:
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
			# Shell toss hit — deals HP damage via take_damage
			target_body.take_damage(0.0, dir)
			if target_body is Bollard:
				(target_body as Bollard).was_hit_by_shell = true
			# Knockback from shell impact
			var shell_impact := shell_toss_vel.length() * 2.0
			if character_type == CharacterType.ZAPPY:
				target_body.apply_central_impulse(dir * ZAPPY_TOSS_KNOCKBACK)
			elif character_type == CharacterType.GOOPY:
				target_body.apply_central_impulse(dir * shell_impact * GOOPY_TOSS_KNOCKBACK_MULT)
			else:
				target_body.apply_central_impulse(dir * shell_impact * 0.9)
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

func take_damage(amount: float, knockback_dir: Vector2) -> void:
	if is_invincible or is_dead:
		return
	# Only shell toss and dash hits deal damage — amount is ignored, HP system used instead
	var hp_loss: int = DAMAGE_SHELLED if not shell_missing else DAMAGE_UNSHELLED
	hit_points = maxi(hit_points - hp_loss, 0)
	# Fixed knockback (no scaling with damage)
	apply_central_impulse(knockback_dir * KNOCKBACK_BASE)
	SFX.play_sfx_varied("hit")
	if hit_points <= 0:
		die()

func _is_in_any_dash() -> bool:
	return is_dashing or is_phase_dashing or is_bolt_dashing or is_goo_dashing

func _on_body_entered(body: Node) -> void:
	if is_dead or is_invincible:
		return
	if not (body is RigidBody2D) or body == self or not body.has_method("take_damage"):
		return
	var other: RigidBody2D = body as RigidBody2D
	# Only dashes deal damage — regular collisions just bump
	if not _is_in_any_dash():
		return
	# If the other snail is also dashing, mutual immunity
	if other is Bollard and (other as Bollard)._is_in_any_dash():
		return
	var dir: Vector2 = (other.global_position - global_position).normalized()
	# Parry deflect: if the target is parrying, the attack bounces back to us
	if other is Bollard and (other as Bollard).is_parrying:
		var reverse_dir: Vector2 = -dir
		take_damage(0.0, reverse_dir)
		apply_central_impulse(reverse_dir * KNOCKBACK_BASE * 2.0)
		var hit_pos: Vector2 = (global_position + other.global_position) * 0.5
		big_hit.emit(hit_pos, true)
		SFX.play_sfx("parry_deflect")
		_end_any_dash()
		return
	# Dash hit — deal HP damage
	var impact_force := linear_velocity.length() * 3.0
	if is_bolt_dashing and character_type == CharacterType.ZAPPY:
		impact_force *= 0.54
	other.apply_central_impulse(dir * impact_force)
	var hit_pos: Vector2 = (global_position + other.global_position) * 0.5
	big_hit.emit(hit_pos, false)
	if is_dashing:
		is_dashing = false
		if dashes_remaining <= 0:
			charge_cooldown = CHARGE_COOLDOWN
	if is_bolt_dashing:
		is_bolt_dashing = false
		if bolt_dashes_remaining <= 0:
			bolt_dash_cooldown = BOLT_DASH_COOLDOWN
	other.take_damage(0.0, dir)


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
	if is_dead:
		return
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
	hit_points = MAX_HIT_POINTS

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
	if is_phase_dashing:
		_phase_set_exceptions(false)
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
	_prev_global_pos = spawn_pos
	# Clear drop-through exceptions
	for dt in drop_through_bodies:
		if is_instance_valid(dt.body):
			remove_collision_exception_with(dt.body)
	drop_through_bodies.clear()

func _update_emerge(delta: float) -> void:
	emerge_progress = minf(emerge_progress + delta / EMERGE_DURATION, 1.0)
	extend_amount = lerpf(0.0, 0.5, emerge_progress)
	_update_collision_shape()
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

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ SPRITE SYSTEM                                                            ║
# ║                                                                           ║
# ║ PALETTE-SWAP SPRITE SYSTEM (side-view snail shape)                       ║
# ║                                                                           ║
# ║ Sprites use key colors that the palette_swap shader remaps at runtime:   ║
# ║   Body:  #FF00FF (highlight)  #CC00CC (midtone)  #990099 (shadow)       ║
# ║   Shell: #00FFFF (highlight)  #00CCCC (midtone)  #009999 (shadow)       ║
# ║ All other pixel colors pass through unchanged (outlines, eyes, etc.)     ║
# ║                                                                           ║
# ║ Per-character sprites in sprites/snail/<blink|goopy|zappy>/:             ║
# ║   shell.png   24x24  — spiral shell (rendered at 2x = 48px)             ║
# ║   neck.png    12x4   — neck tile segment (rendered at 2x = 24x8)        ║
# ║   head.png    14x12  — head with eye stalks (rendered at 2x = 28x24)    ║
# ╚══════════════════════════════════════════════════════════════════════════╝

func _setup_sprites() -> void:
	# Shell (rendered at 2x scale to match BASE_RADIUS * 2 = 48px)
	spr_shell = _make_recolorable_sprite(TEX_SHELL, Vector2.ZERO, -1)
	spr_shell.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

	# Inner body — behind shell, exposed when shell is tossed (body-colored, not shell-shaped)
	spr_body_circle = _make_recolorable_sprite(TEX_INNER_BODY, Vector2.ZERO, -2)
	spr_body_circle.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

	# Neck tiles (stack vertically from shell upward, offset toward facing direction)
	for i in NECK_MAX_TILES:
		var tile := _make_recolorable_sprite(TEX_NECK, Vector2.ZERO, 0)
		tile.visible = false
		spr_neck_tiles.append(tile)

	# Head (caps the neck at the top, with baked-in eye stalks)
	spr_head = _make_recolorable_sprite(TEX_HEAD, Vector2.ZERO, 1)
	spr_head.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

	# Thrown shell (global coords — not attached to snail body)
	spr_thrown_shell = Sprite2D.new()
	spr_thrown_shell.texture = TEX_SHELL
	spr_thrown_shell.material = _make_palette_material()
	spr_thrown_shell.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	spr_thrown_shell.z_index = 5
	spr_thrown_shell.top_level = true
	spr_thrown_shell.visible = false
	add_child(spr_thrown_shell)


func _make_palette_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = PALETTE_SHADER
	mat.set_shader_parameter("body_color", Vector3(bollard_color.r, bollard_color.g, bollard_color.b))
	mat.set_shader_parameter("shell_color", Vector3(accent_color.r, accent_color.g, accent_color.b))
	return mat


func _make_recolorable_sprite(tex: Texture2D, pos: Vector2, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.z_index = z
	s.material = _make_palette_material()
	add_child(s)
	return s


func _set_sprite_colors(sprite: Sprite2D, body_c: Color, shell_c: Color) -> void:
	if sprite.material is ShaderMaterial:
		var mat: ShaderMaterial = sprite.material
		mat.set_shader_parameter("body_color", Vector3(body_c.r, body_c.g, body_c.b))
		mat.set_shader_parameter("shell_color", Vector3(shell_c.r, shell_c.g, shell_c.b))


func update_shell_colors() -> void:
	_load_character_sprites()
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
	spr_neck_tiles.clear()
	_setup_sprites()


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
		body_c = Color(0.6, 0.3, 1.0, 0.4)
		shell_c = Color(0.7, 0.4, 1.0, 0.4)
	if is_bolt_dashing:
		body_c = Color(0.3, 0.9, 1.0)
		shell_c = Color(0.5, 1.0, 1.0)
	if is_goo_dashing:
		body_c = Color(0.3, 0.9, 0.2)
		shell_c = Color(0.4, 1.0, 0.3)
	if is_parrying:
		shell_c = Color(1.0, 1.0, 0.6)
		body_c = body_c.lerp(Color(1.0, 1.0, 0.8), 0.5)

	# ── FACING DIRECTION ─────────────────────────────────────────────────
	if last_aim_dir.x > 0.1:
		facing_right = true
	elif last_aim_dir.x < -0.1:
		facing_right = false
	var face_sign: float = 1.0 if facing_right else -1.0

	# ── BODY CIRCLE (behind shell — visible when shell is tossed) ────────
	_set_sprite_colors(spr_body_circle, body_c, shell_c)

	# ── SHELL ────────────────────────────────────────────────────────────
	spr_shell.visible = not shell_missing
	_set_sprite_colors(spr_shell, body_c, shell_c)
	spr_shell.scale = Vector2(SPRITE_SCALE * face_sign, SPRITE_SCALE)
	if is_phase_dashing:
		spr_shell.self_modulate.a = 0.4
	else:
		spr_shell.self_modulate.a = 1.0

	# ── THROWN SHELL (world-space projectile) ─────────────────────────────
	spr_thrown_shell.visible = shell_missing
	if shell_missing:
		spr_thrown_shell.global_position = shell_toss_pos
		if character_type == CharacterType.ZAPPY and shell_toss_hit:
			var pulse := (sin(shell_toss_timer * 12.0) + 1.0) * 0.5
			var pulse_shell: Color = accent_color.lerp(Color(0.4, 0.85, 1.0), pulse * 0.7)
			_set_sprite_colors(spr_thrown_shell, body_c, pulse_shell)
		else:
			_set_sprite_colors(spr_thrown_shell, body_c, accent_color)
		spr_thrown_shell.rotation += 8.0 * get_physics_process_delta_time()

	# ── NECK (tiling segments — offset toward facing direction) ──────────
	var neck_offset_x: float = face_sign * BASE_RADIUS * 0.35 + body_shake_x
	var tile_sx: float = SPRITE_SCALE * face_sign
	var tile_sy: float = SPRITE_SCALE
	var tiles_needed: int = ceili(post_h / NECK_TILE_HEIGHT) if post_h > 3.0 else 0
	tiles_needed = mini(tiles_needed, NECK_MAX_TILES)
	for i in NECK_MAX_TILES:
		if i < tiles_needed:
			var tile := spr_neck_tiles[i]
			tile.visible = true
			var tile_bottom_y: float = -float(i) * NECK_TILE_HEIGHT
			tile.position = Vector2(neck_offset_x, tile_bottom_y - NECK_TILE_HEIGHT * 0.5)
			tile.scale = Vector2(tile_sx, tile_sy)
			_set_sprite_colors(tile, body_c, shell_c)
			if is_phase_dashing:
				tile.self_modulate.a = 0.4
			else:
				tile.self_modulate.a = 1.0
		else:
			spr_neck_tiles[i].visible = false
	# Clip the topmost tile if neck height isn't a perfect multiple
	if tiles_needed > 0:
		var remainder := fmod(post_h, NECK_TILE_HEIGHT)
		if remainder > 0.01:
			var top_tile := spr_neck_tiles[tiles_needed - 1]
			var clip_sy: float = (remainder / NECK_TILE_HEIGHT) * SPRITE_SCALE
			top_tile.scale = Vector2(tile_sx, clip_sy)
			var tile_bottom_y: float = -float(tiles_needed - 1) * NECK_TILE_HEIGHT
			top_tile.position = Vector2(neck_offset_x, tile_bottom_y - remainder * 0.5)

	# ── HEAD (caps the neck at the top) ──────────────────────────────────
	var tip_y := -post_h
	var head_h: float = TEX_HEAD.get_height() * SPRITE_SCALE
	spr_head.scale = Vector2(SPRITE_SCALE * face_sign, SPRITE_SCALE)
	spr_head.position = Vector2(neck_offset_x, tip_y - head_h * 0.5)
	_set_sprite_colors(spr_head, body_c, shell_c)
	if is_phase_dashing:
		spr_head.self_modulate.a = 0.4
	else:
		spr_head.self_modulate.a = 1.0

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

	# Goopy goo trail puddles — pixelated rectangles (world-aligned, not body-rotated)
	if character_type == CharacterType.GOOPY and not goo_trails.is_empty():
		draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
		for trail in goo_trails:
			var local_pos: Vector2 = trail.pos - global_position
			var trail_alpha: float = clampf(trail.timer / GOO_TRAIL_DURATION, 0.0, 1.0) * 0.7
			var r := GOO_TRAIL_RADIUS
			draw_rect(Rect2(local_pos.x - r, local_pos.y - r * 0.4, r * 2.0, r * 0.8), Color(0.35, 0.8, 0.2, trail_alpha))
			var r2 := r * 0.5
			draw_rect(Rect2(local_pos.x - r2, local_pos.y - r2 * 0.4, r2 * 2.0, r2 * 0.8), Color(0.5, 0.9, 0.3, trail_alpha * 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Zappy electric beam between body and shell
	if shell_missing and character_type == CharacterType.ZAPPY:
		var shell_local := to_local(shell_toss_pos)
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
	var y_diff := ai_target.global_position.y - global_position.y
	var roll := randf()

	# React to incoming shell — parry or dodge
	if ai_target.shell_missing and not ai_target.shell_toss_hit:
		var shell_dist := global_position.distance_to(ai_target.shell_toss_pos)
		var shell_approaching := (ai_target.shell_toss_pos - global_position).normalized().dot(ai_target.shell_toss_vel.normalized()) < -0.3
		if shell_dist < 200.0 and shell_approaching:
			if parry_cooldown <= 0.0 and not is_parrying and randf() < 0.6:
				_start_parry()
				ai_state = "idle"
				ai_action_duration = 0.3
				return
			else:
				ai_state = "retreat"
				ai_action_duration = randf_range(0.2, 0.5)
				return

	# Low HP: more aggressive + use abilities to finish fights, occasionally retreat
	if hit_points <= 1:
		if roll < 0.15:
			ai_state = "retreat"
			ai_action_duration = randf_range(0.3, 0.6)
			return
		elif roll < 0.5:
			ai_state = "ability2"
			ai_action_duration = 0.1
			return

	# Far away: close the gap quickly
	if abs_dist > 300.0:
		if roll < 0.3:
			ai_state = "shell_toss"
			ai_action_duration = 0.1
		else:
			ai_state = "approach"
			ai_action_duration = randf_range(0.3, 0.8)
		return

	# Medium range: mix of attacks and approach
	if abs_dist > 150.0:
		if roll < 0.25:
			ai_state = "shell_toss"
			ai_action_duration = 0.1
		elif roll < 0.45:
			ai_state = "charge_attack"
			ai_action_duration = randf_range(0.3, 0.7)
		elif roll < 0.6:
			ai_state = "ability2"
			ai_action_duration = 0.1
		else:
			ai_state = "approach"
			ai_action_duration = randf_range(0.2, 0.5)
		return

	# Close range: aggressive combat
	if roll < 0.12:
		ai_state = "lower_spin"
		ai_action_duration = randf_range(0.3, 0.5)
	elif roll < 0.32:
		ai_state = "shell_toss"
		ai_action_duration = 0.1
	elif roll < 0.50:
		ai_state = "ability2"
		ai_action_duration = 0.1
	elif roll < 0.70:
		ai_state = "charge_attack"
		ai_action_duration = randf_range(0.2, 0.5)
	elif roll < 0.85:
		ai_state = "attack"
		ai_action_duration = randf_range(0.2, 0.6)
	else:
		# Quick reposition
		ai_state = "approach"
		ai_action_duration = randf_range(0.1, 0.3)

func _ai_near_edge() -> bool:
	return global_position.x < 16.0 or global_position.x > 1264.0

func _ai_edge_safe_dir() -> float:
	var dir := signf(ai_target.global_position.x - global_position.x)
	if global_position.x < 16.0 and dir < 0.0:
		return 1.0
	if global_position.x > 1264.0 and dir > 0.0:
		return -1.0
	return dir

func _ai_approach(delta: float) -> void:
	var dir := _ai_edge_safe_dir()
	apply_torque(LEAN_TORQUE * dir * 1.3)
	extend_amount = move_toward(extend_amount, 0.65, EXTEND_SPEED * 0.8 * delta)

func _ai_attack(delta: float) -> void:
	var dir := _ai_edge_safe_dir()
	apply_torque(LEAN_TORQUE * 1.8 * dir)
	extend_amount = minf(extend_amount + EXTEND_SPEED * 2.0 * delta, 1.0)

func _ai_lower_spin(delta: float) -> void:
	extend_amount = maxf(extend_amount - EXTEND_SPEED * 2.5 * delta, 0.0)
	apply_torque(LEAN_TORQUE * 2.5)

func _ai_retreat(delta: float) -> void:
	var dir := -signf(ai_target.global_position.x - global_position.x)
	if global_position.x < 0.0 and dir < 0.0:
		dir = 1.0
	elif global_position.x > 1280.0 and dir > 0.0:
		dir = -1.0
	apply_torque(LEAN_TORQUE * dir * 1.0)
	extend_amount = move_toward(extend_amount, 0.35, EXTEND_SPEED * 1.5 * delta)
	# Parry if enemy is close while retreating
	if ai_target.global_position.distance_to(global_position) < 100.0 and parry_cooldown <= 0.0 and not is_parrying and randf() < 0.3:
		_start_parry()

func _ai_charge_attack(delta: float) -> void:
	# Aim toward the target, predicting movement slightly
	var to_target := ai_target.global_position - global_position
	var predict_offset := ai_target.linear_velocity * 0.15
	var aim_target := (to_target + predict_offset).normalized()
	aim_dir = Vector2(aim_target.x, clampf(aim_target.y, -0.5, 0.2)).normalized()
	last_aim_dir = aim_dir
	apply_torque(LEAN_TORQUE * signf(to_target.x) * 0.3)
	match character_type:
		CharacterType.ZAPPY:
			is_bolt_charging = true
			bolt_charge_amount = minf(bolt_charge_amount + delta / BOLT_DASH_CHARGE_TIME, 1.0)
		_:
			is_charging = true
			charge_amount = minf(charge_amount + delta / CHARGE_TIME, 1.0)

func _ai_shell_toss() -> void:
	# Aim at the target with prediction
	var to_target := ai_target.global_position - global_position
	var predict_offset := ai_target.linear_velocity * 0.2
	var aim_target := (to_target + predict_offset).normalized()
	aim_dir = Vector2(aim_target.x, clampf(aim_target.y, -0.6, 0.3)).normalized()
	last_aim_dir = aim_dir
	match character_type:
		CharacterType.BLINK:
			if shell_missing:
				if can_teleport_to_shell and not blink_teleport_used:
					# Teleport to shell if it's near the enemy
					var shell_to_enemy := ai_target.global_position.distance_to(shell_toss_pos)
					if shell_to_enemy < 200.0 or randf() < 0.5:
						_blink_teleport_to_shell()
				return
			if shell_toss_cooldown > 0.0 or blink_toss_used:
				return
			toss_charge_amount = randf_range(0.5, 1.0)
			_fire_shell_toss()
			blink_toss_used = true
			can_teleport_to_shell = true
		CharacterType.GOOPY:
			if shell_missing:
				if goopy_tether_active:
					# Zip to shell if near the enemy or pull to recover
					_goopy_zip_to_shell()
				return
			if shell_toss_cooldown > 0.0:
				return
			toss_charge_amount = randf_range(0.5, 1.0)
			_fire_shell_toss()
			goopy_tether_active = true
			goopy_tether_timer = 0.0
		CharacterType.ZAPPY:
			if shell_missing or shell_toss_cooldown > 0.0:
				return
			_fire_zappy_shell_toss()

func _ai_ability2() -> void:
	# Aim toward the enemy for ability2
	var to_target := ai_target.global_position - global_position
	aim_dir = to_target.normalized()
	aim_dir.y = clampf(aim_dir.y, -0.4, 0.2)
	aim_dir = aim_dir.normalized()
	last_aim_dir = aim_dir
	match character_type:
		CharacterType.BLINK:
			if phase_dash_cooldown <= 0.0 and not blink_phase_used:
				_start_phase_dash()
				blink_phase_used = true
		CharacterType.GOOPY:
			if goo_dash_cooldown <= 0.0 and not is_goo_dashing:
				goo_charge_amount = randf_range(0.5, 1.0)
				_start_goo_dash()
		CharacterType.ZAPPY:
			if bolt_dash_cooldown <= 0.0 and bolt_dashes_remaining > 0:
				bolt_charge_amount = randf_range(0.6, 1.0)
				_start_bolt_dash()
