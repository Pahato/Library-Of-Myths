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
var current_book: int = 1

# Hardware Detection
enum InputHardware { KEYBOARD, CONTROLLER }
var current_hardware: InputHardware = InputHardware.KEYBOARD

const CUSTOMIZABLE_ACTIONS = [
	"move_left", "move_right", "move_up", "move_down", "jump", "shoot", "dash",
	"rhythm_lane_0", "rhythm_lane_1", "rhythm_lane_2", "rhythm_lane_3",
	"susanoo_move_left", "susanoo_move_right", "susanoo_move_up", "susanoo_move_down",
	"ui_susanoo_place"
]

const BOOK_ACTIONS = {
	1: ["move_left", "move_right", "jump", "shoot", "dash"],
	2: ["rhythm_lane_0", "rhythm_lane_1", "rhythm_lane_2", "rhythm_lane_3"],
	3: [],
	4: ["susanoo_move_left", "susanoo_move_right", "susanoo_move_up", "susanoo_move_down", "ui_susanoo_place"],
	5: []
}


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
	
	# Deteta o monitor atual para evitar saltar para o monitor primário
	var current_screen = DisplayServer.window_get_current_screen()
	
	if option["fullscreen"]:
		# Preserva o monitor atual ao mudar para ecrã inteiro
		DisplayServer.window_set_current_screen(current_screen)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		print("[RESOLUTION] Aplicado: Ecrã Inteiro no ecrã ", current_screen)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Define o monitor antes de calcular o tamanho e posição da janela
		DisplayServer.window_set_current_screen(current_screen)
		DisplayServer.window_set_size(Vector2i(option["width"], option["height"]))
		
		# Centraliza a janela no monitor atual
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
var thor_current_elite: String = "" # Elite atual para o combate (Fenrir Gigante, Hel Rainha, Gigante de Gelo)

# --- Estado do Livro IV (Susanoo Stealth) ---
var susanoo_barrels_placed: int = 0
var susanoo_intro_played: bool = false

