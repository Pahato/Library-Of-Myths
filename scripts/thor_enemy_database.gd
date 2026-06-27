## Base de dados estática de todos os inimigos do jogo.
## Tema: Mitologia Nórdica — RPG tático estilo Slay the Spire.
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
				"damage_min": 8,
				"damage_max": 11,
				"hits": 1,
				"weight": 3,
			},
			{
				"type": IntentType.DEFEND,
				"block_min": 6,
				"block_max": 10,
				"weight": 2,
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
				"weight": 3,
			},
			{
				"type": IntentType.ATTACK,
				"damage": 8,
				"hits": 1,
				"vulnerable": 2,
				"weight": 2,
			},
		],
	},

	"gigante_gelo": {
		"id": "gigante_gelo",
		"name_pt": "Gigante de Gelo",
		"name_en": "Frost Giant",
		"hp_min": 65,
		"hp_max": 80,
		"type": EnemyType.NORMAL,
		"acts": [2, 3],
		"color": "#6CA6CD",
		"icon": "🧊",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 15,
				"damage_max": 20,
				"hits": 1,
				"weight": 2,
			},
			{
				"type": IntentType.DEFEND,
				"block_min": 12,
				"block_max": 18,
				"weight": 2,
			},
			{
				"type": IntentType.BUFF,
				"strength": 3,
				"weight": 1,
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
				"damage": 4,
				"hits": 3,
				"weight": 3,
			},
			{
				"type": IntentType.ATTACK,
				"damage": 8,
				"hits": 1,
				"weight": 2,
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
			},
			{
				"type": IntentType.DEFEND,
				"block_min": 8,
				"block_max": 12,
				"weight": 2,
			},
		],
	},

	# ── ELITES ───────────────────────────────────────────────

	"hel_rainha": {
		"id": "hel_rainha",
		"name_pt": "Hel, Rainha dos Mortos",
		"name_en": "Hel, Queen of the Dead",
		"hp_min": 110,
		"hp_max": 130,
		"type": EnemyType.ELITE,
		"acts": [1, 2],
		"color": "#8B008B",
		"icon": "👑",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 14,
				"damage_max": 18,
				"hits": 1,
				"weight": 2,
			},
			{
				"type": IntentType.BUFF,
				"heal": 12,
				"weight": 2,
			},
			{
				"type": IntentType.DEBUFF,
				"vulnerable": 2,
				"weight": 1,
			},
		],
	},

	"fenrir_gigante": {
		"id": "fenrir_gigante",
		"name_pt": "Fenrir, O Lobo Gigante",
		"name_en": "Fenrir, The Great Wolf",
		"hp_min": 130,
		"hp_max": 155,
		"type": EnemyType.ELITE,
		"acts": [2, 3],
		"color": "#B22222",
		"icon": "🐺",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 16,
				"damage_max": 22,
				"hits": 1,
				"weight": 2,
			},
			{
				"type": IntentType.BUFF,
				"strength": 4,
				"weight": 2,
			},
			{
				"type": IntentType.ATTACK,
				"damage": 26,
				"hits": 1,
				"weight": 1,
			},
		],
	},

	# ── BOSS ─────────────────────────────────────────────────

	"jormungandr": {
		"id": "jormungandr",
		"name_pt": "Jörmungandr, A Serpente do Mundo",
		"name_en": "Jörmungandr, The World Serpent",
		"hp_min": 240,
		"hp_max": 280,
		"type": EnemyType.BOSS,
		"acts": [3],
		"color": "#2F4F4F",
		"icon": "🐍",
		"intents": [
			{
				"type": IntentType.ATTACK,
				"damage_min": 20,
				"damage_max": 25,
				"hits": 1,
				"weight": 2,
			},
			{
				"type": IntentType.ATTACK_DEFEND,
				"damage": 12,
				"block_min": 12,
				"block_max": 15,
				"weight": 2,
			},
			{
				"type": IntentType.BUFF,
				"strength": 5,
				"weight": 1,
			},
			{
				"type": IntentType.ATTACK,
				"damage": 8,
				"hits": 3,
				"weight": 1,
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


## Escolhe aleatoriamente uma intenção para o inimigo, respeitando os pesos.
## Valores com damage_min/damage_max ou block_min/block_max são resolvidos
## para um valor concreto ("damage" / "block") na cópia devolvida.
static func get_random_intent(enemy_id: String) -> Dictionary:
	if not ENEMIES.has(enemy_id):
		push_warning("ThorEnemyDatabase: inimigo '%s' não encontrado." % enemy_id)
		return {}

	var intents: Array = ENEMIES[enemy_id]["intents"]

	# Calcular o peso total
	var total_weight: int = 0
	for intent: Dictionary in intents:
		total_weight += intent.get("weight", 1) as int

	# Rolar um valor aleatório dentro do peso total
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	var chosen: Dictionary = {}

	for intent: Dictionary in intents:
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
