extends Node
class_name SusanooScene

# ---------------------------------------------------------------------------
# Referências a nós da cena (@onready)
# ---------------------------------------------------------------------------

## Nó do jogador Susanoo.
@onready var player: SusanooPlayer = $SusanooPlayer

## Label do HUD que mostra o número de barris colocados.
@onready var hud_barrels_label: Label = $HUD/BarrelsLabel

## Label do HUD que mostra a dica de interação ([E] Colocar barril).
@onready var hud_action_label: Label = $HUD/ActionLabel

## Container do ecrã de narração introdutório.
@onready var narrator_container: Control = $NarratorContainer

## Nó pai de todas as cabeças do Orochi presentes na cena.
@onready var heads_container: Node = $Heads

## Nó pai de todos os pontos de barril presentes na cena.
@onready var barrels_container: Node = $BarrelPoints

## Cena do DialogueBox partilhada com o resto do projeto.
var dialogue_box_scene: PackedScene = preload("res://scenes/dialogue_box.tscn")

# ---------------------------------------------------------------------------
# Estado da sessão
# ---------------------------------------------------------------------------

## Número total de barris que o jogador tem de colocar para vencer.
var total_barrels: int = 8

## Número de barris colocados até ao momento.
var barrels_placed: int = 0

## Indica se o jogador já pode interagir com o mundo (após o intro).
var game_active: bool = false

## Indica se a sequência de introdução já foi concluída.
var intro_done: bool = false

# Variáveis para a introdução cinematográfica
var camera_target: Vector2 = Vector2(960, 540)
var _active_dialogue: DialogueBox = null
@onready var camera: Camera2D = get_node_or_null("Camera2D")

# Variáveis do menu de pausa
var pause_menu_scene: PackedScene = preload("res://scenes/pause_menu.tscn")
var pause_menu_instance: Node = null


# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------

func _ready() -> void:
	if GameGlobals:
		GameGlobals.play_music("res://assets/music/susanoo_theme.wav", -10.0)
	
	# O controller e o container das cabeças continuam a processar durante a pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	if heads_container:
		heads_container.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var camera_node = get_node_or_null("Camera2D")
	if camera_node:
		camera_node.process_mode = Node.PROCESS_MODE_ALWAYS
		# Define os limites da câmara com base na dimensão do fundo (1672x941 centrado em 960,540)
		camera_node.limit_left = 124
		camera_node.limit_right = 1796
		camera_node.limit_top = 70
		camera_node.limit_bottom = 1011

	# Colocar o jogador na safe zone (fundo centro) e ocultá-lo temporariamente
	if player:
		player.position = Vector2(960, 950)
		player.visible = false
		player.scale = Vector2(3.5, 3.5) # Aumenta a escala do player na fase de stealth
		player.disable_input()

	# Oculta a dica de ação logo no início; só aparece quando o jogador
	# está perto de um ponto de barril.
	if hud_action_label:
		hud_action_label.visible = false

	# Oculta/desativa cabeças em excesso conforme a dificuldade selecionada.
	_configure_heads_for_difficulty()

	# Randomiza os spawns dos saques (barris de sake)
	_randomize_barrel_positions()

	# Pausa o jogo e inicia a sequência de introdução narrativa.
	get_tree().paused = true
	_play_intro()

	# Névoa atmosférica verde rasteira do templo de Susanoo
	var mist = CPUParticles2D.new()
	mist.name = "TempleMist"
	mist.amount = 30
	mist.lifetime = 8.0
	mist.preprocess = 8.0
	mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mist.emission_rect_extents = Vector2(960.0, 80.0)   # Cobre toda a largura do nível
	mist.direction = Vector2(1.0, 0.0)
	mist.spread = 180.0
	mist.gravity = Vector2(0.0, 0.0)
	mist.initial_velocity_min = 4.0
	mist.initial_velocity_max = 12.0
	mist.scale_amount_min = 55.0
	mist.scale_amount_max = 110.0
	mist.color = Color(0.04, 0.18, 0.09, 0.11)          # Verde floresta escura, muito translucido
	var mg = Gradient.new()
	mg.colors = [Color(0.04, 0.18, 0.09, 0.0), Color(0.04, 0.18, 0.09, 0.11), Color(0.04, 0.18, 0.09, 0.0)]
	mg.offsets = [0.0, 0.5, 1.0]
	mist.color_ramp = mg
	mist.position = Vector2(960.0, 880.0)               # Chao do templo (base do ecra)
	mist.z_index = -1                                    # Desenhado atras do jogador e cabecas
	mist.emitting = true
	add_child(mist)


