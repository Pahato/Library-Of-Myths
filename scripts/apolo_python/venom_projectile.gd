extends Area2D

@export var speed: float = 250.0
@export var damage: int = 1
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.ZERO

func _ready():
	# Configurar colisão programática: detecta APENAS o jogador (Layer 2)
	# O veneno atravessa plataformas e o chão sem ser destruído instantaneamente
	collision_layer = 0
	collision_mask = 2

	# Destrói automaticamente após um tempo se não colidir com nada
	get_tree().create_timer(lifetime).timeout.connect(func(): if is_instance_valid(self): queue_free())
	# Liga o sinal de colisão
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Move o projétil na direção especificada
	position += direction * speed * delta
	
	# Destrói o projétil se sair dos limites da arena de jogo para evitar vazamento de memória
	if abs(position.x) > 600.0 or position.y > 150.0 or position.y < -420.0:
		queue_free()

func _on_body_entered(body):
	# Aplica dano se atingir o jogador (só deteta o jogador devido à collision_mask = 2)
	if body.name.to_lower().contains("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_particles()
		queue_free()

func _spawn_particles():
	var particles_scene = load("res://scenes/hit_particles.tscn")
	if particles_scene:
		var p = particles_scene.instantiate()
		p.global_position = global_position
		p.color = Color(0.6, 0.1, 0.8, 1.0) # Roxo Veneno
		get_parent().add_child(p)


