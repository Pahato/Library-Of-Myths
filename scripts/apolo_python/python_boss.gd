extends CharacterBody2D
class_name PythonBoss

# --- Sinais ---
signal boss_died

# --- Atributos do Boss (lidos da dificuldade) ---
@export var max_health: int = 15
var current_health: int = 15

@export var speed: float = 40.0
@export var ai_cooldown: float = 1.8

@export var venom_scene: PackedScene = preload("res://scenes/apolo_python/venom_projectile.tscn")

# --- Estado ---
enum State { IDLE, PATROL, BITE, SPIT, RAIN, FRENZY, ARENA_DASH, PHASE2_TRANSITION }
var current_state: State = State.PATROL

# --- Temporizadores ---
var ai_timer: float = 0.0
var skill_timer: float = 0.0

# --- Referências ---
var player: CharacterBody2D = null
@onready var sprite = $Sprite2D
@onready var health_bar = $ProgressBar

var hitbox_area: Area2D = null
var hitbox_shape: CollisionShape2D = null

# --- Variáveis para Skills ---
var bite_dir: Vector2 = Vector2.ZERO
var spit_count: int = 0
var spit_timer: float = 0.0
var is_biting_windup: bool = false
var bite_windup_timer: float = 0.0
var last_action: State = State.PATROL

# --- Fase 2 ---
var is_phase_2: bool = false
var phase2_triggered: bool = false # flag para ativar só uma vez
var is_invincible: bool = false
var boss_name: String = "PÍTON, A SERPENTE DE DELFOS" # will be updated dynamically via translations

# --- Escudo e Atordoamento (Fase 2) ---
var shield_active: bool = false
var shield_shoot_timer: float = 0.0
var is_stunned: bool = false
var stun_timer: float = 0.0

# --- Frenzy Dash ---
var frenzy_bites_remaining: int = 0
var frenzy_bite_timer: float = 0.0
var frenzy_in_bite: bool = false

# --- Arena Dash ---
var arena_dash_warning_timer: float = 0.0
var arena_dash_active: bool = false
var arena_dash_direction: float = 1.0

# Efeitos Sonoros da Píton
var sound_spit: AudioStreamPlayer
var sound_bite: AudioStreamPlayer
var sound_phase2: AudioStreamPlayer
var sound_hurt: AudioStreamPlayer
var sound_shield_hit: AudioStreamPlayer
var sound_shield_break: AudioStreamPlayer
var sound_shield_recover: AudioStreamPlayer

# Cores
var base_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var phase2_base_color: Color = Color(0.65, 0.1, 0.9, 1.0) # roxo escuro fase 2

# --- Animação Procedural ---
var anim_time: float = 0.0
var base_sprite_scale: Vector2 = Vector2(0.125, 0.125)
var base_sprite_pos: Vector2 = Vector2(0, -44) # Alinhamento perfeito com o chão
var attack_tween: Tween = null
var hit_shake_intensity: float = 0.0
var hit_shake_timer: float = 0.0
var hit_tilt: float = 0.0
var contact_damage_timer: float = 0.0
const CONTACT_DAMAGE_COOLDOWN: float = 0.8