# ---------------------------------------------------------------------------
# Sequência de introdução
# ---------------------------------------------------------------------------

## Instancia o DialogueBox com as 4 linhas do narrador introdutório e aguarda
## o sinal dialogue_finished para arrancar a jogabilidade.
func _play_intro() -> void:
	var box: DialogueBox = dialogue_box_scene.instantiate()

	box.dialogue_list = [
		{"name": "char_narrator", "text": "dialogue_narrator_susanoo_1"},
		{"name": "char_narrator", "text": "dialogue_narrator_susanoo_2"},
		{"name": "char_narrator", "text": "dialogue_narrator_susanoo_3"},
		{"name": "char_narrator", "text": "dialogue_narrator_susanoo_4"},
	]

	# Guardamos a referência do diálogo ativo para ler o progresso
	_active_dialogue = box

	# O DialogueBox despausa o jogo e emite dialogue_finished ao terminar.
	box.dialogue_finished.connect(_on_intro_finished)
	add_child(box)


func _on_intro_finished() -> void:
	intro_done = true
	_active_dialogue = null
	
	# Restaurar process modes padrão para que a pausa funcione
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if heads_container:
		heads_container.process_mode = Node.PROCESS_MODE_PAUSABLE
	var camera_node = get_node_or_null("Camera2D")
	if camera_node:
		camera_node.process_mode = Node.PROCESS_MODE_PAUSABLE
		camera_node.position = player.position if player else camera_node.position
	
	# Mostrar o jogador, colocá-lo na safe zone e dar-lhe controlo
	if player:
		player.visible = true
		player.enable_input()
			
	_start_gameplay()

func _process(delta: float) -> void:
	# Atualizar o target da câmara com base no diálogo de introdução
	if not intro_done:
		_update_intro_camera()
	elif game_active and player:
		camera_target = player.position

	# Mover suavemente a câmara para o target
	var camera_node = get_node_or_null("Camera2D")
	if camera_node:
		camera_node.position = camera_node.position.lerp(camera_target, 3.5 * delta)

func _update_intro_camera() -> void:
	if not _active_dialogue or not is_instance_valid(_active_dialogue):
		return
		
	match _active_dialogue.current_line:
		0:
			# Mostrar cabeças do lado esquerdo
			camera_target = Vector2(500, 300)
		1:
			# Mostrar cabeças do lado direito
			camera_target = Vector2(1400, 400)
		2:
			# Mostrar saques (barris no topo)
			camera_target = Vector2(960, 200)
		3:
			# Focar no ponto de spawn do jogador (safe zone)
			camera_target = Vector2(960, 950)


# ---------------------------------------------------------------------------
# Início da jogabilidade
# ---------------------------------------------------------------------------

## Configura e ativa todos os sistemas de jogo após o intro.
func _start_gameplay() -> void:
	game_active = true

	# Liga o sinal do player.
	if player:
		player.barrel_placed.connect(_on_barrel_placed)
		player.player_caught.connect(_on_player_caught)

	# Liga o sinal de deteção de cada cabeça ativa.
	for head in heads_container.get_children():
		if head.visible and head is OrochiHead:
			head.player_ref = player
			if not head.player_detected.is_connected(_on_player_detected_by_head):
				head.player_detected.connect(_on_player_detected_by_head)

	# Liga o sinal de proximidade de cada ponto de barril.
	for point in barrels_container.get_children():
		if point.has_signal("player_near") and not point.player_near.is_connected(_on_player_near_barrel):
			point.player_near.connect(_on_player_near_barrel)
		if point.has_signal("player_left") and not point.player_left.is_connected(_on_player_left_barrel):
			point.player_left.connect(_on_player_left_barrel)

	_update_hud()


# ---------------------------------------------------------------------------
# Callbacks de sinais
# ---------------------------------------------------------------------------

