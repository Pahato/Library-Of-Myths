## Base de dados estática de todas as cartas do jogo.
## Tema: Mitologia Nórdica (Thor) — RPG tático estilo Slay the Spire.
## Uso: referenciado como classe (ThorCardDatabase.get_card("id")).
extends Node
class_name ThorCardDatabase

# ============================================================
# Enums
# ============================================================

enum CardType { ATTACK, SKILL, POWER }
enum CardRarity { STARTER, COMMON, UNCOMMON, RARE }

# ============================================================
# Base de Dados — todas as cartas definidas como constante
# ============================================================

const CARDS: Dictionary = {
	# --------------------------------------------------------
	# STARTER — cartas iniciais do baralho
	# --------------------------------------------------------
	"golpe_mjolnir": {
		"id": "golpe_mjolnir",
		"name_pt": "Golpe de Mjölnir",
		"name_en": "Mjölnir Strike",
		"desc_pt": "Causa 6 de dano.",
		"desc_en": "Deal 6 damage.",
		"cost": 1,
		"type": CardType.ATTACK,
		"rarity": CardRarity.STARTER,
		"effect": { "damage": 6 },
	},
	"escudo_asgard": {
		"id": "escudo_asgard",
		"name_pt": "Escudo de Asgard",
		"name_en": "Asgard Shield",
		"desc_pt": "Ganha 5 de bloqueio.",
		"desc_en": "Gain 5 block.",
		"cost": 1,
		"type": CardType.SKILL,
		"rarity": CardRarity.STARTER,
		"effect": { "block": 5 },
	},
	"trovao": {
		"id": "trovao",
		"name_pt": "Trovão",
		"name_en": "Thunder",
		"desc_pt": "Causa 10 de dano.",
		"desc_en": "Deal 10 damage.",
		"cost": 2,
		"type": CardType.ATTACK,
		"rarity": CardRarity.STARTER,
		"effect": { "damage": 10 },
	},
	"muralha_gelo": {
		"id": "muralha_gelo",
		"name_pt": "Muralha de Gelo",
		"name_en": "Ice Wall",
		"desc_pt": "Ganha 8 de bloqueio.",
		"desc_en": "Gain 8 block.",
		"cost": 2,
		"type": CardType.SKILL,
		"rarity": CardRarity.STARTER,
		"effect": { "block": 8 },
	},

	# --------------------------------------------------------
	# COMMON — recompensas comuns
	# --------------------------------------------------------
	"rugido_trovao": {
		"id": "rugido_trovao",
		"name_pt": "Rugido do Trovão",
		"name_en": "Thunder Roar",
		"desc_pt": "Aplica 2 turnos de Vulnerável ao inimigo.",
		"desc_en": "Apply 2 turns of Vulnerable to the enemy.",
		"cost": 1,
		"type": CardType.SKILL,
		"rarity": CardRarity.COMMON,
		"effect": { "vulnerable": 2 },
	},
	"golpe_duplo": {
		"id": "golpe_duplo",
		"name_pt": "Golpe Duplo",
		"name_en": "Double Strike",
		"desc_pt": "Causa 4 de dano 2 vezes.",
		"desc_en": "Deal 4 damage 2 times.",
		"cost": 1,
		"type": CardType.ATTACK,
		"rarity": CardRarity.COMMON,
		"effect": { "damage": 4, "hits": 2 },
	},

	# --------------------------------------------------------
	# UNCOMMON — recompensas incomuns
	# --------------------------------------------------------
	"relampago_bifrost": {
		"id": "relampago_bifrost",
		"name_pt": "Relâmpago Bifrost",
		"name_en": "Bifrost Lightning",
		"desc_pt": "Causa 8 de dano a TODOS os inimigos.",
		"desc_en": "Deal 8 damage to ALL enemies.",
		"cost": 2,
		"type": CardType.ATTACK,
		"rarity": CardRarity.UNCOMMON,
		"effect": { "damage": 8, "aoe": true },
	},
	"martelo_giratorio": {
		"id": "martelo_giratorio",
		"name_pt": "Martelo Giratório",
		"name_en": "Spinning Hammer",
		"desc_pt": "Causa 3 de dano 3 vezes.",
		"desc_en": "Deal 3 damage 3 times.",
		"cost": 1,
		"type": CardType.ATTACK,
		"rarity": CardRarity.UNCOMMON,
		"effect": { "damage": 3, "hits": 3 },
	},
	"bencao_odin": {
		"id": "bencao_odin",
		"name_pt": "Bênção de Odin",
		"name_en": "Odin's Blessing",
		"desc_pt": "Compra 2 cartas.",
		"desc_en": "Draw 2 cards.",
		"cost": 1,
		"type": CardType.SKILL,
		"rarity": CardRarity.UNCOMMON,
		"effect": { "draw": 2 },
	},
	"armadura_divina": {
		"id": "armadura_divina",
		"name_pt": "Armadura Divina",
		"name_en": "Divine Armor",
		"desc_pt": "Ganha 12 de bloqueio.",
		"desc_en": "Gain 12 block.",
		"cost": 2,
		"type": CardType.SKILL,
		"rarity": CardRarity.UNCOMMON,
		"effect": { "block": 12 },
	},
	"cadeia_fenrir": {
		"id": "cadeia_fenrir",
		"name_pt": "Cadeia de Fenrir",
		"name_en": "Fenrir's Chain",
		"desc_pt": "Reduz 1 de Força do inimigo.",
		"desc_en": "Reduce enemy Strength by 1.",
		"cost": 1,
		"type": CardType.SKILL,
		"rarity": CardRarity.UNCOMMON,
		"effect": { "weaken": 1 },
	},
	"investida_thor": {
		"id": "investida_thor",
		"name_pt": "Investida de Thor",
		"name_en": "Thor's Charge",
		"desc_pt": "Causa 14 de dano. Perde 2 de bloqueio.",
		"desc_en": "Deal 14 damage. Lose 2 block.",
		"cost": 2,
		"type": CardType.ATTACK,
		"rarity": CardRarity.UNCOMMON,
		"effect": { "damage": 14, "lose_block": 2 },
	},
	"cura_runas": {
		"id": "cura_runas",
		"name_pt": "Cura das Runas",
		"name_en": "Rune Healing",
		"desc_pt": "Recupera 6 pontos de vida.",
		"desc_en": "Heal 6 HP.",
		"cost": 1,
		"type": CardType.SKILL,
		"rarity": CardRarity.UNCOMMON,
		"effect": { "heal": 6 },
	},
	"furia_berserker": {
		"id": "furia_berserker",
		"name_pt": "Fúria Berserker",
		"name_en": "Berserker Fury",
		"desc_pt": "Ganha 2 de Força permanentemente.",
		"desc_en": "Gain 2 Strength permanently.",
		"cost": 1,
		"type": CardType.POWER,
		"rarity": CardRarity.UNCOMMON,
		"effect": { "strength": 2 },
	},

	# --------------------------------------------------------
	# RARE — recompensas raras
	# --------------------------------------------------------
	"tempestade_raios": {
		"id": "tempestade_raios",
		"name_pt": "Tempestade de Raios",
		"name_en": "Lightning Storm",
		"desc_pt": "Causa 20 de dano.",
		"desc_en": "Deal 20 damage.",
		"cost": 3,
		"type": CardType.ATTACK,
		"rarity": CardRarity.RARE,
		"effect": { "damage": 20 },
	},
	"sacrificio_valquiria": {
		"id": "sacrificio_valquiria",
		"name_pt": "Sacrifício Valquíria",
		"name_en": "Valkyrie Sacrifice",
		"desc_pt": "Perde 3 HP. Ganha 3 de energia.",
		"desc_en": "Lose 3 HP. Gain 3 energy.",
		"cost": 0,
		"type": CardType.SKILL,
		"rarity": CardRarity.RARE,
		"effect": { "self_damage": 3, "energy": 3 },
	},
	"valhalla": {
		"id": "valhalla",
		"name_pt": "Valhalla",
		"name_en": "Valhalla",
		"desc_pt": "Ganha 3 de bloqueio no início de cada turno.",
		"desc_en": "Gain 3 block at the start of each turn.",
		"cost": 3,
		"type": CardType.POWER,
		"rarity": CardRarity.RARE,
		"effect": { "block_per_turn": 3 },
	},
	"frenesi_nordico": {
		"id": "frenesi_nordico",
		"name_pt": "Frenesi Nórdico",
		"name_en": "Nordic Frenzy",
		"desc_pt": "Compra 1 carta extra no início de cada turno.",
		"desc_en": "Draw 1 extra card at the start of each turn.",
		"cost": 1,
		"type": CardType.POWER,
		"rarity": CardRarity.RARE,
		"effect": { "draw_per_turn": 1 },
	},
	"escudo_yggdrasil": {
		"id": "escudo_yggdrasil",
		"name_pt": "Escudo de Yggdrasil",
		"name_en": "Yggdrasil Shield",
		"desc_pt": "Ganha 10 de bloqueio e recupera 2 HP.",
		"desc_en": "Gain 10 block and heal 2 HP.",
		"cost": 2,
		"type": CardType.SKILL,
		"rarity": CardRarity.RARE,
		"effect": { "block": 10, "heal": 2 },
	},
	"ira_mjolnir": {
		"id": "ira_mjolnir",
		"name_pt": "Ira de Mjölnir",
		"name_en": "Mjölnir's Wrath",
		"desc_pt": "Causa 8 de dano. +2 de dano por ponto de Força.",
		"desc_en": "Deal 8 damage. +2 damage per Strength.",
		"cost": 2,
		"type": CardType.ATTACK,
		"rarity": CardRarity.RARE,
		"effect": { "damage": 8, "damage_per_strength": 2 },
	},
}

