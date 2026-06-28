extends Area2D

signal altar_activated

var is_charging: bool = false
var charge_amount: float = 0.0
const CHARGE_TIME: float = 1.0 # 1 segundo para carregar completamente
var is_active: bool = false
var anim_time: float = 0.0

# Fase 2: só pode ser ativado quando o boss estiver na Fase 2
var phase2_only: bool = false
var boss_ref: Node = null # Referência ao boss para verificar a fase

var _is_locked: bool = true # Bloqueado até à Fase 2 (se phase2_only = true)

func _ready():
	# Configurar colisão programática: detecta apenas o jogador (Layer 2)
	collision_layer = 0
	collision_mask = 2

	# Criar colisor programaticamente para facilidade de instanciacão
	var col_shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(30, 32)
	col_shape.shape = box
	col_shape.position = Vector2(0, -8)
	add_child(col_shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Cor inicial (cinzento desativado)
	modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	# Z-index para ficar visível acima do fundo
	z_index = -5

func _process(delta):
	anim_time += delta
	
	if is_active:
		queue_redraw()
		return
		
	if is_charging:
		charge_amount += delta
		# Transição suave para dourado solar
		modulate = Color(0.5, 0.5, 0.5).lerp(Color(1.3, 1.1, 0.4), charge_amount / CHARGE_TIME)
		
		if charge_amount >= CHARGE_TIME:
			_activate_altar()
	else:
		if charge_amount > 0:
			charge_amount = max(0.0, charge_amount - delta * 1.5)
			modulate = Color(0.5, 0.5, 0.5).lerp(Color(1.3, 1.1, 0.4), charge_amount / CHARGE_TIME)

	queue_redraw()

func _on_body_entered(body):
	if is_active:
		return
	# Se só ativo na Fase 2, verificar se o boss já entrou nela
	if phase2_only:
		if not is_instance_valid(boss_ref) or not boss_ref.is_phase_2:
			return
		_is_locked = false
	if body.name.to_lower().contains("player"):
		is_charging = true

func _on_body_exited(body):
	if body.name.to_lower().contains("player"):
		is_charging = false

func _activate_altar():
	is_active = true
	is_charging = false
	modulate = Color(1.5, 1.2, 0.4, 1.0) # Dourado brilhante ativo
	altar_activated.emit()
	_spawn_activation_particles()

func reset_altar():
	is_active = false
	is_charging = false
	charge_amount = 0.0
	modulate = Color(0.5, 0.5, 0.5, 1.0)
	queue_redraw()

func _spawn_activation_particles():
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		for i in range(10):
			var p = particles_scene.instantiate()
			# Dispersa à volta do altar
			p.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-16, 4))
			p.color = Color(1.0, 0.9, 0.3, 1.0)
			get_parent().add_child(p)

func _draw():
	# Verificar estado de bloqueio
	var locked = phase2_only and (not is_instance_valid(boss_ref) or not boss_ref.is_phase_2) and not is_active
	
	# 1. Desenha a base de pilar grego
	var stone_color: Color
	if locked:
		stone_color = Color(0.35, 0.35, 0.5) # Azul-acinzentado quando bloqueado
	elif is_active:
		stone_color = Color(0.9, 0.8, 0.5)  # Dourado quando ativo
	else:
		stone_color = Color(0.65, 0.65, 0.65) # Cinzento normal
	
	# Pedestal de base
	draw_rect(Rect2(-12, 4, 24, 4), stone_color)
	# Corpo do pilar
	draw_rect(Rect2(-8, -4, 16, 8), stone_color)
	# Capitel do topo
	draw_rect(Rect2(-10, -8, 20, 4), stone_color)
	
	# 2. Desenha o sol flutuante no topo do altar
	var sun_color = Color(1.3, 1.1, 0.4, 1.0) if is_active else Color(0.4, 0.5, 0.6, 0.8)
	var sun_center = Vector2(0, -22)
	
	# Círculo central do sol
	draw_circle(sun_center, 5.0, sun_color)
	
	# Raios solares em rotação
	var num_rays = 8
	var ray_length = 11.0
	var ray_start = 7.0
	var rotation_offset = anim_time * 1.8 if is_active else anim_time * 0.4
	
	for i in range(num_rays):
		var angle = (i * (PI * 2 / num_rays)) + rotation_offset
		var dir = Vector2(cos(angle), sin(angle))
		var p1 = sun_center + dir * ray_start
		var p2 = sun_center + dir * ray_length
		draw_line(p1, p2, sun_color, 1.5)
		
	# 3. Desenha barra de progresso se estiver a carregar
	if is_charging and charge_amount < CHARGE_TIME:
		var bar_width = 24.0
		var bar_height = 3.0
		var bar_y = -36.0
		# Fundo da barra (preto)
		draw_rect(Rect2(-bar_width/2, bar_y, bar_width, bar_height), Color.BLACK)
		# Preenchimento da barra (laranja/amarelo)
		var fill_width = bar_width * (charge_amount / CHARGE_TIME)
		draw_rect(Rect2(-bar_width/2, bar_y, fill_width, bar_height), Color(1.0, 0.8, 0.2))
