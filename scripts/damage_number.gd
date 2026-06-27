extends Node2D

var amount: int = 0
var color: Color = Color.WHITE

@onready var label = $Label

func _ready():
	label.text = str(-amount) if amount > 0 else "MISS"
	label.modulate = color
	
	# Animação estilo RPG (sobe rapidamente e desvanece)
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Subida com arco aleatório
	var random_x = randf_range(-20, 20)
	tween.tween_property(self, "position", position + Vector2(random_x, -45), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Escala inicial grande (PUMP) e volta ao normal
	scale = Vector2(1.5, 1.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Desvanecimento na segunda metade da animação
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.2)
	
	# Autodestrói quando acabar
	tween.chain().tween_callback(queue_free)