func _ready():
	# Camadas de colisão programáticas: Layer 4 (Enemies = 8), Mask 1 (World = 1)
	collision_layer = 8
	collision_mask = 1

	# Lê dificuldade do GameGlobals
	max_health = GameGlobals.get_boss_phase1_health()
	speed = GameGlobals.get_boss_speed()
	ai_cooldown = GameGlobals.get_boss_ai_cooldown()
	
	current_health = max_health
	# Initialize boss name from translation (respects saved language)
	boss_name = GameGlobals.get_text("boss_name_phase_1")
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	# Ajusta a hitbox de colisão física (CharacterBody2D) para ser pequena (32x32) nos pés
	# Isto evita que a cobra bata com a cabeça ou corpo nas plataformas flutuantes
	var col_shape = $CollisionShape2D
	if col_shape:
		var rect = RectangleShape2D.new()
		rect.size = Vector2(32, 32)
		col_shape.shape = rect
		col_shape.position = Vector2(0, -16)
		
	# Configurar Efeitos Sonoros
	sound_spit = AudioStreamPlayer.new()
	sound_spit.stream = load("res://assets/sounds/shoot.wav")
	sound_spit.volume_db = -8.0
	sound_spit.pitch_scale = 0.7
	sound_spit.bus = "SFX"
	add_child(sound_spit)
	
	sound_bite = AudioStreamPlayer.new()
	sound_bite.stream = load("res://assets/sounds/jump.wav")
	sound_bite.volume_db = -4.0
	sound_bite.pitch_scale = 0.5
	sound_bite.bus = "SFX"
	add_child(sound_bite)

	sound_phase2 = AudioStreamPlayer.new()
	sound_phase2.stream = load("res://assets/sounds/explosion.wav")
	sound_phase2.volume_db = -2.0
	sound_phase2.bus = "SFX"
	add_child(sound_phase2)

	sound_hurt = AudioStreamPlayer.new()
	sound_hurt.stream = load("res://assets/sounds/hurt.wav")
	sound_hurt.volume_db = -4.0
	sound_hurt.pitch_scale = 0.65
	sound_hurt.bus = "SFX"
	add_child(sound_hurt)

	sound_shield_hit = AudioStreamPlayer.new()
	sound_shield_hit.stream = load("res://assets/sounds/clink.wav")
	sound_shield_hit.volume_db = -5.0
	sound_shield_hit.pitch_scale = 1.3
	sound_shield_hit.bus = "SFX"
	add_child(sound_shield_hit)

	sound_shield_break = AudioStreamPlayer.new()
	sound_shield_break.stream = load("res://assets/sounds/explosion.wav")
	sound_shield_break.volume_db = -4.0
	sound_shield_break.pitch_scale = 1.2
	sound_shield_break.bus = "SFX"
	add_child(sound_shield_break)

	sound_shield_recover = AudioStreamPlayer.new()
	sound_shield_recover.stream = load("res://assets/sounds/power_up.wav")
	sound_shield_recover.volume_db = -6.0
	sound_shield_recover.pitch_scale = 0.8
	sound_shield_recover.bus = "SFX"
	add_child(sound_shield_recover)

	# Cria a BossHitbox programaticamente para deteção de setas
	hitbox_area = Area2D.new()
	hitbox_area.name = "BossHitbox"
	hitbox_area.collision_layer = 8
	hitbox_area.collision_mask = 0 # Não precisa detetar nada, apenas ser detetada
	
	hitbox_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(60, 120)
	hitbox_shape.shape = rect_shape
	hitbox_shape.position = Vector2(0, -16) # Bottom da shape alinhado com o ground (sprite position Y=-44 + 44 = 0)
	
	hitbox_area.add_child(hitbox_shape)
	add_child(hitbox_area)

	# Procurar o Jogador
	player = get_parent().get_node_or_null("Player")
	if not player:
		player = get_tree().root.find_child("Player", true, false)

func _physics_process(delta):
	# Se estiver atordoado, congela e não processa IA
	if is_stunned:
		velocity = Vector2.ZERO
		if not is_on_floor():
			velocity.y += 1000.0 * delta
		move_and_slide()
		stun_timer -= delta
		if stun_timer <= 0.0:
			_recover_from_stun()
		
		# Anima o boss (tremer ligeiramente de atordoado)
		_animate_boss(delta)
		queue_redraw()
		return

	# Dano por contacto físico
	_check_player_contact(delta)

	# Aplicar gravidade simples (exceto durante Arena Dash)
	if not is_on_floor() and current_state != State.BITE and current_state != State.ARENA_DASH:
		velocity.y += 1000.0 * delta

	# Procurar jogador se não tiver sido encontrado ainda
	if not player:
		player = get_parent().get_node_or_null("Player")
		return

	# Fase 2 pausa o processamento de IA
	if current_state == State.PHASE2_TRANSITION:
		move_and_slide()
		return

	# Assédio automático com bolas de veneno na Fase 2 enquanto protegida por escudo
	if is_phase_2 and shield_active and not is_stunned:
		shield_shoot_timer += delta
		var shoot_cd = GameGlobals.get_boss_shield_shoot_cooldown()
		if shield_shoot_timer >= shoot_cd:
			shield_shoot_timer = 0.0
			_shoot_venom_projectile()

	# Gerir temporizadores de skills ativas
	if skill_timer > 0:
		skill_timer -= delta
		if skill_timer <= 0:
			_return_to_patrol()

	# Gerir a inteligência artificial decisional
	if current_state == State.PATROL:
		ai_timer += delta
		if ai_timer >= ai_cooldown:
			ai_timer = 0.0
			_evaluate_next_action()

	# Executar comportamentos de estado
	match current_state:
		State.PATROL:
			_behavior_patrol(delta)
		State.BITE:
			_behavior_bite(delta)
		State.SPIT:
			_behavior_spit(delta)
		State.RAIN:
			pass # Projéteis lançados no _start_rain; skill_timer trata do regresso
		State.FRENZY:
			_behavior_frenzy(delta)
		State.ARENA_DASH:
			_behavior_arena_dash(delta)

	# Anti-stack: verifica e corrige boss em cima do jogador
	_prevent_stacking()

	move_and_slide()
	
	# Anima o boss de forma procedural (rastejar, respirar, ataques, impacto)
	_animate_boss(delta)
	
	# Garante o redesenho do escudo se estiver ativo na Fase 2
	if is_phase_2:
		queue_redraw()

