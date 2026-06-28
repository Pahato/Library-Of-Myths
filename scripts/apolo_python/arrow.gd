extends Area2D

@export var speed: float = 500.0
@export var damage: int = 1
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT

func _ready():
	# Scan Layer 1 (World) e Layer 4 (Enemies = 8) -> 1 + 8 = 9
	collision_mask = 9
	# Define o tempo de vida máximo da flecha para não flutuar para sempre
	get_tree().create_timer(lifetime).timeout.connect(func(): if is_instance_valid(self): queue_free())
	# Conecta os sinais de colisão
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	# Move a flecha na direção definida
	position += direction * speed * delta

func _on_body_entered(body):
	# Ignora colisões com o próprio jogador, outras flechas, ou o corpo físico da Python (que usa hitbox dedicada)
	if body.name.to_lower().contains("player") or body.name.to_lower().contains("arrow") or body.name.to_lower().contains("python") or body.has_node("BossHitbox"):
		return
		
	# Aplica dano se o objeto atingido tiver a função de receber dano (ex: inimigos)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_spawn_particles()
		queue_free()
		return
		
	# Colisão com o cenário (chão/paredes)
	_spawn_particles()
	queue_free()

func _on_area_entered(area):
	# Ignora colisões com o próprio jogador ou outras flechas/projéteis do jogador
	if area.name.to_lower().contains("player") or area.name.to_lower().contains("arrow"):
		return
		
	# Deteta a hitbox do boss
	if area.name.to_lower().contains("hitbox") or area.get_parent().has_method("take_damage"):
		var target = area.get_parent() if area.get_parent().has_method("take_damage") else area
		if target.has_method("take_damage"):
			target.take_damage(damage)
			_spawn_particles()
			queue_free()

func _spawn_particles():
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		var p = particles_scene.instantiate()
		p.global_position = global_position
		p.color = Color(1.0, 0.9, 0.4, 1.0) # Amarelo Dourado
		get_parent().add_child(p)

