## Base de dados estática de atributos e comportamentos dos inimigos do Livro III (Thor vs Jörmungandr).
## Classe puramente de dados — sem @onready, sem _ready().
extends Node
class_name ThorEnemyDatabase

# ─────────────────────────────────────────────────────────────
#  Enums
# ─────────────────────────────────────────────────────────────

enum EnemyType { NORMAL, ELITE, BOSS }

enum IntentType { ATTACK, DEFEND, BUFF, ATTACK_DEFEND, DEBUFF }

# ─────────────────────────────────────────────────────────────
#  Dados dos Inimigos
# ─────────────────────────────────────────────────────────────

const ENEMIES: Dictionary = {
	# ── NORMAIS ──────────────────────────────────────────────

	"draugr": {
		"id": "draugr",
		"name_pt": "Draugr",
		"name_en": "Draugr",
		"hp_min": 38,
		"hp_max": 46,
		"type": EnemyType.NORMAL,
		"acts": [1, 2],
		"color": "#5A7A5A",
		"icon": "💀",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 12,
				"damage_max": 15,
				"hits": 1,
				"weight": 3,
				"label": "Golpe Pesado"
			},
			{
				"type": IntentType.ATTACK,
				"damage": 8,
				"hits": 2,
				"weight": 2,
				"label": "Golpe Duplo"
			},
			{
				"type": IntentType.DEFEND,
				"block_min": 6,
				"block_max": 10,
				"weight": 1,
				"label": "Postura Defensiva"
			},
		],
	},

	"lobo_fenrir": {
		"id": "lobo_fenrir",
		"name_pt": "Lobo de Fenrir",
		"name_en": "Fenrir Wolf",
		"hp_min": 48,
		"hp_max": 58,
		"type": EnemyType.NORMAL,
		"acts": [1, 2],
		"color": "#8B6914",
		"icon": "🐺",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 10,
				"damage_max": 14,
				"hits": 1,
				"weight": 4,
				"label": "Mordida"
			},
			{
				"type": IntentType.ATTACK,
				"damage_min": 8,
				"damage_max": 11,
				"hits": 1,
				"weight": 3,
				"label": "Investida"
			},
			{
				"type": IntentType.ATTACK,
				"damage": 8,
				"hits": 1,
				"vulnerable": 2,
				"weight": 2,
				"label": "Rosnar Ameaçador"
			},
		],
	},


	"corvos_hel": {
		"id": "corvos_hel",
		"name_pt": "Corvos de Hel",
		"name_en": "Crows of Hel",
		"hp_min": 25,
		"hp_max": 32,
		"type": EnemyType.NORMAL,
		"acts": [1],
		"color": "#4A4A6A",
		"icon": "🐦",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage": 5,
				"hits": 3,
				"weight": 4,
				"label": "Enxame de Bicos"
			},
			{
				"type": IntentType.ATTACK,
				"damage": 6,
				"hits": 2,
				"weight": 2,
				"label": "Mergulho Cortante"
			},
			{
				"type": IntentType.ATTACK,
				"damage": 8,
				"hits": 1,
				"weight": 1,
				"label": "Bicada Precisa"
			},
		],
	},

	"esqueleto_viking": {
		"id": "esqueleto_viking",
		"name_pt": "Esqueleto Viking",
		"name_en": "Viking Skeleton",
		"hp_min": 42,
		"hp_max": 50,
		"type": EnemyType.NORMAL,
		"acts": [1, 2, 3],
		"color": "#C8B88A",
		"icon": "⚔️",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 9,
				"damage_max": 13,
				"hits": 1,
				"weight": 3,
				"label": "Golpe de Espada"
			},
			{
				"type": IntentType.DEFEND,
				"block_min": 10,
				"block_max": 14,
				"weight": 2,
				"label": "Escudo Erguido"
			},
		],
	},

	# ── ELITES ───────────────────────────────────────────────

	"hel_rainha": {
		"id": "hel_rainha",
		"name_pt": "Hel, Rainha dos Mortos",
		"name_en": "Hel, Queen of the Dead",
		"hp_min": 95,
		"hp_max": 115,
		"type": EnemyType.ELITE,
		"acts": [1],
		"color": "#8B008B",
		"icon": "👑",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 10,
				"damage_max": 14,
				"hits": 1,
				"weight": 3,
				"label": "Toque da Morte"
			},
			{
				"type": IntentType.DEFEND,
				"block_min": 12,
				"block_max": 16,
				"weight": 2,
				"label": "Barreira Spectral"
			},
			{
				"type": IntentType.BUFF,
				"heal": 12,
				"weight": 2,
				"label": "Drenar Vitalidade"
			},
			{
				"type": IntentType.DEBUFF,
				"vulnerable": 2,
				"weight": 2,
				"label": "Maldição da Fraqueza"
			},
		],
	},

	"fenrir_gigante": {
		"id": "fenrir_gigante",
		"name_pt": "Fenrir, O Lobo Gigante",
		"name_en": "Fenrir, The Great Wolf",
		"hp_min": 120,
		"hp_max": 145,
		"type": EnemyType.ELITE,
		"acts": [2, 3],
		"color": "#B22222",
		"icon": "🐺",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 12,
				"damage_max": 15,
				"hits": 1,
				"weight": 3,
				"label": "Mordida Esmagadora"
			},
			{
				"type": IntentType.ATTACK,
				"damage_min": 8,
				"damage_max": 10,
				"hits": 2,
				"weight": 2,
				"label": "Fúria Dupla"
			},
			{
				"type": IntentType.ATTACK,
				"damage": 18,
				"hits": 1,
				"weight": 2,
				"label": "Investida Selvagem"
			},
			{
				"type": IntentType.BUFF,
				"strength": 2,
				"weight": 1,
				"label": "Uivo Primordial"
			},
		],
	},

	"gigante_gelo": {
		"id": "gigante_gelo",
		"name_pt": "Gigante de Gelo",
		"name_en": "Frost Giant",
		"hp_min": 110,
		"hp_max": 135,
		"type": EnemyType.ELITE,
		"acts": [2, 3],
		"color": "#6CA6CD",
		"icon": "🧊",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 10,
				"damage_max": 14,
				"hits": 1,
				"weight": 2,
				"label": "Martelo de Gelo"
			},
			{
				"type": IntentType.DEFEND,
				"block_min": 16,
				"block_max": 22,
				"weight": 3,
				"label": "Pele de Permafrost"
			},
			{
				"type": IntentType.ATTACK_DEFEND,
				"damage": 8,
				"block_min": 12,
				"block_max": 16,
				"weight": 2,
				"label": "Golpe Glacial"
			},
		],
	},

	# ── BOSS ─────────────────────────────────────────────────

	"jormungandr": {
		"id": "jormungandr",
		"name_pt": "Jörmungandr, A Serpente do Mundo",
		"name_en": "Jörmungandr, The World Serpent",
		"hp_min": 180,
		"hp_max": 210,
		"type": EnemyType.BOSS,
		"acts": [3],
		"color": "#2F4F4F",
		"icon": "🐍",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 14,
				"damage_max": 18,
				"hits": 1,
				"weight": 2,
				"label": "Presas Venenosas"
			},
			{
				"type": IntentType.ATTACK_DEFEND,
				"damage": 10,
				"block_min": 10,
				"block_max": 14,
				"weight": 2,
				"label": "Escamas Endurecidas"
			},
			{
				"type": IntentType.BUFF,
				"strength": 2,
				"weight": 1,
				"label": "Fúria do Abismo"
			},
			{
				"type": IntentType.ATTACK,
				"damage": 6,
				"hits": 3,
				"weight": 1,
				"label": "Chicote de Cauda"
			},
		],
	},
}

