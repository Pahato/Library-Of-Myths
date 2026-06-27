extends CanvasLayer

@onready var resume_button = $Panel/VBoxContainer/ResumeButton
@onready var menu_button   = $Panel/VBoxContainer/MenuButton
@onready var title_label   = $Panel/TitleLabel

# ── Opções In-Pause ───────────────────────────────────────────────────────────
var options_overlay: ColorRect = null
var options_panel: Panel = null
var main_options_vbox: VBoxContainer = null
var keybinds_vbox: VBoxContainer = null
var keybinds_grid: GridContainer = null
var keybind_status_label: Label = null
var confirmation_overlay: ColorRect = null
var audio_vbox: VBoxContainer = null
var master_slider: HSlider = null
var music_slider: HSlider = null
var sfx_slider: HSlider = null
var temp_master_volume: float = 0.8
var temp_music_volume: float = 0.8
var temp_sfx_volume: float = 0.8

var rebinding_action: String = ""
var rebinding_button: Button = null

# Temp vars for unapplied settings
var temp_keystroke_enabled: bool = true
var temp_language: int = 0
var temp_resolution_index: int = 3
var temp_keybinds: Dictionary = {}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Traduzir textos
	if title_label:
		title_label.text = GameGlobals.get_text("pause_paused")
	resume_button.text = GameGlobals.get_text("pause_resume")
	menu_button.text   = GameGlobals.get_text("pause_menu")
	
	# Ligar botões base
	resume_button.pressed.connect(_on_resume)
	menu_button.pressed.connect(_on_menu)
	
	# Adicionar botão de Opções ao VBoxContainer
	_add_options_button()
	
	# ── Estilo Visual Premium (RPG / Mitologia) ──────────────────────────────
	_apply_premium_style()
	
	# Foca o botão de continuar automaticamente
	resume_button.grab_focus()
	_connect_button_sounds(self)

func _apply_premium_style():
	var is_rhythm = false
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "RhythmGame":
		is_rhythm = true
		
	# Estilo do Painel principal
	var panel = get_node_or_null("Panel")
	if panel:
		var ps = StyleBoxFlat.new()
		if is_rhythm:
			ps.bg_color = Color(0.06, 0.04, 0.12, 0.96) # Roxo escuro neon
			ps.border_color = Color(0.7, 0.2, 0.9, 1.0) # Magenta/Roxo neon
		else:
			ps.bg_color = Color(0.08, 0.05, 0.03, 0.97) # Castanho rústico
			ps.border_color = Color(0.85, 0.65, 0.25, 1.0) # Ouro rústico
		ps.border_width_left   = 2
		ps.border_width_top    = 3
		ps.border_width_right  = 2
		ps.border_width_bottom = 2
		ps.corner_radius_top_left     = 4
		ps.corner_radius_top_right    = 4
		ps.corner_radius_bottom_left  = 4
		ps.corner_radius_bottom_right = 4
		ps.shadow_size = 20
		ps.shadow_color = Color(0, 0, 0, 0.75)
		panel.add_theme_stylebox_override("panel", ps)
		
		# Só adiciona textura de pedra no modo rústico (Apolo)
		if not is_rhythm:
			_add_stone_texture(panel)
	
	# Fonte Cinzel no título do pause
	if title_label:
		var cinzel = _load_font(true)
		if cinzel:
			title_label.add_theme_font_override("font", cinzel)
		title_label.add_theme_font_size_override("font_size", 20)
		if is_rhythm:
			title_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0, 1.0)) # Cyan neon
		else:
			title_label.add_theme_color_override("font_color", Color(0.96, 0.80, 0.35, 1.0)) # Ouro
		title_label.add_theme_constant_override("outline_size", 2)
		title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	
	# Estilo premium para os botões
	var cinzel_reg = _load_font(false)
	for btn in [resume_button, menu_button]:
		if not btn:
			continue
		_style_menu_button(btn, cinzel_reg)

