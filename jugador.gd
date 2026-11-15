
extends CharacterBody2D

# =====================================
# NODOS
# =====================================

@onready var sprite: Sprite2D = $perro
@onready var pickup_area: Area2D = $perro/pickupArea

var hud: CanvasLayer
var contador: Label


# =====================================
# HELIO
# =====================================

var helio: int = 0

# Cuánto aumenta el salto por cada moneda
@export var aumento_salto_por_moneda: float = 12.0


# =====================================
# MOVIMIENTO
# =====================================

var velocidad: float = 300.0
var velocidad_carrera: float = 550.0
var gravedad: float = 1200.0


# =====================================
# SALTO
# =====================================

var fuerza_salto: float = 350.0
var fuerza_carga: float = 1000.0
var carga_maxima: float = 0.35

var saltos_maximos: int = 2
var saltos_restantes: int = 2

var tiempo_carga: float = 0.0
var cargando_salto: bool = false


# =====================================
# CARRERA
# =====================================

var tiempo_doble_toque: float = 0.30
var tiempo_desde_toque: float = 0.0
var ultima_direccion: int = 0
var corriendo: bool = false


# =====================================
# PODER DE REPULSIÓN
# =====================================

var puede_usar_poder: bool = true
var tiempo_recarga: float = 1.5
var radio_poder: float = 180.0
var fuerza_repulsion: float = 900.0


# =====================================
# INICIO
# =====================================

func _ready():

	# Crear el HUD si todavía no existe
	hud = get_node_or_null("CanvasLayer")

	if hud == null:
		hud = CanvasLayer.new()
		hud.name = "CanvasLayer"
		add_child(hud)

	# Crear el contador si todavía no existe
	contador = hud.get_node_or_null("Contador")

	if contador == null:
		contador = Label.new()
		contador.name = "Contador"
		hud.add_child(contador)

	contador.position = Vector2(25, 25)
	actualizar_contador()

	# Conectar el detector de monedas
	if not pickup_area.area_entered.is_connected(
		_on_pickup_area_area_entered
	):
		pickup_area.area_entered.connect(
			_on_pickup_area_area_entered
		)


# =====================================
# FÍSICA Y MOVIMIENTO
# =====================================

func _physics_process(delta: float):

	# GRAVEDAD
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		velocity.y = 0.0
		saltos_restantes = saltos_maximos

	# DOBLE TOQUE
	tiempo_desde_toque -= delta

	if Input.is_action_just_pressed("ui_right"):
		if ultima_direccion == 1 and tiempo_desde_toque > 0:
			corriendo = true
		else:
			ultima_direccion = 1
			tiempo_desde_toque = tiempo_doble_toque

	if Input.is_action_just_pressed("ui_left"):
		if ultima_direccion == -1 and tiempo_desde_toque > 0:
			corriendo = true
		else:
			ultima_direccion = -1
			tiempo_desde_toque = tiempo_doble_toque

	# MOVIMIENTO
	var direccion = Input.get_axis("ui_left", "ui_right")

	if direccion == 0:
		corriendo = false

	if corriendo:
		velocity.x = direccion * velocidad_carrera
	else:
		velocity.x = direccion * velocidad

	# GIRAR PERSONAJE
	if direccion < 0:
		sprite.flip_h = false
	elif direccion > 0:
		sprite.flip_h = true

	# SALTO Y DOBLE SALTO
	var quiere_saltar = (
		Input.is_action_just_pressed("ui_up")
		or Input.is_action_just_pressed("saltar")
	)

	if quiere_saltar and saltos_restantes > 0:

		velocity.y = -fuerza_salto
		saltos_restantes -= 1

		tiempo_carga = 0.0
		cargando_salto = true

	# CARGAR SALTO
	if cargando_salto:

		if Input.is_action_pressed("ui_up"):

			tiempo_carga = min(
				tiempo_carga + delta,
				carga_maxima
			)

			velocity.y -= fuerza_carga * delta

		else:
			cargando_salto = false

	# PODER DE REPULSIÓN
	if Input.is_action_just_pressed("ui_down"):
		if puede_usar_poder:
			usar_repulsion()

	# MOVIMIENTO Y COLISIONES
	move_and_slide()


# =====================================
# RECOGER HELIO
# =====================================

func _on_pickup_area_area_entered(area: Area2D):

	# Comprobar que sea una moneda de helio
	if not area.is_in_group("moneda_helio"):
		return

	# Evitar recogerla más de una vez
	area.set_deferred("monitoring", false)
	area.set_deferred("monitorable", false)

	# Obtener el valor de la moneda
	var cantidad: int = int(area.get("valor_helio"))

	# AUMENTAR HELIO
	helio += cantidad

	# MEJORAR EL SALTO
	fuerza_salto += aumento_salto_por_moneda

	# ACTUALIZAR CONTADOR
	actualizar_contador()

	# MOSTRAR MENSAJE
	mostrar_aviso("+" + str(cantidad) + " de helio")

	# ELIMINAR MONEDA
	area.queue_free()

	print("Helio: ", helio)
	print("Fuerza de salto: ", fuerza_salto)


# =====================================
# ACTUALIZAR CONTADOR
# =====================================

func actualizar_contador():

	contador.text = "Helio: " + str(helio)


# =====================================
# MENSAJE +10 DE HELIO
# =====================================

func mostrar_aviso(mensaje: String):

	var aviso = Label.new()

	aviso.text = mensaje
	aviso.position = Vector2(25, 60)
	aviso.add_theme_font_size_override("font_size", 24)
	aviso.modulate = Color(1, 1, 0.3, 1)

	hud.add_child(aviso)

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		aviso,
		"position",
		aviso.position + Vector2(0, -35),
		0.8
	)

	tween.tween_property(
		aviso,
		"modulate:a",
		0.0,
		0.8
	)

	await tween.finished

	aviso.queue_free()


# =====================================
# PODER DE REPULSIÓN
# =====================================

func usar_repulsion():

	puede_usar_poder = false

	var objetos = get_tree().get_nodes_in_group("empujables")

	for objeto in objetos:

		if not objeto is RigidBody2D:
			continue

		var distancia = global_position.distance_to(
			objeto.global_position
		)

		if distancia <= radio_poder:

			var direccion = (
				objeto.global_position - global_position
			)

			if direccion.length() > 0:
				direccion = direccion.normalized()
			else:
				direccion = Vector2.UP

			var intensidad = fuerza_repulsion * (
				1.0 - distancia / radio_poder
			)

			objeto.apply_central_impulse(
				direccion * intensidad
			)

	await get_tree().create_timer(tiempo_recarga).timeout

	puede_usar_poder = true