func _prevent_stacking():
	if not player:
		return
	var diff = global_position - player.global_position
	# Boss está "em cima" do jogador: muito perto horizontalmente E acima verticalmente
	if abs(diff.x) < 28 and diff.y < 0 and diff.y > -90:
		# Empurra para o lado oposto ao centro do jogador com velocidade fixa alta
		var push_dir = 1.0 if diff.x >= 0 else -1.0
		if diff.x == 0:
			push_dir = 1.0 if randf() > 0.5 else -1.0
		
		# Define uma velocidade de empurrão horizontal alta para deslizar de imediato
		velocity.x = push_dir * 250.0
		
		# Se o boss estiver em estado passivo (PATROL), força avaliação de nova ação de imediato
		if current_state == State.PATROL:
			ai_timer = ai_cooldown

func _return_to_patrol():
	current_state = State.PATROL
	if sprite:
		sprite.modulate = base_color
	velocity.x = 0

func _evaluate_next_action():
	if not player:
		return

	var dist = global_position.distance_to(player.global_position)
	var chosen_action: State = State.PATROL
	
	# Fase 1: altera a cor base se estiver com raiva (<50% vida)
	if not is_phase_2:
		var is_enraged = current_health < (max_health / 2)
		if is_enraged:
			base_color = Color(1.0, 0.6, 0.6, 1.0)
		else:
			base_color = Color(1.0, 1.0, 1.0, 1.0)

	# Cria uma lista de ações possíveis com base na distância e fase
	var possible_actions: Array = []
	
	if is_phase_2:
		if dist < 170.0:
			# Perto na Fase 2
			possible_actions = [State.FRENZY, State.BITE, State.SPIT]
		else:
			# Longe na Fase 2
			possible_actions = [State.ARENA_DASH, State.SPIT, State.RAIN]
	else:
		# Fase 1
		if dist < 150.0:
			# Perto na Fase 1
			possible_actions = [State.BITE, State.SPIT, State.RAIN]
		else:
			# Longe na Fase 1
			possible_actions = [State.SPIT, State.RAIN]
			
	# Remove a última ação para evitar repetições consecutivas chatas e incentivar variedade
	if possible_actions.size() > 1 and possible_actions.has(last_action):
		possible_actions.erase(last_action)
		
	# Escolhe uma ação aleatória do conjunto filtrado
	if not possible_actions.is_empty():
		chosen_action = possible_actions[randi() % possible_actions.size()]
	else:
		chosen_action = State.SPIT # Fallback de segurança
		
	# Salva a ação atual como a última
	last_action = chosen_action
	
	# Inicia a ação correspondente
	match chosen_action:
		State.BITE:
			_start_bite()
		State.SPIT:
			_start_spit()
		State.RAIN:
			_start_rain()
		State.FRENZY:
			_start_frenzy()
		State.ARENA_DASH:
			_start_arena_dash()
		_:
			_return_to_patrol()

# --- Comportamento: Patrulha ---
func _behavior_patrol(_delta):
	var target_x = player.global_position.x
	
	# Na Fase 2 com escudo ativo, limitar o patrulhamento à zona central
	if is_phase_2 and shield_active:
		target_x = clamp(player.global_position.x, -160.0, 160.0)
		
	var dir = sign(target_x - global_position.x)
	# Reduz velocidade na fase de escudo para dar hipótese ao jogador de navegar a arena
	var current_speed = speed * 0.5 if (is_phase_2 and shield_active) else speed
	
	if abs(target_x - global_position.x) > 10.0:
		velocity.x = dir * current_speed
	else:
		velocity.x = 0
		
	if sprite and dir != 0:
		sprite.flip_h = dir > 0

