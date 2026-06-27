extends Area2D

var speed: float = 240.0
var rotation_speed: float = 0.0
var damage: int = 1
var size: float = 8.0

func _ready():
	# Configurar colisão programática: detecta o cenário (Layer 1) e o jogador (Layer 2) -> 1 + 2 = 3
	collision_layer = 0
	collision_mask = 3

	rotation_speed = randf_range(-3.5, 3.5)
	size = randf_range(6.0, 10.0)
	
	# Configurar colisor programaticamente com base no tamanho aleatório da pedra
	var col_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = size
	col_shape.shape = circle
	add_child(col_shape)
	
	body_entered.connect(_on_body_entered)
	
	# Cor de pedra acinzentada
	modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	# Z-index intermédio
	z_index = 0

func _physics_process(delta):
	# Queda vertical rápida
	position.y += speed * delta
	rotation += rotation_speed * delta
	
	# Destruir se cair fora dos limites do ecrã visível
	if position.y > 160.0:
		queue_free()

func _on_body_entered(body):
	# Ignora projéteis, inimigos ou o boss
	if body.name.to_lower().contains("boss") or body.name.to_lower().contains("python") or body.name.to_lower().contains("arrow") or body.name.to_lower().contains("projectile"):
		return
		
	if body.name.to_lower().contains("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_particles()
		queue_free()
	elif body.name.to_lower().contains("tilemap") or body.is_in_group("platforms") or body.name.to_lower().contains("floor") or body.name.to_lower().contains("ruins"):
		_spawn_particles()
		queue_free()

func _spawn_particles():
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		var p = particles_scene.instantiate()
		p.global_position = global_position
		p.color = Color(0.5, 0.5, 0.5, 1.0) # Partículas cinzentas de pedra partida
		get_parent().add_child(p)

func _draw():
	# Desenhar uma forma de pedra hexagonal irregular
	var points = PackedVector2Array()
	var num_sides = 6
	for i in range(num_sides):
		var angle = i * (PI * 2 / num_sides)
		var dist = size + randf_range(-1.2, 1.2)
		points.append(Vector2(cos(angle), sin(angle)) * dist)
		
	# Desenha preenchimento
	draw_colored_polygon(points, Color(0.38, 0.38, 0.38))
	
	# Desenha contorno escuro
	var outline_color = Color(0.2, 0.2, 0.2)
	for i in range(num_sides):
		draw_line(points[i], points[(i+1) % num_sides], outline_color, 1.2)
