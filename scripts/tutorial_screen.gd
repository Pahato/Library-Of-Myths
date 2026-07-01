extends CanvasLayer
class_name TutorialScreen

# book_type: 1 = Apollo vs Python, 2 = Shiva vs Rudra, 3 = Thor vs Jörmungandr
var book_type: int = 1
var _scene_to_load: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui():
	# Determinar textos com base no livro
	var title_key: String
	var story_key: String
	var controls_key: String
	var objective_key: String
	var tip_key: String
	
	match book_type:
		1:
			title_key = "tutorial_title_book1"
			story_key = "tutorial_story_book1"
			controls_key = "tutorial_controls_book1"
			objective_key = "tutorial_objective_book1"
			tip_key = "tutorial_tip_book1"
		2:
			title_key = "tutorial_title_book2"
			story_key = "tutorial_story_book2"
			controls_key = "tutorial_controls_book2"
			objective_key = "tutorial_objective_book2"
			tip_key = "tutorial_tip_book2"
		3:
			title_key = "tutorial_title_book3"
			story_key = "tutorial_story_book3"
			controls_key = "tutorial_controls_book3"
			objective_key = "tutorial_objective_book3"
			tip_key = "tutorial_tip_book3"
		4:
			title_key = "tutorial_title_book4"
			story_key = "tutorial_story_book4"
			controls_key = "tutorial_controls_book4"
			objective_key = "tutorial_objective_book4"
			tip_key = "tutorial_tip_book4"
		5:
			title_key = "tutorial_title_book5"
			story_key = "tutorial_story_book5"
			controls_key = "tutorial_controls_book5"
			objective_key = "tutorial_objective_book5"
			tip_key = "tutorial_tip_book5"
		_:
			title_key = "tutorial_title_book1"
			story_key = "tutorial_story_book1"
			controls_key = "tutorial_controls_book1"
			objective_key = "tutorial_objective_book1"
			tip_key = "tutorial_tip_book1"
	
	# Cores temáticas por livro
	var accent_color: Color
	var bg_color: Color
	var border_color: Color
	
	match book_type:
		1:
			accent_color = Color(1.0, 0.85, 0.25, 1.0)   # Dourado solar
			bg_color = Color(0.06, 0.04, 0.02, 0.96)
			border_color = Color(0.85, 0.65, 0.25, 1.0)
		2:
			accent_color = Color(0.7, 0.3, 1.0, 1.0)      # Roxo cósmico
			bg_color = Color(0.04, 0.02, 0.10, 0.96)
			border_color = Color(0.6, 0.2, 0.9, 1.0)
		3:
			accent_color = Color(0.3, 0.6, 1.0, 1.0)      # Azul elétrico
			bg_color = Color(0.03, 0.05, 0.12, 0.96)
			border_color = Color(0.25, 0.5, 0.9, 1.0)
		4:
			accent_color = Color(0.9, 0.15, 0.15, 1.0)    # Vermelho japonês
			bg_color = Color(0.10, 0.02, 0.02, 0.96)
			border_color = Color(0.8, 0.1, 0.1, 1.0)
		5:
			accent_color = Color(1.0, 0.75, 0.1, 1.0)     # Ouro Babilónia
			bg_color = Color(0.12, 0.08, 0.02, 0.96)
			border_color = Color(0.9, 0.7, 0.15, 1.0)
		_:
			accent_color = Color(1.0, 0.85, 0.25, 1.0)
			bg_color = Color(0.06, 0.04, 0.02, 0.96)
			border_color = Color(0.85, 0.65, 0.25, 1.0)
	
	# --- Fundo escuro ---
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.layout_mode = 1
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)
	
	# --- Painel central ---
	var panel = Panel.new()
	panel.layout_mode = 1
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -310.0
	panel.offset_top = -250.0
	panel.offset_right = 310.0
	panel.offset_bottom = 250.0
	panel.grow_horizontal = 2
	panel.grow_vertical = 2
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_left = 2
	sb.border_width_top = 3
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border_color
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.shadow_size = 20
	sb.shadow_color = Color(0, 0, 0, 0.7)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	
	# Carregar fonte épica
	var font_bold = _load_font(true)
	var font_reg = _load_font(false)
	
	# --- VBox principal ---
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.layout_mode = 1
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 24.0
	vbox.offset_top = 18.0
	vbox.offset_right = -24.0
	vbox.offset_bottom = -18.0
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Título do livro
	var title_lbl = Label.new()
	title_lbl.text = GameGlobals.get_text(title_key)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", font_bold)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", accent_color)
	title_lbl.add_theme_constant_override("outline_size", 4)
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(title_lbl)
	
	# Linha separadora
	vbox.add_child(_make_separator(border_color))
	
	# História
	var story_lbl = Label.new()
	story_lbl.text = GameGlobals.get_text(story_key)
	story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_lbl.add_theme_font_override("font", font_reg)
	story_lbl.add_theme_font_size_override("font_size", 11)
	story_lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.85, 1.0))
	vbox.add_child(story_lbl)
	
	# Separador
	vbox.add_child(_make_separator(border_color))
	
	# HBox: Controlos | Objetivo
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)
	
	# --- Painel Controlos ---
	var ctrl_panel = _make_sub_panel(bg_color, border_color)
	ctrl_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(ctrl_panel)
	
	var ctrl_vbox = VBoxContainer.new()
	ctrl_vbox.add_theme_constant_override("separation", 6)
	ctrl_panel.add_child(ctrl_vbox)
	
	var ctrl_title = Label.new()
	ctrl_title.text = GameGlobals.get_text("tutorial_controls_title")
	ctrl_title.add_theme_font_override("font", font_bold)
	ctrl_title.add_theme_font_size_override("font_size", 12)
	ctrl_title.add_theme_color_override("font_color", accent_color)
	ctrl_vbox.add_child(ctrl_title)
	
	var ctrl_lbl = Label.new()
	ctrl_lbl.text = _get_dynamic_controls_text()
	ctrl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ctrl_lbl.add_theme_font_override("font", font_reg)
	ctrl_lbl.add_theme_font_size_override("font_size", 10)
	ctrl_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1.0))
	ctrl_vbox.add_child(ctrl_lbl)
	
	# --- Painel Objetivo ---
	var obj_panel = _make_sub_panel(bg_color, border_color)
	obj_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(obj_panel)
	
	var obj_vbox = VBoxContainer.new()
	obj_vbox.add_theme_constant_override("separation", 6)
	obj_panel.add_child(obj_vbox)
	
	var obj_title = Label.new()
	obj_title.text = GameGlobals.get_text("tutorial_objective_title")
	obj_title.add_theme_font_override("font", font_bold)
	obj_title.add_theme_font_size_override("font_size", 12)
	obj_title.add_theme_color_override("font_color", accent_color)
	obj_vbox.add_child(obj_title)
	
	var obj_lbl = Label.new()
	obj_lbl.text = GameGlobals.get_text(objective_key)
	obj_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obj_lbl.add_theme_font_override("font", font_reg)
	obj_lbl.add_theme_font_size_override("font_size", 10)
	obj_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1.0))
	obj_vbox.add_child(obj_lbl)
	
	# Separador
	vbox.add_child(_make_separator(border_color))
	
	# Dica destacada (com autowrap ativo para evitar overflow da caixa)
	var tip_lbl = Label.new()
	tip_lbl.text = GameGlobals.get_text(tip_key)
	tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_lbl.add_theme_font_override("font", font_reg)
	tip_lbl.add_theme_font_size_override("font_size", 10)
	tip_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55, 1.0))
	tip_lbl.add_theme_constant_override("outline_size", 3)
	tip_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(tip_lbl)
	
	# Separador
	vbox.add_child(_make_separator(border_color))
	
	# Scroll Toggle apenas para Shiva
	if book_type == 2:
		var scroll_btn = _make_button(GameGlobals.get_text("options_rhythm_scroll_down") if GameGlobals.rhythm_scroll_down else GameGlobals.get_text("options_rhythm_scroll_up"), font_bold, accent_color, border_color)
		scroll_btn.custom_minimum_size = Vector2(160, 30)
		scroll_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		scroll_btn.pressed.connect(func():
			if GameGlobals:
				GameGlobals.rhythm_scroll_down = not GameGlobals.rhythm_scroll_down
				GameGlobals.save_settings()
				scroll_btn.text = GameGlobals.get_text("options_rhythm_scroll_down") if GameGlobals.rhythm_scroll_down else GameGlobals.get_text("options_rhythm_scroll_up")
				GameGlobals.play_click_sound()
		)
		if GameGlobals:
			scroll_btn.mouse_entered.connect(GameGlobals.play_hover_sound)
		
		# Animação Scale Hover
		scroll_btn.mouse_entered.connect(func():
			scroll_btn.pivot_offset = scroll_btn.size / 2
			var tw = create_tween()
			tw.tween_property(scroll_btn, "scale", Vector2(1.05, 1.05), 0.15)
		)
		scroll_btn.mouse_exited.connect(func():
			var tw = create_tween()
			tw.tween_property(scroll_btn, "scale", Vector2(1.0, 1.0), 0.15)
		)
		
		vbox.add_child(scroll_btn)
		vbox.add_child(_make_separator(border_color))
	
	# --- Botões ---
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	# Botão Voltar
	var back_btn = _make_button(GameGlobals.get_text("tutorial_back"), font_bold, Color(0.5, 0.5, 0.5, 0.85), border_color)
	back_btn.pressed.connect(_on_back_pressed)
	if GameGlobals:
		back_btn.mouse_entered.connect(GameGlobals.play_hover_sound)
	btn_hbox.add_child(back_btn)
	
	# Botão Jogar
	var play_btn = _make_button(GameGlobals.get_text("tutorial_play"), font_bold, accent_color, border_color)
	play_btn.pressed.connect(_on_play_pressed)
	if GameGlobals:
		play_btn.mouse_entered.connect(GameGlobals.play_hover_sound)
	btn_hbox.add_child(play_btn)
	
	# Animação de entrada
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD)

