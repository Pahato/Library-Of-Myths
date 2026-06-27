extends CanvasLayer

# Transição suave entre cenas
# Uso: SceneTransition.fade_to("res://scenes/nome.tscn")

var overlay: ColorRect
var _is_transitioning: bool = false

func _ready():
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Cria o overlay transparente — a primeira cena fica visível de imediato
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)  # Começa TRANSPARENTE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	# Não há fade-in no arranque — o menu aparece diretamente

func fade_to(scene_path: String):
	# Ignora chamadas duplas durante uma transição
	if _is_transitioning:
		return
	_is_transitioning = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# 1) Escurece → 2) Muda de cena → 3) Revela
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(scene_path)
		_do_fade_in()
	)

func _do_fade_in():
	# Garante que o overlay está preto antes de revelar a nova cena
	overlay.color = Color(0, 0, 0, 1)
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		_is_transitioning = false
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
