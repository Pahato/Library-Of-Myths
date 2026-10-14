extends Control
class_name MainMenu

# Estes @onready só referenciam nós que ainda existem na cena (.tscn).
# Os livros antigos (BookApolo, BookShiva, BookThor, BookSusanoo) foram removidos
# da cena e são agora construídos dinamicamente pelo carrossel em código.
@onready var status_label    = $StatusLabel
@onready var diff_label      = $DifficultyLabel
@onready var diff_easy_btn   = $DiffHBoxContainer/DiffEasyButton
@onready var diff_normal_btn = $DiffHBoxContainer/DiffNormalButton
@onready var diff_hard_btn   = $DiffHBoxContainer/DiffHardButton
@onready var credits_btn     = $CreditsButton

# Referências para animações de fade-in
@onready var title_label     = $TitleLabel
@onready var subtitle_label  = $SubtitleLabel
@onready var diff_hbox       = $DiffHBoxContainer

var player_instance: CharacterBody2D = null

# Opções & Controlos Dinâmicos
var options_overlay: ColorRect = null
var options_panel: Panel = null
var main_options_vbox: VBoxContainer = null
var keybinds_vbox: VBoxContainer = null
var keybinds_grid: GridContainer = null
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
var keybind_status_label: Label = null
var keybind_info_label: Label = null
var keybind_selected_book: int = 1
var keybind_tabs_hbox: HBoxContainer = null
var keybinds_modified: bool = false

# Variáveis temporárias para opções (unapplied changes)
var temp_keystroke_enabled: bool = true
var temp_language: int = 0
var temp_resolution_index: int = 3
var temp_keybinds: Dictionary = {}
var confirmation_overlay: ColorRect = null

# Variáveis do Carrossel de Livros (Redesign)
var carousel_index: int = 0
var carousel_books: Array = []
var carousel_container: Control = null
var carousel_cover: TextureButton = null
var carousel_label: Label = null
var carousel_btn_left: Button = null
var carousel_btn_right: Button = null
var carousel_btn_play: Button = null
var _is_ui_enabled: bool = false
# Proteção contra re-abertura acidental do tutorial no mesmo frame
var _tutorial_is_open: bool = false


func _ready():
	get_tree().paused = false
	# Iniciar a música de menu
	if GameGlobals:
		GameGlobals.play_menu_music()

	# Ocultar o ColorRect antigo se existir
	var old_bg = get_node_or_null("BG")
	if old_bg:
		old_bg.visible = false
	
	# Criar e adicionar o novo fundo TextureRect
	var new_bg = TextureRect.new()
	new_bg.name = "NewBG"
	new_bg.texture = load("res://assets/sprites/Trocas/novo_novoMainMenu.png")
	new_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	new_bg.stretch_mode = TextureRect.STRETCH_SCALE
	new_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	new_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(new_bg)
	move_child(new_bg, 0) # Colocar no fundo

	# Criar o painel de fundo para os títulos de forma dinâmica para melhorar a legibilidade
	var header_bg = Panel.new()
	header_bg.name = "HeaderBG"
	header_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	header_bg.offset_left = -330.0
	header_bg.offset_top = 28.0
	header_bg.offset_right = 330.0
	header_bg.offset_bottom = 142.0
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.03, 0.02, 0.6) # Fundo escuro translúcido premium
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.border_width_bottom = 2
	sb.border_color = Color(0.85, 0.65, 0.25, 0.4)
	header_bg.add_theme_stylebox_override("panel", sb)
	
	add_child(header_bg)
	move_child(header_bg, 1) # Colocar atrás dos labels de texto (TitleLabel e SubtitleLabel)
	header_bg.modulate.a = 0.0

	# Inicialmente esconde a UI para a introdução
	if title_label: title_label.modulate.a = 0.0
	if subtitle_label: subtitle_label.modulate.a = 0.0
	# hbox_container foi removido da cena; não há nada para ocultar aqui
	if diff_label: diff_label.modulate.a = 0.0
	if diff_hbox: diff_hbox.modulate.a = 0.0
	if credits_btn: credits_btn.modulate.a = 0.0
	if status_label: status_label.modulate.a = 0.0
	
	# Aplica a fonte Cinzel ao título principal
	if title_label:
		var cinzel = _load_font(true)
		if cinzel:
			title_label.add_theme_font_override("font", cinzel)
	
	# Setup do carrossel de livros
	_setup_book_carousel()
	
	# Criar Botão de Opções dinamicamente no canto inferior direito
	_create_options_button()
	
	# Desativa cliques nos botões durante a animação
	_set_buttons_enabled(false)
	
	# Mostra a dificuldade atual e inicializa traduções
	update_translations()
	
	# Conectar botões de dificuldade
	if GameGlobals:
		if diff_easy_btn:
			diff_easy_btn.pressed.connect(func():
				GameGlobals.current_difficulty = GameGlobals.Difficulty.EASY
				_update_diff_label()
			)
		if diff_normal_btn:
			diff_normal_btn.pressed.connect(func():
				GameGlobals.current_difficulty = GameGlobals.Difficulty.NORMAL
				_update_diff_label()
			)
		if diff_hard_btn:
			diff_hard_btn.pressed.connect(func():
				GameGlobals.current_difficulty = GameGlobals.Difficulty.HARD
				_update_diff_label()
			)
	else:
		if diff_easy_btn:
			diff_easy_btn.pressed.connect(func(): _show_status("GameGlobals não carregado!"))
		if diff_normal_btn:
			diff_normal_btn.pressed.connect(func(): _show_status("GameGlobals não carregado!"))
		if diff_hard_btn:
			diff_hard_btn.pressed.connect(func(): _show_status("GameGlobals não carregado!"))
	
	# Botão de créditos
	if credits_btn:
		credits_btn.pressed.connect(func():
			var transition = get_node_or_null("/root/SceneTransition")
			if transition:
				transition.fade_to("res://scenes/credits.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/credits.tscn")
		)
	
	# Conectar efeitos de hover (passar o rato por cima) nos botões estáticos da cena
	if diff_easy_btn: _setup_hover_events(diff_easy_btn)
	if diff_normal_btn: _setup_hover_events(diff_normal_btn)
	if diff_hard_btn: _setup_hover_events(diff_hard_btn)
	if credits_btn: _setup_hover_events(credits_btn)
	
	# Cria a cadeira de madeira e o pato (Apolo) de forma dinâmica
	_setup_intro_scene()
	
	# Inicia a sequência de animação
	_run_intro_animation()

