extends CharacterBody2D
class_name ApoloPlayer

# --- Sinais ---
signal health_changed(new_health)
signal player_died

# --- Modos de Deus ---
enum GodMode {
	NORMAL,
	APOLLO,
	THOR
}

@export var current_god_mode: GodMode = GodMode.APOLLO
@export var arrow_scene: PackedScene = preload("res://scenes/apolo_python/arrow.tscn")
@export var dialogue_scene: PackedScene = preload("res://scenes/dialogue_box.tscn")
@export var game_ui_scene: PackedScene = preload("res://scenes/game_ui.tscn")
@export var pause_menu_scene: PackedScene = preload("res://scenes/pause_menu.tscn")
@export var shoot_cooldown: float = 0.4

# --- Atributos do Jogador ---
@export var max_health: int = 6
var current_health: int = 6

# --- Configurações de Controlos (Input Map / Teclado Fallback) ---
const INPUT_LEFT = "move_left"
const INPUT_RIGHT = "move_right"
const INPUT_JUMP = "jump"
const INPUT_PARRY = "parry"
const INPUT_SHOOT = "shoot"

# --- Variáveis de movimento ---
const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const GRAVITY = 1000.0

# --- Parry ---
var is_parrying: bool = false
var parry_window_timer: float = 0.0
const PARRY_WINDOW_DURATION: float = 0.08 # Janela extremamente curta (80 milissegundos / ~5 frames)

var shoot_cooldown_timer = 0.0
var solar_powerup_timer = 0.0
var max_arrows: int = 8
var current_arrows: int = 8
var ammo_recharge_timer: float = 0.0
const AMMO_RECHARGE_TIME: float = 0.5
var ammo_delay_timer: float = 0.0
const AMMO_DELAY_TIME: float = 0.8

# --- Invencibilidade (iframes desativados após dano) ---
var is_invincible: bool = false
var iframe_duration: float = 1.0
var iframe_blink_timer: float = 0.0

# --- Solar Dash (Novo para Apolo) ---
const DASH_SPEED = 320.0
const DASH_DURATION = 0.28
const DASH_COOLDOWN = 3.0
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_dir = Vector2.ZERO
var is_dashing = false

# --- Pausa ---
var pause_menu_instance = null

# --- Câmara (Look-ahead e Shake) ---
var camera: Camera2D = null
var shake_intensity: float = 0.0
var shake_decay: float = 12.0 # Velocidade com que o tremor acalma
const CAMERA_SMOOTH_SPEED = 4.0

var camera_zoom_target: float = 2.8
var camera_offset_target: Vector2 = Vector2.ZERO

# --- Polimento de Salto (Coyote Time & Jump Buffer) ---
const COYOTE_DURATION = 0.15
const JUMP_BUFFER_DURATION = 0.12

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var is_cutscene: bool = true
var was_on_floor: bool = false

var sound_shoot: AudioStreamPlayer
var sound_clink: AudioStreamPlayer
var sound_hurt: AudioStreamPlayer
var sound_jump: AudioStreamPlayer

# --- Referências ---
@onready var sprite = $AnimatedSprite2D