## Chamado quando o jogador coloca um barril com sucesso.
func _on_barrel_placed(total: int) -> void:
	barrels_placed = total
	_update_hud()

	# Verifica condição de vitória.
	if barrels_placed >= total_barrels:
		_trigger_victory()


## Chamado quando uma cabeça do Orochi emite player_detected.
## Delega ao player para garantir que o sinal player_caught é emitido uma única vez.
func _on_player_detected_by_head() -> void:
	if player and game_active:
		player.catch_player()


## Chamado quando o sinal player_caught do player é recebido.
func _on_player_caught() -> void:
	if not game_active:
		return
	game_active = false

	# Para o movimento de todas as cabeças.
	_set_heads_active(false)

	_show_game_over()


## Chamado quando o jogador entra na área de interação de um ponto de barril.
func _on_player_near_barrel(point: Node) -> void:
	if player:
		player.near_barrel_point = point
	if hud_action_label:
		hud_action_label.text = GameGlobals.get_text("ui_susanoo_place")
		hud_action_label.visible = true


## Chamado quando o jogador sai da área de interação de um ponto de barril.
func _on_player_left_barrel() -> void:
	if player:
		player.near_barrel_point = null
	if hud_action_label:
		hud_action_label.visible = false


# ---------------------------------------------------------------------------
# Condição de vitória
# ---------------------------------------------------------------------------