func _create_options_button():
	# Criar Botão de Opções
	var options_btn = Button.new()
	options_btn.name = "OptionsButton"
	options_btn.text = GameGlobals.get_text("menu_options")
	options_btn.add_theme_font_size_override("font_size", 12)
	options_btn.custom_minimum_size = Vector2(120, 30)
	
	# Posicionar à esquerda do botão de créditos
	options_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	options_btn.offset_left = -280.0
	options_btn.offset_top = -55.0
	options_btn.offset_right = -160.0
	options_btn.offset_bottom = -25.0
	options_btn.modulate.a = 0.0 # Começa invisível para o fade-in inicial
	
	add_child(options_btn)
	_setup_hover_events(options_btn)
	
	options_btn.pressed.connect(_on_options_pressed)

func _setup_book_carousel():
	# O HBoxContainer original com os livros antigos foi removido da cena.
	# O carrossel é construído inteiramente em código, usando coordenadas
	# absolutas baseadas no viewport para evitar problemas de layout.
	carousel_container = Control.new()
	carousel_container.name = "CarouselContainer"
	carousel_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	carousel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carousel_container.modulate.a = 0.0
	add_child(carousel_container)
	
	# 3. Criar os dados do carrossel com descrições para cada livro
	carousel_books = [
		{
			"id": 1,
			"cover_path": "res://assets/sprites/Trocas/nova_CapaApollo.png",
			"title_key": "menu_book_apolo",
			"desc_pt": "Purifica o solo sagrado de Delfos e derrota a terrível serpente Píton.",
			"desc_en": "Purify the sacred ground of Delphi and defeat the terrible serpent Python.",
			"pressed_func": _on_book_apolo_pressed
		},
		{
			"id": 2,
			"cover_path": "res://assets/sprites/Trocas/nova_CapaShiva.png",
			"title_key": "menu_book_shiva",
			"desc_pt": "Dança o Tandava sob o ritmo do cosmos para acalmar a fúria de Rudra.",
			"desc_en": "Dance the Tandava to the cosmic rhythm to calm the fury of Rudra.",
			"pressed_func": _on_book_shiva_pressed
		},
		{
			"id": 3,
			"cover_path": "res://assets/sprites/Trocas/nova_CapaThor.png",
			"title_key": "menu_book_thor",
			"desc_pt": "Enfrenta a temível Serpente do Mundo e os lobos de Hel no crepúsculo.",
			"desc_en": "Face the fearsome World Serpent and the wolves of Hel at twilight.",
			"pressed_func": _on_book_thor_pressed
		},
		{
			"id": 4,
			"cover_path": "res://assets/sprites/Trocas/nova_CapaSusanoo.png",
			"title_key": "menu_book_susanoo",
			"desc_pt": "Usa astúcia, sake e a lendária espada Totsuka para banir o Orochi.",
			"desc_en": "Use cunning, sake and the legendary Totsuka sword to banish the Orochi.",
			"pressed_func": _on_book_susanoo_pressed
		},
		{
			"id": 5,
			"cover_path": "res://assets/sprites/Trocas/nova_CapaGilgamesh.png",
			"title_key": "menu_book_gilgamesh",
			"desc_pt": "Defende Uruk do lendário Touro dos Céus enviado pelos deuses.",
			"desc_en": "Defend Uruk from the legendary Bull of Heaven sent by the gods.",
			"pressed_func": _on_book_gilgamesh_pressed
		}
	]
	
	# Dimensões fixas dos elementos do carrossel
	const COVER_W  := 480.0
	const COVER_H  := 300.0
	const ARROW_SZ := 50.0
	const LABEL_H  := 35.0
	const PLAY_H   := 44.0
	
	# Centro real do ecrã — get_viewport_rect().size está disponível em _ready()
	# ao contrário do tamanho do parent Control, que só fica correto após layout.
	var vp   := get_viewport_rect().size
	var cx   := vp.x * 0.5
	var cy   := vp.y * 0.5 - 30.0  # ligeiramente acima do centro
	
	var cover_x := cx - COVER_W * 0.5
	var cover_y := cy - COVER_H * 0.5
	var label_y := cover_y + COVER_H + 10.0
	var play_y  := label_y + LABEL_H + 8.0
	
	# 4. Capa do livro central (TextureButton)
	carousel_cover = TextureButton.new()
	carousel_cover.name = "CarouselCover"
	carousel_cover.custom_minimum_size = Vector2(COVER_W, COVER_H)
	carousel_cover.size = Vector2(COVER_W, COVER_H)
	carousel_cover.position = Vector2(cover_x, cover_y)
	carousel_cover.ignore_texture_size = true
	carousel_cover.stretch_mode = TextureButton.STRETCH_SCALE
	carousel_cover.texture_filter = Control.TEXTURE_FILTER_NEAREST
	# Começa com IGNORE; _set_buttons_enabled(true) activa depois da animação
	carousel_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carousel_container.add_child(carousel_cover)
	carousel_cover.pressed.connect(_on_carousel_cover_pressed)
	
	# Hover effects na capa
	carousel_cover.pivot_offset = Vector2(COVER_W * 0.5, COVER_H * 0.5)
	carousel_cover.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(carousel_cover, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_SINE)
		if GameGlobals: GameGlobals.play_hover_sound()
	)
	carousel_cover.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(carousel_cover, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	)
	
	# 5. Seta Esquerda
	carousel_btn_left = Button.new()
	carousel_btn_left.name = "CarouselLeft"
	carousel_btn_left.text = "◀"
	carousel_btn_left.add_theme_font_size_override("font_size", 28)
	carousel_btn_left.custom_minimum_size = Vector2(ARROW_SZ, ARROW_SZ)
	carousel_btn_left.size = Vector2(ARROW_SZ, ARROW_SZ)
	carousel_btn_left.position = Vector2(cover_x - 70.0, cover_y + (COVER_H - ARROW_SZ) * 0.5)
	carousel_btn_left.flat = true
	carousel_btn_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carousel_btn_left.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6, 1.0))
	carousel_btn_left.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.4, 1.0))
	carousel_container.add_child(carousel_btn_left)
	carousel_btn_left.pressed.connect(func(): _navigate_carousel(-1))
	_setup_hover_events(carousel_btn_left)
	
	# 6. Seta Direita
	carousel_btn_right = Button.new()
	carousel_btn_right.name = "CarouselRight"
	carousel_btn_right.text = "▶"
	carousel_btn_right.add_theme_font_size_override("font_size", 28)
	carousel_btn_right.custom_minimum_size = Vector2(ARROW_SZ, ARROW_SZ)
	carousel_btn_right.size = Vector2(ARROW_SZ, ARROW_SZ)
	carousel_btn_right.position = Vector2(cover_x + COVER_W + 20.0, cover_y + (COVER_H - ARROW_SZ) * 0.5)
	carousel_btn_right.flat = true
	carousel_btn_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carousel_btn_right.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6, 1.0))
	carousel_btn_right.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.4, 1.0))
	carousel_container.add_child(carousel_btn_right)
	carousel_btn_right.pressed.connect(func(): _navigate_carousel(1))
	_setup_hover_events(carousel_btn_right)
	
	# 7. Label do Título do Livro
	carousel_label = Label.new()
	carousel_label.name = "CarouselLabel"
	carousel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carousel_label.add_theme_font_size_override("font_size", 18)
	carousel_label.add_theme_color_override("font_color", Color(0.96, 0.87, 0.70, 1.0))
	carousel_label.position = Vector2(cx - 400.0, label_y)
	carousel_label.size = Vector2(800.0, LABEL_H)
	carousel_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cinzel = _load_font(true)
	if cinzel:
		carousel_label.add_theme_font_override("font", cinzel)
	carousel_container.add_child(carousel_label)
	
	# 8. Botão "JOGAR"
	carousel_btn_play = Button.new()
	carousel_btn_play.name = "CarouselPlay"
	carousel_btn_play.custom_minimum_size = Vector2(180.0, PLAY_H)
	carousel_btn_play.size = Vector2(180.0, PLAY_H)
	carousel_btn_play.position = Vector2(cx - 90.0, play_y)
	carousel_btn_play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carousel_btn_play.pressed.connect(_on_carousel_cover_pressed)
	carousel_container.add_child(carousel_btn_play)
	_setup_hover_events(carousel_btn_play)
	
	# Inicializar o primeiro item
	_update_carousel_ui()

