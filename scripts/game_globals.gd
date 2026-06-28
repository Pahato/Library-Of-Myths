extends Node

var music_player: AudioStreamPlayer
var master_volume: float = 0.8
var music_volume: float = 0.8
var sfx_volume: float = 0.8

# --- Idioma ---
enum Language { PT, EN }
var current_language: Language = Language.PT
var keystroke_enabled: bool = true
var rhythm_scroll_down: bool = false


# --- Resolução ---
var current_resolution_index: int = 3 # Padrão: Fullscreen
var resolution_options: Array = [
	{"text": "1280x720", "width": 1280, "height": 720, "fullscreen": false},
	{"text": "1600x900", "width": 1600, "height": 900, "fullscreen": false},
	{"text": "1920x1080", "width": 1920, "height": 1080, "fullscreen": false},
	{"text": "Fullscreen", "width": 0, "height": 0, "fullscreen": true}
]

func _detect_recommended_resolution():
	var screen_size = DisplayServer.screen_get_size()
	print("[RESOLUTION] Ecrã detetado: ", screen_size)
	
	# Procura se o tamanho do ecrã coincide com alguma das nossas resoluções windowed
	for i in range(resolution_options.size()):
		var opt = resolution_options[i]
		if not opt["fullscreen"] and opt["width"] == screen_size.x and opt["height"] == screen_size.y:
			current_resolution_index = i
			print("[RESOLUTION] Resolução recomendada detetada: ", opt["text"])
			return
			
	# Se não coincidir, o padrão recomendado é Fullscreen (Ecrã Inteiro)
	current_resolution_index = 3
	print("[RESOLUTION] Usando Fullscreen (Ecrã Inteiro) como recomendado")

func apply_resolution(index: int):
	if index < 0 or index >= resolution_options.size():
		return
	current_resolution_index = index
	var option = resolution_options[index]
	
	# Detect current screen index to avoid jumping to the primary monitor
	var current_screen = DisplayServer.window_get_current_screen()
	
	if option["fullscreen"]:
		# Ensure we keep the screen index when going fullscreen
		DisplayServer.window_set_current_screen(current_screen)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		print("[RESOLUTION] Aplicado: Ecrã Inteiro no ecrã ", current_screen)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Crucial: set screen first to ensure size/position are calculated relative to this screen
		DisplayServer.window_set_current_screen(current_screen)
		DisplayServer.window_set_size(Vector2i(option["width"], option["height"]))
		
		# Center the window on the CURRENT screen
		var screen_pos = DisplayServer.screen_get_position(current_screen)
		var screen_size = DisplayServer.screen_get_size(current_screen)
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position(screen_pos + (screen_size - window_size) / 2)
		print("[RESOLUTION] Aplicado: ", option["text"], " no ecrã ", current_screen)

# --- Dificuldade ---
enum Difficulty { EASY, NORMAL, HARD }
var current_difficulty: Difficulty = Difficulty.NORMAL

# --- Estado do Livro III (Thor Run) ---
var thor_run_active: bool = false
var thor_hp: int = 80
var thor_max_hp: int = 80
var thor_gold: int = 0
var thor_deck: Array = []
var thor_relics: Array = []
var thor_act: int = 1
var thor_current_layer: int = 1
var thor_map_path: Array = [] # Caminho percorrido no mapa
var thor_map_data: Dictionary = {} # Nós gerados
var thor_node_id: String = "" # Nó atual sendo visitado
var thor_intro_played: bool = false

