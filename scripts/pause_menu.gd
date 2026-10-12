extends CanvasLayer
class_name PauseMenu

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
var rebinding_slot: int = 0
var rebinding_button: Button = null
var rebinding_just_started: bool = false
var keybind_info_label: Label = null

# Temp vars for unapplied settings
var temp_keystroke_enabled: bool = true
var temp_language: int = 0
var temp_resolution_index: int = 3
var temp_keybinds: Dictionary = {}
var keybinds_modified: bool = false

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
	# Inserir entre o ResumeButton e o MenuButton
	vbox.add_child(opt_btn)
	vbox.move_child(opt_btn, 1) # Posição 1 = entre Resume (0) e Menu (2)
	opt_btn.pressed.connect(_on_options_pressed)
	# Aplicar estilo RPG premium
	_style_menu_button(opt_btn, _load_font(false))

func _get_current_book() -> int:
	var scene = get_tree().current_scene
	if scene:
		var path = scene.scene_file_path.to_lower()
		var sname = scene.name.to_lower()
		if "apolo" in path or "gamelevel" in sname or "python" in path: return 1
		elif "shiva" in path or "rhythm" in path or "rhythm" in sname: return 2
		elif "thor" in path or "battle" in sname or "thormap" in sname or "jormungandr" in path: return 3
		elif "susanoo" in path or "orochi" in path or "susanoo" in sname: return 4
		elif "gilgamesh" in path or "gilgamesh" in sname: return 5
	if GameGlobals and GameGlobals.current_book > 0:
		return GameGlobals.current_book
	return 1

func _input(event):
	if rebinding_action != "":
		_handle_rebinding_input(event)
		return

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
	if GameGlobals and GameGlobals.thor_run_active:
		_show_thor_quit_confirmation()
	else:
		get_tree().paused = false
		SceneTransition.fade_to("res://scenes/main_menu.tscn")
		queue_free()

