extends Area2D

## Ponto de colocação de um barril de sake na fase de stealth do Livro IV.
## Emite sinais quando o jogador entra e sai da área de interação.
## Após a colocação, desativa-se para evitar interações repetidas.

signal player_near(point: Node)
signal player_left

## Sprite que indica o ponto de colocação (semitransparente antes de ser colocado).
@onready var _indicator: Sprite2D = $Sprite2D

## Indica se este ponto já recebeu um barril.
var _is_placed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if _is_placed:
		return
	if body is CharacterBody2D and body.get_script() != null:
		player_near.emit(self)

func _on_body_exited(body: Node) -> void:
	if _is_placed:
		return
	if body is CharacterBody2D and body.get_script() != null:
		player_left.emit()

## Chamado pelo SusanooPlayer quando coloca o barril neste ponto.
## Mostra o barril sólido e desativa este ponto de colocação.
func on_barrel_placed() -> void:
	_is_placed = true

	# Torna o indicador sólido para mostrar que o barril foi colocado.
	if _indicator:
		_indicator.modulate = Color(1, 1, 1, 1.0)

	# Emite saída para limpar a referência no player.
	player_left.emit()

	# Desativa colisões para não interferir novamente.
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

