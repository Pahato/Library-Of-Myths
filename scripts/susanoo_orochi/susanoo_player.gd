extends CharacterBody2D
class_name SusanooPlayer

# ---------------------------------------------------------------------------
# Sinais
# ---------------------------------------------------------------------------

## Emitido sempre que um barril de sake é colocado num ponto válido.
## Passa o total acumulado de barris colocados.
signal barrel_placed(total: int)

## Emitido quando uma cabeça do Orochi deteta o jogador.
signal player_caught

# ---------------------------------------------------------------------------
# Parâmetros exportados
# ---------------------------------------------------------------------------

## Velocidade de movimento em píxeis por segundo.
@export var move_speed: float = 120.0

## Número total de barris de sake que o jogador deve colocar para vencer.
@export var total_barrels: int = 8

# ---------------------------------------------------------------------------
# Estado interno
# ---------------------------------------------------------------------------

## Número de barris já colocados com sucesso.
var barrels_placed: int = 0

## Referência ao ponto de barril mais próximo, definida externamente
## pelo próprio ponto quando o jogador entra na sua área de interação.
var near_barrel_point: Node = null

## Indica se o jogador está habilitado a receber input.
var _input_enabled: bool = true

# ---------------------------------------------------------------------------
# Nós filhos
# ---------------------------------------------------------------------------

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Camadas de colisão programáticas: Layer 2 (Players), Mask 1 (World)
	collision_layer = 2
	collision_mask = 1
	# Garante que o nó processa mesmo quando o jogo está pausado (durante diálogos).
	process_mode = Node.PROCESS_MODE_PAUSABLE


# ---------------------------------------------------------------------------
# _physics_process — movimento e animações
# ---------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if not _input_enabled:
		velocity = Vector2.ZERO
		_play_animation(Vector2.ZERO)
		move_and_slide()
		global_position.x = clamp(global_position.x, 150.0, 1770.0)
		global_position.y = clamp(global_position.y, 90.0, 990.0)
		return

	var direction: Vector2 = _get_input_direction()
	velocity = direction * move_speed

	_play_animation(direction)
	move_and_slide()
	
	# Garante que o jogador não sai dos limites do mapa (fundo do templo)
	global_position.x = clamp(global_position.x, 150.0, 1770.0)
	global_position.y = clamp(global_position.y, 90.0, 990.0)



# ---------------------------------------------------------------------------
# _input — interação com pontos de barril
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not _input_enabled:
		return

	# Tecla E: colocar barril no ponto mais próximo, se disponível.
	if event.is_action_pressed("ui_susanoo_place") and near_barrel_point != null:
		_place_barrel()


# ---------------------------------------------------------------------------
# Funções públicas
# ---------------------------------------------------------------------------

## Chamada externamente (pelo OrochiHead ou pelo SusanooScene) quando o jogador
## é detetado. Desativa o input e emite o sinal player_caught.
func catch_player() -> void:
	if not _input_enabled:
		return
	_input_enabled = false
	velocity = Vector2.ZERO
	player_caught.emit()


## Desativa o input do jogador (usado ao acionar a sequência de vitória).
func disable_input() -> void:
	_input_enabled = false
	velocity = Vector2.ZERO


## Reativa o input do jogador.
func enable_input() -> void:
	_input_enabled = true


# ---------------------------------------------------------------------------
# Funções privadas
# ---------------------------------------------------------------------------

## Regista a colocação de um barril e emite o sinal barrel_placed.
func _place_barrel() -> void:
	if near_barrel_point == null:
		return

	# Notifica o ponto de barril para se desativar (evita colocação dupla).
	if near_barrel_point.has_method("on_barrel_placed"):
		near_barrel_point.on_barrel_placed()

	near_barrel_point = null
	barrels_placed += 1
	barrel_placed.emit(barrels_placed)


## Devolve a direção de movimento normalizada com base no input do utilizador.
## Suporta WASD e teclas de seta. Devolve Vector2.ZERO se não houver input.
func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO

	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")

	# Normaliza para evitar velocidade diagonal superior à nominal.
	if dir.length_squared() > 1.0:
		dir = dir.normalized()

	return dir


func _play_animation(direction: Vector2) -> void:
	if sprite == null:
		return

	if direction == Vector2.ZERO:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("Idle"):
			if sprite.animation != "Idle":
				sprite.play("Idle")
		return

	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("Run"):
		if sprite.animation != "Run":
			sprite.play("Run")

	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false