func _update_carousel_ui():
	if carousel_books.is_empty():
		return
		
	var book_data = carousel_books[carousel_index]
	var cover_tex = load(book_data["cover_path"])
	if cover_tex:
		carousel_cover.texture_normal = cover_tex
		
	carousel_label.text = GameGlobals.get_text(book_data["title_key"])
	
	# Determinar cor de destaque temática por livro
	var accent_color: Color
	match book_data["id"]:
		1: accent_color = Color(1.0, 0.85, 0.25, 1.0)   # Apolo (Dourado solar)
		2: accent_color = Color(0.7, 0.3, 1.0, 1.0)     # Shiva (Roxo cósmico)
		3: accent_color = Color(0.3, 0.6, 1.0, 1.0)     # Thor (Azul elétrico)
		4: accent_color = Color(0.9, 0.15, 0.15, 1.0)   # Susanoo (Vermelho japonês)
		5: accent_color = Color(1.0, 0.75, 0.1, 1.0)    # Gilgamesh (Ouro Babilónia)
		_: accent_color = Color(1.0, 0.85, 0.25, 1.0)
		
	carousel_label.add_theme_color_override("font_color", accent_color)
	
	# Atualizar o título principal com a cor temática correspondente
	if title_label:
		title_label.add_theme_color_override("font_color", accent_color)
		
	# Atualizar o painel de fundo (HeaderBG) com a borda e fundo temáticos
	var header_bg = get_node_or_null("HeaderBG")
	if header_bg:
		var sb = header_bg.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			var new_sb = sb.duplicate() as StyleBoxFlat
			new_sb.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.45)
			new_sb.bg_color = Color(0.04 + accent_color.r * 0.02, 0.03 + accent_color.g * 0.02, 0.02 + accent_color.b * 0.02, 0.62)
			header_bg.add_theme_stylebox_override("panel", new_sb)
	
	# Atualizar o subtítulo dinâmico (descrição e cor do livro selecionado)
	if subtitle_label:
		var is_pt = true
		if GameGlobals:
			is_pt = (GameGlobals.current_language == GameGlobals.Language.PT)
		subtitle_label.text = book_data.get("desc_pt", "") if is_pt else book_data.get("desc_en", "")
		# Cores atenuadas a 85% para excelente hierarquia de texto no ecrã
		subtitle_label.add_theme_color_override("font_color", Color(accent_color.r * 0.9, accent_color.g * 0.9, accent_color.b * 0.9, 0.85))
	
	if carousel_btn_play:
		carousel_btn_play.text = GameGlobals.get_text("tutorial_play")
		
		# Criar StyleBoxes premium personalizados para o botão "JOGAR" correspondendo ao livro ativo
		var sb_normal = StyleBoxFlat.new()
		sb_normal.bg_color = Color(accent_color.r * 0.15, accent_color.g * 0.15, accent_color.b * 0.15, 0.85)
		sb_normal.border_width_left = 2
		sb_normal.border_width_top = 2
		sb_normal.border_width_right = 2
		sb_normal.border_width_bottom = 2
		sb_normal.border_color = accent_color
		sb_normal.corner_radius_top_left = 6
		sb_normal.corner_radius_top_right = 6
		sb_normal.corner_radius_bottom_left = 6
		sb_normal.corner_radius_bottom_right = 6
		
		var sb_hover = sb_normal.duplicate()
		sb_hover.bg_color = Color(accent_color.r * 0.25, accent_color.g * 0.25, accent_color.b * 0.25, 0.95)
		sb_hover.border_color = accent_color.lightened(0.2)
		
		var sb_pressed = sb_normal.duplicate()
		sb_pressed.bg_color = Color(accent_color.r * 0.08, accent_color.g * 0.08, accent_color.b * 0.08, 0.9)
		sb_pressed.border_color = accent_color.darkened(0.2)
		
		carousel_btn_play.add_theme_stylebox_override("normal", sb_normal)
		carousel_btn_play.add_theme_stylebox_override("hover", sb_hover)
		carousel_btn_play.add_theme_stylebox_override("pressed", sb_pressed)
		carousel_btn_play.add_theme_color_override("font_color", Color.WHITE)
		carousel_btn_play.add_theme_color_override("font_hover_color", Color.WHITE)
		
		var cinzel = _load_font(true)
		if cinzel:
			carousel_btn_play.add_theme_font_override("font", cinzel)
		carousel_btn_play.add_theme_font_size_override("font_size", 14)