## Inicia a sequência de vitória: para o player, faz animação do Orochi bebedo e morrendo, e depois mostra diálogo.
func _trigger_victory() -> void:
	if not game_active:
		return
	game_active = false

	# Impede que o jogador continue a mover-se.
	if player:
		player.disable_input()

	# Para o movimento das cabeças.
	_set_heads_active(false)

	# Cria animação das cabeças do Orochi a rodopiar, a ficar vermelhas e a desaparecer (bebedeira e morte)
	var victory_tween = create_tween().set_parallel(true)
	for head in heads_container.get_children():
		if head.visible and head is OrochiHead:
			# Rodopia as cabeças
			victory_tween.tween_property(head, "rotation", head.rotation + PI * 8.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			# Fica avermelhado (bêbedo) e depois transparente
			victory_tween.tween_property(head, "modulate", Color(1.0, 0.3, 0.3, 0.0), 2.0).set_trans(Tween.TRANS_SINE)
			# Encolhe
			victory_tween.tween_property(head, "scale", Vector2.ZERO, 2.0).set_trans(Tween.TRANS_QUAD)

	# Quando a animação terminar, mostra o diálogo do narrador
	victory_tween.chain().tween_callback(func():
		var box: DialogueBox = dialogue_box_scene.instantiate()
		box.dialogue_list = [
			{"name": "char_narrator", "text": "dialogue_narrator_susanoo_victory_1"},
			{"name": "char_narrator", "text": "dialogue_narrator_susanoo_victory_2"},
		]
		box.dialogue_finished.connect(_on_victory_dialogue_finished)
		add_child(box)
	)


## Após o diálogo de vitória, mostra o ecrã de vitória premium.
func _on_victory_dialogue_finished() -> void:
	_show_victory_screen()

func _show_victory_screen() -> void:
	var is_pt = GameGlobals and GameGlobals.current_language == GameGlobals.Language.PT
	
	# CanvasLayer de alta prioridade
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	
	# Overlay escuro semitransparente
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)
	
	# Partículas de pétalas de sakura vermelhas (ambiente japonês de vitória)
	var petals := CPUParticles2D.new()
	petals.amount = 35
	petals.lifetime = 5.0
	petals.preprocess = 2.0
	petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	petals.emission_rect_extents = Vector2(650.0, 5.0)
	petals.direction = Vector2(0.3, 1.0)
	petals.spread = 20.0
	petals.gravity = Vector2(15.0, 40.0)
	petals.initial_velocity_min = 20.0
	petals.initial_velocity_max = 60.0
	petals.angular_velocity_min = -90.0
	petals.angular_velocity_max = 90.0
	petals.scale_amount_min = 2.5
	petals.scale_amount_max = 5.5
	petals.color = Color(0.9, 0.2, 0.2, 0.85)
	var ppg := Gradient.new()
	ppg.colors = [Color(1.0, 0.3, 0.35, 0.9), Color(0.85, 0.15, 0.15, 0.5), Color(0.7, 0.1, 0.1, 0.0)]
	ppg.offsets = [0.0, 0.6, 1.0]
	petals.color_ramp = ppg
	petals.position = Vector2(640.0, 0.0)
	petals.emitting = true
	overlay.add_child(petals)
	
	# CenterContainer
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	# Painel — vermelho escarlate/preto japonês de Susanoo
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(460.0, 280.0)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.01, 0.01, 0.97)      # Vermelho escuro/preto japonês
	ps.border_width_left = 3
	ps.border_width_top = 3
	ps.border_width_right = 3
	ps.border_width_bottom = 3
	ps.border_color = Color(0.90, 0.20, 0.20, 1.0)   # Borda vermelha fogo de Susanoo
	ps.corner_radius_top_left = 8
	ps.corner_radius_top_right = 8
	ps.corner_radius_bottom_left = 8
	ps.corner_radius_bottom_right = 8
	ps.shadow_size = 20
	ps.shadow_color = Color(0.7, 0.05, 0.05, 0.55)   # Sombra vermelha
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	# Emoji sabre
	var sword_lbl := Label.new()
	sword_lbl.text = "⚔️"
	sword_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sword_lbl.add_theme_font_size_override("font_size", 42)
	vbox.add_child(sword_lbl)
	
	# Título
	var title := Label.new()
	title.text = "🌸 SUSANOO TRIUNFOU! 🌸" if is_pt else "🌸 SUSANOO TRIUMPHANT! 🌸"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var f_bold = _load_cinzel(true)
	if f_bold:
		title.add_theme_font_override("font", f_bold)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	vbox.add_child(title)
	
	# Descrição
	var desc := Label.new()
	desc.text = "As oito cabeças de Yamata no Orochi tombaram.\nSusanoo salvou Kushinadahime e ganhou o favor dos deuses." if is_pt else "The eight heads of Yamata no Orochi have fallen.\nSusanoo saved Kushinadahime and earned the favor of the gods."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var f_reg = _load_cinzel(false)
	if f_reg:
		desc.add_theme_font_override("font", f_reg)
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.88, 0.80, 0.78, 1.0))
	vbox.add_child(desc)
	
	# Separador
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.90, 0.20, 0.20, 0.5))
	sep.add_theme_constant_override("separation", 6)
	vbox.add_child(sep)
	
	# Botão Menu
	var btn := Button.new()
	btn.text = "🏠  Voltar ao Menu" if is_pt else "🏠  Back to Menu"
	if f_reg:
		btn.add_theme_font_override("font", f_reg)
	btn.add_theme_font_size_override("font_size", 14)
	btn.custom_minimum_size = Vector2(200.0, 40.0)
	
	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color(0.15, 0.03, 0.03, 1.0)
	sb_n.border_width_left = 1; sb_n.border_width_top = 1
	sb_n.border_width_right = 1; sb_n.border_width_bottom = 1
	sb_n.border_color = Color(0.75, 0.18, 0.18, 0.8)
	sb_n.corner_radius_top_left = 5; sb_n.corner_radius_top_right = 5
	sb_n.corner_radius_bottom_left = 5; sb_n.corner_radius_bottom_right = 5
	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = Color(0.28, 0.06, 0.06, 1.0)
	sb_h.border_width_left = 1; sb_h.border_width_top = 1
	sb_h.border_width_right = 1; sb_h.border_width_bottom = 1
	sb_h.border_color = Color(1.0, 0.35, 0.35, 1.0)
	sb_h.corner_radius_top_left = 5; sb_h.corner_radius_top_right = 5
	sb_h.corner_radius_bottom_left = 5; sb_h.corner_radius_bottom_right = 5
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	btn.add_theme_color_override("font_color", Color(0.95, 0.82, 0.82, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.5, 0.5, 1.0))
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(btn)
	
	# Animação de entrada (bounce)
	panel.scale = Vector2.ZERO
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _load_cinzel(bold: bool) -> Font:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	return load(path) as Font




# ---------------------------------------------------------------------------
# Ecrã de Game Over
# ---------------------------------------------------------------------------

