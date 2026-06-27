extends Control

# =============================================================================
# THOR REST — Descanso / Acampamento
# Livro III: Thor vs Jörmungandr
# =============================================================================

var font_bold: FontFile = null
var font_reg: FontFile = null
const ACCENT_COLOR = Color(0.9, 0.4, 0.1, 1.0) # Laranja fogo
const HEAL_COLOR = Color(0.3, 1.0, 0.5, 1.0)

func _ready():
	font_bold = _load_font(true)
	font_reg = _load_font(false)
	_build_ui()
	
	if GameGlobals:
		GameGlobals.play_music("res://assets/music/time_for_adventure.mp3", -8.0)

func _load_font(bold: bool = false) -> FontFile:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	var f = FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	return f

func _build_ui():
	# Fundo
	var bg_color = ColorRect.new()
	bg_color.color = Color(0.02, 0.01, 0.05, 1.0)
	bg_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	var bg_tex = load("res://assets/sprites/Sprites Thor/Cenários/rest_bg.png")
	if bg_tex:
		var bg_rect = TextureRect.new()
		bg_rect.texture = bg_tex
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
		bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_rect.modulate = Color(1.0, 1.0, 1.0, 0.5)
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_rect)
	
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -300
	vbox.offset_top = -200
	vbox.offset_right = 300
	vbox.offset_bottom = 200
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	add_child(vbox)
	
	# Ícone Fogueira
	var icon = Label.new()
	icon.text = "🔥"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 64)
	vbox.add_child(icon)
	
	# Título
	var title = Label.new()
	title.text = "Acampamento Seguro" if is_pt else "Safe Camp"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold: title.add_theme_font_override("font", font_bold)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	vbox.add_child(title)
	
	# Status
	var hp_label = Label.new()
	var current_hp = GameGlobals.thor_hp if GameGlobals else 80
	var max_hp = GameGlobals.thor_max_hp if GameGlobals else 80
	hp_label.text = ("❤️ HP Atual: %d / %d" % [current_hp, max_hp]) if is_pt else ("❤️ Current HP: %d / %d" % [current_hp, max_hp])
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_reg: hp_label.add_theme_font_override("font", font_reg)
	hp_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(hp_label)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox)
	
	# Opção 1: Descansar (Curar 30%)
	var heal_amount = int(max_hp * 0.3)
	var heal_btn = _create_option_button(
		"Descansar" if is_pt else "Rest",
		"❤️ +" + str(heal_amount) + " HP",
		"Cura 30% da vida máxima." if is_pt else "Heal 30% of max HP.",
		HEAL_COLOR
	)
	heal_btn.pressed.connect(func():
		if GameGlobals:
			GameGlobals.play_click_sound()
			GameGlobals.thor_hp = mini(GameGlobals.thor_hp + heal_amount, GameGlobals.thor_max_hp)
		_return_to_map()
	)
	hbox.add_child(heal_btn)
	
	# Opção 2: Treinar (+10 Max HP)
	var maxhp_btn = _create_option_button(
		"Treinar" if is_pt else "Train",
		"💪 +10 Max HP",
		"Aumenta a tua vida máxima para o resto da run." if is_pt else "Increase your max HP for the rest of the run.",
		Color(1.0, 0.8, 0.2)
	)
	maxhp_btn.pressed.connect(func():
		if GameGlobals:
			GameGlobals.play_click_sound()
			GameGlobals.thor_max_hp += 10
			GameGlobals.thor_hp += 10
		_return_to_map()
	)
	hbox.add_child(maxhp_btn)

func _create_option_button(title_text: String, effect_text: String, desc_text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(250, 150)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = color.darkened(0.3)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_h = sb.duplicate()
	sb_h.border_color = color
	sb_h.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	btn.add_theme_stylebox_override("hover", sb_h)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	btn.add_child(vbox)
	
	var t_lbl = Label.new()
	t_lbl.text = title_text
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold: t_lbl.add_theme_font_override("font", font_bold)
	t_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(t_lbl)
	
	var e_lbl = Label.new()
	e_lbl.text = effect_text
	e_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold: e_lbl.add_theme_font_override("font", font_bold)
	e_lbl.add_theme_font_size_override("font_size", 16)
	e_lbl.add_theme_color_override("font_color", color)
	vbox.add_child(e_lbl)
	
	var d_lbl = Label.new()
	d_lbl.text = desc_text
	d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_reg: d_lbl.add_theme_font_override("font", font_reg)
	d_lbl.add_theme_font_size_override("font_size", 12)
	d_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(d_lbl)
	
	return btn

func _return_to_map():
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		transition.fade_to("res://scenes/thor_map.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/thor_map.tscn")