func _navigate_carousel(direction: int):
	if not _is_ui_enabled:
		return
		
	carousel_index = (carousel_index + direction) % carousel_books.size()
	if carousel_index < 0:
		carousel_index = carousel_books.size() - 1
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(carousel_cover, "modulate:a", 0.0, 0.12)
	tween.tween_property(carousel_label, "modulate:a", 0.0, 0.12)
	if subtitle_label:
		tween.tween_property(subtitle_label, "modulate:a", 0.0, 0.12)
	
	tween.chain().tween_callback(func():
		_update_carousel_ui()
		var fade_in_tween = create_tween().set_parallel(true)
		fade_in_tween.tween_property(carousel_cover, "modulate:a", 1.0, 0.18)
		fade_in_tween.tween_property(carousel_label, "modulate:a", 1.0, 0.18)
		if subtitle_label:
			fade_in_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.18)
	)
	
	if GameGlobals:
		GameGlobals.play_click_sound()

func _on_carousel_cover_pressed():
	if not _is_ui_enabled:
		return
	# Impede re-abertura se o tutorial já está aberto
	if _tutorial_is_open:
		return
	var book_data = carousel_books[carousel_index]
	book_data["pressed_func"].call()

func _setup_intro_scene():
	print("[INTRO DEBUG] A iniciar a montagem da cena de introdução...")
	
	# 2. Instancia o jogador Apolo (Pato)
	var player_scene = load("res://scenes/apolo_python/player.tscn")
	if player_scene:
		player_instance = player_scene.instantiate()
		player_instance.is_cutscene = true
		player_instance.scale = Vector2(4.8, 4.8) # Diminuído para caber perfeitamente na cadeira
		
		# Posição inicial: fora do ecrã à esquerda no chão (Y = 590)
		player_instance.global_position = Vector2(-100, 590)
		add_child(player_instance)

func _run_intro_animation():
	if not player_instance:
		_fade_in_ui()
		return
		
	# Inicia animação de correr
	player_instance.sprite.play("Run")
	
	var tween = create_tween()
	# 1. Caminha pelo chão até à posição anterior à cadeira (X = 220)
	tween.tween_property(player_instance, "global_position:x", 220.0, 1.8).set_trans(Tween.TRANS_SINE)
	
	# 2. Transição de salto parabólico em direção à cadeira
	tween.tween_callback(func():
		player_instance.sprite.play("Idle")
	)
	tween.tween_interval(0.2)
	tween.tween_callback(func():
		var jump_tween = create_tween().set_parallel(true)
		jump_tween.tween_property(player_instance, "global_position:x", 300.0, 0.45)
		
		# Curva vertical do arco de salto
		var y_tween = create_tween()
		y_tween.tween_property(player_instance, "global_position:y", 315.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		y_tween.tween_property(player_instance, "global_position:y", 395.0, 0.23).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		y_tween.tween_callback(func():
			# Conclusão do salto no assento da cadeira
			player_instance.sprite.play("Idle")
		)
	)
	tween.tween_interval(0.8)
	
	# 3. Revela a Biblioteca e os Livros
	tween.tween_callback(func():
		_fade_in_ui()
	)


func _fade_in_ui():
	var fade_tween = create_tween().set_parallel(true)
	
	var header_bg = get_node_or_null("HeaderBG")
	if header_bg:
		fade_tween.tween_property(header_bg, "modulate:a", 1.0, 0.6)
		
	if title_label:
		title_label.position.y -= 20.0 # Começa ligeiramente acima para fazer slide down
		fade_tween.tween_property(title_label, "modulate:a", 1.0, 0.6)
		fade_tween.tween_property(title_label, "position:y", title_label.position.y + 20.0, 0.6).set_trans(Tween.TRANS_SINE)
		
	if subtitle_label:
		fade_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.8)
		
	if carousel_container:
		carousel_container.position.y += 30.0 # Começa abaixo para fazer slide up
		fade_tween.tween_property(carousel_container, "modulate:a", 1.0, 0.8)
		fade_tween.tween_property(carousel_container, "position:y", carousel_container.position.y - 30.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	if diff_label:
		fade_tween.tween_property(diff_label, "modulate:a", 1.0, 0.8)
	if diff_hbox:
		fade_tween.tween_property(diff_hbox, "modulate:a", 1.0, 0.8)
	if credits_btn:
		fade_tween.tween_property(credits_btn, "modulate:a", 1.0, 0.8)
		
	var opt_btn = get_node_or_null("OptionsButton")
	if opt_btn:
		fade_tween.tween_property(opt_btn, "modulate:a", 1.0, 0.8)
		
	fade_tween.chain().tween_callback(func():
		_set_buttons_enabled(true)
	)

func _set_buttons_enabled(enabled: bool):
	_is_ui_enabled = enabled
	var filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if diff_easy_btn: diff_easy_btn.mouse_filter = filter
	if diff_normal_btn: diff_normal_btn.mouse_filter = filter
	if diff_hard_btn: diff_hard_btn.mouse_filter = filter
	if credits_btn: credits_btn.mouse_filter = filter
	
	if carousel_cover: carousel_cover.mouse_filter = filter
	if carousel_btn_left: carousel_btn_left.mouse_filter = filter
	if carousel_btn_right: carousel_btn_right.mouse_filter = filter
	if carousel_btn_play: carousel_btn_play.mouse_filter = filter
	
	var opt_btn = get_node_or_null("OptionsButton")
	if opt_btn: opt_btn.mouse_filter = filter

func _update_diff_label():
	if diff_label:
		if GameGlobals:
			diff_label.text = GameGlobals.get_text("menu_diff_label") + GameGlobals.get_difficulty_label()
		else:
			diff_label.text = "Dificuldade: Normal"

func _setup_hover_events(button: Button):
	if not button:
		return
	button.pivot_offset = button.size / 2
	
	if GameGlobals:
		if not button.mouse_entered.is_connected(GameGlobals.play_hover_sound):
			button.mouse_entered.connect(GameGlobals.play_hover_sound)
		if not button.pressed.is_connected(GameGlobals.play_click_sound):
			button.pressed.connect(GameGlobals.play_click_sound)
	
	button.mouse_entered.connect(func():
		button.pivot_offset = button.size / 2
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE)
	)
	button.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	)