# --- Traduções ---
var translations: Dictionary = {
	"PT": {
		# Main Menu
		"menu_title": "A Biblioteca de Mitos",
		"menu_subtitle": "Escolhe um livro para ler e reviver a lenda",
		"menu_book_apolo": "LIVRO I\nApolo\nvs\nPíton",
		"menu_book_shiva": "LIVRO II\nShiva\nvs\nRudra",
		"menu_book_thor": "LIVRO III\nThor\nvs\nJörmungandr",
		"menu_book_susanoo": "LIVRO IV\nSusanoo\nvs\nOrochi",
		"menu_locked_thor": "O Livro III ainda está a ser escrito...",
		"menu_locked_susanoo": "O Livro IV ainda está a ser escrito...",
		"menu_diff_easy": "Fácil",
		"menu_diff_normal": "Normal",
		"menu_diff_hard": "Difícil",
		"menu_diff_label": "Dificuldade: ",
		"menu_credits": "Créditos",
		"menu_options": "Opções",
		"menu_status_globals_error": "GameGlobals não carregado!",
		
		# Options Menu
		"options_title": "Opções",
		"options_keystroke_enabled": "Keystroke [Ativado]",
		"options_keystroke_disabled": "Keystroke [Desativado]",
		"options_language": "Idioma [Português]",
		"options_resolution": "Resolução [TEXT]",
		"resolution_fullscreen": "Ecrã Inteiro",
		"options_keybinds": "Personalizar Teclas",
		"options_back": "Voltar",
		"options_apply": "Aplicar",
		"confirm_title": "Alterações não aplicadas",
		"confirm_text": "Tens alterações que não foram aplicadas.\nO que gostarias de fazer?",
		"confirm_apply_exit": "Sair e Aplicar",
		"confirm_discard_exit": "Só Sair",
		"confirm_cancel": "Cancelar",
		
		# Keybinds Menu
		"keybinds_title": "Personalizar Teclas",
		"keybinds_move_left": "Mover Esquerda",
		"keybinds_move_right": "Mover Direita",
		"keybinds_jump": "Saltar / Jump",
		"keybinds_parry": "Parry / Defesa",
		"keybinds_shoot": "Disparar / Tiro",
		"keybinds_press_any_key": "Pressione uma tecla...",
		"keybinds_duplicate": "Tecla já está em uso!",
		"keybinds_reset": "Restaurar Padrão",
		
		# Credits Screen
		"credits_title": "📖  A BIBLIOTECA DE MITOS",
		"credits_dev": "Desenvolvimento/Programação",
		"credits_art": "Arte/Sprites",
		"credits_engine": "Motor de Jogo",
		"credits_inst": "Instituição",
		"credits_date": "Projeto PAP — 2026/2027",
		
		# Pause Menu
		"pause_resume": "▶  Continuar",
		"pause_menu": "🏠  Menu Principal",
		"pause_paused": "⏸  Pausa",
		
		# GameOver Screen
		"gameover_title": "Morreste...",
		"gameover_retry": "Tentar Novamente",
		"gameover_menu": "Voltar à Biblioteca",
		
		# Victory Screen
		"victory_title": "Vitória de Apolo!",
		"victory_menu": "Voltar à Biblioteca",
		
		# Character Names
		"char_narrator": "Narrador",
		"char_apolo": "Apolo",
		"char_python": "Píton",
		
		# Dialogue - Intro
		"dialogue_narrator_1": "De todos os deuses do Olimpo, Apolo destaca-se como o senhor da luz, da verdade e da profecia...",
		"dialogue_narrator_2": "Enviado pelos céus para pôr fim às sombras, o jovem arqueiro solar desce à terra de Delfos...",
		"dialogue_apolo_reflect_1": "Delfos... Este solo outrora sagrado está frio, corrompido pela presença do mal.",
		"dialogue_apolo_reflect_2": "A terrível serpente Píton deve estar por perto. Tenho de a purificar com as minhas flechas de luz!",
		"dialogue_apolo_python_1": "Píton! O teu veneno não vai mais corromper esta terra sagrada!",
		"dialogue_python_apolo_1": "Sssss... Outro deus tolo em forma de pato que ousa desafiar-me!",
		"dialogue_apolo_python_2": "Eu trago as flechas de luz do Sol! Prepara-te para a tua queda!",
		"dialogue_apolo_victory_1": "Está feito. A luz do Sol triunfou sobre as trevas!",
		"dialogue_apolo_victory_2": "Delfos está salva. Que a profecia se cumpra!",
		
		# Game UI
		"ui_recharging": "FLECHAS: Recarregando...",
		"ui_arrows": "FLECHAS: ",
		"ui_phase_1": "Fase 1: Derrote a forma física de Píton",
		"ui_shield_active": "ESCUDO ATIVO! Carregar ambos os Altares:  ",
		"ui_stunned": "PÍTON SHADOW ATORDOADA! APROVEITA!",
		"ui_shield_broken": "Escudo Destruído! Dispara sem parar!",
		"ui_solar_active": "PODER SOLAR ATIVO! (TIRO TRIPLO)",
		"ui_dash_ready": "DASH: PRONTO [SHIFT]",
		"ui_dash_cooldown": "DASH: ",
		
		# Boss Names
		"boss_name_phase_1": "PÍTON, A SERPENTE DE DELFOS",
		"boss_name_phase_2": "PÍTON SHADOW, A FORMA REVELADA DO CAOS",
		
		# Character Names (Book 2)
		"char_shiva": "Shiva",
		"char_rudra": "Rudra",
		
		# Dialogue - Book 2 Intro
		"dialogue_narrator_shiva_1": "No topo do sagrado Monte Kailash, o universo treme sob o som de tambores distantes...",
		"dialogue_narrator_shiva_2": "Shiva, o deus da dança e da transformação, prepara-se para enfrentar a ira da tempestade...",
		"dialogue_shiva_reflect_1": "Esta montanha é o pilar do cosmos. Rudra deseja trazer a destruição antes do tempo.",
		"dialogue_shiva_reflect_2": "Devo dançar o ritmo da criação para harmonizar a sua fúria destrutiva!",
		"dialogue_shiva_rudra_1": "Rudra! Controla a tua fúria! A dança cósmica restabelecerá o equilíbrio.",
		"dialogue_rudra_shiva_1": "ROOOAAR! A tua dança é fraca, Shiva! Deixa que a tempestade consuma tudo!",
		"dialogue_shiva_rudra_2": "QUACK! Então sente o compasso do universo! Segue o meu ritmo!",
		"dialogue_shiva_victory_1": "A tempestade acalmou... O equilíbrio do cosmos foi restaurado.",
		"dialogue_shiva_victory_2": "Que a paz reine sobre Kailash.",
		
		# Rhythm UI & Settings
		"ui_rhythm_combo": "Combo: ",
		"ui_rhythm_score": "Pontos: ",
		"ui_rhythm_accuracy": "Precisão: ",
		"ui_rhythm_perfect": "PERFEITO!",
		"ui_rhythm_good": "BOM",
		"ui_rhythm_okay": "OK",
		"ui_rhythm_miss": "FALHOU!",
		"ui_rhythm_shock": "CHOCADO!",
		"options_rhythm_scroll": "Direção das Setas",
		"options_rhythm_scroll_up": "Setas a Subir",
		"options_rhythm_scroll_down": "Setas a Descer",
		"victory_title_shiva": "Vitória de Shiva!",
		"boss_name_rudra": "RUDRA, O SENHOR DAS TEMPESTADES",
		"gameover_title_shiva": "A tempestade consumiu o cosmos...",
		"ui_rhythm_title": "DUELO CÓSMICO DE RITMO",
		"ui_rhythm_player_lane": "PLAYER (A S W D / ◀ ▼ ▲ ▶)",
		"ui_rhythm_boss_lane": "RUDRA (OPONENTE)",
		"options_audio": "Controlo de Áudio",
		"audio_title": "Definições de Áudio",
		"audio_master": "Volume Geral",
		"audio_music": "Volume da Música",
		"audio_sfx": "Volume de Efeitos",
		
		# Character Names & Dialogue (Book 3)
		"char_thor": "Thor",
		"char_jormungandr": "Jörmungandr",
		
		# Dialogue - Book 3 Intro
		"dialogue_thor_story_intro_1": "Midgard, o reino dos homens, foi assolado pelo frio do Fimbulwinter. Das profundezas do oceano, a Serpente do Mundo acordou, espalhando o seu veneno pelos reinos nórdicos...",
		"dialogue_thor_story_intro_2": "O Ragnarök aproxima-se. Para salvar os nove reinos, Thor deve marchar até à batalha final contra Jörmungandr.",
		"dialogue_thor_story_intro_3": "Mjölnir clama pelo trovão. Nenhum lobo, gigante ou esqueleto de Helheim ficará de pé!",
		"dialogue_thor_intro_1": "O Ragnarök aproxima-se... Sinto o veneno da serpente no ar de Midgard.",
		"dialogue_thor_intro_2": "Mjölnir guiará o meu caminho. Nenhuma fera de Helheim me impedirá!",
		"dialogue_draugr_intro": "Gggrrr... Carnes vivas... Não passarás por Midgard!",
		"dialogue_generic_thor_fight_1": "Aparece, criatura! Sente o trovão de Asgard!",
		"dialogue_generic_monster_growl": "Roaar! O monstro avança ferozmente!",
		"dialogue_thor_jormungandr_1": "Jörmungandr! A nossa batalha final é hoje! Pelo destino dos nove reinos!",
		"dialogue_jormungandr_thor_1": "ROOOAAR! Deus do Trovão... O teu corpo cairá no oceano e o teu martelo afundará no abismo!",
		"dialogue_thor_jormungandr_2": "Veremos se o teu veneno é mais forte que o relâmpago divino! QUACK!",
		"dialogue_thor_victory_1": "Jörmungandr foi derrotada... O Ragnarök foi travado e a serpente jaz nas profundezas.",
		"dialogue_thor_victory_2": "Midgard está salva! O trovão de Asgard triunfa uma vez mais!",
		
		# Enemy Names
		"draugr": "Draugr",
		"lobo_fenrir": "Lobo de Fenrir",
		"gigante_gelo": "Gigante de Gelo",
		"corvos_hel": "Corvos de Hel",
		"esqueleto_viking": "Esqueleto Viking",
		"hel_rainha": "Hel, Rainha dos Mortos",
		"fenrir_gigante": "Fenrir, Lobo Gigante",
		"jormungandr": "Jörmungandr",
		
		# Tutorial - Livro I (Apollo vs Python)
		"tutorial_title_book1": "📖 LIVRO I — Apolo vs Píton",
		"tutorial_story_book1": "Apolo desceu à terra sagrada de Delfos para purificar a terrível serpente Píton que corrompe o oráculo.",
		"tutorial_controls_title": "⌨ CONTROLOS",
		"tutorial_controls_book1": "A / ◀  →  Mover Esquerda\nD / ▶  →  Mover Direita\nEspaço / W / ▲  →  Saltar\nBotão Esquerdo do Rato  →  Disparar Flecha\nShift Esq. / Botão B  →  Dash Solar",
		"tutorial_objective_title": "🎯 OBJETIVO",
		"tutorial_objective_book1": "Fase 1: Reduza a vida da Píton a 50%\nFase 2: Ative os 2 Pilares Solares nas plataformas laterais para quebrar o escudo\nDepois: Dispare até à vitória!",
		"tutorial_tip_book1": "💡 Os Pilares Solares só ficam disponíveis na Fase 2!",
		
		# Tutorial - Livro II (Shiva vs Rudra)
		"tutorial_title_book2": "📖 LIVRO II — Shiva vs Rudra",
		"tutorial_story_book2": "Shiva deve dançar ao ritmo cósmico para harmonizar a fúria destrutiva de Rudra no topo do Monte Kailash.",
		"tutorial_controls_book2": "A / ◀  →  Nota Esquerda\nS / ▼  →  Nota Baixo\nW / ▲  →  Nota Cima\nD / ▶  →  Nota Direita\nESC  →  Pausar",
		"tutorial_objective_book2": "Acerte nas notas ao ritmo da música para encher a barra de Shiva!\nSe a barra chegar ao limite de Rudra, perdes.\nSobrevive até ao fim da música para vencer!",
		"tutorial_tip_book2": "💡 As notas de Tempestade (douradas) prejudicam-te — evita-as!",
		
		# Tutorial - Livro III (Thor vs Jörmungandr)
		"tutorial_title_book3": "📖 LIVRO III — Thor vs Jörmungandr",
		"tutorial_story_book3": "O Ragnarök chegou. Thor, o deus do trovão, deve atravessar os reinos de Midgard, Jotunheim e Helheim, enfrentando horrores nórdicos até à batalha final contra Jörmungandr, a Serpente do Mundo.",
		"tutorial_controls_book3": "Rato (Clique)  →  Selecionar e Jogar Carta\nBotão  →  Terminar Turno\nESC  →  Pausar",
		"tutorial_objective_book3": "Use cartas de ataque, escudo e poderes para derrotar os inimigos!\nCada carta custa energia (⚡). Gere bem os seus recursos!\nDerrote o inimigo antes que ele o destrua!",
		"tutorial_tip_book3": "💡 Veja a Próxima Ação do inimigo, por cima da barra de vida — mostra se vai atacar, defender ou ganhar Força!",
		
		"tutorial_play": "▶  Jogar!",
		"tutorial_back": "◀  Voltar",
	},
	"EN": {
		# Main Menu
		"menu_title": "The Library of Myths",
		"menu_subtitle": "Choose a book to read and relive the legend",
		"menu_book_apolo": "BOOK I\nApollo\nvs\nPython",
		"menu_book_shiva": "BOOK II\nShiva\nvs\nRudra",
		"menu_book_thor": "BOOK III\nThor\nvs\nJörmungandr",
		"menu_book_susanoo": "BOOK IV\nSusanoo\nvs\nOrochi",
		"menu_locked_thor": "Book III is still being written...",
		"menu_locked_susanoo": "Book IV is still being written...",
		"menu_diff_easy": "Easy",
		"menu_diff_normal": "Normal",
		"menu_diff_hard": "Hard",
		"menu_diff_label": "Difficulty: ",
		"menu_credits": "Credits",
		"menu_options": "Options",
		"menu_status_globals_error": "GameGlobals not loaded!",
		
		# Options Menu
		"options_title": "Options",
		"options_keystroke_enabled": "Keystroke [Enabled]",
		"options_keystroke_disabled": "Keystroke [Disabled]",
		"options_language": "Language [English]",
		"options_resolution": "Resolution [TEXT]",
		"resolution_fullscreen": "Fullscreen",
		"options_keybinds": "Customize Keys",
		"options_back": "Back",
		"options_apply": "Apply",
		"confirm_title": "Unapplied Changes",
		"confirm_text": "You have changes that were not applied.\nWhat would you like to do?",
		"confirm_apply_exit": "Apply and Exit",
		"confirm_discard_exit": "Just Exit",
		"confirm_cancel": "Cancel",
		
		# Keybinds Menu
		"keybinds_title": "Customize Keys",
		"keybinds_move_left": "Move Left",
		"keybinds_move_right": "Move Right",
		"keybinds_jump": "Jump",
		"keybinds_parry": "Parry / Block",
		"keybinds_shoot": "Shoot / Fire",
		"keybinds_press_any_key": "Press any key...",
		"keybinds_duplicate": "Key already in use!",
		"keybinds_reset": "Reset Default",
		
		# Credits Screen
		"credits_title": "📖  THE LIBRARY OF MYTHS",
		"credits_dev": "Development & Programming",
		"credits_art": "Art & Sprites",
		"credits_engine": "Game Engine",
		"credits_date": "PAP Project — 2025/2026",
		
		# Pause Menu
		"pause_resume": "▶  Resume",
		"pause_menu": "🏠  Main Menu",
		"pause_paused": "⏸  Pause",
		
		# GameOver Screen
		"gameover_title": "You Died...",
		"gameover_retry": "Try Again",
		"gameover_menu": "Return to Library",
		
		# Victory Screen
		"victory_title": "Apollo's Victory!",
		"victory_menu": "Return to Library",
		
		# Character Names
		"char_narrator": "Narrator",
		"char_apolo": "Apollo",
		"char_python": "Python",
		
		# Dialogue - Intro
		"dialogue_narrator_1": "Of all the gods of Olympus, Apollo stands out as the lord of light, truth, and prophecy...",
		"dialogue_narrator_2": "Sent by the heavens to put an end to the shadows, the young solar archer descends to Delphi...",
		"dialogue_apolo_reflect_1": "Delphi... This once sacred ground is cold, corrupted by the presence of evil.",
		"dialogue_apolo_reflect_2": "The terrible serpent Python must be nearby. I must purify it with my arrows of light!",
		"dialogue_apolo_python_1": "Python! Your venom will no longer corrupt this sacred land!",
		"dialogue_python_apolo_1": "Sssss... Another foolish duck-shaped god who dares to challenge me!",
		"dialogue_apolo_python_2": "I bring the solar arrows of light! Prepare for your fall!",
		"dialogue_apolo_victory_1": "It is done. The light of the Sun has triumphed over darkness!",
		"dialogue_apolo_victory_2": "Delphi is saved. Let the prophecy be fulfilled!",
		
		# Game UI
		"ui_recharging": "ARROWS: Recharging...",
		"ui_arrows": "ARROWS: ",
		"ui_phase_1": "Phase 1: Defeat the physical form of Python",
		"ui_shield_active": "SHIELD ACTIVE! Charge both Altars:  ",
		"ui_stunned": "PYTHON SHADOW STUNNED! STRIKE NOW!",
		"ui_shield_broken": "Shield Broken! Shoot continuously!",
		"ui_solar_active": "SOLAR POWER ACTIVE! (TRIPLE SHOT)",
		"ui_dash_ready": "DASH: READY [SHIFT]",
		"ui_dash_cooldown": "DASH: ",
		
		# Boss Names
		"boss_name_phase_1": "PYTHON, THE SERPENT OF DELPHI",
		"boss_name_phase_2": "PYTHON SHADOW, THE REVEALED FORM OF CHAOS",
		
		# Character Names (Book 2)
		"char_shiva": "Shiva",
		"char_rudra": "Rudra",
		
		# Dialogue - Book 2 Intro
		"dialogue_narrator_shiva_1": "Atop the sacred Mount Kailash, the universe trembles under the sound of distant drums...",
		"dialogue_narrator_shiva_2": "Shiva, the god of dance and transformation, prepares to face the wrath of the storm...",
		"dialogue_shiva_reflect_1": "This mountain is the pillar of the cosmos. Rudra wishes to bring destruction before its time.",
		"dialogue_shiva_reflect_2": "I must dance the rhythm of creation to harmonize his destructive fury!",
		"dialogue_shiva_rudra_1": "Rudra! Control your fury! The cosmic dance will restore balance.",
		"dialogue_rudra_shiva_1": "ROOOAAR! Your dance is weak, Shiva! Let the storm consume everything!",
		"dialogue_shiva_rudra_2": "QUACK! Then feel the beat of the universe! Follow my rhythm!",
		"dialogue_shiva_victory_1": "The storm has calmed... The balance of the cosmos has been restored.",
		"dialogue_shiva_victory_2": "Let peace reign over Kailash.",
		
		# Rhythm UI & Settings
		"ui_rhythm_combo": "Combo: ",
		"ui_rhythm_score": "Score: ",
		"ui_rhythm_accuracy": "Accuracy: ",
		"ui_rhythm_perfect": "PERFECT!",
		"ui_rhythm_good": "GOOD",
		"ui_rhythm_okay": "OK",
		"ui_rhythm_miss": "MISS!",
		"ui_rhythm_shock": "SHOCKED!",
		"options_rhythm_scroll": "Arrow Direction",
		"options_rhythm_scroll_up": "Arrows Up",
		"options_rhythm_scroll_down": "Arrows Down",
		"victory_title_shiva": "Shiva's Victory!",
		"boss_name_rudra": "RUDRA, THE LORD OF STORMS",
		"gameover_title_shiva": "The storm consumed the cosmos...",
		"ui_rhythm_title": "COSMIC RHYTHM DUEL",
		"ui_rhythm_player_lane": "PLAYER (A S W D / ◀ ▼ ▲ ▶)",
		"ui_rhythm_boss_lane": "RUDRA (OPPONENT)",
		"options_audio": "Audio Control",
		"audio_title": "Audio Settings",
		"audio_master": "Master Volume",
		"audio_music": "Music Volume",
		"audio_sfx": "SFX Volume",
		
		# Character Names & Dialogue (Book 3)
		"char_thor": "Thor",
		"char_jormungandr": "Jörmungandr",
		
		# Dialogue - Book 3 Intro
		"dialogue_thor_story_intro_1": "Midgard, the realm of men, has been plagued by the cold of Fimbulwinter. From the depths of the ocean, the World Serpent awakened, spreading its poison across the Norse realms...",
		"dialogue_thor_story_intro_2": "Ragnarök draws near. To save the nine realms, Thor must march towards the final battle against Jörmungandr.",
		"dialogue_thor_story_intro_3": "Mjölnir calls for the thunder. No wolf, giant, or skeleton of Helheim shall stand!",
		"dialogue_thor_intro_1": "Ragnarök draws near... I feel the serpent's poison in Midgard's air.",
		"dialogue_thor_intro_2": "Mjölnir will guide my way. No beast of Helheim shall stop me!",
		"dialogue_draugr_intro": "Gggrrr... Living flesh... You shall not pass through Midgard!",
		"dialogue_generic_thor_fight_1": "Face me, creature! Feel the thunder of Asgard!",
		"dialogue_generic_monster_growl": "Roaar! The monster lunges fiercely!",
		"dialogue_thor_jormungandr_1": "Jörmungandr! Our final battle is today! For the fate of the nine realms!",
		"dialogue_jormungandr_thor_1": "ROOOAAR! God of Thunder... Your body shall fall into the ocean, and your hammer will sink into the abyss!",
		"dialogue_thor_jormungandr_2": "We shall see if your poison is stronger than the divine lightning! QUACK!",
		"dialogue_thor_victory_1": "Jörmungandr has been defeated... Ragnarök has been halted and the serpent lies in the depths.",
		"dialogue_thor_victory_2": "Midgard is saved! The thunder of Asgard triumphs once more!",
		
		# Enemy Names
		"draugr": "Draugr",
		"lobo_fenrir": "Fenrir Wolf",
		"gigante_gelo": "Frost Giant",
		"corvos_hel": "Crows of Hel",
		"esqueleto_viking": "Viking Skeleton",
		"hel_rainha": "Hel, Queen of the Dead",
		"fenrir_gigante": "Fenrir, The Great Wolf",
		"jormungandr": "Jörmungandr",
		
		# Tutorial - Book I (Apollo vs Python)
		"tutorial_title_book1": "📖 BOOK I — Apollo vs Python",
		"tutorial_story_book1": "Apollo descended to the sacred land of Delphi to purify the terrible serpent Python that corrupts the oracle.",
		"tutorial_controls_title": "⌨ CONTROLS",
		"tutorial_controls_book1": "A / ◀  →  Move Left\nD / ▶  →  Move Right\nSpace / W / ▲  →  Jump\nLeft Mouse Button  →  Shoot Arrow\nLeft Shift / Button B  →  Solar Dash",
		"tutorial_objective_title": "🎯 OBJECTIVE",
		"tutorial_objective_book1": "Phase 1: Reduce Python's HP to 50%\nPhase 2: Activate the 2 Solar Pillars on the side platforms to break the shield\nThen: Shoot until victory!",
		"tutorial_tip_book1": "💡 Solar Pillars only become available in Phase 2!",
		
		# Tutorial - Book II (Shiva vs Rudra)
		"tutorial_title_book2": "📖 BOOK II — Shiva vs Rudra",
		"tutorial_story_book2": "Shiva must dance to the cosmic rhythm to harmonize Rudra's destructive fury atop Mount Kailash.",
		"tutorial_controls_book2": "A / ◀  →  Left Note\nS / ▼  →  Down Note\nW / ▲  →  Up Note\nD / ▶  →  Right Note\nESC  →  Pause",
		"tutorial_objective_book2": "Hit the notes to the beat to fill Shiva's bar!\nIf the bar reaches Rudra's side, you lose.\nSurvive until the end of the song to win!",
		"tutorial_tip_book2": "💡 Storm notes (golden) hurt you — avoid them!",
		
		# Tutorial - Book III (Thor vs Jörmungandr)
		"tutorial_title_book3": "📖 BOOK III — Thor vs Jörmungandr",
		"tutorial_story_book3": "Ragnarök has come. Thor, the god of thunder, must journey through the realms of Midgard, Jotunheim and Helheim, facing Norse horrors until the final battle against Jörmungandr, the World Serpent.",
		"tutorial_controls_book3": "Mouse (Click)  →  Select and Play Card\nButton  →  End Turn\nESC  →  Pause",
		"tutorial_objective_book3": "Use attack, shield and power cards to defeat enemies!\nEach card costs energy (⚡). Manage your resources wisely!\nDefeat the enemy before it destroys you!",
		"tutorial_tip_book3": "💡 Watch the enemy's Next Action above their health bar — it shows if they'll attack, defend, or gain Strength!",
		
		"tutorial_play": "▶  Play!",
		"tutorial_back": "◀  Back",
	}
}