# ─────────────────────────────────────────────────────────────
#  Funções Públicas Estáticas
# ─────────────────────────────────────────────────────────────

## Devolve uma cópia profunda dos dados do inimigo pelo seu ID.
## Retorna um dicionário vazio se o ID não existir.
static func get_enemy(id: String) -> Dictionary:
	if not ENEMIES.has(id):
		push_warning("ThorEnemyDatabase: inimigo '%s' não encontrado." % id)
		return {}
	return ENEMIES[id].duplicate(true)


## Devolve uma lista de IDs de inimigos NORMAIS disponíveis no ato indicado.
static func get_enemies_for_act(act: int) -> Array:
	var result: Array = []
	for enemy_id: String in ENEMIES:
		var enemy: Dictionary = ENEMIES[enemy_id]
		if enemy["type"] == EnemyType.NORMAL and act in enemy["acts"]:
			result.append(enemy_id)
	return result


## Devolve uma lista de IDs de inimigos ELITE disponíveis no ato indicado.
static func get_elites_for_act(act: int) -> Array:
	var result: Array = []
	for enemy_id: String in ENEMIES:
		var enemy: Dictionary = ENEMIES[enemy_id]
		if enemy["type"] == EnemyType.ELITE and act in enemy["acts"]:
			result.append(enemy_id)
	return result