func _style_menu_button(btn: Button, font = null):
	var is_rhythm = false
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "RhythmGame":
		is_rhythm = true
		
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 14)
	
	if is_rhythm:
		btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.98, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.25, 0.95, 1.0, 1.0)) # Cyan
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		btn.add_theme_color_override("font_color", Color(0.92, 0.85, 0.70, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.6, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	
	var sb_normal = StyleBoxFlat.new()
	if is_rhythm:
		sb_normal.bg_color = Color(0.08, 0.05, 0.14, 0.85)
		sb_normal.border_color = Color(0.7, 0.2, 0.8, 0.6) # Roxo
	else:
		sb_normal.bg_color = Color(0.14, 0.09, 0.05, 0.85)
		sb_normal.border_color = Color(0.55, 0.42, 0.18, 0.7)
	sb_normal.border_width_left   = 1
	sb_normal.border_width_top    = 1
	sb_normal.border_width_right  = 1
	sb_normal.border_width_bottom = 1
	sb_normal.corner_radius_top_left     = 3
	sb_normal.corner_radius_top_right    = 3
	sb_normal.corner_radius_bottom_left  = 3
	sb_normal.corner_radius_bottom_right = 3
	
	var sb_hover = StyleBoxFlat.new()
	if is_rhythm:
		sb_hover.bg_color = Color(0.18, 0.10, 0.28, 0.95)
		sb_hover.border_color = Color(0.15, 0.85, 0.95, 1.0) # Cyan
	else:
		sb_hover.bg_color = Color(0.30, 0.18, 0.05, 0.95)
		sb_hover.border_color = Color(0.9, 0.72, 0.3, 1.0)
	sb_hover.border_width_left   = 1
	sb_hover.border_width_top    = 1
	sb_hover.border_width_right  = 1
	sb_hover.border_width_bottom = 1
	sb_hover.corner_radius_top_left     = 3
	sb_hover.corner_radius_top_right    = 3
	sb_hover.corner_radius_bottom_left  = 3
	sb_hover.corner_radius_bottom_right = 3
	
	var sb_pressed = StyleBoxFlat.new()
	if is_rhythm:
		sb_pressed.bg_color = Color(0.28, 0.15, 0.40, 0.95)
		sb_pressed.border_color = Color(1.0, 0.25, 0.85, 1.0) # Magenta
	else:
		sb_pressed.bg_color = Color(0.45, 0.28, 0.08, 0.95)
		sb_pressed.border_color = Color(1.0, 0.85, 0.4, 1.0)
	sb_pressed.border_width_left   = 1
	sb_pressed.border_width_top    = 1
	sb_pressed.border_width_right  = 1
	sb_pressed.border_width_bottom = 1
	sb_pressed.corner_radius_top_left     = 3
	sb_pressed.corner_radius_top_right    = 3
	sb_pressed.corner_radius_bottom_left  = 3
	sb_pressed.corner_radius_bottom_right = 3
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_hover)


func _add_options_button():
	var vbox = $Panel/VBoxContainer
	if not vbox:
		return
	var opt_btn = Button.new()
	opt_btn.name = "OptionsButton"
	opt_btn.text = GameGlobals.get_text("menu_options")
	opt_btn.layout_mode = 2
	# Inserir entre o ResumeButton e o MenuButton
	vbox.add_child(opt_btn)
	vbox.move_child(opt_btn, 1) # Posição 1 = entre Resume (0) e Menu (2)
	opt_btn.pressed.connect(_on_options_pressed)
	# Aplicar estilo RPG premium
	_style_menu_button(opt_btn, _load_font(false))

func _input(event):
	# ESC fecha o menu de pausa (mas não se o menu de opções estiver aberto)
	if event.is_action_pressed("ui_cancel"):
		if options_overlay and options_overlay.visible:
			# Fechar o overlay de opções com ESC
			if confirmation_overlay and confirmation_overlay.visible:
				confirmation_overlay.hide()
			elif keybinds_vbox and keybinds_vbox.visible:
				keybinds_vbox.hide()
				if main_options_vbox:
					main_options_vbox.show()
				_update_options_labels()
			else:
				_on_back_pressed()
		else:
			_on_resume()

func _on_resume():
	get_tree().paused = false
	queue_free()

func _on_menu():
	get_tree().paused = false
	SceneTransition.fade_to("res://scenes/main_menu.tscn")
	queue_free()

# ── Lógica de Opções (espelho do main_menu.gd) ────────────────────────────────

# Carrega a fonte Cinzel (estílo épico/mitológico)
func _load_font(bold: bool = false) -> FontFile:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	var f = FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	return f

# Adiciona textura de pedra como fundo de um painel
func _add_stone_texture(panel: Panel) -> void:
	var texture = load("res://assets/ui/stone_panel_bg.png") as Texture2D
	if not texture:
		return
	var tex_rect = TextureRect.new()
	tex_rect.name = "StoneBg"
	tex_rect.texture = texture
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.modulate = Color(1.0, 1.0, 1.0, 0.18)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tex_rect)
	panel.move_child(tex_rect, 0)