func _show_thor_quit_confirmation():
	var is_pt = (GameGlobals.current_language == GameGlobals.Language.PT) if GameGlobals else true
	
	var quit_overlay = ColorRect.new()
	quit_overlay.name = "ThorQuitOverlay"
	quit_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	quit_overlay.color = Color(0, 0, 0, 0.6)
	quit_overlay.z_index = 30
	quit_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(quit_overlay)
	
	var c_size = Vector2(400, 280)
	var c_panel = Panel.new()
	c_panel.name = "ConfirmationPanel"
	c_panel.size = c_size
	c_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var vp = get_viewport().get_visible_rect().size
	c_panel.position = (vp - c_size) / 2
	
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.08, 0.05, 0.03, 0.98) # Castanho escuro rústico
	c_style.border_width_left   = 2
	c_style.border_width_top    = 3
	c_style.border_width_right  = 2
	c_style.border_width_bottom = 2
	c_style.border_color = Color(0.85, 0.65, 0.25, 1.0) # Dourado
	c_style.corner_radius_top_left     = 6
	c_style.corner_radius_top_right    = 6
	c_style.corner_radius_bottom_left  = 6
	c_style.corner_radius_bottom_right = 6
	c_style.shadow_size = 20
	c_style.shadow_color = Color(0, 0, 0, 0.8)
	c_panel.add_theme_stylebox_override("panel", c_style)
	quit_overlay.add_child(c_panel)
	
	# Adiciona textura de pedra
	_add_stone_texture(c_panel)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_vbox.offset_left = 20
	content_vbox.offset_top = 20
	content_vbox.offset_right = -20
	content_vbox.offset_bottom = -20
	content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_theme_constant_override("separation", 14)
	c_panel.add_child(content_vbox)
	
	var f_bold = _load_font(true)
	var f_reg = _load_font(false)
	
	# Título
	var t_lbl = Label.new()
	t_lbl.text = "SAIR DA JORNADA" if is_pt else "LEAVE JOURNEY"
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if f_bold: t_lbl.add_theme_font_override("font", f_bold)
	t_lbl.add_theme_font_size_override("font_size", 16)
	t_lbl.add_theme_color_override("font_color", Color(0.96, 0.80, 0.35, 1.0))
	content_vbox.add_child(t_lbl)
	
	# Descrição
	var d_lbl = Label.new()
	d_lbl.text = "Como deseja sair da lenda de Thor?" if is_pt else "How do you want to leave Thor's legend?"
	d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if f_reg: d_lbl.add_theme_font_override("font", f_reg)
	d_lbl.add_theme_font_size_override("font_size", 11)
	d_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	content_vbox.add_child(d_lbl)
	
	# Botão 1: Salvar e Sair
	var btn_save = Button.new()
	btn_save.text = "Salvar e Sair" if is_pt else "Save and Exit"
	_style_quit_button(btn_save, Color(0.3, 0.8, 0.4), f_bold)
	btn_save.pressed.connect(func():
		if GameGlobals:
			GameGlobals.play_click_sound()
			GameGlobals.save_settings()
		get_tree().paused = false
		SceneTransition.fade_to("res://scenes/main_menu.tscn")
		queue_free()
	)
	content_vbox.add_child(btn_save)
	
	# Botão 2: Abandonar Run (Resetar)
	var btn_reset = Button.new()
	btn_reset.text = "Abandonar Run (Resetar)" if is_pt else "Abandon Run (Reset)"
	_style_quit_button(btn_reset, Color(0.9, 0.3, 0.3), f_bold)
	btn_reset.pressed.connect(func():
		if GameGlobals:
			GameGlobals.play_click_sound()
			GameGlobals.thor_run_active = false
			GameGlobals.thor_hp = 80
			GameGlobals.thor_max_hp = 80
			GameGlobals.thor_gold = 0
			GameGlobals.thor_deck = []
			GameGlobals.thor_relics = []
			GameGlobals.thor_act = 1
			GameGlobals.thor_current_layer = 1
			GameGlobals.thor_map_path = []
			GameGlobals.thor_map_data = {}
			GameGlobals.thor_node_id = ""
			GameGlobals.thor_intro_played = false
		get_tree().paused = false
		SceneTransition.fade_to("res://scenes/main_menu.tscn")
		queue_free()
	)
	content_vbox.add_child(btn_reset)
	
	# Botão 3: Cancelar
	var btn_cancel = Button.new()
	btn_cancel.text = "Cancelar" if is_pt else "Cancel"
	_style_quit_button(btn_cancel, Color(0.6, 0.6, 0.6), f_bold)
	btn_cancel.pressed.connect(func():
		if GameGlobals:
			GameGlobals.play_click_sound()
		quit_overlay.queue_free()
	)
	content_vbox.add_child(btn_cancel)
	
	btn_save.grab_focus()
	_connect_button_sounds(quit_overlay)