func get_text(key: String) -> String:
	var lang_str = "PT" if current_language == Language.PT else "EN"
	if translations.has(lang_str) and translations[lang_str].has(key):
		return translations[lang_str][key]
	return key

# --- Configurações por Dificuldade ---
func get_boss_phase1_health() -> int:
	match current_difficulty:
		Difficulty.EASY:   return 15
		Difficulty.NORMAL: return 30
		Difficulty.HARD:   return 45
	return 30

func get_boss_phase2_health() -> int:
	match current_difficulty:
		Difficulty.EASY:   return 20
		Difficulty.NORMAL: return 35
		Difficulty.HARD:   return 55
	return 35

func get_boss_speed() -> float:
	match current_difficulty:
		Difficulty.EASY:   return 25.0
		Difficulty.NORMAL: return 40.0
		Difficulty.HARD:   return 65.0
	return 40.0

func get_boss_ai_cooldown() -> float:
	match current_difficulty:
		Difficulty.EASY:   return 2.8
		Difficulty.NORMAL: return 1.8
		Difficulty.HARD:   return 1.4
	return 1.8

func get_boss_shield_shoot_cooldown() -> float:
	match current_difficulty:
		Difficulty.EASY:   return 9999.0 # Desativado no fácil
		Difficulty.NORMAL: return 1.6
		Difficulty.HARD:   return 1.0
	return 1.6