func _on_options_pressed():
	temp_keystroke_enabled = GameGlobals.keystroke_enabled
	temp_language = GameGlobals.current_language
	temp_resolution_index = GameGlobals.current_resolution_index
	temp_master_volume = GameGlobals.master_volume
	temp_music_volume = GameGlobals.music_volume
	temp_sfx_volume = GameGlobals.sfx_volume
	temp_keybinds = {}
	for action in ["move_left", "move_right", "jump", "parry", "shoot"]:
		temp_keybinds[action] = InputMap.action_get_events(action).duplicate(true)
	
	_create_options_overlay()
	if options_overlay:
		options_overlay.show()
		keybinds_vbox.hide()
		main_options_vbox.show()
		_update_options_labels()

func _create_options_overlay():
	if options_overlay:
		return
	
	# Overlay escuro sobre o pause menu
	options_overlay = ColorRect.new()
	options_overlay.name = "OptionsOverlay"
	options_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	options_overlay.color = Color(0, 0, 0, 0.6)
	options_overlay.visible = false
	options_overlay.z_index = 10
	options_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	options_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(options_overlay)
	
	# Painel Central — PRESET_TOP_LEFT + position manual (PRESET_CENTER confliciona)
	var panel_size = Vector2(380, 430)
	options_panel = Panel.new()
	options_panel.name = "OptionsPanel"
	options_panel.size = panel_size
	options_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var vp_size = get_viewport().get_visible_rect().size
	options_panel.position = (vp_size - panel_size) / 2
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.07, 0.04, 0.97)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 3
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.85, 0.68, 0.3, 1.0)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.shadow_size = 18
	panel_style.shadow_color = Color(0, 0, 0, 0.7)
	options_panel.add_theme_stylebox_override("panel", panel_style)
	options_overlay.add_child(options_panel)
	# Textura de pedra no fundo
	_add_stone_texture(options_panel)
	
	# Título com fonte Cinzel épica
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = GameGlobals.get_text("options_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.4, 1.0))
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	var cinzel_bold = _load_font(true)
	if cinzel_bold: title.add_theme_font_override("font", cinzel_bold)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 15
	title.offset_bottom = 50
	options_panel.add_child(title)
	
	# ── Menu Principal das Opções ──
	main_options_vbox = VBoxContainer.new()
	main_options_vbox.name = "MainOptionsVBox"
	main_options_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_options_vbox.offset_top = 55
	main_options_vbox.offset_bottom = -15
	main_options_vbox.offset_left = 30
	main_options_vbox.offset_right = -30
	main_options_vbox.add_theme_constant_override("separation", 10)
	main_options_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	options_panel.add_child(main_options_vbox)
	
	# 1. Keystroke
	var keystroke_btn = Button.new()
	keystroke_btn.name = "KeystrokeButton"
	keystroke_btn.add_theme_font_size_override("font_size", 14)
	keystroke_btn.pressed.connect(_on_keystroke_toggle)
	main_options_vbox.add_child(keystroke_btn)
	
	# 2. Idioma
	var lang_btn = Button.new()
	lang_btn.name = "LanguageButton"
	lang_btn.add_theme_font_size_override("font_size", 14)
	lang_btn.pressed.connect(_on_language_toggle)
	main_options_vbox.add_child(lang_btn)
	
	# 3. Resolução
	var resolution_btn = Button.new()
	resolution_btn.name = "ResolutionButton"
	resolution_btn.add_theme_font_size_override("font_size", 14)
	resolution_btn.pressed.connect(_on_resolution_toggle)
	main_options_vbox.add_child(resolution_btn)
	
	# 4. Keybinds
	var keybinds_menu_btn = Button.new()
	keybinds_menu_btn.name = "KeybindsMenuButton"
	keybinds_menu_btn.add_theme_font_size_override("font_size", 14)
	keybinds_menu_btn.pressed.connect(_on_keybinds_menu_pressed)
	main_options_vbox.add_child(keybinds_menu_btn)
	
	# Botão de Áudio
	var audio_menu_btn = Button.new()
	audio_menu_btn.name = "AudioMenuButton"
	audio_menu_btn.add_theme_font_size_override("font_size", 14)
	audio_menu_btn.pressed.connect(_on_audio_menu_pressed)
	_style_menu_button(audio_menu_btn, _load_font(false))
	main_options_vbox.add_child(audio_menu_btn)
	
	# 5. Aplicar
	var apply_btn = Button.new()
	apply_btn.name = "ApplyButton"
	apply_btn.add_theme_font_size_override("font_size", 14)
	apply_btn.pressed.connect(_on_apply_pressed)
	main_options_vbox.add_child(apply_btn)
	
	# 6. Voltar
	var back_btn = Button.new()
	back_btn.name = "BackButton"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(_on_back_pressed)
	main_options_vbox.add_child(back_btn)
	
	# ── Submenu de Keybinds ──
	keybinds_vbox = VBoxContainer.new()
	keybinds_vbox.name = "KeybindsVBox"
	keybinds_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	keybinds_vbox.offset_top = 55
	keybinds_vbox.offset_bottom = -15
	keybinds_vbox.offset_left = 20
	keybinds_vbox.offset_right = -20
	keybinds_vbox.add_theme_constant_override("separation", 10)
	keybinds_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	keybinds_vbox.visible = false
	options_panel.add_child(keybinds_vbox)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	keybinds_vbox.add_child(scroll)
	
	keybinds_grid = GridContainer.new()
	keybinds_grid.columns = 2
	keybinds_grid.add_theme_constant_override("h_separation", 20)
	keybinds_grid.add_theme_constant_override("v_separation", 6)
	keybinds_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(keybinds_grid)
	
	var actions = {
		"move_left": "keybinds_move_left",
		"move_right": "keybinds_move_right",
		"jump": "keybinds_jump",
		"parry": "keybinds_parry",
		"shoot": "keybinds_shoot"
	}
	for action in actions:
		var lbl = Label.new()
		lbl.name = action + "_Label"
		lbl.text = GameGlobals.get_text(actions[action])
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 1.0))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		keybinds_grid.add_child(lbl)
		
		var btn = Button.new()
		btn.name = action + "_Button"
		btn.custom_minimum_size = Vector2(100, 24)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func(): _on_keybind_button_pressed(action, btn))
		keybinds_grid.add_child(btn)
	
	keybind_status_label = Label.new()
	keybind_status_label.name = "KeybindStatusLabel"
	keybind_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keybind_status_label.add_theme_font_size_override("font_size", 12)
	keybind_status_label.text = ""
	keybinds_vbox.add_child(keybind_status_label)
	
	var base_hbox = HBoxContainer.new()
	base_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	base_hbox.add_theme_constant_override("separation", 20)
	keybinds_vbox.add_child(base_hbox)
	
	var reset_btn = Button.new()
	reset_btn.name = "ResetButton"
	reset_btn.add_theme_font_size_override("font_size", 13)
	reset_btn.pressed.connect(_on_keybinds_reset_pressed)
	base_hbox.add_child(reset_btn)
	
	var k_back_btn = Button.new()
	k_back_btn.name = "KeybindsBackButton"
	k_back_btn.add_theme_font_size_override("font_size", 13)
	k_back_btn.pressed.connect(_on_keybinds_back_pressed)
	base_hbox.add_child(k_back_btn)
	
	_update_options_labels()
	
	# -------------------- SUBMENU DE ÁUDIO --------------------
	audio_vbox = VBoxContainer.new()
	audio_vbox.name = "AudioVBox"
	audio_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	audio_vbox.offset_top = 55
	audio_vbox.offset_bottom = -15
	audio_vbox.offset_left = 30
	audio_vbox.offset_right = -30
	audio_vbox.add_theme_constant_override("separation", 14)
	audio_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	audio_vbox.visible = false
	options_panel.add_child(audio_vbox)
	
	# Master Volume
	var master_lbl = Label.new()
	master_lbl.name = "MasterLabel"
	master_lbl.add_theme_font_size_override("font_size", 13)
	audio_vbox.add_child(master_lbl)
	
	master_slider = HSlider.new()
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.05
	master_slider.value = temp_master_volume
	master_slider.value_changed.connect(func(val):
		temp_master_volume = val
		GameGlobals.apply_volume("Master", val)
	)
	audio_vbox.add_child(master_slider)
	
	# Music Volume
	var music_lbl = Label.new()
	music_lbl.name = "MusicLabel"
	music_lbl.add_theme_font_size_override("font_size", 13)
	audio_vbox.add_child(music_lbl)
	
	music_slider = HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = temp_music_volume
	music_slider.value_changed.connect(func(val):
		temp_music_volume = val
		GameGlobals.apply_volume("Music", val)
	)
	audio_vbox.add_child(music_slider)
	
	# SFX Volume
	var sfx_lbl = Label.new()
	sfx_lbl.name = "SFXLabel"
	sfx_lbl.add_theme_font_size_override("font_size", 13)
	audio_vbox.add_child(sfx_lbl)
	
	sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = temp_sfx_volume
	sfx_slider.value_changed.connect(func(val):
		temp_sfx_volume = val
		GameGlobals.apply_volume("SFX", val)
		GameGlobals.play_hover_sound()
	)
	audio_vbox.add_child(sfx_slider)
	
	# Botão de Voltar do Submenu Áudio
	var audio_back_btn = Button.new()
	audio_back_btn.name = "AudioBackButton"
	audio_back_btn.add_theme_font_size_override("font_size", 13)
	audio_back_btn.pressed.connect(_on_audio_back_pressed)
	_style_menu_button(audio_back_btn, _load_font(false))
	audio_vbox.add_child(audio_back_btn)
	
	_connect_button_sounds(options_overlay)