func _style_quit_button(btn: Button, color: Color, font: FontFile):
	btn.custom_minimum_size = Vector2(280, 36)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 11)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	sb.border_width_left   = 1
	sb.border_width_top    = 1
	sb.border_width_right  = 1
	sb.border_width_bottom = 1
	sb.border_color = color.darkened(0.3)
	sb.corner_radius_top_left     = 5
	sb.corner_radius_top_right    = 5
	sb.corner_radius_bottom_left  = 5
	sb.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_h = sb.duplicate()
	sb_h.bg_color = Color(0.15, 0.12, 0.1, 0.95)
	sb_h.border_color = color
	btn.add_theme_stylebox_override("hover", sb_h)
	
	var sb_p = sb.duplicate()
	sb_p.bg_color = Color(0.06, 0.04, 0.03, 0.95)
	sb_p.border_color = color.darkened(0.5)
	btn.add_theme_stylebox_override("pressed", sb_p)

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
	keybinds_modified = false
	temp_keybinds = {}
	
	var use_controller = (GameGlobals.current_hardware == GameGlobals.InputHardware.CONTROLLER)
	
	for action in GameGlobals.CUSTOMIZABLE_ACTIONS:
		temp_keybinds[action] = []
		var events_loaded = 0
		for ev in InputMap.action_get_events(action):
			if use_controller:
				if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
					temp_keybinds[action].append(ev.duplicate(true))
					events_loaded += 1
					if events_loaded >= 1:
						break
			else:
				if ev is InputEventKey or ev is InputEventMouseButton:
					temp_keybinds[action].append(ev.duplicate(true))
					events_loaded += 1
					if action in ["rhythm_lane_0", "rhythm_lane_1", "rhythm_lane_2", "rhythm_lane_3"]:
						if events_loaded >= 2:
							break
					else:
						if events_loaded >= 1:
							break
	for action in GameGlobals.CUSTOMIZABLE_ACTIONS:
		temp_keybinds[action] = []
		for ev in InputMap.action_get_events(action):
			# Incluir todos os tipos de eventos relevantes
			if ev is InputEventKey or ev is InputEventMouseButton or ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				temp_keybinds[action].append(ev.duplicate(true))
				if temp_keybinds[action].size() >= 2:
					break
	
	_create_options_overlay()
	if options_overlay:
		options_overlay.show()
		var vp_size = get_viewport().get_visible_rect().size
		options_panel.position = (vp_size - options_panel.size) / 2
		# Inicializa no menu de opções principal
		keybinds_vbox.hide()
		main_options_vbox.show()
		_update_options_labels()
		
		# Forçar foco no primeiro botão para permitir navegação com comando/teclado
		var opt_btn = main_options_vbox.get_node_or_null("KeystrokeButton")
		if opt_btn:
			opt_btn.grab_focus()

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
	var panel_size = Vector2(470, 480)
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
	scroll.custom_minimum_size = Vector2(0, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	keybinds_vbox.add_child(scroll)
	
	keybinds_grid = GridContainer.new()
	keybinds_grid.columns = 3
	keybinds_grid.add_theme_constant_override("h_separation", 14)
	keybinds_grid.add_theme_constant_override("v_separation", 6)
	keybinds_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(keybinds_grid)
	
	keybind_info_label = Label.new()
	keybind_info_label.name = "KeybindInfoLabel"
	keybind_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keybind_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	keybind_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keybind_info_label.add_theme_font_size_override("font_size", 12)
	keybind_info_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))
	keybind_info_label.visible = false
	keybind_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keybind_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	keybinds_vbox.add_child(keybind_info_label)
	
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
	
	var book_id = _get_current_book()
	if book_id == 3:
		if keybind_info_label:
			keybind_info_label.text = GameGlobals.translations[lang_str]["keybinds_book3_info"]
			keybind_info_label.show()
	elif book_id == 5:
		if keybind_info_label:
			keybind_info_label.text = GameGlobals.translations[lang_str]["keybinds_book5_info"]
			keybind_info_label.show()
	else:
		if keybind_info_label:
			keybind_info_label.hide()
		var h_act = keybinds_grid.get_node_or_null("Header_Action")
		if h_act: h_act.text = GameGlobals.translations[lang_str]["keybinds_title"]
		var h_p = keybinds_grid.get_node_or_null("Header_Primary")
		if h_p: h_p.text = GameGlobals.translations[lang_str]["keybinds_slot_primary"]
		var h_e = keybinds_grid.get_node_or_null("Header_Extra")
		if h_e: h_e.text = GameGlobals.translations[lang_str]["keybinds_slot_extra"]
		for action in GameGlobals.BOOK_ACTIONS.get(book_id, []):
			var lbl = keybinds_grid.get_node_or_null(action + "_Label")
			if lbl:
				lbl.text = GameGlobals.translations[lang_str].get("keybinds_" + action, action)
			var btn0 = keybinds_grid.get_node_or_null(action + "_Slot0_Button")
			if btn0:
				if rebinding_action == action and rebinding_slot == 0:
					btn0.text = GameGlobals.translations[lang_str]["keybinds_press_any_key"]
				else:
					btn0.text = _get_slot_key_text(action, 0)
			var btn1 = keybinds_grid.get_node_or_null(action + "_Slot1_Button")
			if btn1:
				if rebinding_action == action and rebinding_slot == 1:
					btn1.text = GameGlobals.translations[lang_str]["keybinds_press_any_key"]
				else:
					btn1.text = _get_slot_key_text(action, 1)
	
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