# --- Traduções ---
var translations: Dictionary = {
	"PT": {
		# Main Menu
		"menu_title": "A Biblioteca de Mitos",
		"menu_subtitle": "Escolhe um livro para ler e reviver a lenda",
		"menu_book_apolo": "LIVRO I: Apolo vs Píton",
		"menu_book_shiva": "LIVRO II: Shiva vs Rudra",
		"menu_book_thor": "LIVRO III: Thor vs Jörmungandr",
		"menu_book_susanoo": "LIVRO IV: Susanoo vs Orochi",
		"menu_book_gilgamesh": "LIVRO V: Gilgamesh vs Touro dos Céus",
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
		"options_keystroke_enabled": "Keystroke [ Ativado ]",
		"options_keystroke_disabled": "Keystroke [ Desativado ]",
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
		"keybinds_move_up": "Mover Cima",
		"keybinds_move_down": "Mover Baixo",
		"keybinds_jump": "Saltar",
		"keybinds_shoot": "Disparar Flecha",
		"keybinds_dash": "Dash Solar",
		"keybinds_susanoo_move_left": "Mover Esquerda",
		"keybinds_susanoo_move_right": "Mover Direita",
		"keybinds_susanoo_move_up": "Mover Cima",
		"keybinds_susanoo_move_down": "Mover Baixo",
		"keybinds_susanoo_place": "Colocar Sake",
		"keybinds_rhythm_lane_0": "Nota Esquerda",
		"keybinds_rhythm_lane_1": "Nota Baixo",
		"keybinds_rhythm_lane_2": "Nota Cima",
		"keybinds_rhythm_lane_3": "Nota Direita",
		"keybinds_slot_primary": "Principal",
		"keybinds_slot_extra": "Extra",
		"keybinds_press_any_key": "Prime uma tecla...",
		"keybinds_duplicate": "Tecla já em uso!",
		"keybinds_reset": "Restaurar Padrão",
		"keybinds_clear_hint": "Pressiona DELETE para limpar a tecla",
		"keybinds_book_1": "Livro I (Apolo)",
		"keybinds_book_2": "Livro II (Shiva)",
		"keybinds_book_3": "Livro III (Thor)",
		"keybinds_book_4": "Livro IV (Susanoo)",
		"keybinds_book_5": "Livro V (Gilgamesh)",
		"keybinds_book3_info": "Esta história utiliza exclusivamente o rato:\n• Clique do Rato: Selecionar e jogar cartas\n• Roda do Rato: Rolar e navegar pelo mapa\n• Botão Terminar Turno: Avançar turno\n• ESC: Menu de Pausa",
		"keybinds_book5_info": "Esta história utiliza reflexos dinâmicos e rato:\n• Teclas no Ecrã: Esquivas de QTE\n• Círculos de Precisão: Clicar com timing exato\n• Clique Rápido no Ecrã: Disparar Portão da Babilónia\n• ESC: Menu de Pausa",
		
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
		"dialogue_narrator_1": "O Monte Parnaso treme. Hera, com inveja de Leto (mãe de Apolo), enviou a monstruosa serpente Píton para persegui-la...",
		"dialogue_narrator_2": "Mas agora, apenas quatro dias após nascer, o jovem deus solar Apolo desce a Delfos para caçar a besta e reclamar o Oráculo!",
		"dialogue_apolo_reflect_1": "Delfos... o 'umbigo do mundo' (Omphalos) está envolto em vapores venenosos do abismo.",
		"dialogue_apolo_reflect_2": "A Píton esconde-se nesta fenda sagrada. Vou purificar este templo e fundar os meus Jogos Píticos!",
		"dialogue_apolo_python_1": "Besta ctónica! O teu reinado de terror sobre o oráculo de Gaia termina hoje!",
		"dialogue_python_apolo_1": "Sssss... Apolo! És apenas uma cria divina em forma de pato. O meu veneno dissolverá a tua luz!",
		"dialogue_apolo_python_2": "Cria ou não, as minhas flechas douradas foram forjadas por Hefesto! Sente o calor de mil sóis! QUACK!",
		"dialogue_apolo_victory_1": "A Píton jaz derrotada. O sangue da serpente sagrada deu poder às profecias da Pitonisa!",
		"dialogue_apolo_victory_2": "Delfos agora é a terra da verdade e da luz. Que comecem os Jogos Píticos!",
		
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
		"dialogue_narrator_shiva_1": "Nas neves eternas do Monte Kailash, Rudra, a face tempestuosa do vento e da caça, ruge com fúria cega...",
		"dialogue_narrator_shiva_2": "Para evitar que o cosmos seja reduzido a cinzas antes do ciclo terminar, Shiva Mahadeva deve iniciar a dança da criação!",
		"dialogue_shiva_reflect_1": "Esta montanha sagrada sustenta os céus. A fúria descontrolada de Rudra vai desalinhar o equilíbrio cósmico.",
		"dialogue_shiva_reflect_2": "Vou tocar o meu tambor Damaru e dançar o Tandava para canalizar este caos numa nova criação!",
		"dialogue_shiva_rudra_1": "Rudra! O som do meu Damaru rege o batimento do universo. Junta-te à harmonia cósmica!",
		"dialogue_rudra_shiva_1": "ROOOAAR! A tua ordem é ilusória, Shiva! A minha tempestade vai soprar as estrelas para o esquecimento!",
		"dialogue_shiva_rudra_2": "QUACK! A destruição sem criação é apenas vazio. Sente o compasso eterno da minha dança!",
		"dialogue_shiva_victory_1": "O Tandava dissipou os ventos da destruição. Rudra foi pacificado sob a harmonia das esferas.",
		"dialogue_shiva_victory_2": "Kailash permanece em paz. O ciclo cósmico continua em perfeito equilíbrio.",
		
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
		"ui_rhythm_player_lane": "PLAYER",
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
		"dialogue_thor_story_intro_1": "O Fimbulwinter cobriu Midgard de gelo. A Serpente de Midgard, Jörmungandr, acordou nas profundezas do oceano, cuspindo veneno nos céus...",
		"dialogue_thor_story_intro_2": "O Ragnarök chegou. Profetizou-se que o Deus do Trovão cairia após dar nove passos devido ao veneno da serpente. Thor ergue o Mjölnir para desafiar o destino!",
		"dialogue_thor_story_intro_3": "Mjölnir clama pelo trovão. Nenhum lobo de Fenrir, gigante ou esqueleto de Helheim ficará de pé!",
		"dialogue_thor_intro_1": "O Ragnarök aproxima-se... Sinto o veneno da serpente corromper o ar de Midgard.",
		"dialogue_thor_intro_2": "Mjölnir guiará o meu caminho. Nenhuma fera de Helheim me impedirá!",
		"dialogue_draugr_intro": "Gggrrr... O Ragnarök consome a carne dos deuses! O teu martelo cairá hoje!",
		"dialogue_generic_thor_fight_1": "Pela glória de Asgard e Midgard! Sente a força de Mjölnir e o estalar do trovão!",
		"dialogue_generic_monster_growl": "ROOOAAR! A criatura ruge, erguendo garras cobertas de gelo e escudos quebrados!",
		"dialogue_thor_jormungandr_1": "Jörmungandr! Monstro de Loki! A nossa antiga disputa pesqueira termina hoje na praia do fim do mundo!",
		"dialogue_jormungandr_thor_1": "ROOOAAR! Filho de Odin... O teu escudo partirá sob as minhas presas, e o teu sangue envenenará o oceano!",
		"dialogue_thor_jormungandr_2": "Veremos se o teu veneno aguenta dez mil raios invocados do próprio Asgard! QUACK!",
		"dialogue_thor_victory_1": "A Serpente do Mundo cai sem vida. A profecia foi desafiada e os nove reinos respiram novamente.",
		"dialogue_thor_victory_2": "Midgard está a salvo! Mesmo o veneno do Ragnarök recua perante o poder do trovão! Odin orgulha-se!",
		
		# Diálogo — Cinemática de Despertar (Thor vs Jörmungandr)
		"dialogue_awakening_narrator_1": "Thor perderia tão facilmente assim?",
		"dialogue_awakening_jormungandr_1": "Fraco demais... nem mereces um turno.",
		"dialogue_awakening_thor_1": "Levanta-te... ainda não terminámos.",
		"dialogue_awakening_narrator_2": "O Deus do Trovão ergue-se das cinzas. A verdadeira batalha começa agora!",
		"dialogue_awakening_thor_new": "Não posso cair aqui... Mjölnir... chegou a hora de despertar!",
		"dialogue_awakening_jormungandr_new": "Impossível... continuas a resistir ao meu veneno?",
		
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
		"tutorial_tip_book2": "💡 As notas de Tempestade (douradas) prejudicam a barra de Shiva. Evita tocar nelas!",
		
		# Tutorial - Livro III (Thor vs Jörmungandr)
		"tutorial_title_book3": "📖 LIVRO III — Thor vs Jörmungandr",
		"tutorial_story_book3": "O Ragnarök chegou. Thor, o deus do trovão, deve atravessar os reinos de Midgard, Jotunheim e Helheim, enfrentando horrores nórdicos até à batalha final contra Jörmungandr, a Serpente do Mundo.",
		"tutorial_controls_book3": "Rato (Clique)  →  Selecionar e Jogar Carta\nBotão  →  Terminar Turno\nESC  →  Pausar",
		"tutorial_objective_book3": "Use cartas de ataque, escudo e poderes para derrotar os inimigos!\nCada carta custa energia (⚡). Gere bem os seus recursos!\nDerrote o inimigo antes que ele o destrua!",
		"tutorial_tip_book3": "💡 Observa a próxima ação do inimigo sobre a barra de vida para saberes se vai atacar, defender ou ganhar Força!",
		
		"tutorial_play": "▶  Jogar!",
		"tutorial_back": "◀  Voltar",
		
		# Nomes de Personagens (Livro IV)
		"char_susanoo": "Susanoo",
		"char_orochi": "Yamata no Orochi",
		
		# Diálogo — Intro do Livro IV
		"dialogue_narrator_susanoo_1": "Expulso dos céus, o deus da tempestade Susanoo desceu à província de Izumo e encontrou um casal de idosos em prantos...",
		"dialogue_narrator_susanoo_2": "A terrível serpente de oito cabeças Yamata-no-Orochi já havia devorado sete das suas filhas, e a última, Kushinada, seria a próxima.",
		"dialogue_narrator_susanoo_3": "Susanoo transformou a donzela num pente para o seu cabelo e ordenou ao povo que preparasse sake refinado oito vezes.",
		"dialogue_narrator_susanoo_4": "O plano era simples mas genial: atrair a besta colossal com o sake para beber em oito taças, embebedá-la e atacar!",
		
		# Diálogo — Vitória Livro IV
		"dialogue_narrator_susanoo_victory_1": "O Orochi colocou cada uma das suas cabeças nas taças de sake, bebeu avidamente e adormeceu profundamente.",
		"dialogue_narrator_susanoo_victory_2": "Susanoo desembainhou a sua espada Totsuka-no-Tsurugi e cortou a besta em pedaços! Na cauda do Orochi, descobriu a lendária espada Kusanagi!",
		
		# Diálogo — Game Over Livro IV
		"dialogue_narrator_susanoo_caught": "Uma das oito cabeças farejou o teu rasto e virou os olhos brilhantes na tua direção! O plano falhou!",
		
		# HUD — Livro IV
		"ui_susanoo_barrels": "Barris colocados: ",
		"ui_susanoo_place": "[E] Colocar barril de sake",
		"ui_susanoo_title": "STEALTH DO SAKE",
		
		# Ecrãs de Resultado — Livro IV
		"victory_title_susanoo": "Vitória de Susanoo!",
		"gameover_title_susanoo": "Foste detetado...",
		"gameover_retry_susanoo": "Tentar Novamente",
		
		# Tutorial — Livro IV
		"tutorial_title_book4": "📖 LIVRO IV — Susanoo vs Yamata no Orochi",
		"tutorial_story_book4": "Susanoo, deus da tempestade, deve colocar 8 barris de sake pelos pontos do templo para embebedar o Orochi de 8 cabeças — sem ser visto.",
		"tutorial_controls_book4": "W / A / S / D ou ↑ ← ↓ →  →  Mover\nE  →  Colocar barril de sake",
		"tutorial_objective_book4": "Coloca os 8 barris de sake nos pontos marcados do templo sem ser detetado pelas cabeças do Orochi!\nSe uma cabeça te vir, o jogo acaba.",
		"tutorial_tip_book4": "💡 Presta atenção aos cones de visão laranja. Se entrares num, tens um breve momento para recuar!",
		
		# Nomes de Personagens (Livro V)
		"char_gilgamesh": "Gilgamesh",
		"char_touro": "O Touro dos Céus",
		
		# Diálogo — Intro do Livro V
		"dialogue_narrator_gilgamesh_1": "Após Gilgamesh rejeitar a deusa Ishtar, ela exigiu ao seu pai Anu que libertasse o Touro dos Céus (Gugalanna) para destruir Uruk...",
		"dialogue_narrator_gilgamesh_2": "Os passos da besta colossal causaram sismos que abriram fendas na terra, engolindo centenas de cidadãos.",
		"dialogue_narrator_gilgamesh_3": "Mas Gilgamesh, o Rei dos Heróis, ao lado do seu fiel companheiro Enkidu, ergueu o Portão da Babilónia para defender o seu povo!",
		"dialogue_narrator_gilgamesh_4": "Não é apenas uma batalha por honra: é o confronto definitivo da humanidade contra a opressão dos próprios deuses!",
		
		# Diálogo — Vitória Livro V
		"dialogue_narrator_gilgamesh_victory_1": "Enkidu imobilizou o touro pelos cornos, permitindo a Gilgamesh trespassar a criatura divina com as suas espadas lendárias.",
		"dialogue_narrator_gilgamesh_victory_2": "O Touro dos Céus foi derrotado. Gilgamesh provou que o orgulho de Uruk e a união dos mortais podem superar a fúria do Olimpo e dos deuses!",
		
		# Tutorial — Livro V
		"tutorial_title_book5": "📖 LIVRO V — Gilgamesh vs O Touro dos Céus",
		"tutorial_story_book5": "Gilgamesh deve sobreviver aos ataques catastróficos do Touro dos Céus e carregar a sua Fúria Real para descarregar o Portão da Babilónia.",
		"tutorial_controls_book5": "Rato e Teclado  →  QTE / Esquiva\nClique Rápido  →  Disparar Espadas\nESC  →  Pausar",
		"tutorial_objective_book5": "Sobrevive aos ataques do Boss. Quando a barra de Fúria encher, clica no ecrã para disparar espadas de ouro!",
		"tutorial_tip_book5": "💡 Clica nos círculos de precisão apenas quando o anel exterior encolher até ao centro!",
	},
	"EN": {
		# Main Menu
		"menu_title": "The Library of Myths",
		"menu_subtitle": "Choose a book to read and relive the legend",
		"menu_book_apolo": "BOOK I: Apollo vs Python",
		"menu_book_shiva": "BOOK II: Shiva vs Rudra",
		"menu_book_thor": "BOOK III: Thor vs Jörmungandr",
		"menu_book_susanoo": "BOOK IV: Susanoo vs Orochi",
		"menu_book_gilgamesh": "BOOK V: Gilgamesh vs The Bull of Heaven",
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
		"options_keystroke_enabled": "Keystroke [ Enabled ]",
		"options_keystroke_disabled": "Keystroke [ Disabled ]",
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
		"keybinds_move_up": "Move Up",
		"keybinds_move_down": "Move Down",
		"keybinds_jump": "Jump",
		"keybinds_shoot": "Shoot Arrow",
		"keybinds_dash": "Solar Dash",
		"keybinds_susanoo_move_left": "Move Left",
		"keybinds_susanoo_move_right": "Move Right",
		"keybinds_susanoo_move_up": "Move Up",
		"keybinds_susanoo_move_down": "Move Down",
		"keybinds_susanoo_place": "Place Sake",
		"keybinds_rhythm_lane_0": "Left Note",
		"keybinds_rhythm_lane_1": "Down Note",
		"keybinds_rhythm_lane_2": "Up Note",
		"keybinds_rhythm_lane_3": "Right Note",
		"keybinds_slot_primary": "Primary",
		"keybinds_slot_extra": "Extra",
		"keybinds_press_any_key": "Press any key...",
		"keybinds_duplicate": "Key already in use!",
		"keybinds_reset": "Reset Default",
		"keybinds_clear_hint": "Press DELETE to clear key",
		"keybinds_book_1": "Book I (Apollo)",
		"keybinds_book_2": "Book II (Shiva)",
		"keybinds_book_3": "Book III (Thor)",
		"keybinds_book_4": "Book IV (Susanoo)",
		"keybinds_book_5": "Book V (Gilgamesh)",
		"keybinds_book3_info": "This story exclusively uses the mouse:\n• Mouse Click: Select and play cards\n• Mouse Wheel: Scroll and pan the map\n• End Turn Button: End turn\n• ESC: Pause Menu",
		"keybinds_book5_info": "This story uses dynamic reflexes and mouse:\n• On-Screen Keys: QTE Dodges\n• Precision Circles: Click with exact timing\n• Rapid Screen Click: Fire Gate of Babylon\n• ESC: Pause Menu",
		
		# Credits Screen
		"credits_title": "📖  THE LIBRARY OF MYTHS",
		"credits_dev": "Development & Programming",
		"credits_art": "Art & Sprites",
		"credits_engine": "Game Engine",
		"credits_date": "PAP Project — 2026/2027",
		
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
		"dialogue_narrator_1": "Mount Parnassus trembles. Hera, jealous of Leto (mother of Apollo), sent the monstrous serpent Python to hunt her...",
		"dialogue_narrator_2": "But now, just four days after his birth, the young solar god Apollo descends to Delphi to slay the beast and claim the Oracle!",
		"dialogue_apolo_reflect_1": "Delphi... the 'navel of the world' (Omphalos) is shrouded in toxic, poisonous vapors from the abyss.",
		"dialogue_apolo_reflect_2": "Python hides within this sacred chasm. I shall purify this temple and establish my Pythian Games!",
		"dialogue_apolo_python_1": "Chthonic beast! Your reign of terror over Gaia's sacred oracle ends today!",
		"dialogue_python_apolo_1": "Sssss... Apollo! You are but a newborn divine duckling. My venom shall dissolve your light!",
		"dialogue_apolo_python_2": "Newborn or not, my golden arrows were forged by Hephaestus himself! Feel the heat of a thousand suns! QUACK!",
		"dialogue_apolo_victory_1": "Python lies defeated. The blood of the sacred serpent has empowered the Pythia's prophecies!",
		"dialogue_apolo_victory_2": "Delphi is now the land of light and truth. Let the Pythian Games begin!",
		
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
		"dialogue_narrator_shiva_1": "In the eternal snows of Mount Kailash, Rudra, the stormy face of wind and hunt, roars with blind fury...",
		"dialogue_narrator_shiva_2": "To prevent the cosmos from burning to ashes before the cycle ends, Shiva Mahadeva must begin the dance of creation!",
		"dialogue_shiva_reflect_1": "This sacred mountain supports the heavens. Rudra's untamed anger will throw off the cosmic balance.",
		"dialogue_shiva_reflect_2": "I shall beat my Damaru drum and dance the Tandava to channel this chaos into new creation!",
		"dialogue_shiva_rudra_1": "Rudra! The sound of my Damaru beats the pulse of the universe. Align with the cosmic harmony!",
		"dialogue_rudra_shiva_1": "ROOOAAR! Your dance is but a flutter, Shiva! My storm shall blow the stars into oblivion!",
		"dialogue_shiva_rudra_2": "QUACK! Destruction without creation is but void. Feel the eternal rhythm of my dance!",
		"dialogue_shiva_victory_1": "The Tandava has dissolved the winds of ruin. Rudra has been pacified under the harmony of the spheres.",
		"dialogue_shiva_victory_2": "Kailash remains at peace. The cosmic cycle continues in perfect balance.",
		
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
		"ui_rhythm_player_lane": "PLAYER",
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
		"dialogue_thor_story_intro_1": "Fimbulwinter has covered Midgard in ice. The Midgard Serpent, Jörmungandr, awakened in the ocean depths, spitting poison into the skies...",
		"dialogue_thor_story_intro_2": "Ragnarök has arrived. It is prophesied that the Thunder God will fall after taking nine steps due to the serpent's venom. Thor raises Mjölnir to defy fate!",
		"dialogue_thor_story_intro_3": "Mjölnir calls for the thunder. No wolf of Fenrir, giant, or skeleton of Helheim shall stand!",
		"dialogue_thor_intro_1": "Ragnarök draws near... I feel the serpent's poison corrupting the air of Midgard.",
		"dialogue_thor_intro_2": "Mjölnir will guide my way. No beast of Helheim shall stop me!",
		"dialogue_draugr_intro": "Gggrrr... Ragnarök consumes the flesh of gods! Your hammer falls today!",
		"dialogue_generic_thor_fight_1": "For the glory of Asgard and Midgard! Feel the might of Mjölnir and the crackle of thunder!",
		"dialogue_generic_monster_growl": "ROOOAAR! The creature bellows, raising claws covered in frost and broken shields!",
		"dialogue_thor_jormungandr_1": "Jörmungandr! Spawn of Loki! Our old fishing feud ends today on the shores of the end of the world!",
		"dialogue_jormungandr_thor_1": "ROOOAAR! Son of Odin... Your shield will shatter under my fangs, and your blood shall poison the ocean!",
		"dialogue_thor_jormungandr_2": "We shall see if your poison can withstand ten thousand lightning bolts summoned from Asgard! QUACK!",
		"dialogue_thor_victory_1": "The World Serpent falls lifeless. Prophecy has been defied, and the nine realms breathe once more.",
		"dialogue_thor_victory_2": "Midgard is saved! Even the poison of Ragnarök retreats before the power of thunder! Odin is proud!",
		
		# Dialogue — Awakening Cinematic (Thor vs Jörmungandr)
		"dialogue_awakening_narrator_1": "Would Thor fall so easily?",
		"dialogue_awakening_jormungandr_1": "Too weak... you don't even deserve a turn.",
		"dialogue_awakening_thor_1": "Rise... we're not done yet.",
		"dialogue_awakening_narrator_2": "The God of Thunder rises from the ashes. The true battle begins now!",
		"dialogue_awakening_thor_new": "I cannot fall here... Mjölnir... the hour of awakening has come!",
		"dialogue_awakening_jormungandr_new": "Impossible... you still resist my venom?",
		
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
		"tutorial_tip_book2": "💡 Golden storm notes harm Shiva's balance, make sure to avoid them!",
		
		# Tutorial - Book III (Thor vs Jörmungandr)
		"tutorial_title_book3": "📖 BOOK III — Thor vs Jörmungandr",
		"tutorial_story_book3": "Ragnarök has come. Thor, the god of thunder, must journey through the realms of Midgard, Jotunheim and Helheim, facing Norse horrors until the final battle against Jörmungandr, the World Serpent.",
		"tutorial_controls_book3": "Mouse (Click)  →  Select and Play Card\nButton  →  End Turn\nESC  →  Pause",
		"tutorial_objective_book3": "Use attack, shield and power cards to defeat enemies!\nEach card costs energy (⚡). Manage your resources wisely!\nDefeat the enemy before it destroys you!",
		"tutorial_tip_book3": "💡 Check the enemy's next intent above their health bar to see if they will attack, defend, or gain Strength!",
		
		"tutorial_play": "▶  Play!",
		"tutorial_back": "◀  Back",
		
		# Character Names (Book IV)
		"char_susanoo": "Susanoo",
		"char_orochi": "Yamata no Orochi",
		
		# Dialogue — Book IV Intro
		"dialogue_narrator_susanoo_1": "Banished from heaven, the storm god Susanoo descended to the province of Izumo and found an elderly couple weeping...",
		"dialogue_narrator_susanoo_2": "The terrifying eight-headed serpent Yamata-no-Orochi had already devoured seven of their daughters, and Kushinada was next.",
		"dialogue_narrator_susanoo_3": "Susanoo transformed the maiden into a comb for his hair and ordered the people to brew sake refined eight times.",
		"dialogue_narrator_susanoo_4": "The plan was simple yet brilliant: lure the colossal beast with sake in eight bowls, get it drunk, and strike!",
		
		# Dialogue — Book IV Victory
		"dialogue_narrator_susanoo_victory_1": "The Orochi placed each of its heads into the sake bowls, drank greedily, and fell into a deep slumber.",
		"dialogue_narrator_susanoo_victory_2": "Susanoo raised his sword Totsuka-no-Tsurugi and severed the eight heads of the beast. Izumo was saved and the legendary Kusanagi sword was found inside!",
		
		# Dialogue — Book IV Game Over
		"dialogue_narrator_susanoo_caught": "One of the eight heads caught your scent and turned its glowing eyes towards you! The plan has failed!",
		
		# HUD — Book IV
		"ui_susanoo_barrels": "Barrels placed: ",
		"ui_susanoo_place": "[E] Place sake barrel",
		"ui_susanoo_title": "SAKE STEALTH",
		
		# Result Screens — Book IV
		"victory_title_susanoo": "Susanoo's Victory!",
		"gameover_title_susanoo": "You were spotted...",
		"gameover_retry_susanoo": "Try Again",
		
		# Tutorial — Book IV
		"tutorial_title_book4": "📖 BOOK IV — Susanoo vs Yamata no Orochi",
		"tutorial_story_book4": "Susanoo, god of the storm, must place 8 sake barrels at points throughout the temple to intoxicate the eight-headed Orochi — without being seen.",
		"tutorial_controls_book4": "W / A / S / D or ↑ ← ↓ →  →  Move\nE  →  Place sake barrel",
		"tutorial_objective_book4": "Place all 8 sake barrels at the marked points in the temple without being spotted by Orochi's heads!\nIf a head sees you, the game is over.",
		"tutorial_tip_book4": "💡 Watch the orange vision cones. If you enter one, you have a brief moment to step back!",
		
		# Character Names (Book V)
		"char_gilgamesh": "Gilgamesh",
		"char_touro": "The Bull of Heaven",
		
		# Dialogue — Book V Intro
		"dialogue_narrator_gilgamesh_1": "After Gilgamesh rejected the goddess Ishtar, she demanded that her father Anu release the Bull of Heaven (Gugalanna) to destroy Uruk...",
		"dialogue_narrator_gilgamesh_2": "The colossal beast's footsteps caused massive earthquakes that split the earth, swallowing hundreds of citizens.",
		"dialogue_narrator_gilgamesh_3": "But Gilgamesh, the King of Heroes, alongside his loyal companion Enkidu, raised the Gate of Babylon to defend his people!",
		"dialogue_narrator_gilgamesh_4": "This is not just a battle for honor: it is humanity's ultimate stand against the oppression of the gods themselves!",
		
		# Dialogue — Book V Victory
		"dialogue_narrator_gilgamesh_victory_1": "Enkidu grabbed the bull by its horns, allowing Gilgamesh to pierce the divine beast with a barrage of legendary weapons.",
		"dialogue_narrator_gilgamesh_victory_2": "The Bull of Heaven lies defeated. Gilgamesh proved that Uruk's pride and mortal bonds can overcome the fury of the heavens!",
		
		# Tutorial — Book V
		"tutorial_title_book5": "📖 BOOK V — Gilgamesh vs The Bull of Heaven",
		"tutorial_story_book5": "Gilgamesh must survive the catastrophic attacks of the Bull of Heaven and charge his Royal Fury to unleash the Gate of Babylon.",
		"tutorial_controls_book5": "Mouse and Keyboard  →  QTE / Dodge\nRapid Click  →  Fire Swords\nESC  →  Pause",
		"tutorial_objective_book5": "Survive the boss's attacks. When the Fury bar is full, click on the screen to fire golden swords!",
		"tutorial_tip_book5": "💡 Click the precision circles only when the outer ring shrinks to the center!",
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
		Difficulty.NORMAL: return 30
		Difficulty.HARD:   return 40
	return 30

func get_boss_speed() -> float:
	match current_difficulty:
		Difficulty.EASY:   return 25.0
		Difficulty.NORMAL: return 40.0
		Difficulty.HARD:   return 60.0
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
		Difficulty.NORMAL: return 2.4
		Difficulty.HARD:   return 1.8
	return 2.0

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

func get_action_key_name(action: String, fallback: String = "") -> String:
	if not InputMap.has_action(action):
		return fallback
	var events = InputMap.action_get_events(action)
	var use_controller = (current_hardware == InputHardware.CONTROLLER)
	
	for ev in events:
		if use_controller:
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				var n = format_event_name(ev)
				if n != "": return n
		else:
			if ev is InputEventKey or ev is InputEventMouseButton:
				var n = format_event_name(ev)
				if n != "": return n
				
	for ev in events:
		if ev is InputEventKey or ev is InputEventMouseButton or ev is InputEventJoypadButton:
			var n = format_event_name(ev)
			if n != "": return n
			
	return fallback

func format_event_name(ev: InputEvent) -> String:
	var is_pt = (current_language == Language.PT)
	if ev is InputEventKey:
		var kc = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
		match kc:
			KEY_SHIFT: return "SHIFT"
			KEY_SPACE: return "ESPAÇO" if is_pt else "SPACE"
			KEY_LEFT: return "◀"
			KEY_RIGHT: return "▶"
			KEY_UP: return "▲"
			KEY_DOWN: return "▼"
			KEY_ENTER: return "ENTER"
			KEY_ESCAPE: return "ESC"
			_: return OS.get_keycode_string(kc).to_upper()
	elif ev is InputEventMouseButton:
		match ev.button_index:
			MOUSE_BUTTON_LEFT: return "BOTÃO ESQ." if is_pt else "LMB"
			MOUSE_BUTTON_RIGHT: return "BOTÃO DIR." if is_pt else "RMB"
			MOUSE_BUTTON_MIDDLE: return "BOTÃO MEIO" if is_pt else "MMB"
			_: return "M" + str(ev.button_index)
	elif ev is InputEventJoypadButton:
		match ev.button_index:
			JOY_BUTTON_A: return "A"
			JOY_BUTTON_B: return "B"
			JOY_BUTTON_X: return "X"
			JOY_BUTTON_Y: return "Y"
			JOY_BUTTON_LEFT_SHOULDER: return "LB"
			JOY_BUTTON_RIGHT_SHOULDER: return "RB"
			JOY_BUTTON_DPAD_LEFT: return "◀"
			JOY_BUTTON_DPAD_RIGHT: return "▶"
			JOY_BUTTON_DPAD_UP: return "▲"
			JOY_BUTTON_DPAD_DOWN: return "▼"
			_: return "BTN " + str(ev.button_index)
	return ""

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

	for action in CUSTOMIZABLE_ACTIONS:
		var events = InputMap.action_get_events(action)
		var action_slots = []
		for ev in events:
			if ev is InputEventKey:
				action_slots.append({"type": "key", "code": ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode})
			elif ev is InputEventMouseButton:
				action_slots.append({"type": "mouse", "code": ev.button_index})
			if action_slots.size() >= 2:
				break
		config.set_value("keybinds_v2", action, action_slots)
				
	config.save(SAVE_PATH)
	print("[SETTINGS] Gravadas com sucesso!")

func reset_to_defaults():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		config.erase_section("keybinds")
		config.erase_section("keybinds_v2")
		config.save(SAVE_PATH)
	for action in CUSTOMIZABLE_ACTIONS:
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
	
	if config.has_section("keybinds_v2"):
		for action in CUSTOMIZABLE_ACTIONS:
			if config.has_section_key("keybinds_v2", action):
				var action_slots = config.get_value("keybinds_v2", action, [])
				var keep_events = []
				for ev in InputMap.action_get_events(action):
					if not (ev is InputEventKey or ev is InputEventMouseButton):
						keep_events.append(ev)
				InputMap.action_erase_events(action)
				for item in action_slots:
					var event = null
					if item["type"] == "key":
						event = InputEventKey.new()
						event.physical_keycode = item["code"]
					elif item["type"] == "mouse":
						event = InputEventMouseButton.new()
						event.button_index = item["code"]
					if event:
						InputMap.action_add_event(action, event)
				for ev in keep_events:
					InputMap.action_add_event(action, ev)
	elif config.has_section("keybinds"):
		for action in CUSTOMIZABLE_ACTIONS:
			if config.has_section_key("keybinds", action):
				var data = config.get_value("keybinds", action)
				var keep_events = []
				for ev in InputMap.action_get_events(action):
					if not (ev is InputEventKey or ev is InputEventMouseButton):
						keep_events.append(ev)
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
				for ev in keep_events:
					InputMap.action_add_event(action, ev)
				
	print("[SETTINGS] Carregadas com sucesso!")

func _detect_input_hardware():
	# Verificar se há algum comando conectado
	var joy_count = Input.get_connected_joypads().size()
	if joy_count > 0:
		current_hardware = InputHardware.CONTROLLER
		print("[HARDWARE] Detetado(s) comando(s): ", joy_count)
	else:
		current_hardware = InputHardware.KEYBOARD
		print("[HARDWARE] A usar teclado")

func _ready():
	# Configurar os controlos padrão no InputMap
	_setup_default_controls()
	# Sobrescrever com definições salvas se existirem
	load_settings()
	# Detectar hardware de input
	_detect_input_hardware()
	
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
	# 1. move_left (A)
	_ensure_action("move_left", [
		{"type": "key", "code": KEY_A},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_LEFT},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0}
	])
	
	# 2. move_right (D)
	_ensure_action("move_right", [
		{"type": "key", "code": KEY_D},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_RIGHT},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0}
	])
	
	# 3. move_up (W)
	_ensure_action("move_up", [
		{"type": "key", "code": KEY_W},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_UP},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0}
	])

	# 4. move_down (S)
	_ensure_action("move_down", [
		{"type": "key", "code": KEY_S},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_DOWN},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0}
	])
	
	# 5. jump (Espaço / Botão A do comando)
	_ensure_action("jump", [
		{"type": "key", "code": KEY_SPACE},
		{"type": "joy_button", "code": JOY_BUTTON_A}
	])
	
	# 6. shoot (Botão Esquerdo do Rato / Botão X do comando)
	_ensure_action("shoot", [
		{"type": "mouse", "code": MOUSE_BUTTON_LEFT},
		{"type": "joy_button", "code": JOY_BUTTON_X}
	])

	# 7. dash (Shift / Botão B do comando)
	_ensure_action("dash", [
		{"type": "key", "code": KEY_SHIFT},
		{"type": "joy_button", "code": JOY_BUTTON_B}
	])

	# 8. rhythm_lane_0 (A)
	_ensure_action("rhythm_lane_0", [
		{"type": "key", "code": KEY_A},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_LEFT}
	])

	# 9. rhythm_lane_1 (S)
	_ensure_action("rhythm_lane_1", [
		{"type": "key", "code": KEY_S},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_DOWN}
	])

	# 10. rhythm_lane_2 (W)
	_ensure_action("rhythm_lane_2", [
		{"type": "key", "code": KEY_W},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_UP}
	])

	# 11. rhythm_lane_3 (D)
	_ensure_action("rhythm_lane_3", [
		{"type": "key", "code": KEY_D},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_RIGHT}
	])

	# 12. ui_susanoo_place — colocar barril de sake (Livro IV)
	_ensure_action("ui_susanoo_place", [
		{"type": "key", "code": KEY_E},
		{"type": "joy_button", "code": JOY_BUTTON_Y},
		{"type": "joy_button", "code": JOY_BUTTON_RIGHT_SHOULDER}
	])
	
	# 13. Susanoo movement actions (Livro IV)
	_ensure_action("susanoo_move_left", [
		{"type": "key", "code": KEY_A},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_LEFT},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0}
	])
	_ensure_action("susanoo_move_right", [
		{"type": "key", "code": KEY_D},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_RIGHT},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0}
	])
	_ensure_action("susanoo_move_up", [
		{"type": "key", "code": KEY_W},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_UP},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0}
	])
	_ensure_action("susanoo_move_down", [
		{"type": "key", "code": KEY_S},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_DOWN},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0}
	])