func _update_options_labels():
	if not options_overlay:
		return
	
	var title = options_panel.get_node("TitleLabel")
	if title:
		if keybinds_vbox and keybinds_vbox.visible:
			title.text = GameGlobals.translations["PT"]["keybinds_title"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["keybinds_title"]
		elif audio_vbox and audio_vbox.visible:
			title.text = GameGlobals.translations["PT"]["audio_title"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["audio_title"]
		else:
			title.text = GameGlobals.translations["PT"]["options_title"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["options_title"]
	
	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	
	var k_btn = main_options_vbox.get_node("KeystrokeButton")
	if k_btn:
		k_btn.text = GameGlobals.translations[lang_str]["options_keystroke_enabled"] if temp_keystroke_enabled else GameGlobals.translations[lang_str]["options_keystroke_disabled"]
	
	var l_btn = main_options_vbox.get_node("LanguageButton")
	if l_btn:
		l_btn.text = GameGlobals.translations[lang_str]["options_language"]
	
	var res_btn = main_options_vbox.get_node("ResolutionButton")
	if res_btn:
		var r_opt = GameGlobals.resolution_options[temp_resolution_index]
		var res_text = r_opt["text"]
		if r_opt["fullscreen"]:
			res_text = GameGlobals.translations[lang_str]["resolution_fullscreen"]
		res_btn.text = GameGlobals.translations[lang_str]["options_resolution"].replace("[TEXT]", res_text)
	
	var kb_btn = main_options_vbox.get_node("KeybindsMenuButton")
	if kb_btn:
		kb_btn.text = GameGlobals.translations[lang_str]["options_keybinds"]
	
	var apply_btn = main_options_vbox.get_node("ApplyButton")
	if apply_btn:
		apply_btn.text = GameGlobals.translations[lang_str]["options_apply"]
	
	var b_btn = main_options_vbox.get_node("BackButton")
	if b_btn:
		b_btn.text = GameGlobals.translations[lang_str]["options_back"]
	
	var actions = {
		"move_left": "keybinds_move_left",
		"move_right": "keybinds_move_right",
		"jump": "keybinds_jump",
		"parry": "keybinds_parry",
		"shoot": "keybinds_shoot"
	}
	for action in actions:
		var lbl = keybinds_grid.get_node(action + "_Label")
		if lbl:
			lbl.text = GameGlobals.translations[lang_str][actions[action]]
		var btn = keybinds_grid.get_node(action + "_Button")
		if btn:
			if rebinding_action == action:
				btn.text = GameGlobals.translations[lang_str]["keybinds_press_any_key"]
			else:
				btn.text = _get_action_key_text(action)
	
	var r_btn = keybinds_vbox.find_child("ResetButton", true, false) if keybinds_vbox else null
	if r_btn:
		r_btn.text = GameGlobals.translations[lang_str]["keybinds_reset"]
	
	var kb_back = keybinds_vbox.find_child("KeybindsBackButton", true, false) if keybinds_vbox else null
	if kb_back:
		kb_back.text = GameGlobals.translations[lang_str]["options_back"]
		
	var audio_btn = main_options_vbox.get_node("AudioMenuButton")
	if audio_btn:
		audio_btn.text = GameGlobals.translations[lang_str]["options_audio"]
		
	if audio_vbox:
		var m_lbl = audio_vbox.get_node("MasterLabel")
		if m_lbl:
			m_lbl.text = GameGlobals.translations[lang_str]["audio_master"] + ": " + str(round(temp_master_volume * 100)) + "%"
		var mu_lbl = audio_vbox.get_node("MusicLabel")
		if mu_lbl:
			mu_lbl.text = GameGlobals.translations[lang_str]["audio_music"] + ": " + str(round(temp_music_volume * 100)) + "%"
		var sf_lbl = audio_vbox.get_node("SFXLabel")
		if sf_lbl:
			sf_lbl.text = GameGlobals.translations[lang_str]["audio_sfx"] + ": " + str(round(temp_sfx_volume * 100)) + "%"
		var ab_btn = audio_vbox.get_node("AudioBackButton")
		if ab_btn:
			ab_btn.text = GameGlobals.translations[lang_str]["options_back"]

func _on_keystroke_toggle():
	temp_keystroke_enabled = not temp_keystroke_enabled
	_update_options_labels()

func _on_language_toggle():
	if temp_language == GameGlobals.Language.PT:
		temp_language = GameGlobals.Language.EN
	else:
		temp_language = GameGlobals.Language.PT
	_update_options_labels()

func _on_resolution_toggle():
	temp_resolution_index = (temp_resolution_index + 1) % GameGlobals.resolution_options.size()
	_update_options_labels()

func _on_keybinds_menu_pressed():
	main_options_vbox.hide()
	keybinds_vbox.show()
	_update_options_labels()

func _on_keybinds_back_pressed():
	rebinding_action = ""
	rebinding_button = null
	if keybind_status_label:
		keybind_status_label.text = ""
	keybinds_vbox.hide()
	main_options_vbox.show()
	_update_options_labels()

func _on_audio_menu_pressed():
	main_options_vbox.hide()
	audio_vbox.show()
	_update_options_labels()

func _on_audio_back_pressed():
	audio_vbox.hide()
	main_options_vbox.show()
	_update_options_labels()

func _on_keybinds_reset_pressed():
	temp_keybinds["move_left"]  = [_create_key_event(KEY_A)]
	temp_keybinds["move_right"] = [_create_key_event(KEY_D)]
	temp_keybinds["jump"]       = [_create_key_event(KEY_SPACE)]
	temp_keybinds["parry"]      = [_create_key_event(KEY_C)]
	temp_keybinds["shoot"]      = [_create_mouse_event(MOUSE_BUTTON_LEFT)]
	if keybind_status_label:
		keybind_status_label.text = ""
	_update_options_labels()

func _on_keybind_button_pressed(action: String, btn: Button):
	if rebinding_action != "":
		rebinding_action = ""
		rebinding_button = null
		_update_options_labels()
	rebinding_action = action
	rebinding_button = btn
	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	btn.text = GameGlobals.translations[lang_str]["keybinds_press_any_key"]
	if keybind_status_label:
		keybind_status_label.text = btn.text
		keybind_status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.4))

func _is_key_already_bound(new_event: InputEvent, exclude_action: String) -> bool:
	for action in ["move_left", "move_right", "jump", "parry", "shoot"]:
		if action == exclude_action:
			continue
		var events = temp_keybinds.get(action, InputMap.action_get_events(action))
		for ev in events:
			if ev is InputEventKey and new_event is InputEventKey:
				if ev.physical_keycode == new_event.physical_keycode:
					return true
			elif ev is InputEventMouseButton and new_event is InputEventMouseButton:
				if ev.button_index == new_event.button_index:
					return true
	return false

func _get_action_key_text(action: String) -> String:
	var events = temp_keybinds.get(action, InputMap.action_get_events(action))
	if events.is_empty():
		return "---"
	var event = events[0]
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:   return "LMB"
			MOUSE_BUTTON_RIGHT:  return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			_: return "Mouse " + str(event.button_index)
	return event.as_text()

func _on_apply_pressed():
	GameGlobals.keystroke_enabled = temp_keystroke_enabled
	GameGlobals.current_language  = temp_language
	GameGlobals.master_volume = temp_master_volume
	GameGlobals.music_volume = temp_music_volume
	GameGlobals.sfx_volume = temp_sfx_volume
	GameGlobals.apply_resolution(temp_resolution_index)
	for action in temp_keybinds:
		InputMap.action_erase_events(action)
		for ev in temp_keybinds[action]:
			InputMap.action_add_event(action, ev)
	GameGlobals.save_settings()
	_update_options_labels()
	print("[PAUSE OPTIONS] Definições aplicadas e gravadas!")

func _has_unsaved_changes() -> bool:
	if temp_keystroke_enabled != GameGlobals.keystroke_enabled: return true
	if temp_language != GameGlobals.current_language: return true
	if temp_resolution_index != GameGlobals.current_resolution_index: return true
	if temp_master_volume != GameGlobals.master_volume: return true
	if temp_music_volume != GameGlobals.music_volume: return true
	if temp_sfx_volume != GameGlobals.sfx_volume: return true
	for action in ["move_left", "move_right", "jump", "parry", "shoot"]:
		if temp_keybinds.has(action):
			var cur = InputMap.action_get_events(action)
			var tmp = temp_keybinds[action]
			if cur.size() != tmp.size(): return true
			if not cur.is_empty() and not tmp.is_empty():
				var e1 = cur[0]; var e2 = tmp[0]
				if e1 is InputEventKey and e2 is InputEventKey:
					if e1.physical_keycode != e2.physical_keycode: return true
				elif e1 is InputEventMouseButton and e2 is InputEventMouseButton:
					if e1.button_index != e2.button_index: return true
				else: return true
	return false

func _on_back_pressed():
	if _has_unsaved_changes():
		_show_confirmation_popup()
	else:
		options_overlay.hide()

func _show_confirmation_popup():
	if confirmation_overlay:
		confirmation_overlay.show()
		_update_confirmation_popup_labels()
		return
	
	confirmation_overlay = ColorRect.new()
	confirmation_overlay.name = "ConfirmationOverlay"
	confirmation_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirmation_overlay.color = Color(0, 0, 0, 0.45)
	confirmation_overlay.z_index = 20
	confirmation_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirmation_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	options_overlay.add_child(confirmation_overlay)
	
	# Painel — PRESET_TOP_LEFT + posição manual
	var c_size = Vector2(360, 240)
	var c_panel = Panel.new()
	c_panel.name = "ConfirmationPanel"
	c_panel.size = c_size
	c_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var vp2 = get_viewport().get_visible_rect().size
	c_panel.position = (vp2 - c_size) / 2
	
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.10, 0.07, 0.04, 0.97)
	c_style.border_width_left   = 2
	c_style.border_width_top    = 3
	c_style.border_width_right  = 2
	c_style.border_width_bottom = 2
	c_style.border_color = Color(0.85, 0.68, 0.3, 1.0)
	c_style.corner_radius_top_left     = 4
	c_style.corner_radius_top_right    = 4
	c_style.corner_radius_bottom_left  = 4
	c_style.corner_radius_bottom_right = 4
	c_style.shadow_size = 16
	c_style.shadow_color = Color(0, 0, 0, 0.7)
	c_panel.add_theme_stylebox_override("panel", c_style)
	confirmation_overlay.add_child(c_panel)
	
	# Textura de pedra
	_add_stone_texture(c_panel)
	
	# VBox único para TODO o conteúdo (título + mensagem + botões)
	var content_vbox = VBoxContainer.new()
	content_vbox.name = "ContentVBox"
	content_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_vbox.offset_top    = 15
	content_vbox.offset_bottom = -12
	content_vbox.offset_left   = 25
	content_vbox.offset_right  = -25
	content_vbox.add_theme_constant_override("separation", 10)
	content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	c_panel.add_child(content_vbox)
	
	# Título
	var c_title = Label.new()
	c_title.name = "TitleLabel"
	c_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_title.add_theme_font_size_override("font_size", 16)
	c_title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.4, 1.0))
	c_title.add_theme_constant_override("outline_size", 2)
	c_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	var cinzel = _load_font(true)
	if cinzel: c_title.add_theme_font_override("font", cinzel)
	c_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(c_title)
	
	# Separador dourado
	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(0.75, 0.55, 0.2, 0.6))
	sep.add_theme_constant_override("separation", 4)
	content_vbox.add_child(sep)
	
	# Mensagem
	var c_text = Label.new()
	c_text.name = "MessageLabel"
	c_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_text.add_theme_font_size_override("font_size", 12)
	c_text.add_theme_color_override("font_color", Color(0.88, 0.82, 0.72, 1.0))
	c_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_vbox.add_child(c_text)
	
	# Espaçador elástico
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(spacer)
	
	# Botões (dentro do VBox — sem PRESET_BOTTOM_WIDE)
	var btn_apply_exit = Button.new()
	btn_apply_exit.name = "ApplyExitButton"
	btn_apply_exit.add_theme_font_size_override("font_size", 12)
	btn_apply_exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_apply_exit.pressed.connect(func():
		_on_apply_pressed()
		confirmation_overlay.hide()
		options_overlay.hide()
	)
	content_vbox.add_child(btn_apply_exit)
	
	var btn_discard_exit = Button.new()
	btn_discard_exit.name = "DiscardExitButton"
	btn_discard_exit.add_theme_font_size_override("font_size", 12)
	btn_discard_exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_discard_exit.pressed.connect(func():
		# Restaurar volumes originais
		GameGlobals.apply_volume("Master", GameGlobals.master_volume)
		GameGlobals.apply_volume("Music", GameGlobals.music_volume)
		GameGlobals.apply_volume("SFX", GameGlobals.sfx_volume)
		confirmation_overlay.hide()
		options_overlay.hide()
	)
	content_vbox.add_child(btn_discard_exit)
	
	var btn_cancel = Button.new()
	btn_cancel.name = "CancelButton"
	btn_cancel.add_theme_font_size_override("font_size", 12)
	btn_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cancel.pressed.connect(func():
		confirmation_overlay.hide()
	)
	content_vbox.add_child(btn_cancel)
	
	_update_confirmation_popup_labels()
	_connect_button_sounds(confirmation_overlay)