func _ready():
	# Camadas de colisão programáticas: Layer 2 (Players = 2), Mask 1 (World = 1)
	collision_layer = 2
	collision_mask = 1

	# Lê vida máxima da dificuldade global
	max_health = GameGlobals.get_player_max_health()
	current_health = max_health
	# Atualiza a UI com a vida inicial
	health_changed.emit(current_health)
	if sprite:
		sprite.play("Idle")
	sprite.animation_finished.connect(_on_animation_finished)
	# Animações do pato rodam mesmo com o jogo pausado
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup programático da ação "dash" caso não esteja no InputMap
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
		var ev_key = InputEventKey.new()
		ev_key.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("dash", ev_key)
		var ev_joy = InputEventJoypadButton.new()
		ev_joy.button_index = JOY_BUTTON_B
		InputMap.action_add_event("dash", ev_joy)
	
	camera = get_node_or_null("Camera2D")
	if camera and not is_cutscene:
		camera.limit_bottom = 55
	
	# Instanciar a UI do jogo automaticamente (apenas na fase de jogo, não no menu principal)
	if not is_cutscene:
		instantiate_ui()
		
	# Configurar Efeitos Sonoros
	sound_shoot = AudioStreamPlayer.new()
	sound_shoot.stream = load("res://assets/sounds/shoot.wav")
	sound_shoot.volume_db = -6.0
	sound_shoot.bus = "SFX"
	add_child(sound_shoot)
	
	sound_clink = AudioStreamPlayer.new()
	sound_clink.stream = load("res://assets/sounds/clink.wav")
	sound_clink.volume_db = -4.0
	sound_clink.bus = "SFX"
	add_child(sound_clink)

	sound_hurt = AudioStreamPlayer.new()
	sound_hurt.stream = load("res://assets/sounds/hurt.wav")
	sound_hurt.volume_db = -3.0
	sound_hurt.bus = "SFX"
	add_child(sound_hurt)

	sound_jump = AudioStreamPlayer.new()
	sound_jump.stream = load("res://assets/sounds/jump.wav")
	sound_jump.volume_db = -8.0
	sound_jump.bus = "SFX"
	add_child(sound_jump)

func instantiate_ui():
	var parent = get_parent()
	if not parent:
		return
	# Não instanciar a UI se a fase estiver numa cutscene ativa (ex: introdução no céu)
	if "cutscene_active" in parent and parent.cutscene_active:
		return
		
	# Instanciar a UI geral de corações/fim de jogo
	if game_ui_scene:
		var ui = game_ui_scene.instantiate()
		parent.call_deferred("add_child", ui)


func _on_animation_finished():
	pass