func _style_menu_button(btn: Button, font = null):
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.92, 0.85, 0.70, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.6, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	
	var sb_normal = StyleBoxFlat.new()
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

func _on_book_apolo_pressed():
	_show_tutorial(1, "res://scenes/apolo_python/game.tscn")

func _on_book_shiva_pressed():
	_show_tutorial(2, "res://scenes/shiva_rudra/rhythm_game.tscn")

func _on_book_thor_pressed():
	_show_tutorial(3, "res://scenes/thor_jormungandr/thor_map.tscn")

func _on_book_susanoo_pressed():
	_show_tutorial(4, "res://scenes/susanoo_orochi/susanoo_scene.tscn")

func _on_book_gilgamesh_pressed():
	_show_tutorial(5, "res://scenes/gilgamesh_qte/gilgamesh_scene.tscn")

func _show_tutorial(book: int, scene: String):
	# Evita abrir dois tutoriais ao mesmo tempo
	if _tutorial_is_open:
		return
	_tutorial_is_open = true
	
	if GameGlobals:
		GameGlobals.current_book = book
	
	var tutorial_scene = load("res://scenes/tutorial_screen.tscn")
	if not tutorial_scene:
		_tutorial_is_open = false
		var transition = get_node_or_null("/root/SceneTransition")
		if transition:
			transition.fade_to(scene)
		else:
			get_tree().change_scene_to_file(scene)
		return
	
	var tutorial = tutorial_scene.instantiate()
	tutorial.book_type = book
	tutorial._scene_to_load = scene
	add_child(tutorial)
	# Repor a flag quando o tutorial for removido da árvore
	tutorial.tree_exited.connect(func(): _tutorial_is_open = false)


func _show_status(text: String):
	if status_label:
		status_label.text = text
		status_label.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_property(status_label, "modulate:a", 0.0, 1.5).set_delay(1.0)

func _load_transparent_texture(path: String) -> Texture2D:
	print("[INTRO DEBUG] A tentar carregar textura: ", path)
	var image: Image = null
	
	image = Image.load_from_file(path)
	if image:
		print("[INTRO DEBUG] Sucesso: Carregado diretamente do disco via load_from_file. Tamanho: ", image.get_size())
	else:
		print("[INTRO DEBUG] Falha no load_from_file. A tentar usar o load() padrão do Godot...")
		var base_texture = load(path)
		if base_texture:
			image = base_texture.get_image()
			print("[INTRO DEBUG] Sucesso: Imagem obtida a partir do load() padrão.")
		else:
			print("[INTRO DEBUG] ERRO CRÍTICO: Não foi possível ler a imagem por nenhuma via.")
			return null
			
	image.convert(Image.FORMAT_RGBA8)
			
	var magenta_pixels_count = 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color = image.get_pixel(x, y)
			if color.r > 0.85 and color.g < 0.15 and color.b > 0.85:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				magenta_pixels_count += 1
				
	print("[INTRO DEBUG] Concluído. Pixéis magenta convertidos para transparente: ", magenta_pixels_count)
	return ImageTexture.create_from_image(image)

# -----------------------------------------------------------------------------
# LÓGICA DO MENU DE OPÇÕES (PROGRAMÁTICO & PREMIUM)
# -----------------------------------------------------------------------------

# --- Adiciona textura de pedra como fundo de um painel ---
func _add_stone_texture(panel: Panel) -> void:
	var tex_path = "res://assets/ui/stone_panel_bg.png"
	var texture = load(tex_path) as Texture2D
	if not texture:
		return
	var tex_rect = TextureRect.new()
	tex_rect.name = "StoneBg"
	tex_rect.texture = texture
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.modulate = Color(1.0, 1.0, 1.0, 0.18) # 18% opacidade: visivel mas subtil
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.show_behind_parent = false
	panel.add_child(tex_rect)
	# Mover para o primeiro filho (atras de tudo)
	panel.move_child(tex_rect, 0)

# --- Carregamento da fonte Cinzel ---
func _load_font(bold: bool = false) -> FontFile:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	return load(path) as FontFile

