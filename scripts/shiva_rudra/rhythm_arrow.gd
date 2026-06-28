extends Node2D

var lane: int = 0
var target_time: float = 0.0
var is_player: bool = true
var type: String = "normal" # "normal" or "storm"
var was_hit: bool = false:
	set(value):
		was_hit = value
		if value:
			visible = false
		queue_redraw()

# --- Propriedades de Recetor (Target Receptor) ---
var is_receptor: bool = false
var is_pulsing: float = 0.0 # Tempo restante de brilho ao pressionar

var arrow_color: Color = Color.WHITE
var glow_color: Color = Color.WHITE

func _ready():
	# Configurar cores com base na pista e tipo de nota
	if type == "storm":
		arrow_color = Color(1.0, 0.75, 0.0, 1.0) # Ouro Elétrico
		glow_color = Color(1.0, 0.9, 0.2, 0.4)
	else:
		match lane:
			0: # Left
				arrow_color = Color(0.68, 0.38, 0.96, 1.0) # Roxo
				glow_color = Color(0.68, 0.38, 0.96, 0.35)
			1: # Down
				arrow_color = Color(0.23, 0.51, 0.96, 1.0) # Azul
				glow_color = Color(0.23, 0.51, 0.96, 0.35)
			2: # Up
				arrow_color = Color(0.06, 0.73, 0.51, 1.0) # Verde
				glow_color = Color(0.06, 0.73, 0.51, 0.35)
			3: # Right
				arrow_color = Color(0.94, 0.27, 0.27, 1.0) # Vermelho
				glow_color = Color(0.94, 0.27, 0.27, 0.35)
	queue_redraw()

func _process(delta):
	if is_receptor and is_pulsing > 0.0:
		is_pulsing -= delta
		if is_pulsing <= 0.0:
			queue_redraw()

func pulse():
	is_pulsing = 0.12 # 120ms de flash visual
	queue_redraw()

func _draw():
	if was_hit:
		return
		
	if is_receptor:
		var size_mult = 1.15 if is_pulsing > 0.0 else 1.0
		var color = arrow_color
		
		if is_pulsing > 0.0:
			color.a = 0.8
			# Desenhar preenchido brilhante no pulso
			_draw_arrow_shape(size_mult, color, false)
			_draw_arrow_shape(size_mult, Color.WHITE, true) # Contorno branco
		else:
			color.a = 0.35
			# Desenhar apenas o contorno (hollow) do recetor
			_draw_arrow_shape(size_mult, color, true)
	else:
		# Desenhar nota normal (queda/subida)
		# 1. Glow / Sombra
		_draw_arrow_shape(1.35, glow_color, false)
		# 2. Corpo principal
		_draw_arrow_shape(1.0, arrow_color, false)

func _draw_arrow_shape(size_multiplier: float, color: Color, outline_only: bool):
	if type == "storm":
		# Desenhar relâmpago estilizado
		var points = PackedVector2Array([
			Vector2(0, -24) * size_multiplier,
			Vector2(12, -4) * size_multiplier,
			Vector2(4, -4) * size_multiplier,
			Vector2(12, 24) * size_multiplier,
			Vector2(-10, 2) * size_multiplier,
			Vector2(-2, 2) * size_multiplier
		])
		if outline_only:
			var outline = points.duplicate()
			outline.append(points[0])
			draw_polyline(outline, color, 2.0, true)
		else:
			draw_polygon(points, [color])
			
			# Adicionar centro branco brilhante
			var inner_points = PackedVector2Array([
				Vector2(0, -18) * size_multiplier,
				Vector2(6, -4) * size_multiplier,
				Vector2(0, -4) * size_multiplier,
				Vector2(6, 16) * size_multiplier,
				Vector2(-5, 2) * size_multiplier,
				Vector2(-1, 2) * size_multiplier
			])
			draw_polygon(inner_points, [Color.WHITE])
	else:
		# Desenhar seta base apontada para CIMA (Y negativo)
		var points = PackedVector2Array([
			Vector2(0, -24) * size_multiplier,
			Vector2(24, -2) * size_multiplier,
			Vector2(10, -2) * size_multiplier,
			Vector2(10, 24) * size_multiplier,
			Vector2(-10, 24) * size_multiplier,
			Vector2(-10, -2) * size_multiplier,
			Vector2(-24, -2) * size_multiplier
		])
		
		# Rodar os pontos com base na pista
		var rot = 0.0
		match lane:
			0: rot = -PI / 2.0 # Left
			1: rot = PI        # Down
			2: rot = 0.0       # Up
			3: rot = PI / 2.0  # Right
			
		var rotated_points = PackedVector2Array()
		for p in points:
			rotated_points.append(p.rotated(rot))
			
		if outline_only:
			var outline = rotated_points.duplicate()
			outline.append(rotated_points[0])
			draw_polyline(outline, color, 2.5, true)
		else:
			draw_polygon(rotated_points, [color])
			
			# Contorno brilhante branco por cima
			var outline = rotated_points.duplicate()
			outline.append(rotated_points[0])
			draw_polyline(outline, Color.WHITE.darkened(0.15), 1.5, true)