func _physics_process(delta):
	# Ajusta a velocidade da animação: Idle mais lenta e relaxada (60%), outras normal (100%)
	if sprite:
		if sprite.animation == "Idle":
			sprite.speed_scale = 0.6
		else:
			sprite.speed_scale = 1.0

	if is_cutscene:
		# Durante a cutscene, apenas atualizamos a câmara
		_process_camera(delta)
		return
		
	# Gerir timers do Solar Dash
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			_end_dash()
	
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if is_dashing:
		# Ignora a gravidade e movimento normal, avança na direção do dash
		velocity = dash_dir * DASH_SPEED
		_spawn_dash_particles()
	else:
		_handle_gravity(delta)
		
		# Verifica aterragem (Squash and Stretch)
		var currently_on_floor = is_on_floor()
		if currently_on_floor and not was_on_floor and velocity.y >= 0:
			# Acabou de aterrar
			if sprite:
				var tween = create_tween()
				tween.tween_property(sprite, "scale", Vector2(1.4, 0.6), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_spawn_dust_particles()
		was_on_floor = currently_on_floor
		
		# Gerir Coyote Time & Jump Buffer
		if coyote_timer > 0:
			coyote_timer -= delta
		if jump_buffer_timer > 0:
			jump_buffer_timer -= delta
			
		if is_on_floor():
			coyote_timer = COYOTE_DURATION
		
		_handle_movement()
		_handle_jump()

	if shoot_cooldown_timer > 0:
		shoot_cooldown_timer -= delta
		
	# Power-up Solar (Tiro Triplo)
	if solar_powerup_timer > 0.0:
		solar_powerup_timer -= delta

	# Recarga de munição (flechas)
	if ammo_delay_timer > 0.0:
		ammo_delay_timer -= delta
	else:
		if current_arrows < max_arrows:
			ammo_recharge_timer += delta
			if ammo_recharge_timer >= AMMO_RECHARGE_TIME:
				current_arrows += 1
				ammo_recharge_timer = 0.0
	
	_handle_parry(delta)
	
	# Habilidades específicas por Deus
	if current_god_mode == GodMode.APOLLO:
		_handle_shooting()
		_handle_dash()
	
	_update_animation()
	move_and_slide()
	
	# Atualiza tremor e movimento suave da câmara
	_process_camera(delta)

func _input(event):
	# ESC abre/fecha o menu de pausa (só funciona in-game, não no menu principal/cutscene)
	if event.is_action_pressed("ui_cancel") and not get_tree().paused and not is_cutscene:
		_toggle_pause()
		
	# Regista intenção de saltar (Jump Buffer)
	var is_jump_input = InputMap.has_action(INPUT_JUMP) and event.is_action_pressed(INPUT_JUMP)
	if is_jump_input:
		if not get_tree().paused:
			jump_buffer_timer = JUMP_BUFFER_DURATION

func _toggle_pause():
	if is_instance_valid(pause_menu_instance):
		return # Já está aberto
	get_tree().paused = true
	pause_menu_instance = pause_menu_scene.instantiate()
	# Quando fechar o pause, limpa a referência
	pause_menu_instance.tree_exited.connect(func(): pause_menu_instance = null)
	get_parent().add_child(pause_menu_instance)

func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _handle_movement():
	var direction = 0
	if InputMap.has_action(INPUT_LEFT) and Input.is_action_pressed(INPUT_LEFT):
		direction -= 1
	if InputMap.has_action(INPUT_RIGHT) and Input.is_action_pressed(INPUT_RIGHT):
		direction += 1
	
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func _handle_jump():
	# Se o buffer de salto e o coyote time estiverem ativos, salta
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		# Consome os buffers para não repetir o salto
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		if sound_jump:
			sound_jump.pitch_scale = randf_range(0.9, 1.1)
			sound_jump.play()
			
		# Squash and Stretch no salto
		if sprite:
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2(0.7, 1.4), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_spawn_dust_particles()

func _handle_parry(delta):
	# Diminui o temporizador da janela de parry
	if parry_window_timer > 0.0:
		parry_window_timer -= delta
		if parry_window_timer <= 0.0:
			is_parrying = false
			if sprite:
				sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
				
	# Ativa o parry ao pressionar o botão (apenas com is_action_just_pressed para evitar segurar)
	var wants_parry = InputMap.has_action(INPUT_PARRY) and Input.is_action_just_pressed(INPUT_PARRY)
	if wants_parry and not is_parrying:
		is_parrying = true
		parry_window_timer = PARRY_WINDOW_DURATION
		# Feedback visual de postura de defesa: tom dourado solar brilhante
		if sprite:
			sprite.modulate = Color(1.8, 1.5, 0.4, 1.0)
			# Pequeno tremor ao entrar na guarda
			shake_camera(0.8)

func _handle_shooting():
	# "shoot" já inclui: clique esquerdo do rato, tecla J, e botão X do comando (via GameGlobals)
	var wants_shoot = InputMap.has_action(INPUT_SHOOT) and Input.is_action_just_pressed(INPUT_SHOOT)
	if wants_shoot and shoot_cooldown_timer <= 0:
		if current_arrows > 0:
			shoot_cooldown_timer = shoot_cooldown
			current_arrows -= 1
			ammo_delay_timer = AMMO_DELAY_TIME
			_shoot_arrow()
		else:
			# Pequena vibração da câmara por falta de munição
			shake_camera(0.6)


func _shoot_arrow():
	if not arrow_scene:
		return
		
	if sound_shoot:
		sound_shoot.pitch_scale = randf_range(0.85, 1.15)
		sound_shoot.play()
	
	# Calcula a direção em coordenadas do mundo a partir da posição do rato no ecrã
	var mouse_world_pos: Vector2
	if camera:
		mouse_world_pos = get_global_mouse_position()
	else:
		# Fallback: dispara na direção do sprite
		var dir_fallback = -1 if sprite.flip_h else 1
		mouse_world_pos = global_position + Vector2(dir_fallback * 100, 0)
	
	var shoot_dir = (mouse_world_pos - global_position).normalized()
	
	# Vira o sprite para o lado do rato
	sprite.flip_h = mouse_world_pos.x < global_position.x
	
	if solar_powerup_timer > 0.0:
		# Disparo Solar: 3 flechas em leque
		var angles = [-0.15, 0.0, 0.15]
		for angle in angles:
			var arrow = arrow_scene.instantiate()
			arrow.global_position = global_position
			var rotated_dir = shoot_dir.rotated(angle)
			arrow.direction = rotated_dir
			arrow.rotation = rotated_dir.angle()
			
			# Modula a flecha com um tom dourado extra brilhante
			arrow.modulate = Color(1.5, 1.2, 0.3)
			get_parent().add_child(arrow)
		
		# Tremor ligeiramente superior pelo disparo triplo
		shake_camera(2.2)
	else:
		# Disparo normal
		var arrow = arrow_scene.instantiate()
		arrow.global_position = global_position
		arrow.direction = shoot_dir
		arrow.rotation = shoot_dir.angle()
		get_parent().add_child(arrow)
		
		# Tremor subtil ao disparar flechas
		shake_camera(1.5)

func _handle_dash():
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		_start_dash()

func _start_dash():
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	is_invincible = true
	
	# Determinar direção
	var move_dir = 0
	if InputMap.has_action(INPUT_LEFT) and Input.is_action_pressed(INPUT_LEFT):
		move_dir -= 1
	if InputMap.has_action(INPUT_RIGHT) and Input.is_action_pressed(INPUT_RIGHT):
		move_dir += 1
		
	if move_dir == 0:
		dash_dir = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	else:
		dash_dir = Vector2(move_dir, 0).normalized()
		sprite.flip_h = move_dir < 0
		
	# Tocar som de vento de luz (sopro solar) reusando sound_shoot acelerado
	if sound_shoot:
		var sound_dash = AudioStreamPlayer.new()
		sound_dash.stream = sound_shoot.stream
		sound_dash.volume_db = -2.0
		sound_dash.pitch_scale = 1.95
		sound_dash.bus = "SFX"
		add_child(sound_dash)
		sound_dash.play()
		sound_dash.finished.connect(func(): sound_dash.queue_free())
		
	# Feedback visual: pisca em dourado/amarelo ultra brilhante
	if sprite:
		sprite.modulate = Color(2.5, 2.0, 0.4, 0.9)
		
	# Vibração subtil da câmara no arranque do dash
	shake_camera(2.0)

func _hit_stop(time_scale_val: float, duration: float):
	Engine.time_scale = time_scale_val
	get_tree().create_timer(duration * time_scale_val).timeout.connect(func():
		Engine.time_scale = 1.0
	)

func _spawn_damage_number(amount: int, col: Color):
	var dnum_scene = load("res://scenes/damage_number.tscn")
	if dnum_scene:
		var dnum = dnum_scene.instantiate()
		dnum.amount = amount
		dnum.color = col
		dnum.global_position = global_position + Vector2(randf_range(-15, 15), -40)
		get_parent().add_child(dnum)

func _spawn_dust_particles():
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		# Emite várias partículas para criar uma nuvem
		for i in range(5):
			var p = particles_scene.instantiate()
			p.global_position = global_position + Vector2(randf_range(-8, 8), 12)
			p.color = Color(0.8, 0.8, 0.8, 0.6) # Poeira
			get_parent().add_child(p)

func _end_dash():
	is_dashing = false
	is_invincible = false
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _spawn_dash_particles():
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		var p = particles_scene.instantiate()
		p.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-20, 5))
		p.color = Color(1.0, 0.85, 0.2, 0.75) # Amarelo/dourado brilhante solar
		get_parent().add_child(p)