func get_player_max_health() -> int:
	match current_difficulty:
		Difficulty.EASY:   return 8
		Difficulty.NORMAL: return 6
		Difficulty.HARD:   return 4
	return 6

func get_difficulty_label() -> String:
	match current_difficulty:
		Difficulty.EASY:   return get_text("menu_diff_easy")
		Difficulty.NORMAL: return get_text("menu_diff_normal")
		Difficulty.HARD:   return get_text("menu_diff_hard")
	return get_text("menu_diff_normal")

# --- Persistência de Definições ---
const SAVE_PATH = "user://settings.cfg"

func save_settings():
	var config = ConfigFile.new()
	config.set_value("settings", "keystroke_enabled", keystroke_enabled)
	config.set_value("settings", "language", int(current_language))
	config.set_value("settings", "difficulty", int(current_difficulty))
	config.set_value("settings", "resolution_index", current_resolution_index)
	config.set_value("settings", "rhythm_scroll_down", rhythm_scroll_down)
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)

	
	for action in ["move_left", "move_right", "jump", "parry", "shoot"]:
		var events = InputMap.action_get_events(action)
		if not events.is_empty():
			var event = events[0]
			if event is InputEventKey:
				config.set_value("keybinds", action, {"type": "key", "code": event.physical_keycode})
			elif event is InputEventMouseButton:
				config.set_value("keybinds", action, {"type": "mouse", "code": event.button_index})
				
	config.save(SAVE_PATH)
	print("[SETTINGS] Gravadas com sucesso!")

