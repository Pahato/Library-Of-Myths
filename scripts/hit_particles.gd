extends CPUParticles2D

func _ready():
	# Começa a emitir as partículas imediatamente
	emitting = true
	# Destrói o nó automaticamente quando a emissão terminar
	finished.connect(queue_free)