func take_damage(amount: int):
	# Ignora dano se estiver invencível (por exemplo, logo após um parry bem-sucedido ou pós-dano)
	if is_invincible:
		return

	# Se estiver na janela de Parry bem sucedida, anula o dano e faz o parry
	if is_parrying:
		_trigger_successful_parry()
		return
		
	current_health -= amount
	_spawn_damage_number(amount, Color(1.0, 0.2, 0.2)) # Vermelho para o player
	health_changed.emit(current_health)
	print("Jogador recebeu dano! Vida atual: ", current_health)
	if sound_hurt:
		sound_hurt.play()
	
	# Tremor forte ao receber dano
	shake_camera(7.0)
	
	# Hit Stop épico ao levar dano
	_hit_stop(0.05, 0.1)
	
	# Ativar frames de invencibilidade temporários pós-dano (600ms)
	is_invincible = true
	get_tree().create_timer(0.6).timeout.connect(func():
		# Só remove invencibilidade se não estiver no meio de um dash ativo
		if is_instance_valid(self) and not is_dashing:
			is_invincible = false
	)
	
	# Feedback de piscar (vermelho de impacto, depois intermitente translúcido)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.08)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)
		# Pisca-pisca de invencibilidade
		for i in range(4):
			tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.4), 0.06)
			tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.06)
		
	if current_health <= 0:
		print("Jogador morreu!")
		player_died.emit()

