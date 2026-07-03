extends Node2D

@onready var player = $Player
@onready var boss = $Python

var cutscene_active: bool = true

# --- Altares, Veneno e Perigos de Arena ---
var left_altar: Area2D = null
var right_altar: Area2D = null
var poison_floor: Area2D = null
var rock_spawn_timer: float = 0.0
const ROCK_SPAWN_INTERVAL: float = 3.5 # detritos a cada 3.5 segundos

var music_player: AudioStreamPlayer

func _ready():
	# Parar música de menu e iniciar música de combate
	if GameGlobals:
		GameGlobals.stop_music()
	
	music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://assets/music/achilles.mp3")
	music_player.volume_db = -6.0
	music_player.name = "LevelMusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	music_player.finished.connect(func(): music_player.play())

	# Construir o layout do mapa/arena dinamicamente
	_build_arena_map()
	
	# Inicializar altares e veneno
	_setup_arena_hazards()
	
	if not player or not boss:
		return
		
	# Instanciar o fundo do céu dinamicamente
	_setup_background()
		
	# 1. Configurações iniciais da cutscene
	cutscene_active = true
	player.is_cutscene = true
	
	# Desativa a física e inteligência do boss temporariamente
	boss.set_physics_process(false)
	boss.health_bar.hide()
	
	# Posiciona o jogador fora do ecrã (esquerda) e o boss no céu (escondido)
	player.global_position = Vector2(-220, -12)
	if player.sprite:
		player.sprite.play("Idle")
	boss.global_position = Vector2(100, -350)
	
	# Configura a câmara inicial bem alta no céu (Y=-280) para esconder o jogador na base
	player.camera_offset_target = Vector2(0, -280)
	player.camera_zoom_target = 3.5
	
	# Inicia a sequência narrativa (Prólogo)
	# Usamos call_deferred ou um pequeno timer para dar tempo ao SceneTransition de completar o fade-in inicial
	get_tree().create_timer(0.2).timeout.connect(_play_prologue)

func _play_prologue():
	if not is_instance_valid(player) or not player.dialogue_scene:
		_pan_down_and_walk()
		return
		
	var dialogue = player.dialogue_scene.instantiate()
	dialogue.dialogue_list = [
		{"name": "char_narrator", "text": "dialogue_narrator_1"},
		{"name": "char_narrator", "text": "dialogue_narrator_2"}
	]
	dialogue.dialogue_finished.connect(_pan_down_and_walk)
	add_child(dialogue)