func _update_confirmation_popup_labels():
	if not confirmation_overlay:
		return
	var c_panel = confirmation_overlay.get_node_or_null("ConfirmationPanel")
	if not c_panel:
		return
	var content_vbox = c_panel.get_node_or_null("ContentVBox")
	if not content_vbox:
		return
	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	
	var c_title = content_vbox.get_node_or_null("TitleLabel")
	if c_title: c_title.text = GameGlobals.translations[lang_str]["confirm_title"]
	
	var c_text = content_vbox.get_node_or_null("MessageLabel")
	if c_text: c_text.text = GameGlobals.translations[lang_str]["confirm_text"]
	
	var btn1 = content_vbox.get_node_or_null("ApplyExitButton")
	if btn1: btn1.text = GameGlobals.translations[lang_str]["confirm_apply_exit"]
	var btn2 = content_vbox.get_node_or_null("DiscardExitButton")
	if btn2: btn2.text = GameGlobals.translations[lang_str]["confirm_discard_exit"]
	var btn3 = content_vbox.get_node_or_null("CancelButton")
	if btn3: btn3.text = GameGlobals.translations[lang_str]["confirm_cancel"]


func _create_key_event(code: int) -> InputEventKey:
	var ev = InputEventKey.new()
	ev.physical_keycode = code
	return ev