func _on_options_pressed():
	# Inicializar as variáveis temporárias com as opções atuais
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
			# Se usar comando, só carregar eventos de comando
			# Se usar teclado, só carregar eventos de teclado/mouse
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
					# Livro 2 (ritmo) pode ter 2 slots preenchidos no teclado
					if action in ["rhythm_lane_0", "rhythm_lane_1", "rhythm_lane_2", "rhythm_lane_3"]:
						if events_loaded >= 2:
							break
					else:
						if events_loaded >= 1:
							break
		
	_create_options_overlay()
	if options_overlay:
		options_overlay.show()
		# Forçar reposicionamento caso o tamanho da janela tenha mudado
		options_panel.position = (size - options_panel.size) / 2
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
		
	# Overlay escuro transparente
	options_overlay = ColorRect.new()
	options_overlay.name = "OptionsOverlay"
	options_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	options_overlay.color = Color(0, 0, 0, 0.6)
	options_overlay.visible = false
	options_overlay.z_index = 10
	
	# ATIVAR FILTRO LINEAR PARA TUDO NO MENU DE OPÇÕES (TEXTO LISO E HD, NÃO BLURRY/PIXELADO)
	options_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	add_child(options_overlay)
	
	# Painel Central — posicionado manualmente (sem PRESET_CENTER para evitar conflito de anchors)
	var panel_size = Vector2(470, 490)
	options_panel = Panel.new()
	options_panel.name = "OptionsPanel"
	options_panel.size = panel_size
	options_panel.set_anchors_preset(Control.PRESET_TOP_LEFT) # Anchors em 0 para posição manual
	var vp = get_viewport_rect().size
	options_panel.position = (vp - panel_size) / 2
	
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
	# Textura de pedra no fundo do painel
	_add_stone_texture(options_panel)
	
	# Título do Painel com fonte Cinzel épica
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
	
	# -------------------- MENU DE OPÇÕES PRINCIPAL --------------------
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
	
	# 1. Botão Keystroke HUD
	var keystroke_btn = Button.new()
	keystroke_btn.name = "KeystrokeButton"
	keystroke_btn.add_theme_font_size_override("font_size", 14)
	keystroke_btn.pressed.connect(_on_keystroke_toggle)
	_setup_hover_events(keystroke_btn)
	main_options_vbox.add_child(keystroke_btn)
	
	# 2. Botão de Idioma
	var lang_btn = Button.new()
	lang_btn.name = "LanguageButton"
	lang_btn.add_theme_font_size_override("font_size", 14)
	lang_btn.pressed.connect(_on_language_toggle)
	_setup_hover_events(lang_btn)
	main_options_vbox.add_child(lang_btn)
	
	# 3. Botão de Resolução / Ecrã
	var resolution_btn = Button.new()
	resolution_btn.name = "ResolutionButton"
	resolution_btn.add_theme_font_size_override("font_size", 14)
	resolution_btn.pressed.connect(_on_resolution_toggle)
	_setup_hover_events(resolution_btn)
	main_options_vbox.add_child(resolution_btn)
	
	# 4. Botão Personalizar Keybinds
	var keybinds_menu_btn = Button.new()
	keybinds_menu_btn.name = "KeybindsMenuButton"
	keybinds_menu_btn.add_theme_font_size_override("font_size", 14)
	keybinds_menu_btn.pressed.connect(_on_keybinds_menu_pressed)
	_setup_hover_events(keybinds_menu_btn)
	main_options_vbox.add_child(keybinds_menu_btn)
	
	# Botão de Áudio
	var audio_menu_btn = Button.new()
	audio_menu_btn.name = "AudioMenuButton"
	audio_menu_btn.add_theme_font_size_override("font_size", 14)
	audio_menu_btn.pressed.connect(_on_audio_menu_pressed)
	_setup_hover_events(audio_menu_btn)
	main_options_vbox.add_child(audio_menu_btn)
	
	# 5. Botão Aplicar
	var apply_btn = Button.new()
	apply_btn.name = "ApplyButton"
	apply_btn.add_theme_font_size_override("font_size", 14)
	apply_btn.pressed.connect(_on_apply_pressed)
	_setup_hover_events(apply_btn)
	main_options_vbox.add_child(apply_btn)
	
	# 6. Botão Voltar
	var back_btn = Button.new()
	back_btn.name = "BackButton"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(_on_back_pressed)
	_setup_hover_events(back_btn)
	main_options_vbox.add_child(back_btn)
	
	# -------------------- SUBMENU DE KEYBINDS --------------------
	keybinds_vbox = VBoxContainer.new()
	keybinds_vbox.name = "KeybindsVBox"
	keybinds_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	keybinds_vbox.offset_top = 45
	keybinds_vbox.offset_bottom = -15
	keybinds_vbox.offset_left = 16
	keybinds_vbox.offset_right = -16
	keybinds_vbox.add_theme_constant_override("separation", 8)
	keybinds_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	keybinds_vbox.visible = false
	options_panel.add_child(keybinds_vbox)
	
	# HBox com abas/seletores dos 5 livros
	keybind_tabs_hbox = HBoxContainer.new()
	keybind_tabs_hbox.name = "KeybindTabsHBox"
	keybind_tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	keybind_tabs_hbox.add_theme_constant_override("separation", 4)
	keybinds_vbox.add_child(keybind_tabs_hbox)
	
	for b_id in range(1, 6):
		var tab_btn = Button.new()
		tab_btn.name = "BookTab_" + str(b_id)
		tab_btn.add_theme_font_size_override("font_size", 10)
		tab_btn.custom_minimum_size = Vector2(78, 26)
		tab_btn.pressed.connect(func(): _on_keybind_tab_selected(b_id))
		_setup_hover_events(tab_btn)
		keybind_tabs_hbox.add_child(tab_btn)
	
	# ScrollContainer para as teclas
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 210)
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
	
	# Mensagem de Estado de Rebinding (Erro/Instrução)
	keybind_status_label = Label.new()
	keybind_status_label.name = "KeybindStatusLabel"
	keybind_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keybind_status_label.add_theme_font_size_override("font_size", 12)
	keybind_status_label.text = ""
	keybinds_vbox.add_child(keybind_status_label)
	
	# Botões na base de keybinds (Restaurar Padrão e Voltar)
	var base_hbox = HBoxContainer.new()
	base_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	base_hbox.add_theme_constant_override("separation", 20)
	keybinds_vbox.add_child(base_hbox)
	
	var reset_btn = Button.new()
	reset_btn.name = "ResetButton"
	reset_btn.add_theme_font_size_override("font_size", 13)
	reset_btn.pressed.connect(_on_keybinds_reset_pressed)
	_setup_hover_events(reset_btn)
	base_hbox.add_child(reset_btn)
	
	var k_back_btn = Button.new()
	k_back_btn.name = "KeybindsBackButton"
	k_back_btn.add_theme_font_size_override("font_size", 13)
	k_back_btn.pressed.connect(_on_keybinds_back_pressed)
	_setup_hover_events(k_back_btn)
	base_hbox.add_child(k_back_btn)
	
	# Inicializar textos com base no idioma atual
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
	_setup_hover_events(audio_back_btn)
	audio_vbox.add_child(audio_back_btn)