func _ensure_action(action_name: String, bindings: Array):
	# Cria a ação se ela não existir de todo no projeto
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	# Caso o utilizador defina controlos no editor não sejam sobrepostos
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
	# Evita reiniciar caso a mesma faixa já esteja em reprodução
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
	# Reconecta sinal de repetição automática em loop
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


# Toca efeito sonoro dramático de derrota (para a música, pitch grave e lento)
func play_defeat_sound():
	stop_music()
	# Tom grave e pesado — soa a tragédia épica
	var sfx1 = AudioStreamPlayer.new()
	sfx1.stream = load("res://assets/sounds/explosion.wav")
	sfx1.pitch_scale = 0.45
	sfx1.volume_db = -4.0
	sfx1.bus = "SFX"
	sfx1.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx1)
	sfx1.play()
	sfx1.finished.connect(sfx1.queue_free)

	# Segundo som de dano em cima, ligeiramente atrasado
	await get_tree().create_timer(0.35).timeout
	if not is_inside_tree():
		return
	var sfx2 = AudioStreamPlayer.new()
	sfx2.stream = load("res://assets/sounds/hurt.wav")
	sfx2.pitch_scale = 0.5
	sfx2.volume_db = -6.0
	sfx2.bus = "SFX"
	sfx2.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx2)
	sfx2.play()
	sfx2.finished.connect(sfx2.queue_free)

# Toca efeito sonoro triunfante de vitória (para a música, pitch agudo e vibrante)
func play_victory_sound():
	stop_music()
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load("res://assets/sounds/power_up.wav")
	sfx.pitch_scale = 1.25
	sfx.volume_db = -3.0
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