func _make_separator(color: Color) -> HSeparator:
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator_color", color)
	sep.add_theme_constant_override("separation", 2)
	return sep

func _make_sub_panel(bg: Color, border: Color) -> PanelContainer:
	var p = PanelContainer.new()
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg.lightened(0.04)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = border
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	
	# Configurar margens internas para que o conteúdo não toque nos limites
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	
	p.add_theme_stylebox_override("panel", sb)
	return p

func _make_button(txt: String, font: FontFile, col: Color, border: Color) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(140, 36)
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 12)
	
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = col.darkened(0.55)
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.border_color = col
	sb_normal.corner_radius_top_left = 4
	sb_normal.corner_radius_top_right = 4
	sb_normal.corner_radius_bottom_left = 4
	sb_normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", sb_normal)
	
	var sb_hover = sb_normal.duplicate()
	sb_hover.bg_color = col.darkened(0.3)
	sb_hover.border_color = col.lightened(0.2)
	btn.add_theme_stylebox_override("hover", sb_hover)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn

func _on_back_pressed():
	if GameGlobals:
		GameGlobals.play_click_sound()
	queue_free()

func _on_play_pressed():
	if GameGlobals:
		GameGlobals.play_click_sound()
	queue_free()
	var transition = get_tree().root.get_node_or_null("SceneTransition")
	if transition:
		transition.fade_to(_scene_to_load)
	else:
		get_tree().change_scene_to_file(_scene_to_load)