func _update_options_labels():
	if not options_overlay:
		return
		
	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	
	var title = options_panel.get_node("TitleLabel")
	if title:
		if keybinds_vbox.visible:
			title.text = GameGlobals.translations["PT"]["keybinds_title"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["keybinds_title"]
		elif audio_vbox and audio_vbox.visible:
			title.text = GameGlobals.translations["PT"]["audio_title"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["audio_title"]
		else:
			title.text = GameGlobals.translations["PT"]["options_title"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["options_title"]
			
	# Botões principais
	var k_btn = main_options_vbox.get_node("KeystrokeButton")
	if k_btn:
		k_btn.text = GameGlobals.translations[lang_str]["options_keystroke_enabled"] if temp_keystroke_enabled else GameGlobals.translations[lang_str]["options_keystroke_disabled"]
		
	var l_btn = main_options_vbox.get_node("LanguageButton")
	if l_btn:
		l_btn.text = GameGlobals.translations["PT"]["options_language"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["options_language"]
		
	var res_btn = main_options_vbox.get_node("ResolutionButton")
	if res_btn:
		var r_opt = GameGlobals.resolution_options[temp_resolution_index]
		var res_text = r_opt["text"]
		lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
		if r_opt["fullscreen"]:
			res_text = GameGlobals.translations[lang_str]["resolution_fullscreen"]
		res_btn.text = GameGlobals.translations[lang_str]["options_resolution"].replace("[TEXT]", res_text)
		
	var kb_btn = main_options_vbox.get_node("KeybindsMenuButton")
	if kb_btn:
		kb_btn.text = GameGlobals.translations["PT"]["options_keybinds"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["options_keybinds"]
		
	var apply_btn = main_options_vbox.get_node("ApplyButton")
	if apply_btn:
		apply_btn.text = GameGlobals.translations["PT"]["options_apply"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["options_apply"]

	var b_btn = main_options_vbox.get_node("BackButton")
	if b_btn:
		b_btn.text = GameGlobals.translations["PT"]["options_back"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["options_back"]
		
	var audio_btn = main_options_vbox.get_node("AudioMenuButton")
	if audio_btn:
		audio_btn.text = GameGlobals.translations["PT"]["options_audio"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["options_audio"]
		
	if audio_vbox:
		lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
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
		
	# Textos do submenu de keybinds
	lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	
	# Atualizar abas dos livros
	if keybind_tabs_hbox:
		for b_id in range(1, 6):
			var tab_btn = keybind_tabs_hbox.get_node_or_null("BookTab_" + str(b_id))
			if tab_btn:
				tab_btn.text = GameGlobals.translations[lang_str]["keybinds_book_" + str(b_id)]
				if b_id == keybind_selected_book:
					tab_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
				else:
					tab_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	
	if keybind_selected_book == 3:
		if keybind_info_label:
			keybind_info_label.text = GameGlobals.translations[lang_str]["keybinds_book3_info"]
			keybind_info_label.show()
	elif keybind_selected_book == 5:
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
		for action in GameGlobals.BOOK_ACTIONS.get(keybind_selected_book, []):
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
				
	var r_btn = keybinds_vbox.find_child("ResetButton", true, false)
	if r_btn:
		r_btn.text = GameGlobals.translations[lang_str]["keybinds_reset"]
		
	var kb_back = keybinds_vbox.find_child("KeybindsBackButton", true, false)
	if kb_back:
		kb_back.text = GameGlobals.translations[lang_str]["options_back"]

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

func _on_keybind_tab_selected(book_id: int):
	keybind_selected_book = book_id
	rebinding_action = ""
	rebinding_slot = 0
	rebinding_button = null
	if keybind_status_label:
		keybind_status_label.text = ""
	# NÃO recarregar keybinds ao mudar de aba - apenas atualizar a UI
	_populate_main_keybinds()
	_update_options_labels()

func _populate_main_keybinds():
	if not keybinds_grid:
		return
	for child in keybinds_grid.get_children():
		child.queue_free()
	
	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	var actions = GameGlobals.BOOK_ACTIONS.get(keybind_selected_book, [])

	if keybind_selected_book == 3:
		if keybind_info_label:
			keybind_info_label.text = GameGlobals.translations[lang_str]["keybinds_book3_info"]
			keybind_info_label.show()
		return
	elif keybind_selected_book == 5:
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
		_setup_hover_events(btn0)
		keybinds_grid.add_child(btn0)

		var btn1 = Button.new()
		btn1.name = action + "_Slot1_Button"
		btn1.custom_minimum_size = Vector2(85, 24)
		btn1.add_theme_font_size_override("font_size", 12)
		btn1.add_theme_constant_override("content_margin_left", 0)
		btn1.add_theme_constant_override("content_margin_right", 0)
		btn1.pressed.connect(func(): _on_keybind_slot_pressed(action, 1, btn1))
		_setup_hover_events(btn1)
		keybinds_grid.add_child(btn1)

func _on_keybinds_menu_pressed():
	main_options_vbox.hide()
	keybinds_vbox.show()
	_populate_main_keybinds()
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
	match keybind_selected_book:
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
			MOUSE_BUTTON_LEFT:
				return "LMB" if lang_str == "EN" else "Botão Esq."
			MOUSE_BUTTON_RIGHT:
				return "RMB" if lang_str == "EN" else "Botão Dir."
			MOUSE_BUTTON_MIDDLE:
				return "MMB" if lang_str == "EN" else "Botão Meio"
			_:
				return "Mouse " + str(event.button_index)
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
	# Aplicar as alterações nas globais
	GameGlobals.keystroke_enabled = temp_keystroke_enabled
	GameGlobals.current_language = temp_language
	GameGlobals.master_volume = temp_master_volume
	GameGlobals.music_volume = temp_music_volume
	GameGlobals.sfx_volume = temp_sfx_volume
	
	# Aplicar a resolução (irá reposicionar e centrar na tela correta sem saltar de monitor)
	GameGlobals.apply_resolution(temp_resolution_index)
	
	# Aplicar os Keybinds no InputMap real mantendo gamepad
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
	
	# Salvar no ficheiro
	GameGlobals.save_settings()
	
	# Atualizar traduções
	update_translations()
	_update_options_labels()
	
	print("[OPTIONS] Todas as alterações foram aplicadas e gravadas!")

func _on_back_pressed():
	# Se existirem alterações pendentes não guardadas, perguntar
	if _has_unsaved_changes():
		_show_confirmation_popup()
	else:
		options_overlay.hide()

func _has_unsaved_changes() -> bool:
	if temp_keystroke_enabled != GameGlobals.keystroke_enabled:
		return true
	if temp_language != GameGlobals.current_language:
		return true
	if temp_resolution_index != GameGlobals.current_resolution_index:
		return true
	if temp_master_volume != GameGlobals.master_volume:
		return true
	if temp_music_volume != GameGlobals.music_volume:
		return true
	if temp_sfx_volume != GameGlobals.sfx_volume:
		return true
	
	# Verificar se keybinds foram modificados
	if keybinds_modified:
		return true
	
	return false

func _show_confirmation_popup():
	if confirmation_overlay:
		confirmation_overlay.show()
		_update_confirmation_popup_labels()
		return
		
	# Criar o popup de confirmação
	confirmation_overlay = ColorRect.new()
	confirmation_overlay.name = "ConfirmationOverlay"
	confirmation_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirmation_overlay.color = Color(0, 0, 0, 0.45)
	confirmation_overlay.z_index = 20
	confirmation_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirmation_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	options_overlay.add_child(confirmation_overlay)
	
	# Painel de Confirmação — posição manual com TOP_LEFT
	var c_size = Vector2(360, 240)
	var c_panel = Panel.new()
	c_panel.name = "ConfirmationPanel"
	c_panel.size = c_size
	c_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var vp2 = get_viewport_rect().size
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
	
	# Textura de pedra no fundo do painel
	_add_stone_texture(c_panel)
	
	# Container vertical unificado para elementos do diálogo de confirmação
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
	
	# Título do Popup
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
	
	# Separador dourado decorativo
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
	
	# Espaçador elástico entre mensagem e botões
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(spacer)
	
	# Botões — dentro do VBox (sem PRESET_BOTTOM_WIDE que causava overflow)
	var btn_apply_exit = Button.new()
	btn_apply_exit.name = "ApplyExitButton"
	btn_apply_exit.add_theme_font_size_override("font_size", 12)
	btn_apply_exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_setup_hover_events(btn_apply_exit)
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
	_setup_hover_events(btn_discard_exit)
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
	_setup_hover_events(btn_cancel)
	btn_cancel.pressed.connect(func():
		confirmation_overlay.hide()
	)
	content_vbox.add_child(btn_cancel)
	
	_update_confirmation_popup_labels()


func _update_confirmation_popup_labels():
	if not confirmation_overlay:
		return
		
	var c_panel = confirmation_overlay.get_node("ConfirmationPanel")
	if not c_panel:
		return
	var lang_str = "PT" if temp_language == GameGlobals.Language.PT else "EN"
	
	# Título agora está no ContentVBox
	var content_vbox = c_panel.get_node_or_null("ContentVBox")
	if not content_vbox:
		return
	
	var c_title = content_vbox.get_node_or_null("TitleLabel")
	if c_title:
		c_title.text = GameGlobals.translations[lang_str]["confirm_title"]
		
	var c_text = content_vbox.get_node_or_null("MessageLabel")
	if c_text:
		c_text.text = GameGlobals.translations[lang_str]["confirm_text"]
	
	var btn1 = content_vbox.get_node_or_null("ApplyExitButton")
	if btn1: btn1.text = GameGlobals.translations[lang_str]["confirm_apply_exit"]
	var btn2 = content_vbox.get_node_or_null("DiscardExitButton")
	if btn2: btn2.text = GameGlobals.translations[lang_str]["confirm_discard_exit"]
	var btn3 = content_vbox.get_node_or_null("CancelButton")
	if btn3: btn3.text = GameGlobals.translations[lang_str]["confirm_cancel"]


func update_translations():
	if title_label: title_label.text = GameGlobals.get_text("menu_title")
	if subtitle_label: subtitle_label.text = GameGlobals.get_text("menu_subtitle")
	# Labels dos livros antigos foram removidos da cena; o carrossel usa _update_carousel_ui()
	if diff_easy_btn: diff_easy_btn.text = GameGlobals.get_text("menu_diff_easy")
	if diff_normal_btn: diff_normal_btn.text = GameGlobals.get_text("menu_diff_normal")
	if diff_hard_btn: diff_hard_btn.text = GameGlobals.get_text("menu_diff_hard")
	if credits_btn: credits_btn.text = GameGlobals.get_text("menu_credits")
	
	_update_carousel_ui()
	
	var opt_btn = get_node_or_null("OptionsButton")
	if opt_btn: opt_btn.text = GameGlobals.get_text("menu_options")
	
	_update_diff_label()

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

func _input(event):
	if rebinding_action == "":
		# Ignorar cliques do rato na navegação global de teclas/comando.
		# O rato é tratado de forma nativa e direta pelos próprios botões.
		if event is InputEventMouseButton:
			return
			
		# Navegação no menu principal com comando/teclado (quando opções estão fechadas)
		if _is_ui_enabled and (options_overlay == null or not options_overlay.visible):
			if event.is_pressed() and not event.is_echo():
				if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
					_navigate_carousel(-1)
					get_viewport().set_input_as_handled()
				elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
					_navigate_carousel(1)
					get_viewport().set_input_as_handled()
				elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("shoot"):
					_on_carousel_cover_pressed()
					get_viewport().set_input_as_handled()
		return
		
	if rebinding_just_started:
		return
		
	if not event.is_pressed():
		return
		
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		rebinding_action = ""
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
		# Verificar se a tecla/botão já está em uso
		if _is_key_already_bound(event, rebinding_action, keybind_selected_book):
			if keybind_status_label:
				keybind_status_label.text = GameGlobals.translations["PT"]["keybinds_duplicate"] if temp_language == GameGlobals.Language.PT else GameGlobals.translations["EN"]["keybinds_duplicate"]
				keybind_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			return
			
		# Configurar a tecla no slot específico
		if not temp_keybinds.has(rebinding_action):
			temp_keybinds[rebinding_action] = []
		
		# Garantir que o array tem espaço suficiente
		while temp_keybinds[rebinding_action].size() <= rebinding_slot:
			temp_keybinds[rebinding_action].append(null)
		
		temp_keybinds[rebinding_action][rebinding_slot] = event
		
		# Marcar que keybinds foram modificados
		keybinds_modified = true
		
		# Limpar estado
		rebinding_action = ""
		rebinding_slot = 0
		rebinding_button = null
		
		if keybind_status_label:
			keybind_status_label.text = ""
			
		_update_options_labels()
		get_viewport().set_input_as_handled()