func _populate_keybinds_grid():
	if not keybinds_grid:
		return
	for child in keybinds_grid.get_children():
		child.queue_free()
	
	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	var book_id = _get_current_book()
	var actions = GameGlobals.BOOK_ACTIONS.get(book_id, [])

	if book_id == 3:
		if keybind_info_label:
			keybind_info_label.text = GameGlobals.translations[lang_str]["keybinds_book3_info"]
			keybind_info_label.show()
		return
	elif book_id == 5:
		if keybind_info_label:
			keybind_info_label.text = GameGlobals.translations[lang_str]["keybinds_book5_info"]
			keybind_info_label.show()
		return
	else:
		if keybind_info_label:
			keybind_info_label.hide()

	# Headers
	var h_act = Label.new()
	h_act.name = "Header_Action"
	h_act.text = GameGlobals.translations[lang_str]["keybinds_title"]
	h_act.add_theme_font_size_override("font_size", 12)
	h_act.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3, 1.0))
	h_act.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keybinds_grid.add_child(h_act)

	var h_p = Label.new()
	h_p.name = "Header_Primary"
	h_p.text = GameGlobals.translations[lang_str]["keybinds_slot_primary"]
	h_p.add_theme_font_size_override("font_size", 12)
	h_p.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3, 1.0))
	h_p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keybinds_grid.add_child(h_p)

	var h_e = Label.new()
	h_e.name = "Header_Extra"
	h_e.text = GameGlobals.translations[lang_str]["keybinds_slot_extra"]
	h_e.add_theme_font_size_override("font_size", 12)
	h_e.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3, 1.0))
	h_e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keybinds_grid.add_child(h_e)

	for action in actions:
		var lbl = Label.new()
		lbl.name = action + "_Label"
		lbl.text = GameGlobals.translations[lang_str].get("keybinds_" + action, action)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 1.0))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		keybinds_grid.add_child(lbl)

		var btn0 = Button.new()
		btn0.name = action + "_Slot0_Button"
		btn0.custom_minimum_size = Vector2(85, 24)
		btn0.add_theme_font_size_override("font_size", 12)
		btn0.add_theme_constant_override("content_margin_left", 0)
		btn0.add_theme_constant_override("content_margin_right", 0)
		btn0.pressed.connect(func(): _on_keybind_slot_pressed(action, 0, btn0))
		keybinds_grid.add_child(btn0)

		var btn1 = Button.new()
		btn1.name = action + "_Slot1_Button"
		btn1.custom_minimum_size = Vector2(85, 24)
		btn1.add_theme_font_size_override("font_size", 12)
		btn1.add_theme_constant_override("content_margin_left", 0)
		btn1.add_theme_constant_override("content_margin_right", 0)
		btn1.pressed.connect(func(): _on_keybind_slot_pressed(action, 1, btn1))
		keybinds_grid.add_child(btn1)

	_connect_button_sounds(keybinds_grid)

func _on_keybinds_menu_pressed():
	main_options_vbox.hide()
	keybinds_vbox.show()
	_populate_keybinds_grid()
	_update_options_labels()
	
	# Focar no botão "Voltar" do submenu de keybinds para controlo simples
	var kb_back = keybinds_vbox.get_node_or_null("KeybindsBackButton")
	if kb_back:
		kb_back.grab_focus()