## Constrói e apresenta um ecrã de Game Over simples dentro de um CanvasLayer.
func _show_game_over() -> void:
	# Toca som de derrota temático
	if GameGlobals:
		GameGlobals.play_defeat_sound()
	# Criar um CanvasLayer para garantir que o UI desenha por cima da câmara e centrado
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "GameOverLayer"
	add_child(canvas_layer)

	# Painel de fundo semitransparente.
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(overlay)

	# CenterContainer para centrar tudo perfeitamente
	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(center_container)

	# Painel decorado premium
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(420.0, 240.0)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.08, 0.04, 0.04, 0.96) # Vermelho escuro/preto temático de Susanoo
	ps.border_width_left = 2
	ps.border_width_top = 2
	ps.border_width_right = 2
	ps.border_width_bottom = 2
	ps.border_color = Color(0.9, 0.15, 0.15, 1.0) # Borda vermelha fogo do Orochi
	ps.corner_radius_top_left = 6
	ps.corner_radius_top_right = 6
	ps.corner_radius_bottom_left = 6
	ps.corner_radius_bottom_right = 6
	ps.shadow_size = 15
	ps.shadow_color = Color(0, 0, 0, 0.8)
	panel.add_theme_stylebox_override("panel", ps)
	center_container.add_child(panel)

	# Container vertical
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Título de Game Over.
	var title_label := Label.new()
	title_label.text = GameGlobals.get_text("gameover_title_susanoo")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15, 1.0))
	var font_bold = load("res://assets/fonts/Cinzel-Bold.ttf") as FontFile
	if font_bold:
		title_label.add_theme_font_override("font", font_bold)
	vbox.add_child(title_label)

	# Espaçador.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 10.0)
	vbox.add_child(spacer)

	# Estilos para os botões
	var font_reg = load("res://assets/fonts/Cinzel-Regular.ttf") as FontFile
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.15, 0.06, 0.06, 0.85)
	sb_normal.border_color = Color(0.9, 0.15, 0.15, 0.6)
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.corner_radius_top_left = 3
	sb_normal.corner_radius_top_right = 3
	sb_normal.corner_radius_bottom_left = 3
	sb_normal.corner_radius_bottom_right = 3

	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.3, 0.08, 0.08, 0.95)
	sb_hover.border_color = Color(1.0, 0.25, 0.25, 1.0)
	sb_hover.border_width_left = 1
	sb_hover.border_width_top = 1
	sb_hover.border_width_right = 1
	sb_hover.border_width_bottom = 1
	sb_hover.corner_radius_top_left = 3
	sb_hover.corner_radius_top_right = 3
	sb_hover.corner_radius_bottom_left = 3
	sb_hover.corner_radius_bottom_right = 3

	# Botão de retry.
	var retry_btn := Button.new()
	retry_btn.text = GameGlobals.get_text("gameover_retry_susanoo")
	retry_btn.custom_minimum_size = Vector2(300.0, 36.0)
	if font_reg:
		retry_btn.add_theme_font_override("font", font_reg)
	retry_btn.add_theme_stylebox_override("normal", sb_normal)
	retry_btn.add_theme_stylebox_override("hover", sb_hover)
	retry_btn.add_theme_stylebox_override("focus", sb_hover)
	retry_btn.pressed.connect(_on_retry_pressed)
	vbox.add_child(retry_btn)

	# Botão de regresso ao menu.
	var menu_btn := Button.new()
	menu_btn.text = GameGlobals.get_text("gameover_menu")
	menu_btn.custom_minimum_size = Vector2(300.0, 36.0)
	if font_reg:
		menu_btn.add_theme_font_override("font", font_reg)
	menu_btn.add_theme_stylebox_override("normal", sb_normal)
	menu_btn.add_theme_stylebox_override("hover", sb_hover)
	menu_btn.add_theme_stylebox_override("focus", sb_hover)
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)
	
	if GameGlobals:
		retry_btn.mouse_entered.connect(GameGlobals.play_hover_sound)
		retry_btn.pressed.connect(GameGlobals.play_click_sound)
		menu_btn.mouse_entered.connect(GameGlobals.play_hover_sound)
		menu_btn.pressed.connect(GameGlobals.play_click_sound)

	# Garante que o jogo está despausado para que os botões respondam.
	get_tree().paused = false


## Reinicia a cena atual (retry).
func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


## Regressa ao menu principal.
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------

