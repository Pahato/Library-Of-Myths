extends Area2D

var damage_timer: float = 0.0
const DAMAGE_COOLDOWN: float = 1.5
var active: bool = false
var target_y: float = 6.0 # Cobre o chão plano, deixando plataformas e ruínas limpas
var current_y: float = 80.0 # inicia abaixo da tela visível
var rise_speed: float = 35.0
var anim_time: float = 0.0

func _ready():
	# Configurar colisão programática: detecta apenas o jogador (Layer 2)
	collision_layer = 0
	collision_mask = 2

	# Configurar colisor horizontal gigante programaticamente
	var col_shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(1200, 40)
	col_shape.shape = box
	col_shape.position = Vector2(0, 30) # colisor fica ligeiramente abaixo do topo do fluido
	add_child(col_shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Posição inicial no eixo Y (bem escondido)
	global_position = Vector2(0, current_y)
	hide()

func start_rising():
	active = true
	show()

func reset_floor():
	active = false
	current_y = 80.0
	global_position = Vector2(0, current_y)
	hide()

func _process(delta):
	if not active:
		return
		
	anim_time += delta
	
	# Faz subir gradualmente o ácido até ao Y alvo
	if current_y > target_y:
		current_y = max(target_y, current_y - rise_speed * delta)
		global_position.y = current_y
		
	# Gestão de temporizador de dano
	if damage_timer > 0.0:
		damage_timer -= delta
		
	# Verifica se o jogador está a tocar no veneno e aplica dano
	for body in get_overlapping_bodies():
		if body.name.to_lower().contains("player") and damage_timer <= 0.0:
			if body.has_method("take_damage"):
				body.take_damage(1)
				damage_timer = DAMAGE_COOLDOWN
				
	queue_redraw()

func _on_body_entered(body):
	if body.name.to_lower().contains("player") and damage_timer <= 0.0:
		if body.has_method("take_damage"):
			body.take_damage(1)
			damage_timer = DAMAGE_COOLDOWN

func _on_body_exited(_body):
	pass

func _draw():
	# 1. Desenha o fluído venenoso (verde ácido translúcido)
	var acid_color = Color(0.12, 0.60, 0.22, 0.42)
	# Retângulo cobrindo a largura da arena e estendendo-se para baixo
	draw_rect(Rect2(-600, 0, 1200, 180), acid_color)
	
	# 2. Desenha a linha de ondulação de superfície do ácido
	var wave_color = Color(0.25, 0.85, 0.32, 0.75)
	var num_points = 50
	var total_width = 1200.0
	var wave_points = PackedVector2Array()
	
	for i in range(num_points + 1):
		var px = -600.0 + (i * (total_width / num_points))
		# Composição de ondas de seno/coseno para aspeto dinâmico orgânico
		var py = sin(px * 0.045 + anim_time * 3.5) * 3.5 + cos(px * 0.015 + anim_time * 1.8) * 1.5
		wave_points.append(Vector2(px, py))
		
	# Desenha os segmentos de linha da onda
	for i in range(num_points):
		draw_line(wave_points[i], wave_points[i+1], wave_color, 2.0)
		
	# 3. Desenha pequenas bolhas ácidas a subir e rebentar
	var bubble_color = Color(0.3, 0.9, 0.4, 0.5)
	for i in range(8):
		# Posições pseudo-aleatórias baseadas no tempo
		var seed_val = i * 175.4
		var bx = -500.0 + fmod(seed_val * 9.87 + anim_time * 12.0, 1000.0)
		var by = 10.0 + fmod(seed_val * 3.12 - anim_time * 25.0, 80.0)
		var radius = 2.0 + fmod(seed_val * 1.23, 3.0)
		draw_circle(Vector2(bx, by), radius, bubble_color)