func _create_mouse_event(code: int) -> InputEventMouseButton:
	var ev = InputEventMouseButton.new()
	ev.button_index = code
	return ev

# Capturar teclas durante o rebind
func _unhandled_input(event: InputEvent):
	if rebinding_action == "":
		return
	if not event.is_pressed():
		return
	if event is InputEventKey or event is InputEventMouseButton:
		if event is InputEventMouseButton:
			if rebinding_button and rebinding_button.get_global_rect().has_point(event.global_position):
				return
		if _is_key_already_bound(event, rebinding_action):
			var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
			if keybind_status_label:
				keybind_status_label.text = GameGlobals.translations[lang_str]["keybinds_duplicate"]
				keybind_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			return
		temp_keybinds[rebinding_action] = [event]
		rebinding_action = ""
		rebinding_button = null
		if keybind_status_label:
			keybind_status_label.text = ""
		_update_options_labels()
		get_viewport().set_input_as_handled()

func _connect_button_sounds(node: Node):
	if not node:
		return
	if node is Button:
		# Centraliza o pivot para a animação de hover
		node.pivot_offset = node.size / 2
		if GameGlobals:
			if not node.pressed.is_connected(GameGlobals.play_click_sound):
				node.pressed.connect(GameGlobals.play_click_sound)
			if not node.mouse_entered.is_connected(GameGlobals.play_hover_sound):
				node.mouse_entered.connect(GameGlobals.play_hover_sound)
		
		# Animação Scale Hover
		if not node.mouse_entered.is_connected(_on_btn_hover.bind(node)):
			node.mouse_entered.connect(_on_btn_hover.bind(node))
		if not node.mouse_exited.is_connected(_on_btn_unhover.bind(node)):
			node.mouse_exited.connect(_on_btn_unhover.bind(node))

	for child in node.get_children():
		_connect_button_sounds(child)

func _on_btn_hover(btn: Button):
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE)

func _on_btn_unhover(btn: Button):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
