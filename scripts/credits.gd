extends Control
class_name Credits

@onready var back_button = $VBoxContainer/BackButton

# Lista de linhas de créditos (podes editar à vontade)
var credits_lines: Array = [
	{"label": "credits_title", "size": 22, "color": Color(0.96, 0.87, 0.7, 1.0)},
	{"label": "", "size": 14, "color": Color(1,1,1,1)},
	{"label": "credits_dev", "size": 14, "color": Color(0.7, 0.85, 1.0, 1.0)},
	{"label": "Rodrigo Pereira", "size": 18, "color": Color(1, 1, 1, 1)},
	{"label": "", "size": 14, "color": Color(1,1,1,1)},
	{"label": "credits_art", "size": 14, "color": Color(0.7, 0.85, 1.0, 1.0)},
	{"label": "Rodrigo Pereira e Inteligência Artificial", "size": 18, "color": Color(1, 1, 1, 1)},
	{"label": "", "size": 14, "color": Color(1,1,1,1)},
	{"label": "credits_engine", "size": 14, "color": Color(0.7, 0.85, 1.0, 1.0)},
	{"label": "Godot Engine 4", "size": 16, "color": Color(1, 1, 1, 1)},
	{"label": "", "size": 14, "color": Color(1,1,1,1)},
	{"label": "credits_inst", "size": 14, "color": Color(0.7, 0.85, 1.0, 1.0)},
	{"label": "Escola Profissional de Gaia (EPGaia)", "size": 16, "color": Color(1, 1, 1, 1)},
	{"label": "", "size": 14, "color": Color(1,1,1,1)},
	{"label": "credits_date", "size": 13, "color": Color(0.7, 0.7, 0.7, 1.0)},
]

func _ready():
	if GameGlobals:
		GameGlobals.play_menu_music()
	if back_button:
		back_button.text = GameGlobals.get_text("options_back")
		back_button.pressed.connect(_on_back)
		if GameGlobals:
			back_button.mouse_entered.connect(GameGlobals.play_hover_sound)
			back_button.pressed.connect(GameGlobals.play_click_sound)
	_build_credits()

func _build_credits():
	var container = $ScrollContainer/VBoxContainer
	for line_data in credits_lines:
		var lbl = Label.new()
		var text_key = line_data["label"]
		lbl.text = GameGlobals.get_text(text_key)
		lbl.add_theme_font_size_override("font_size", line_data["size"])
		lbl.add_theme_color_override("font_color", line_data["color"])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		container.add_child(lbl)

func _on_back():
	SceneTransition.fade_to("res://scenes/main_menu.tscn")