func _trigger_successful_parry():
	# 1. Faz vibrar a câmara
	shake_camera(4.5)
	
	# Hit Stop épico do Parry
	_hit_stop(0.02, 0.15)
	
	# 2. Desativa o parry de imediato (o timing foi bem sucedido, termina a janela)
	is_parrying = false
	parry_window_timer = 0.0
	
	if sound_clink:
		sound_clink.play()
	
	# 3. Dá 0.15 segundos de imunidade absoluta pós-parry para prevenir dano por múltiplos perigos sobrepostos
	is_invincible = true
	get_tree().create_timer(0.15).timeout.connect(func():
		is_invincible = false
	)
	
	# 4. Pisca o jogador em dourado intenso brilhante
	if sprite:
		sprite.modulate = Color(2.5, 2.2, 0.5, 1.0)
		# Restaura a cor normal após um curto intervalo
		get_tree().create_timer(0.12).timeout.connect(func():
			if is_instance_valid(self) and sprite:
				sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		)
		
	# 5. Spawna partículas de parry douradas
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		for i in range(12):
			var p = particles_scene.instantiate()
			p.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-25, 5))
			p.color = Color(1.0, 0.9, 0.3, 1.0)
			get_parent().add_child(p)
			
	# 6. Spawna uma etiqueta flutuante bonita "PARRY!" por cima de Apolo
	var label = Label.new()
	label.text = "PARRY!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position = position + Vector2(-30, -38)
	get_parent().add_child(label)
	
	# Animação de subida e fade-out para a etiqueta
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 18.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): label.queue_free())

func _update_animation():
	if not is_on_floor():
		# Usa animação de salto se existir, caso contrário usa Idle
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("Jump"):
			sprite.play("Jump")
		else:
			sprite.play("Idle")
	elif velocity.x != 0:
		sprite.play("Run")
	else:
		sprite.play("Idle")

# --- Funções Auxiliares da Câmara ---
func shake_camera(intensity: float):
	shake_intensity = max(shake_intensity, intensity)

func _process_camera(delta):
	if not camera:
		return
		
	# 1) Zoom da câmara suave
	var target_zoom_vec = Vector2(camera_zoom_target, camera_zoom_target)
	camera.zoom = camera.zoom.lerp(target_zoom_vec, 3.0 * delta)
		
	# 2) Deslocamento da Câmara (Look-ahead + Offset Customizado) com interpolação suave
	var look_direction = -1.0 if sprite.flip_h else 1.0
	var base_target_x = 4.0 + (look_direction * 5.0)
	
	var target_pos = Vector2(base_target_x, 13.0) + camera_offset_target
	camera.position = camera.position.lerp(target_pos, CAMERA_SMOOTH_SPEED * delta)
	
	# 3) Tremor de Câmara (Camera Shake) com decaimento exponencial
	if shake_intensity > 0.0:
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO
