extends CharacterBody2D
class_name OrochiHead

# ---------------------------------------------------------------------------
# Sinais
# ---------------------------------------------------------------------------

## Emitido após o tempo de alerta expirar com o jogador dentro do cone de visão.
signal player_detected

# ---------------------------------------------------------------------------
# Parâmetros exportados
# ---------------------------------------------------------------------------

## Pontos de patrulha (em coordenadas globais) definidos no editor ou externamente.
@export var patrol_points: Array[Vector2] = []

## Velocidade de deslocação entre pontos de patrulha, em píxeis por segundo.
@export var patrol_speed: float = 60.0

## Ângulo total do cone de visão em graus (metade de cada lado da direção frontal).
@export var vision_angle: float = 60.0

## Distância máxima a que a cabeça deteta o jogador, em píxeis.
@export var vision_range: float = 200.0

## Tempo em estado de alerta antes de emitir player_detected, em segundos.
@export var alert_time: float = 1.0

# ---------------------------------------------------------------------------
# Referências externas
# ---------------------------------------------------------------------------

## Referência ao nó do jogador. Deve ser atribuída pelo SusanooScene em _ready.
var player_ref: Node2D = null

# ---------------------------------------------------------------------------
# Estado interno de patrulha
# ---------------------------------------------------------------------------

## Índice do próximo ponto de patrulha a atingir.
var _patrol_index: int = 0

# ---------------------------------------------------------------------------
# Estado interno de alerta
# ---------------------------------------------------------------------------

## Indica se a cabeça está atualmente em estado de alerta.
var _is_alert: bool = false

## Acumulador do tempo de alerta decorrido.
var _alert_timer: float = 0.0

# ---------------------------------------------------------------------------
# Cores do cone de visão
# ---------------------------------------------------------------------------

## Cor do cone em estado de patrulha normal (laranja transparente).
const CONE_COLOR_NORMAL := Color(1.0, 0.5, 0.0, 0.25)

## Cor do cone em estado de alerta (vermelho transparente).
const CONE_COLOR_ALERT  := Color(1.0, 0.0, 0.0, 0.40)

# ---------------------------------------------------------------------------
# Nós filhos
# ---------------------------------------------------------------------------

## Sprite da cabeça do Orochi. O nó deve chamar-se 'Sprite'.
@onready var _sprite: Node2D = $Sprite if has_node("Sprite") else null

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Caso não haja pontos de patrulha definidos, a cabeça fica estática.
	if patrol_points.is_empty():
		patrol_points.append(global_position)


# ---------------------------------------------------------------------------
# _physics_process — patrulha e deteção
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_patrol(delta)
	_check_vision(delta)


# ---------------------------------------------------------------------------
# _draw — cone de visão
# ---------------------------------------------------------------------------

func _draw() -> void:
	var color: Color = CONE_COLOR_ALERT if _is_alert else CONE_COLOR_NORMAL
	var half_angle: float = deg_to_rad(vision_angle * 0.5)
	var steps: int = 16
	var angle_step: float = (half_angle * 2.0) / float(steps)

	# A direção frontal da cabeça é o seu eixo X local (direita por defeito).
	# O _draw() usa coordenadas locais, pelo que não precisamos de conversão global.
	var base_angle: float = -half_angle

	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)

	for i in range(steps + 1):
		var current_angle: float = base_angle + angle_step * float(i)
		var point: Vector2 = Vector2(cos(current_angle), sin(current_angle)) * vision_range
		points.append(point)

	points.append(Vector2.ZERO)
	draw_colored_polygon(points, color)


# ---------------------------------------------------------------------------
# Funções privadas — patrulha
# ---------------------------------------------------------------------------

## Move a cabeça em direção ao próximo ponto de patrulha e avança no índice
## quando o alcança. O loop é circular.
func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target: Vector2 = patrol_points[_patrol_index]
	var to_target: Vector2 = target - global_position

	if to_target.length() < patrol_speed * delta + 1.0:
		# Chegou ao ponto: avança para o seguinte.
		global_position = target
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		velocity = Vector2.ZERO
	else:
		var dir: Vector2 = to_target.normalized()
		velocity = dir * patrol_speed
		_face_direction(dir)

	move_and_slide()


# ---------------------------------------------------------------------------
# Funções privadas — deteção
# ---------------------------------------------------------------------------

## Verifica o cone de visão e gere o estado de alerta.
func _check_vision(delta: float) -> void:
	var in_cone: bool = _is_player_in_cone()

	if in_cone:
		if not _is_alert:
			# Entra em alerta.
			_is_alert = true
			_alert_timer = 0.0
			queue_redraw()

		_alert_timer += delta

		if _alert_timer >= alert_time:
			# Tempo de alerta esgotado: emite sinal de deteção.
			player_detected.emit()
			# Reinicia o timer para evitar emissão repetida por frame.
			_alert_timer = 0.0
	else:
		if _is_alert:
			# O jogador saiu do cone durante o estado de alerta: cancela.
			_is_alert = false
			_alert_timer = 0.0
			queue_redraw()


## Devolve verdadeiro se o jogador estiver dentro do cone de visão desta cabeça.
## Verifica simultaneamente a distância e o ângulo em relação à direção frontal.
func _is_player_in_cone() -> bool:
	if player_ref == null or not is_instance_valid(player_ref):
		return false

	var to_player: Vector2 = player_ref.global_position - global_position

	# Verificação de distância.
	if to_player.length() > vision_range:
		return false

	# Direção frontal da cabeça (eixo X global rotacionado pelo rotation do nó).
	var forward: Vector2 = Vector2.RIGHT.rotated(global_rotation)

	# Ângulo entre a direção frontal e o vetor ao jogador.
	var angle_to_player: float = rad_to_deg(forward.angle_to(to_player))

	# Verifica se o ângulo está dentro da metade do cone.
	return abs(angle_to_player) <= vision_angle * 0.5


## Roda a sprite (e o cone) para apontar na direção indicada.
func _face_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	# Roda o nó inteiro para que o eixo X aponte na direção de movimento.
	rotation = dir.angle()
	queue_redraw()