func reset_to_defaults():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		config.erase_section("keybinds")
		config.save(SAVE_PATH)
	for action in ["move_left", "move_right", "jump", "parry", "shoot"]:
		InputMap.action_erase_events(action)
	_setup_default_controls()
	print("[SETTINGS] Controlos padrão restaurados!")

func load_settings():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		print("[SETTINGS] Nenhum ficheiro encontrado, a usar padrão.")
		_detect_recommended_resolution()
		apply_resolution(current_resolution_index)
		return
		
	keystroke_enabled = config.get_value("settings", "keystroke_enabled", true)
	current_language = config.get_value("settings", "language", Language.PT) as Language
	current_difficulty = config.get_value("settings", "difficulty", Difficulty.NORMAL) as Difficulty
	rhythm_scroll_down = config.get_value("settings", "rhythm_scroll_down", false)
	master_volume = config.get_value("settings", "master_volume", 0.8)
	music_volume = config.get_value("settings", "music_volume", 0.8)
	sfx_volume = config.get_value("settings", "sfx_volume", 0.8)
	
	current_resolution_index = config.get_value("settings", "resolution_index", -1)

	if current_resolution_index == -1:
		_detect_recommended_resolution()
	apply_resolution(current_resolution_index)
	
	for action in ["move_left", "move_right", "jump", "parry", "shoot"]:
		if config.has_section_key("keybinds", action):
			var data = config.get_value("keybinds", action)
			InputMap.action_erase_events(action)
			var event = null
			if data["type"] == "key":
				event = InputEventKey.new()
				event.physical_keycode = data["code"]
			elif data["type"] == "mouse":
				event = InputEventMouseButton.new()
				event.button_index = data["code"]
				
			if event:
				InputMap.action_add_event(action, event)
				
	print("[SETTINGS] Carregadas com sucesso!")