# ============================================================
# Funções de Acesso — interface pública (estáticas)
# ============================================================


## Devolve uma cópia do dicionário da carta com o [param id] indicado.
## Retorna dicionário vazio se o ID não existir.
static func get_card(id: String) -> Dictionary:
	if CARDS.has(id):
		return CARDS[id].duplicate(true)
	push_warning("ThorCardDatabase: carta '%s' não encontrada." % id)
	return {}


## Devolve o baralho inicial do jogador (array de IDs).
static func get_starter_deck() -> Array:
	return [
		"golpe_mjolnir", "golpe_mjolnir", "golpe_mjolnir", "golpe_mjolnir",
		"escudo_asgard", "escudo_asgard", "escudo_asgard", "escudo_asgard",
		"trovao",
		"muralha_gelo",
	]


## Devolve um array de IDs elegíveis para recompensa.
## Se [param rarity_filter] for >= 0, filtra pela raridade correspondente.
## Se for -1 (padrão), devolve todas as cartas que não sejam STARTER.
static func get_reward_pool(rarity_filter: int = -1) -> Array:
	var pool: Array = []
	for id: String in CARDS:
		var card: Dictionary = CARDS[id]
		# Ignorar cartas iniciais
		if card["rarity"] == CardRarity.STARTER:
			continue
		# Aplicar filtro de raridade, se pedido
		if rarity_filter >= 0 and card["rarity"] != rarity_filter:
			continue
		pool.append(id)
	return pool