## Devolve um inimigo NORMAL aleatório para o ato indicado, com probabilidades ponderadas.
## Probabilidades: Corvos de Hel 30%, Draugr 20%, Esqueleto Viking 30%, Lobo de Fenrir 20%.
static func get_weighted_normal_enemy(act: int) -> String:
	var enemies = get_enemies_for_act(act)
	if enemies.is_empty():
		return "draugr"
	
	# Pesos para cada inimigo (devem somar 100)
	var weights = {
		"corvos_hel": 30,
		"draugr": 20,
		"esqueleto_viking": 30,
		"lobo_fenrir": 20
	}
	
	# Filtrar apenas inimigos disponíveis neste ato
	var available = []
	var total_weight = 0
	for enemy_id in enemies:
		if weights.has(enemy_id):
			available.append(enemy_id)
			total_weight += weights[enemy_id]
	
	if available.is_empty():
		return enemies[0]
	
	# Normalizar pesos
	var roll = randi() % total_weight
	var cumulative = 0
	for enemy_id in available:
		cumulative += weights[enemy_id]
		if roll < cumulative:
			return enemy_id
	
	return available[0]


## Escolhe uma intenção para o inimigo com lógica contextual básica.
## Evita repetir Vulnerable desnecessário e adiciona variedade simples.
static func get_random_intent(enemy_id: String, player_vulnerable: int = 0, last_intent_type: int = -1) -> Dictionary:
	if not ENEMIES.has(enemy_id):
		push_warning("ThorEnemyDatabase: inimigo '%s' não encontrado." % enemy_id)
		return {}

	var intents: Array = ENEMIES[enemy_id]["intents"]

	# Filtrar intents inválidas contextualmentes
	var valid_intents: Array = []
	for intent in intents:
		var intent_copy = intent.duplicate(true)
		var skip = false
		
		# Não aplicar Vulnerable se jogador já está Vulnerable
		if intent_copy.get("type") == IntentType.DEBUFF and intent_copy.get("vulnerable", 0) > 0:
			if player_vulnerable > 0:
				skip = true
		
		# Evitar repetir o mesmo tipo de intent consecutivamente (50% chance de skip)
		if last_intent_type != -1 and intent_copy.get("type") == last_intent_type:
			if randf() < 0.5:
				skip = true
		
		if not skip:
			# No modo Difícil, Jörmungandr usa menos ataques defensivos (ATTACK_DEFEND)
			if enemy_id == "jormungandr" and GameGlobals and GameGlobals.current_difficulty == GameGlobals.Difficulty.HARD:
				if intent_copy.get("type") == IntentType.ATTACK_DEFEND:
					intent_copy["weight"] = maxi(1, int(intent_copy.get("weight", 2) * 0.5))
			valid_intents.append(intent_copy)
	
	# Fallback: se todas foram filtradas, usar todas
	if valid_intents.is_empty():
		valid_intents = intents.duplicate(true)

	# Calcular o peso total
	var total_weight: int = 0
	for intent: Dictionary in valid_intents:
		total_weight += intent.get("weight", 1) as int

	# Rolar um valor aleatório dentro do peso total
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	var chosen: Dictionary = {}

	for intent: Dictionary in valid_intents:
		cumulative += intent.get("weight", 1) as int
		if roll < cumulative:
			chosen = intent.duplicate(true)
			break

	# Resolver intervalos de dano (damage_min / damage_max → damage)
	if chosen.has("damage_min") and chosen.has("damage_max"):
		var dmg_min: int = chosen["damage_min"] as int
		var dmg_max: int = chosen["damage_max"] as int
		chosen["damage"] = dmg_min + (randi() % (dmg_max - dmg_min + 1))
		chosen.erase("damage_min")
		chosen.erase("damage_max")

	# Resolver intervalos de bloqueio (block_min / block_max → block)
	if chosen.has("block_min") and chosen.has("block_max"):
		var blk_min: int = chosen["block_min"] as int
		var blk_max: int = chosen["block_max"] as int
		chosen["block"] = blk_min + (randi() % (blk_max - blk_min + 1))
		chosen.erase("block_min")
		chosen.erase("block_max")

	# Garantir que hits existe em ataques
	if chosen.get("type") in [IntentType.ATTACK, IntentType.ATTACK_DEFEND]:
		if not chosen.has("hits"):
			chosen["hits"] = 1

	return chosen