func _ready():
	# Configurar os controlos padrão no InputMap
	_setup_default_controls()
	# Sobrescrever com definições salvas se existirem
	load_settings()
	
	# Criar os buses de áudio se não existirem
	var music_bus_idx = AudioServer.get_bus_index("Music")
	if music_bus_idx == -1:
		AudioServer.add_bus()
		music_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_idx, "Music")
		AudioServer.set_bus_send(music_bus_idx, "Master")
		
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx == -1:
		AudioServer.add_bus()
		sfx_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		AudioServer.set_bus_send(sfx_bus_idx, "Master")

	# Aplicar os volumes iniciais
	apply_volume("Master", master_volume)
	apply_volume("Music", music_volume)
	apply_volume("SFX", sfx_volume)
	
	music_player = AudioStreamPlayer.new()
	music_player.name = "GlobalMusicPlayer"
	music_player.bus = "Music"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)

func _setup_default_controls():
	# 1. move_left
	_ensure_action("move_left", [
		{"type": "key", "code": KEY_A},
		{"type": "key", "code": KEY_LEFT},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_LEFT},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0}
	])
	
	# 2. move_right
	_ensure_action("move_right", [
		{"type": "key", "code": KEY_D},
		{"type": "key", "code": KEY_RIGHT},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_RIGHT},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0}
	])
	
	# 3. jump
	_ensure_action("jump", [
		{"type": "key", "code": KEY_SPACE},
		{"type": "key", "code": KEY_W},
		{"type": "key", "code": KEY_UP},
		{"type": "joy_button", "code": JOY_BUTTON_A}
	])
	
	# 4. parry
	_ensure_action("parry", [
		{"type": "key", "code": KEY_C},
		{"type": "key", "code": KEY_SHIFT},
		{"type": "joy_button", "code": JOY_BUTTON_B},
		{"type": "joy_button", "code": JOY_BUTTON_X}
	])
	
	# 5. shoot
	_ensure_action("shoot", [
		{"type": "key", "code": KEY_J},
		{"type": "mouse", "code": MOUSE_BUTTON_LEFT},
		{"type": "joy_button", "code": JOY_BUTTON_X}
	])