func _pan_down_and_walk():
	if not is_instance_valid(player):
		return
		
	# Iniciar a música de combate exatamente quando o pan down começa
	if is_instance_valid(music_player) and not music_player.playing:
		music_player.play()
		
	# 1. Animação de correr do jogador
	player.sprite.play("Run")
	
	# Criar tweens em paralelo para mover a câmara e o jogador
	var tween = create_tween().set_parallel(true)
	
	# Deslocar a câmara suavemente do céu para o chão
	tween.tween_property(player, "camera_offset_target:y", 0.0, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player, "camera_zoom_target", 2.8, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Mover o jogador para o centro do ecrã
	tween.tween_property(player, "global_position:x", -40.0, 2.5).set_trans(Tween.TRANS_SINE)
	
	# Quando terminar o pan down e a caminhada
	tween.chain().tween_callback(_play_apollo_reflection)

func _play_apollo_reflection():
	if not is_instance_valid(player):
		return
		
	# Pato fica parado e olha em redor
	player.sprite.play("Idle")
	
	var reflection_tween = create_tween()
	# Pequena pausa dramática antes de falar
	reflection_tween.tween_interval(0.4)
	reflection_tween.tween_callback(func():
		if not is_instance_valid(player) or not player.dialogue_scene:
			_run_boss_entrance()
			return
			
		var dialogue = player.dialogue_scene.instantiate()
		dialogue.dialogue_list = [
			{"name": "char_apolo", "text": "dialogue_apolo_reflect_1"},
			{"name": "char_apolo", "text": "dialogue_apolo_reflect_2"}
		]
		dialogue.dialogue_finished.connect(_run_boss_entrance)
		add_child(dialogue)
	)

func _run_boss_entrance():
	if not is_instance_valid(player) or not is_instance_valid(boss):
		_on_cutscene_finished()
		return
		
	# 1. Tremor de terra leve de aviso
	player.shake_camera(3.0)
	
	var boss_tween = create_tween()
	boss_tween.tween_interval(0.6)
	
	# 2. A cobra (Píton) cai estrondosamente do céu!
	boss_tween.tween_callback(func():
		var fall_tween = create_tween()
		fall_tween.tween_property(boss, "global_position:y", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall_tween.tween_callback(func():
			# Impacto forte da queda e tremor
			player.shake_camera(8.5)
			
			# Salto de impacto (o pato voa levemente devido ao tremor de terra)
			if is_instance_valid(player):
				if player.sprite and player.sprite.sprite_frames.has_animation("Jump"):
					player.sprite.play("Jump")
				var impact_tween = player.create_tween()
				impact_tween.tween_property(player, "global_position:y", -42.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				impact_tween.tween_property(player, "global_position:y", -12.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				impact_tween.tween_callback(func():
					if is_instance_valid(player) and player.sprite:
						player.sprite.play("Idle")
				)
			
			# ZOOM OUT e PAN PARA A PÍTON!
			player.camera_zoom_target = 2.2 # Diminui o zoom para ver a arena
			player.camera_offset_target = Vector2(105.0, -10.0) # Move a câmara para focar na Píton
			
			# Pisca a cobra a vermelho para dar impacto visual de queda
			if boss.sprite:
				boss.sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
				get_tree().create_timer(0.15).timeout.connect(func():
					if is_instance_valid(boss) and boss.sprite:
						boss.sprite.modulate = boss.base_color
				)
		)
	)
	
	# Espera o boss cair e fica a focar no boss por 0.8s (queda de 0.45s + 0.8s)
	boss_tween.tween_interval(1.25)
	
	# 3. A câmara move-se para o enquadramento do Diálogo e inicia-o
	boss_tween.tween_callback(func():
		if not is_instance_valid(player):
			return
		player.camera_zoom_target = 2.5 # Enquadramento intermédio ideal para ler
		player.camera_offset_target = Vector2(30.0, 0.0) # Foca ligeiramente ao centro
		
		if player.dialogue_scene:
			var dialogue = player.dialogue_scene.instantiate()
			dialogue.dialogue_list = [
				{"name": "char_apolo", "text": "dialogue_apolo_python_1"},
				{"name": "char_python", "text": "dialogue_python_apolo_1"},
				{"name": "char_apolo", "text": "dialogue_apolo_python_2"}
			]
			# Conecta ao término do diálogo para iniciar a jogabilidade
			dialogue.dialogue_finished.connect(_on_cutscene_finished)
			add_child(dialogue)
	)

func _on_cutscene_finished():
	if not is_instance_valid(player) or not is_instance_valid(boss):
		return
		
	cutscene_active = false
	player.is_cutscene = false
	boss.set_physics_process(true)
	boss.health_bar.show()
	
	# Instancia a UI geral (corações, etc.) agora que a batalha começou
	player.instantiate_ui()
	
	# Restaura a câmara para a jogabilidade normal focada no jogador
	player.camera_zoom_target = 2.8
	player.camera_offset_target = Vector2.ZERO

func _setup_background():
	# Criar um CanvasLayer para o fundo para que ele siga a câmara automaticamente e cubra todo o ecrã
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "DelphiBackgroundLayer"
	canvas_layer.layer = -100 # Desenha atrás do jogo principal (que está na camada 0)
	add_child(canvas_layer)

	var bg_container = Control.new()
	bg_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(bg_container)

	var bg = TextureRect.new()
	bg.name = "DelphiBackground"
	
	# Carregar via recurso nativo do Godot (muito mais robusto e compatível)
	var tex = load("res://assets/sprites/delphi_battle_bg.png")
	
	# Fallback caso a importação do Godot esteja inválida (valid=false no .import)
	if not tex:
		var img = _load_png_from_path("res://assets/sprites/delphi_battle_bg.png")
		if img:
			tex = ImageTexture.create_from_image(img)
			
	if tex:
		bg.texture = tex
	
	if not bg.texture:
		# Fallback: cor sólida escura se a imagem falhar
		var fallback = ColorRect.new()
		fallback.name = "BGFallback"
		fallback.color = Color(0.08, 0.05, 0.12, 1.0)
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_container.add_child(fallback)
		return
	
	# Preencher o ecrã inteiro — centrado e escalado para cobrir
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Ligeira cor para integrar com o tom escuro da batalha
	bg.modulate = Color(0.85, 0.80, 0.90, 1.0)
	bg_container.add_child(bg)
	print("[BG] Fundo de Delfos em CanvasLayer carregado com sucesso!")


# Carrega um PNG diretamente dos bytes do disco — não precisa de ser importado pelo Godot
func _load_png_from_path(res_path: String) -> Image:
	# Converte res:// → caminho absoluto com barras corretas para Windows
	var abs_path = ProjectSettings.globalize_path(res_path).replace("\\", "/")
	
	if not FileAccess.file_exists(abs_path):
		printerr("[BG] Ficheiro não existe no disco: ", abs_path)
		return null
	
	# Método 1: Image.load_from_file com caminho absoluto
	var img = Image.load_from_file(abs_path)
	if img and img.get_width() > 0 and img.get_height() > 0:
		return img
	
	# Método 2: Lê os bytes do ficheiro manualmente (funciona sem importação do Godot)
	var fa = FileAccess.open(abs_path, FileAccess.READ)
	if fa:
		var bytes = fa.get_buffer(fa.get_length())
		fa.close()
		var img_buf = Image.new()
		if img_buf.load_png_from_buffer(bytes) == OK and img_buf.get_width() > 0:
			return img_buf
		if img_buf.load_jpg_from_buffer(bytes) == OK and img_buf.get_width() > 0:
			return img_buf
		if img_buf.load_webp_from_buffer(bytes) == OK and img_buf.get_width() > 0:
			return img_buf
		printerr("[BG] Decoders falharam para: ", abs_path)
	else:
		printerr("[BG] FileAccess.open falhou para: ", abs_path, " — código: ", FileAccess.get_open_error())
	
	return null

func _build_arena_map():
	var tile_map = $TileMapLayer
	if not tile_map:
		printerr("[MAP] TileMapLayer não encontrado!")
		return
		
	# Limpa qualquer célula existente
	tile_map.clear()
	
	var source_id = 0
	
	# Configurações de tamanho da arena (X total de 70 blocos de largura)
	var min_x = -35
	var max_x = 35
	var floor_y = 0
	var wall_height = 14
	
	# 1. Desenhar o chão principal (Grass Blocks (0,0) com terra (0,1) por baixo)
	for x in range(min_x, max_x + 1):
		tile_map.set_cell(Vector2i(x, floor_y), source_id, Vector2i(0, 0))
		tile_map.set_cell(Vector2i(x, floor_y + 1), source_id, Vector2i(0, 1))
		tile_map.set_cell(Vector2i(x, floor_y + 2), source_id, Vector2i(0, 1))
		
	# 2. Desenhar as paredes laterais (Stone Blocks (7,0)) para fechar o mapa
	for y in range(floor_y - wall_height, floor_y + 1):
		tile_map.set_cell(Vector2i(min_x, y), source_id, Vector2i(7, 0))
		tile_map.set_cell(Vector2i(max_x, y), source_id, Vector2i(7, 0))
		
	# 3. Desenhar a estrutura de Ruínas Laterais (deixando o centro X = -15 a 15 completamente aberto)
	# Lado Esquerdo:
	# Degrau 1 (Y = -1, X de -19 a -16)
	for x in range(-19, -15):
		tile_map.set_cell(Vector2i(x, -1), source_id, Vector2i(2, 0))
	# Degrau 2 (Y = -2, X de -24 a -20)
	for x in range(-24, -19):
		tile_map.set_cell(Vector2i(x, -2), source_id, Vector2i(2, 0))
	# Pilar/Plataforma Alta (Y = -3, X de -34 a -25)
	for x in range(-34, -24):
		tile_map.set_cell(Vector2i(x, -3), source_id, Vector2i(2, 0))
	# Corpo do pilar de suporte (X = -29, de Y = -2 a 0)
	for y in range(-2, 1):
		tile_map.set_cell(Vector2i(-29, y), source_id, Vector2i(2, 0))
		
	# Lado Direito:
	# Degrau 1 (Y = -1, X de 16 a 19)
	for x in range(16, 20):
		tile_map.set_cell(Vector2i(x, -1), source_id, Vector2i(2, 0))
	# Degrau 2 (Y = -2, X de 20 a 24)
	for x in range(20, 25):
		tile_map.set_cell(Vector2i(x, -2), source_id, Vector2i(2, 0))
	# Pilar/Plataforma Alta (Y = -3, X de 25 a 34)
	for x in range(25, 35):
		tile_map.set_cell(Vector2i(x, -3), source_id, Vector2i(2, 0))
	# Corpo do pilar de suporte (X = 29, de Y = -2 a 0)
	for y in range(-2, 1):
		tile_map.set_cell(Vector2i(29, y), source_id, Vector2i(2, 0))
		
	# Plataformas Flutuantes Centrais (para ajudar a travessia aérea na Fase 2)
	# Plataforma Flutuante Esquerda (X de -9 a -3, Y = -3)
	for x in range(-9, -2):
		tile_map.set_cell(Vector2i(x, -3), source_id, Vector2i(2, 0))
	# Plataforma Flutuante Direita (X de 3 a 9, Y = -3)
	for x in range(3, 10):
		tile_map.set_cell(Vector2i(x, -3), source_id, Vector2i(2, 0))

func _setup_arena_hazards():
	# Instanciar Altares Solares
	var AltarScript = load("res://scripts/apolo_python/solar_altar.gd")
	
	# Pilar esquerdo está centrado em X = -464 (bloco -29 * 16), e topo está em Y = -48 (-3 * 16)
	left_altar = Area2D.new()
	left_altar.set_script(AltarScript)
	left_altar.position = Vector2(-464, -48)
	left_altar.name = "LeftSolarAltar"
	add_child(left_altar)
	# Só pode ser ativado na Fase 2 — passar referência ao boss
	left_altar.phase2_only = true
	left_altar.boss_ref = boss
	left_altar.altar_activated.connect(_on_altar_activated)
	
	# Pilar direito está centrado em X = 464 (bloco 29 * 16), e topo está em Y = -48
	right_altar = Area2D.new()
	right_altar.set_script(AltarScript)
	right_altar.position = Vector2(464, -48)
	right_altar.name = "RightSolarAltar"
	add_child(right_altar)
	# Só pode ser ativado na Fase 2 — passar referência ao boss
	right_altar.phase2_only = true
	right_altar.boss_ref = boss
	right_altar.altar_activated.connect(_on_altar_activated)
	
	# Instanciar Chão Venenoso
	var PoisonFloorScript = load("res://scripts/apolo_python/poison_floor.gd")
	poison_floor = Area2D.new()
	poison_floor.set_script(PoisonFloorScript)
	poison_floor.name = "PoisonFloor"
	add_child(poison_floor)


func _on_altar_activated():
	if not is_instance_valid(left_altar) or not is_instance_valid(right_altar):
		return
		
	# Verifica se ambos estão ativados
	if left_altar.is_active and right_altar.is_active:
		# Quebra o escudo do boss e atordoa-o
		if is_instance_valid(boss) and boss.has_method("break_shield"):
			boss.break_shield()
			
		# Ativa power-up Solar no jogador (tiro triplo em leque)
		if is_instance_valid(player):
			player.solar_powerup_timer = 10.0 # 10 segundos
			_spawn_solar_notification()

func reset_solar_altars():
	if is_instance_valid(left_altar):
		left_altar.reset_altar()
	if is_instance_valid(right_altar):
		right_altar.reset_altar()

func _spawn_solar_notification():
	if not is_instance_valid(player):
		return
	# Cria uma notificação visual simples (Label flutuante)
	var label = Label.new()
	label.text = GameGlobals.get_text("ui_solar_active") if GameGlobals else "SOLAR POWER ACTIVE!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	label.add_theme_font_size_override("font_size", 9)
	label.position = player.position + Vector2(-100, -45)
	add_child(label)
	
	# Anima a subir e desaparecer
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 20.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): label.queue_free())

func _process(delta):
	# Se a luta começou e não estamos em cutscene
	if cutscene_active:
		return
		
	if not is_instance_valid(boss) or not is_instance_valid(player):
		return
		
	# Lógica da Fase 2
	if boss.is_phase_2:
		# Inundação de ácido no chão
		if is_instance_valid(poison_floor) and not poison_floor.active:
			poison_floor.start_rising()
			
		# Spawn de pedras de detritos caindo do teto
		rock_spawn_timer += delta
		if rock_spawn_timer >= ROCK_SPAWN_INTERVAL:
			rock_spawn_timer = 0.0
			_spawn_falling_rock()

func _spawn_falling_rock():
	if not is_instance_valid(player):
		return
		
	var RockScript = load("res://scripts/apolo_python/falling_rock.gd")
	var rock = Area2D.new()
	rock.set_script(RockScript)
	
	# Escolhe posição X. 50% de hipóteses de cair perto do jogador para o forçar a mover-se
	var spawn_x = randf_range(-400.0, 400.0)
	if randf() > 0.45:
		spawn_x = player.global_position.x + randf_range(-90.0, 90.0)
		
	# Clampa aos limites da arena
	spawn_x = clamp(spawn_x, -520.0, 520.0)
	
	# Spawn bem alto no teto (Y = -350)
	rock.position = Vector2(spawn_x, -350.0)
	add_child(rock)