func _on_keybinds_back_pressed():
	rebinding_action = ""
	rebinding_slot = 0
	rebinding_button = null
	if keybind_status_label:
		keybind_status_label.text = ""
	keybinds_vbox.hide()
	main_options_vbox.show()
	_update_options_labels()
	
	# Devolver foco ao botão do menu de opções
	var kb_btn = main_options_vbox.get_node_or_null("KeybindsMenuButton")
	if kb_btn:
		kb_btn.grab_focus()

func _on_audio_menu_pressed():
	main_options_vbox.hide()
	audio_vbox.show()
	_update_options_labels()
	
	# Focar no botão "Voltar" do submenu de áudio
	var a_back = audio_vbox.get_node_or_null("AudioBackButton")
	if a_back:
		a_back.grab_focus()

func _on_audio_back_pressed():
	audio_vbox.hide()
	main_options_vbox.show()
	_update_options_labels()
	
	# Devolver foco ao botão do menu de opções
	var a_btn = main_options_vbox.get_node_or_null("AudioMenuButton")
	if a_btn:
		a_btn.grab_focus()

func _on_keybinds_reset_pressed():
	var book_id = _get_current_book()
	match book_id:
		1:
			temp_keybinds["move_left"]  = [_create_key_event(KEY_A)]
			temp_keybinds["move_right"] = [_create_key_event(KEY_D)]
			temp_keybinds["jump"]       = [_create_key_event(KEY_SPACE)]
			temp_keybinds["shoot"]      = [_create_mouse_event(MOUSE_BUTTON_LEFT)]
			temp_keybinds["dash"]       = [_create_key_event(KEY_SHIFT)]
		2:
			temp_keybinds["rhythm_lane_0"] = [_create_key_event(KEY_A)]
			temp_keybinds["rhythm_lane_1"] = [_create_key_event(KEY_S)]
			temp_keybinds["rhythm_lane_2"] = [_create_key_event(KEY_W)]
			temp_keybinds["rhythm_lane_3"] = [_create_key_event(KEY_D)]
		4:
			temp_keybinds["move_left"]         = [_create_key_event(KEY_A)]
			temp_keybinds["move_right"]        = [_create_key_event(KEY_D)]
			temp_keybinds["move_up"]           = [_create_key_event(KEY_W)]
			temp_keybinds["move_down"]         = [_create_key_event(KEY_S)]
			temp_keybinds["ui_susanoo_place"]  = [_create_key_event(KEY_E)]
		5:
			# Livro V não tem controlos customizáveis, apenas rato e QTEs
			# Deixar vazio para usar valores padrão do sistema
			pass
	if keybind_status_label:
		keybind_status_label.text = ""
	_update_options_labels()

func _on_keybind_slot_pressed(action: String, slot: int, btn: Button):
	# Se já estiver a fazer rebinding da mesma ação e slot, não fazer nada
	if rebinding_action == action and rebinding_slot == slot:
		return
	
	if rebinding_action != "":
		rebinding_action = ""
		rebinding_slot = 0
		rebinding_button = null
		_update_options_labels()
	rebinding_action = action
	rebinding_slot = slot
	rebinding_button = btn
	rebinding_just_started = true
	get_tree().process_frame.connect(func(): rebinding_just_started = false, CONNECT_ONE_SHOT)
	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	var use_controller = (GameGlobals.current_hardware == GameGlobals.InputHardware.CONTROLLER)
	if use_controller:
		btn.text = "Pressiona botão..." if lang_str == "PT" else "Press button..."
	else:
		btn.text = GameGlobals.translations[lang_str]["keybinds_press_any_key"]
	if keybind_status_label:
		keybind_status_label.text = GameGlobals.translations[lang_str]["keybinds_clear_hint"]
		keybind_status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.4))