func _ensure_action(action_name: String, bindings: Array):
	# Cria a ação se ela não existir de todo no projeto
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	# Só adiciona os eventos se a lista de eventos para esta ação estiver vazia
	# (isto permite que, caso o utilizador defina controlos no editor, eles não sejam sobrepostos)
	if InputMap.action_get_events(action_name).is_empty():
		for binding in bindings:
			var event = null
			match binding["type"]:
				"key":
					event = InputEventKey.new()
					# Usamos physical_keycode para suportar automaticamente layouts regionais (AZERTY, QWERTZ, etc.)
					event.physical_keycode = binding["code"]
				"mouse":
					event = InputEventMouseButton.new()
					event.button_index = binding["code"]
				"joy_button":
					event = InputEventJoypadButton.new()
					event.button_index = binding["code"]
				"joy_axis":
					event = InputEventJoypadMotion.new()
					event.axis = binding["axis"]
					event.axis_value = binding["value"]
			
			if event:
				InputMap.action_add_event(action_name, event)

func play_music(stream_path: String, volume: float = -10.0):
	if not music_player:
		return
	# Don't restart if same track is already playing
	if music_player.stream != null and music_player.stream.resource_path == stream_path and music_player.playing:
		return
	var stream = load(stream_path)
	if stream == null:
		print("[MUSIC] Falha ao carregar: ", stream_path)
		return
	music_player.stream = stream
	music_player.volume_db = volume
	music_player.bus = "Music"
	music_player.play()
	# Reconnect loop signal
	if music_player.finished.is_connected(music_player.play):
		music_player.finished.disconnect(music_player.play)
	music_player.finished.connect(music_player.play)

func play_menu_music():
	play_music("res://assets/music/menu_theme.mp3", -12.0)

func stop_music():
	if music_player:
		music_player.stop()
		music_player.stream = null

func play_click_sound():
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load("res://assets/sounds/click.wav")
	sfx.pitch_scale = 1.1
	sfx.volume_db = -6.0
	sfx.bus = "SFX"
	sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func play_hover_sound():
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load("res://assets/sounds/click.wav")
	sfx.pitch_scale = 0.85
	sfx.volume_db = -14.0
	sfx.bus = "SFX"
	sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func apply_volume(bus_name: String, volume_linear: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		if volume_linear <= 0.01:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume_linear))