func _load_font(bold: bool = false) -> FontFile:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	var f = FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	return f

func _get_action_keys_string(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	var events = InputMap.action_get_events(action)
	var keys = []
	for ev in events:
		if ev is InputEventKey:
			var key_name = OS.get_keycode_string(ev.physical_keycode) if ev.physical_keycode != 0 else OS.get_keycode_string(ev.keycode)
			if key_name == "Left": key_name = "◀"
			elif key_name == "Right": key_name = "▶"
			elif key_name == "Up": key_name = "▲"
			elif key_name == "Down": key_name = "▼"
			elif key_name == "Space": key_name = "Espaço" if GameGlobals.current_language == GameGlobals.Language.PT else "Space"
			if not keys.has(key_name):
				keys.append(key_name)
		elif ev is InputEventMouseButton:
			var btn_name = ""
			match ev.button_index:
				MOUSE_BUTTON_LEFT:
					btn_name = "Botão Esq. Rato" if GameGlobals.current_language == GameGlobals.Language.PT else "LMB"
				MOUSE_BUTTON_RIGHT:
					btn_name = "Botão Dir. Rato" if GameGlobals.current_language == GameGlobals.Language.PT else "RMB"
				MOUSE_BUTTON_MIDDLE:
					btn_name = "Botão Meio" if GameGlobals.current_language == GameGlobals.Language.PT else "MMB"
				_:
					btn_name = "Mouse " + str(ev.button_index)
			if not keys.has(btn_name):
				keys.append(btn_name)
		elif ev is InputEventJoypadButton:
			var btn_name = "Button " + str(ev.button_index)
			match ev.button_index:
				JOY_BUTTON_A: btn_name = "Botão A" if GameGlobals.current_language == GameGlobals.Language.PT else "Button A"
				JOY_BUTTON_B: btn_name = "Botão B" if GameGlobals.current_language == GameGlobals.Language.PT else "Button B"
				JOY_BUTTON_X: btn_name = "Botão X" if GameGlobals.current_language == GameGlobals.Language.PT else "Button X"
				JOY_BUTTON_Y: btn_name = "Botão Y" if GameGlobals.current_language == GameGlobals.Language.PT else "Button Y"
			if not keys.has(btn_name):
				keys.append(btn_name)
				
	return " / ".join(keys)

func _get_dynamic_controls_text() -> String:
	var is_pt = (GameGlobals.current_language == GameGlobals.Language.PT)
	if book_type == 1:
		var left_keys = _get_action_keys_string("move_left")
		var right_keys = _get_action_keys_string("move_right")
		var jump_keys = _get_action_keys_string("jump")
		var shoot_keys = _get_action_keys_string("shoot")
		var dash_keys = _get_action_keys_string("dash")
		
		if is_pt:
			return (
				left_keys + "  →  Mover Esquerda\n" +
				right_keys + "  →  Mover Direita\n" +
				jump_keys + "  →  Saltar\n" +
				shoot_keys + "  →  Disparar Flecha\n" +
				dash_keys + "  →  Dash Solar"
			)
		else:
			return (
				left_keys + "  →  Move Left\n" +
				right_keys + "  →  Move Right\n" +
				jump_keys + "  →  Jump\n" +
				shoot_keys + "  →  Shoot Arrow\n" +
				dash_keys + "  →  Solar Dash"
			)
	elif book_type == 3:
		if is_pt:
			return "Rato (Clique)  →  Selecionar Carta\nRato (Clique)  →  Jogar Carta\nBotão  →  Terminar Turno\nESC  →  Pausar"
		else:
			return "Mouse (Click)  →  Select Card\nMouse (Click)  →  Play Card\nButton  →  End Turn\nESC  →  Pause"
	else:
		if is_pt:
			return "A / ◀  →  Nota Esquerda\nS / ▼  →  Nota Baixo\nW / ▲  →  Nota Cima\nD / ▶  →  Nota Direita\nESC  →  Pausar"
		else:
			return "A / ◀  →  Left Note\nS / ▼  →  Down Note\nW / ▲  →  Up Note\nD / ▶  →  Right Note\nESC  →  Pause"