func _events_match(e1: InputEvent, e2: InputEvent) -> bool:
	if e1 == null or e2 == null:
		return false
	if e1 is InputEventKey and e2 is InputEventKey:
		var k1 = e1.physical_keycode if e1.physical_keycode != 0 else e1.keycode
		var k2 = e2.physical_keycode if e2.physical_keycode != 0 else e2.keycode
		return k1 == k2
	elif e1 is InputEventMouseButton and e2 is InputEventMouseButton:
		return e1.button_index == e2.button_index
	elif e1 is InputEventJoypadButton and e2 is InputEventJoypadButton:
		return e1.button_index == e2.button_index
	elif e1 is InputEventJoypadMotion and e2 is InputEventJoypadMotion:
		return e1.axis == e2.axis and e1.axis_value == e2.axis_value
	return false

func _is_key_already_bound(new_event: InputEvent, exclude_action: String, book_id: int) -> bool:
	var book_actions = GameGlobals.BOOK_ACTIONS.get(book_id, [])
	for action in book_actions:
		if action == exclude_action:
			continue
		var events = temp_keybinds.get(action, [])
		for ev in events:
			if _events_match(new_event, ev):
				return true
	return false

func _get_slot_key_text(action: String, slot: int) -> String:
	var events = temp_keybinds.get(action, [])
	if slot >= events.size() or events[slot] == null:
		return "---"
	return _get_event_name(events[slot])

func _get_event_name(event: InputEvent) -> String:
	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	var use_controller = (GameGlobals.current_hardware == GameGlobals.InputHardware.CONTROLLER)
	
	# Filtrar eventos baseado no hardware atual
	if use_controller:
		if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			return "---"
	else:
		if not (event is InputEventKey or event is InputEventMouseButton):
			return "---"
	
	if event is InputEventKey:
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		match code:
			KEY_SPACE: return "ESPAÇO" if lang_str == "PT" else "SPACE"
			KEY_SHIFT: return "SHIFT"
			KEY_LEFT: return "◀"
			KEY_RIGHT: return "▶"
			KEY_UP: return "▲"
			KEY_DOWN: return "▼"
			KEY_ENTER: return "ENTER"
			_: return OS.get_keycode_string(code)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:   return "LMB" if lang_str == "EN" else "Botão Esq."
			MOUSE_BUTTON_RIGHT:  return "RMB" if lang_str == "EN" else "Botão Dir."
			MOUSE_BUTTON_MIDDLE: return "MMB" if lang_str == "EN" else "Botão Meio"
			_: return "Mouse " + str(event.button_index)
	elif event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_A: return "Botão A" if lang_str == "PT" else "Button A"
			JOY_BUTTON_B: return "Botão B" if lang_str == "PT" else "Button B"
			JOY_BUTTON_X: return "Botão X" if lang_str == "PT" else "Button X"
			JOY_BUTTON_Y: return "Botão Y" if lang_str == "PT" else "Button Y"
			JOY_BUTTON_DPAD_LEFT: return "◀"
			JOY_BUTTON_DPAD_RIGHT: return "▶"
			JOY_BUTTON_DPAD_UP: return "▲"
			JOY_BUTTON_DPAD_DOWN: return "▼"
			JOY_BUTTON_LEFT_SHOULDER: return "L1"
			JOY_BUTTON_RIGHT_SHOULDER: return "R1"
			_: return "Button " + str(event.button_index)
	elif event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_LEFT_X:
				if event.axis_value < -0.5: return "◀"
				elif event.axis_value > 0.5: return "▶"
			JOY_AXIS_LEFT_Y:
				if event.axis_value < -0.5: return "▲"
				elif event.axis_value > 0.5: return "▼"
	return "---"

