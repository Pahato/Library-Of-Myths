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

## Velocidade de rotação suave da cabeça (radianos por segundo).
@export var turn_speed: float = PI * 1.5

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
# @onready var _sprite: Node2D = $Sprite if has_node("Sprite") else null

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# A textura do Orochi está virada para a esquerda por defeito, mas o código de visão 
	# e rotação do nó assume que aponta para a direita (eixo X local).
	# Rodamos a Sprite em 180 graus (PI) para que alinhe com a física e o cone de visão!
	var sprite = get_node_or_null("Sprite")
	if sprite:
		sprite.rotation = PI

	# Caso não haja pontos de patrulha definidos, a cabeça fica estática.
	if patrol_points.is_empty():
		patrol_points.append(global_position)

	# Ajustar alert_time baseado na dificuldade para dar janela de reação justa
	if GameGlobals:
		match GameGlobals.current_difficulty:
			GameGlobals.Difficulty.EASY:
				alert_time = 1.2
			GameGlobals.Difficulty.NORMAL:
				alert_time = 0.8
			GameGlobals.Difficulty.HARD:
				alert_time = 0.45  # Mínimo de reação humana no modo Hard


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
		_face_direction(dir, delta)

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
## Verifica simultaneamente a distância, o ângulo e a oclusão visual (paredes/obstáculos).
func _is_player_in_cone() -> bool:
	if player_ref == null or not is_instance_valid(player_ref):
		return false

	# Se o jogador estiver invisível (por exemplo, na introdução), não é detetado
	if not player_ref.visible:
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
	if abs(angle_to_player) > vision_angle * 0.5:
		return false

	# Verificação de oclusão visual (raycast para verificar paredes/obstáculos)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player_ref.global_position, collision_mask)
	var result = space_state.intersect_ray(query)

	# Se o raycast atingir algo antes do jogador, há uma parede/obstáculo bloqueando a visão
	if result.size() > 0:
		var collider = result.get("collider")
		# Se o objeto atingido não é o jogador, há algo bloqueando a visão
		if collider != player_ref and collider != player_ref.get_parent():
			return false

	return true


## Roda a sprite (e o cone) suavemente para apontar na direção indicada.
func _face_direction(dir: Vector2, delta: float = 0.016) -> void:
	if dir == Vector2.ZERO:
		return
	var target_rot = dir.angle()
	rotation = rotate_toward(rotation, target_rot, turn_speed * delta)
	queue_redraw()