## Atualiza a label de barris com o texto localizado e o contador atual.
func _update_hud() -> void:
	if hud_barrels_label:
		hud_barrels_label.text = (
			GameGlobals.get_text("ui_susanoo_barrels")
			+ str(barrels_placed)
			+ "/"
			+ str(total_barrels)
		)


# ---------------------------------------------------------------------------
# Configuração por dificuldade
# ---------------------------------------------------------------------------

## Devolve o número de cabeças ativas conforme a dificuldade selecionada.
func _get_active_heads_count() -> int:
	match GameGlobals.current_difficulty:
		GameGlobals.Difficulty.EASY:   return 4
		GameGlobals.Difficulty.HARD:   return 8
		_:                             return 6  # NORMAL


## Devolve a velocidade de patrulha das cabeças conforme a dificuldade.
func _get_patrol_speed_for_difficulty() -> float:
	match GameGlobals.current_difficulty:
		GameGlobals.Difficulty.EASY:   return 50.0
		GameGlobals.Difficulty.HARD:   return 120.0
		_:                             return 80.0  # NORMAL


## Devolve o tempo de alerta das cabeças conforme a dificuldade.
func _get_alert_time_for_difficulty() -> float:
	match GameGlobals.current_difficulty:
		GameGlobals.Difficulty.EASY:   return 1.5
		GameGlobals.Difficulty.HARD:   return 0.0
		_:                             return 0.8  # NORMAL


## Oculta as cabeças em excesso e ajusta a velocidade de patrulha das ativas.
func _configure_heads_for_difficulty() -> void:
	var active_count: int = _get_active_heads_count()
	var patrol_speed: float = _get_patrol_speed_for_difficulty()
	var alert_time: float = _get_alert_time_for_difficulty()
	var all_heads: Array = heads_container.get_children()

	for i in range(all_heads.size()):
		var head: Node = all_heads[i]
		if i < active_count:
			# Cabeça ativa: torna visível e configura velocidade.
			head.visible = true
			head.process_mode = Node.PROCESS_MODE_INHERIT
			if head is OrochiHead:
				head.patrol_speed = patrol_speed
				head.alert_time = alert_time
		else:
			# Cabeça em excesso: oculta e desativa processamento.
			head.visible = false
			head.process_mode = Node.PROCESS_MODE_DISABLED


## Ativa ou desativa o processamento de todas as cabeças visíveis.
func _set_heads_active(active: bool) -> void:
	for head in heads_container.get_children():
		if head.visible:
			head.process_mode = (
				Node.PROCESS_MODE_INHERIT if active
				else Node.PROCESS_MODE_DISABLED
			)


## Randomiza as posições dos pontos de barril de sake na área caminhável do templo.
func _randomize_barrel_positions() -> void:
	var points: Array = barrels_container.get_children()
	var generated_positions: Array = []
	
	# Ponto de spawn do player a evitar
	var player_spawn := Vector2(960, 950)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for point in points:
		var valid_pos := false
		var attempts := 0
		var new_pos := Vector2.ZERO
		
		while not valid_pos and attempts < 100:
			attempts += 1
			# Gera posição aleatória nos limites da área caminhável do templo
			new_pos.x = rng.randf_range(250.0, 1450.0)
			new_pos.y = rng.randf_range(180.0, 820.0)
			
			# Evita spawnar em cima do jogador
			if new_pos.distance_to(player_spawn) < 220.0:
				continue
				
			# Evita spawnar muito próximo de outros barris
			var too_close := false
			for pos in generated_positions:
				if new_pos.distance_to(pos) < 180.0:
					too_close = true
					break
			
			if not too_close:
				valid_pos = true
		
		if valid_pos:
			point.position = new_pos
			generated_positions.append(new_pos)


# ---------------------------------------------------------------------------
# Menu de pausa
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	# ESC abre/fecha o menu de pausa (só funciona com o jogo a decorrer)
	if event.is_action_pressed("ui_cancel") and game_active:
		_toggle_pause()


func _toggle_pause() -> void:
	if is_instance_valid(pause_menu_instance):
		return # Já está aberto
	get_tree().paused = true
	pause_menu_instance = pause_menu_scene.instantiate()
	pause_menu_instance.tree_exited.connect(func(): pause_menu_instance = null)
	add_child(pause_menu_instance)