func _on_apply_pressed():
	GameGlobals.keystroke_enabled = temp_keystroke_enabled
	GameGlobals.current_language  = temp_language
	GameGlobals.master_volume = temp_master_volume
	GameGlobals.music_volume = temp_music_volume
	GameGlobals.sfx_volume = temp_sfx_volume
	GameGlobals.apply_resolution(temp_resolution_index)
	for action in temp_keybinds:
		var keep_events = []
		for ev in InputMap.action_get_events(action):
			if not (ev is InputEventKey or ev is InputEventMouseButton):
				keep_events.append(ev)
		InputMap.action_erase_events(action)
		for ev in temp_keybinds[action]:
			if ev != null:
				InputMap.action_add_event(action, ev)
		for ev in keep_events:
			InputMap.action_add_event(action, ev)
	
	# Reset flag de keybinds modificados
	keybinds_modified = false
	
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
	if keybinds_modified: return true
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

func _create_joy_button_event(code: int) -> InputEventJoypadButton:
	var ev = InputEventJoypadButton.new()
	ev.button_index = code
	return ev

# Capturar teclas durante o rebind
func _handle_rebinding_input(event: InputEvent):
	if rebinding_action == "":
		return
	if rebinding_just_started:
		return
	if not event.is_pressed() or event.is_echo():
		return

	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"

	# ESC: Cancela o rebinding sem alterar nada
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		rebinding_action = ""
		rebinding_slot = 0
		rebinding_button = null
		if keybind_status_label:
			keybind_status_label.text = ""
		_update_options_labels()
		get_viewport().set_input_as_handled()
		return

	# DELETE ou BACKSPACE: Limpa a tecla do slot selecionado
	if event is InputEventKey and (event.physical_keycode == KEY_BACKSPACE or event.physical_keycode == KEY_DELETE):
		if temp_keybinds.has(rebinding_action):
			var slots = temp_keybinds[rebinding_action]
			if rebinding_slot == 1 and slots.size() > 1:
				slots.remove_at(1)
			elif rebinding_slot == 0:
				if slots.size() > 1:
					slots.remove_at(0)
				elif slots.size() == 1:
					slots.clear()
		rebinding_action = ""
		rebinding_slot = 0
		rebinding_button = null
		if keybind_status_label:
			keybind_status_label.text = ""
		_update_options_labels()
		get_viewport().set_input_as_handled()
		return

	var use_controller = (GameGlobals.current_hardware == GameGlobals.InputHardware.CONTROLLER)
	
	# Filtrar eventos baseado no hardware atual
	if use_controller:
		if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			return
	else:
		if not (event is InputEventKey or event is InputEventMouseButton):
			return

	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		var book_id = _get_current_book()
		if _is_key_already_bound(event, rebinding_action, book_id):
			if keybind_status_label:
				keybind_status_label.text = GameGlobals.translations[lang_str]["keybinds_duplicate"]
				keybind_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			get_viewport().set_input_as_handled()
			return

		var current_slots = temp_keybinds.get(rebinding_action, [])
		var other_slot = 1 if rebinding_slot == 0 else 0
		if other_slot < current_slots.size() and _events_match(event, current_slots[other_slot]):
			# Mesma tecla já atribuída no outro campo desta ação
			rebinding_action = ""
			rebinding_slot = 0
			rebinding_button = null
			if keybind_status_label:
				keybind_status_label.text = ""
			_update_options_labels()
			get_viewport().set_input_as_handled()
			return

		while temp_keybinds[rebinding_action].size() <= rebinding_slot:
			temp_keybinds[rebinding_action].append(null)
		temp_keybinds[rebinding_action][rebinding_slot] = event

		# Limpar eventuais nulls
		var cleaned = []
		for ev in temp_keybinds[rebinding_action]:
			if ev != null:
				cleaned.append(ev)
		temp_keybinds[rebinding_action] = cleaned
		
		# Marcar que keybinds foram modificados
		keybinds_modified = true

		rebinding_action = ""
		rebinding_slot = 0
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