# --- Comportamento e Configuração: Mordida (Bite) ---
func _start_bite():
	current_state = State.BITE
	skill_timer = 0.85 # Duração total (0.35s windup + 0.5s dash)
	is_biting_windup = true
	bite_windup_timer = 0.35
	velocity = Vector2.ZERO
	
	# Determina direção do jogador no início da preparação
	if player:
		bite_dir = (player.global_position - global_position).normalized()
	else:
		bite_dir = Vector2.RIGHT
		
	# Animação de puxar para trás (preparação)
	if sprite:
		if attack_tween:
			attack_tween.kill()
		attack_tween = create_tween()
		sprite.position = base_sprite_pos
		sprite.modulate = Color(1.6, 0.15, 0.15, 1.0) # vermelho de aviso brilhante
		
		var pullback_pos = base_sprite_pos - bite_dir * 24.0
		attack_tween.tween_property(sprite, "position", pullback_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Tremer na postura de recuo
		for i in range(2):
			attack_tween.tween_property(sprite, "position", pullback_pos + Vector2(-3, 0), 0.05)
			attack_tween.tween_property(sprite, "position", pullback_pos + Vector2(3, 0), 0.05)

func _behavior_bite(delta):
	if is_biting_windup:
		velocity = Vector2.ZERO
		bite_windup_timer -= delta
		if bite_windup_timer <= 0.0:
			is_biting_windup = false
			# Agora executa a investida/dash real!
			velocity = bite_dir * 320.0
			if sound_bite:
				sound_bite.play()
			
			# Animação de lunge rápida para a frente
			if sprite:
				if attack_tween:
					attack_tween.kill()
				attack_tween = create_tween()
				var lunge_pos = base_sprite_pos + bite_dir * 60.0
				sprite.modulate = Color(1.8, 0.0, 0.0, 1.0) # Vermelho de ataque ativo
				attack_tween.tween_property(sprite, "position", lunge_pos, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				attack_tween.tween_property(sprite, "position", base_sprite_pos, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return

	# Dash ativo
	velocity.x = bite_dir.x * 320.0
	if not player:
		return
	var diff = player.global_position - global_position
	# Verifica colisão de proximidade na investida
	if abs(diff.x) < 30.0 and diff.y > -110.0 and diff.y < 15.0:
		if player.has_method("take_damage"):
			player.take_damage(2)
		_return_to_patrol()

# --- Comportamento e Configuração: Cuspir Veneno (Spit) ---
func _start_spit():
	current_state = State.SPIT
	skill_timer = 1.0
	if sprite:
		sprite.modulate = Color(0.8, 0.5, 1.0, 1.0)
	velocity = Vector2.ZERO
	spit_count = 3
	spit_timer = 0.0

func _behavior_spit(delta):
	if spit_timer > 0:
		spit_timer -= delta
	if spit_count > 0 and spit_timer <= 0:
		spit_timer = 0.25
		spit_count -= 1
		_shoot_venom_projectile()

func _shoot_venom_projectile():
	if not venom_scene or not player:
		return
	if sound_spit:
		sound_spit.play()
	
	var shoot_dir = (player.global_position - global_position).normalized()
	
	if is_phase_2:
		# Disparo triplo em leque (spread) na Fase 2
		var angles = [-0.2, 0.0, 0.2]
		for angle in angles:
			var venom = venom_scene.instantiate()
			var rotated_dir = shoot_dir.rotated(angle)
			venom.position = global_position + rotated_dir * 25.0
			venom.direction = rotated_dir
			# Aumenta velocidade do veneno da Fase 2
			if "speed" in venom:
				venom.speed *= 1.15
			get_parent().add_child(venom)
	else:
		var venom = venom_scene.instantiate()
		venom.position = global_position + shoot_dir * 25.0
		venom.direction = shoot_dir
		get_parent().add_child(venom)
	
	# Animação de recuo e disparo (Recoil & Snap)
	if sprite:
		if attack_tween:
			attack_tween.kill()
		attack_tween = create_tween()
		
		# Recua na direção oposta ao disparo
		var recoil_pos = base_sprite_pos - shoot_dir * 16.0
		sprite.position = recoil_pos
		# Snap rápido de volta à posição original
		attack_tween.tween_property(sprite, "position", base_sprite_pos, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- Comportamento e Configuração: Chuva Venenosa (Rain) ---
func _start_rain():
	current_state = State.RAIN
	skill_timer = 1.2
	if sprite:
		sprite.modulate = Color(1.0, 0.8, 0.4, 1.0)
	velocity = Vector2.ZERO
	
	# Animação de erguer a cabeça para invocar chuva
	if sprite:
		if attack_tween:
			attack_tween.kill()
		attack_tween = create_tween()
		sprite.position = base_sprite_pos
		
		# Eleva verticalmente a cabeça
		attack_tween.tween_property(sprite, "position", base_sprite_pos + Vector2(0, -22.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		attack_tween.tween_interval(0.6)
		attack_tween.tween_property(sprite, "position", base_sprite_pos, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	var total_drops = 7 if is_phase_2 else 5
	for i in range(total_drops):
		_spawn_rain_drop(i, total_drops)

func _spawn_rain_drop(index: int, total: int):
	if not venom_scene or not player:
		return
	var venom = venom_scene.instantiate()
	var offset_x = (index - float(total - 1) / 2.0) * (300.0 / float(total)) + randf_range(-15, 15)
	var spawn_pos = Vector2(player.global_position.x + offset_x, player.global_position.y - 220.0)
	venom.position = spawn_pos
	venom.direction = Vector2.DOWN
	
	# Gotas caem mais rápido na Fase 2
	var base_speed = 180.0
	if is_phase_2:
		base_speed *= 1.3
	venom.speed = base_speed
	
	get_parent().add_child(venom)

# =============================================================
# --- FASE 2 ---
# =============================================================

func _start_phase_2_transition():
	if phase2_triggered:
		return
	phase2_triggered = true
	is_invincible = true
	current_health = 1
	current_state = State.PHASE2_TRANSITION
	velocity = Vector2.ZERO
	if sound_phase2:
		sound_phase2.play()

	# Tremor de câmara forte e persistente
	if player and player.has_method("shake_camera"):
		player.shake_camera(15.0)

	# Animação de piscar (roxo <-> branco) e crescer fisicamente (evolução)
	if sprite:
		var flash_tween = create_tween()
		flash_tween.set_parallel(true)
		
		var growth_scale = base_sprite_scale * 1.5
		var growth_pos = base_sprite_pos + Vector2(0, -22)
		
		for i in range(8):
			var t = flash_tween.chain()
			t.tween_property(sprite, "modulate", Color(0.7, 0.1, 0.9, 1.0), 0.08)
			t.tween_property(sprite, "scale", base_sprite_scale.lerp(growth_scale, float(i)/8.0), 0.08)
			t.tween_property(sprite, "position", base_sprite_pos.lerp(growth_pos, float(i)/8.0), 0.08)
			
			t.chain().tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)

		# Pausa dramática pós-evolução antes de carregar
		flash_tween.chain().tween_interval(0.4)
		flash_tween.chain().tween_callback(func():
			_activate_phase_2()
		)

func _activate_phase_2():
	is_phase_2 = true
	is_invincible = false
	base_color = phase2_base_color
	shield_active = true # Ativa o escudo protetor da Fase 2
	boss_name = GameGlobals.get_text("boss_name_phase_2")

	# Reiniciar a vida com a vida máxima da Fase 2
	max_health = GameGlobals.get_boss_phase2_health()
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	# Atualizar a escala e posição base permanente para a forma evoluída
	base_sprite_scale = Vector2(0.18, 0.18)
	base_sprite_pos = Vector2(0, -66) # Grounding perfeito para o sprite maior

	# Reutilizar o sprite transparente original da Píton, mas com escala aumentada
	# e modulate roxo escuro/neon para caracterizar a Fase 2 (evita imagem de carta bugada)
	var tex = load("res://assets/sprites/Python.png")
	if tex:
		sprite.texture = tex

	# Melhora as estatísticas para a Fase 2 (mais forte e agressiva com mini-cooldown justo)
	speed = GameGlobals.get_boss_speed() * 1.5
	ai_cooldown = max(1.1, GameGlobals.get_boss_ai_cooldown() * 0.75)

	if sprite:
		sprite.modulate = base_color
		sprite.scale = base_sprite_scale
		sprite.position = base_sprite_pos

	# Ajusta o tamanho da hitbox para a Fase 2 (1.5x maior)
	if is_instance_valid(hitbox_shape) and hitbox_shape.shape is RectangleShape2D:
		hitbox_shape.shape.size = Vector2(90, 180)
		hitbox_shape.position = Vector2(0, -24) # Bottom alinhado com o ground (sprite Y=-66 + 66 = 0)

	# Tremor de terra final para selar a transformação
	if player and player.has_method("shake_camera"):
		player.shake_camera(9.0)

	# Retoma a ação e IA normais
	_return_to_patrol()
	current_state = State.PATROL

func _load_texture(path: String) -> Texture2D:
	var abs_path = ProjectSettings.globalize_path(path).replace("\\", "/")
	if FileAccess.file_exists(abs_path):
		var img = Image.load_from_file(abs_path)
		if img and img.get_width() > 0:
			return ImageTexture.create_from_image(img)
	return load(path)

# --- Frenzy Dash: 3 Mordidas Consecutivas ---
func _start_frenzy():
	current_state = State.FRENZY
	frenzy_bites_remaining = 3
	frenzy_bite_timer = 0.45 # tempo de aviso da primeira mordida do frenzy
	frenzy_in_bite = false
	velocity = Vector2.ZERO
	if player:
		bite_dir = (player.global_position - global_position).normalized()
		
	# Puxa para trás (preparação)
	if sprite:
		if attack_tween:
			attack_tween.kill()
		attack_tween = create_tween()
		sprite.position = base_sprite_pos
		sprite.modulate = Color(1.6, 0.15, 0.15, 1.0)
		var pullback_pos = base_sprite_pos - bite_dir * 28.0
		attack_tween.tween_property(sprite, "position", pullback_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		for i in range(3):
			attack_tween.tween_property(sprite, "position", pullback_pos + Vector2(-3, 0), 0.06)
			attack_tween.tween_property(sprite, "position", pullback_pos + Vector2(3, 0), 0.06)

func _behavior_frenzy(delta):
	if frenzy_in_bite:
		# Mantém a investida atual
		velocity.x = bite_dir.x * 380.0

		# Verifica colisão com o jogador via proximidade
		if player:
			var diff = player.global_position - global_position
			if abs(diff.x) < 30.0 and diff.y > -110.0 and diff.y < 15.0:
				if player.has_method("take_damage"):
					player.take_damage(1) # 1 dano por mordida
				frenzy_in_bite = false
				frenzy_bite_timer = 0.35 # pausa/preparação antes da próxima mordida
				velocity = Vector2.ZERO
				# Puxa para trás preparando a próxima
				if sprite and frenzy_bites_remaining > 0:
					if attack_tween:
						attack_tween.kill()
					attack_tween = create_tween()
					bite_dir = (player.global_position - global_position).normalized()
					var pullback = base_sprite_pos - bite_dir * 20.0
					attack_tween.tween_property(sprite, "position", pullback, 0.15).set_trans(Tween.TRANS_QUAD)

		# Termina esta mordida após 0.4s
		frenzy_bite_timer -= delta
		if frenzy_bite_timer <= 0:
			frenzy_in_bite = false
			frenzy_bite_timer = 0.35 # pausa/preparação
			velocity = Vector2.ZERO
			# Puxa para trás preparando a próxima
			if sprite and frenzy_bites_remaining > 0:
				if attack_tween:
					attack_tween.kill()
				attack_tween = create_tween()
				if player:
					bite_dir = (player.global_position - global_position).normalized()
				var pullback = base_sprite_pos - bite_dir * 20.0
				attack_tween.tween_property(sprite, "position", pullback, 0.15).set_trans(Tween.TRANS_QUAD)
	else:
		velocity.x = move_toward(velocity.x, 0, 1000.0 * delta) # trava
		
		frenzy_bite_timer -= delta
		
		# Animação de preparação/wind-up durante a pausa
		if frenzy_bite_timer > 0.0 and frenzy_bites_remaining > 0:
			if sprite:
				sprite.modulate = Color(1.6, 0.15, 0.15, 1.0)
				
		if frenzy_bite_timer <= 0:
			if frenzy_bites_remaining > 0:
				# Inicia próxima mordida
				frenzy_bites_remaining -= 1
				frenzy_in_bite = true
				frenzy_bite_timer = 0.45 # duração da investida
				if player:
					bite_dir = (player.global_position - global_position).normalized()
				velocity = bite_dir * 380.0
				if sound_bite:
					sound_bite.play()

				# Animação de lunge
				if sprite:
					if attack_tween:
						attack_tween.kill()
					attack_tween = create_tween()
					var lunge_pos = base_sprite_pos + bite_dir * 60.0
					sprite.modulate = Color(1.8, 0.0, 0.0, 1.0)
					attack_tween.tween_property(sprite, "position", lunge_pos, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					attack_tween.tween_property(sprite, "position", base_sprite_pos, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			else:
				# Terminou todas as mordidas
				_return_to_patrol()

# --- Arena Dash: Atravessa o mapa inteiro ---
func _start_arena_dash():
	current_state = State.ARENA_DASH
	velocity = Vector2.ZERO
	arena_dash_active = false
	arena_dash_warning_timer = 0.6 # tempo de aviso antes do dash

	if not player:
		_return_to_patrol()
		return

	# Define a direção: dash na direção do jogador
	arena_dash_direction = sign(player.global_position.x - global_position.x)

	# Aviso visual: laranja pulsante
	if sprite:
		sprite.modulate = Color(1.0, 0.5, 0.0, 1.0)
		sprite.flip_h = arena_dash_direction > 0

	# Vibração lateral e tremer de preparação (sem jiggle/escala)
	if sprite:
		if attack_tween:
			attack_tween.kill()
		attack_tween = create_tween()
		sprite.position = base_sprite_pos
		for i in range(4):
			attack_tween.tween_property(sprite, "position", base_sprite_pos + Vector2(-6.0, 0), 0.07)
			attack_tween.tween_property(sprite, "position", base_sprite_pos + Vector2(6.0, 0), 0.07)
		attack_tween.tween_property(sprite, "position", base_sprite_pos, 0.07)

func _behavior_arena_dash(delta):
	if not arena_dash_active:
		# Fase de aviso: conta o timer
		arena_dash_warning_timer -= delta
		velocity.x = 0

		if arena_dash_warning_timer <= 0:
			# Inicia o dash real
			arena_dash_active = true
			velocity.x = arena_dash_direction * 650.0
			if sound_bite:
				sound_bite.play()
			velocity.y = 0
			if sprite:
				sprite.modulate = Color(1.0, 0.3, 0.0, 1.0) # laranja queimado durante o dash
	else:
		# Dash ativo: verifica colisão por proximidade com o jogador
		if player:
			var diff = player.global_position - global_position
			if abs(diff.x) < 32.0 and diff.y > -110.0 and diff.y < 15.0:
				if player.has_method("take_damage"):
					player.take_damage(3) # dano alto
				arena_dash_active = false
				_return_to_patrol()
				return

		# Verifica se o boss já saiu dos limites do ecrã visível (para ou ao chegar à parede)
		# Termina quando bate numa parede (colisão lateral) ou após 1.5s de limite de segurança
		skill_timer = max(skill_timer, 0.0) # usa skill_timer como fallback de segurança
		if get_slide_collision_count() > 0:
			for i in get_slide_collision_count():
				var col = get_slide_collision(i)
				# Se bate em algo que não é o jogador (parede/chão), termina o dash
				var c = col.get_collider()
				if c and not c.name.to_lower().contains("player"):
					arena_dash_active = false
					_return_to_patrol()
					return

		# Limite de segurança por distância percorrida
		if abs(global_position.x) > 600:
			arena_dash_active = false
			_return_to_patrol()

# --- Receber Dano ---
func take_damage(amount: int):
	if is_invincible:
		return
		
	if is_phase_2 and shield_active:
		# Imune a dano se o escudo estiver ativo
		_spawn_shield_sparks()
		return

	current_health -= amount
	_spawn_damage_number(amount)
	
	if sound_hurt:
		sound_hurt.play()
	if health_bar:
		health_bar.value = current_health

	# Ativa o tremor de impacto (hit shake) e recoil (tilt) na rotação
	hit_shake_intensity = 7.0
	hit_shake_timer = 0.18
	if player:
		# Inclina-se para trás, oposto à direção do jogador
		var hit_dir = sign(global_position.x - player.global_position.x)
		hit_tilt = hit_dir * 0.16
	else:
		hit_tilt = 0.16

	# Verificar transição para Fase 2 (a 50% da vida máxima, Fase 1 apenas)
	if not is_phase_2 and not phase2_triggered:
		if current_health <= max_health / 2:
			_start_phase_2_transition()
			return # Interrompe — a transição toma conta do resto
	
	# Verificar morte na Fase 2 (vida a zero depois do escudo ter sido partido)
	if is_phase_2 and current_health <= 0:
		_trigger_epic_death()
		return

	# Tremor de câmara no jogador ao acertar no boss
	if player and player.has_method("shake_camera"):
		player.shake_camera(3.5)

	# Feedback rápido de piscar a branco (Flash) ao sofrer dano
	if sprite:
		sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
		get_tree().create_timer(0.1).timeout.connect(func():
			if is_instance_valid(self) and sprite:
				# Restaura a cor correta dependendo do estado
				match current_state:
					State.PATROL: sprite.modulate = base_color
					State.BITE:   sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)
					State.SPIT:   sprite.modulate = Color(0.8, 0.5, 1.0, 1.0)
					State.RAIN:   sprite.modulate = Color(1.0, 0.8, 0.4, 1.0)
					State.FRENZY: sprite.modulate = Color(1.0, 0.1, 0.2, 1.0)
					State.ARENA_DASH: sprite.modulate = Color(1.0, 0.3, 0.0, 1.0)
					_:            sprite.modulate = base_color
		)

func _spawn_damage_number(amount: int):
	var dnum_scene = load("res://scenes/damage_number.tscn")
	if dnum_scene:
		var dnum = dnum_scene.instantiate()
		dnum.amount = amount
		dnum.color = Color.WHITE
		dnum.global_position = global_position + Vector2(randf_range(-20, 20), -60)
		get_parent().add_child(dnum)

func _trigger_epic_death():
	is_invincible = true
	current_state = State.PHASE2_TRANSITION # Pára a IA
	velocity = Vector2.ZERO
	
	# Câmara Lenta Épica
	Engine.time_scale = 0.2
	
	if player and player.has_method("shake_camera"):
		player.shake_camera(20.0)
	
	if sound_shield_break:
		sound_shield_break.pitch_scale = 0.6
		sound_shield_break.play()
	
	# Várias explosões ao longo de um curto tempo
	var tween = create_tween()
	tween.set_parallel(false)
	for i in range(5):
		tween.tween_callback(func():
			_spawn_death_particles()
			if sprite:
				sprite.modulate = Color(2.0, 0.2, 0.2, 1.0) # Flash Vermelho Forte
				sprite.position += Vector2(randf_range(-15, 15), randf_range(-15, 15))
		)
		tween.tween_interval(0.15)
		
	tween.tween_callback(func():
		Engine.time_scale = 1.0
		_spawn_death_particles(true) # Explosão Gigante Final
		boss_died.emit()
		queue_free()
	)

func _spawn_death_particles(is_huge: bool = false):
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		var count = 40 if is_huge else 12
		for i in range(count):
			var p = particles_scene.instantiate()
			p.global_position = global_position + Vector2(randf_range(-80, 80), randf_range(-120, 20))
			p.color = Color(0.6, 0.1, 0.9, 1.0) if not is_huge else Color(1.0, 0.9, 0.2, 1.0)
			get_parent().add_child(p)

func _animate_boss(delta):
	if not sprite:
		return
		
	anim_time += delta
	
	# 1. Processar tremor de impacto (Hit Shake)
	var shake_offset = Vector2.ZERO
	if hit_shake_timer > 0.0:
		hit_shake_timer -= delta
		shake_offset = Vector2(
			randf_range(-hit_shake_intensity, hit_shake_intensity),
			randf_range(-hit_shake_intensity, hit_shake_intensity)
		)
		hit_shake_intensity = move_toward(hit_shake_intensity, 0.0, delta * 35.0)
		hit_tilt = move_toward(hit_tilt, 0.0, delta * 0.9)
	else:
		hit_shake_intensity = 0.0
		hit_tilt = 0.0

	# 2. Atualizar posição do sprite (posição base + interpolação de tremor)
	if not attack_tween or not attack_tween.is_running():
		sprite.position = base_sprite_pos + shake_offset
	else:
		sprite.position += shake_offset

	# 3. Rotação e oscilação
	var current_target_rotation = 0.0
	if hit_shake_timer > 0.0:
		current_target_rotation = hit_tilt
	else:
		match current_state:
			State.PATROL:
				# Oscilação lateral muito subtil ao rastejar (sem jiggle de escala)
				var slither_freq = 12.0 if is_phase_2 else 8.0
				var slither_angle = 0.05 if is_phase_2 else 0.03
				current_target_rotation = sin(anim_time * slither_freq) * slither_angle
			State.ARENA_DASH:
				if arena_dash_active:
					# Inclina-se ligeiramente para a frente na direção do dash
					current_target_rotation = arena_dash_direction * 0.15
			_:
				current_target_rotation = 0.0
				
	# Ajusta rotação conforme a direção horizontal que está virado
	var rot_factor = -1.0 if sprite.flip_h else 1.0
	sprite.rotation = lerp(sprite.rotation, current_target_rotation * rot_factor, 10.0 * delta)

	# 4. Escala mantida perfeitamente fixa para evitar "jiggle physics" goofy
	sprite.scale = base_sprite_scale

	# 5. Sincroniza a BossHitbox com a posição e rotação do sprite
	if is_instance_valid(hitbox_area):
		hitbox_area.position = sprite.position
		hitbox_area.rotation = sprite.rotation

func _check_player_contact(delta):
	if not player or is_stunned or current_state == State.PHASE2_TRANSITION:
		return
		
	if contact_damage_timer > 0.0:
		contact_damage_timer -= delta
		
	var diff = player.global_position - global_position
	# Verifica colisão de sobreposição (caixa delimitadora aproximada 40x110)
	if abs(diff.x) < 28.0 and diff.y > -110.0 and diff.y < 15.0:
		if contact_damage_timer <= 0.0:
			if player.has_method("take_damage"):
				var dmg = 2 if is_phase_2 else 1
				player.take_damage(dmg)
				contact_damage_timer = CONTACT_DAMAGE_COOLDOWN

# --- Escudo e Atordoamento (Fase 2) ---

func _spawn_shield_sparks():
	if sound_shield_hit:
		sound_shield_hit.play()
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		var p = particles_scene.instantiate()
		p.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-70, -20))
		p.color = Color(0.8, 0.2, 1.0, 1.0) # Roxo brilhante do escudo
		get_parent().add_child(p)
	
	# Vibração de câmara ligeira
	if player and player.has_method("shake_camera"):
		player.shake_camera(1.0)

func break_shield():
	if not shield_active:
		return
	shield_active = false
	is_stunned = true
	if sound_shield_break:
		sound_shield_break.play()
	stun_timer = 4.0 # Atordoada por 4 segundos
	velocity = Vector2.ZERO
	
	# Cor dourada temporária de atordoamento
	if sprite:
		sprite.modulate = Color(1.5, 1.2, 0.4, 1.0)
		
	# Tremor forte no jogador
	if player and player.has_method("shake_camera"):
		player.shake_camera(6.0)
		
	# Explosão de faíscas douradas de quebra de escudo
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		for i in range(15):
			var p = particles_scene.instantiate()
			p.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-80, 0))
			p.color = Color(1.0, 0.9, 0.3, 1.0)
			get_parent().add_child(p)

func _recover_from_stun():
	is_stunned = false
	shield_active = true # Reativa o escudo protetor
	if sound_shield_recover:
		sound_shield_recover.play()
	if sprite:
		sprite.modulate = base_color
		
	# Informa o nível para redefinir os altares
	var level = get_parent()
	if level and level.has_method("reset_solar_altars"):
		level.reset_solar_altars()

func _draw():
	if is_phase_2 and shield_active:
		# Desenha escudo esférico brilhante à volta do boss
		var pulse = 1.0 + sin(anim_time * 6.5) * 0.05
		var shield_color = Color(0.6, 0.1, 0.9, 0.16) # Roxo translúcido
		var outline_color = Color(0.85, 0.2, 1.0, 0.72) # Roxo vibrante de contorno
		
		# O escudo segue a posição dinâmica do sprite
		var center_pos = sprite.position
		var radius = 72.0 * pulse
		draw_circle(center_pos, radius, shield_color)
		draw_arc(center_pos, radius, 0.0, PI * 2, 32, outline_color, 2.0)
