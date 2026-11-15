
extends CharacterBody2D

# =====================================
# NODOS
# =====================================

@onready var sprite = get_node_or_null("perro")
@onready var pickup_area = get_node_or_null("perro/pickupArea")

var hud: CanvasLayer
var contador: Label


# =====================================
# MONEDAS Y RECURSOS
# =====================================

var helio: int = 0
var moneda_carbono: int = 0

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

	# Grupo para el mapa infinito
	add_to_group("jugador")

	# Crear HUD
	hud = get_node_or_null("CanvasLayer")

	if hud == null:
		hud = CanvasLayer.new()
		hud.name = "CanvasLayer"
		add_child(hud)

	# Crear contador
	contador = hud.get_node_or_null("Contador")

	if contador == null:
		contador = Label.new()
		contador.name = "Contador"
		hud.add_child(contador)

	contador.position = Vector2(25, 25)

	actualizar_contador()

	# Comprobar sprite
	if sprite == null:
		push_error("No se encontró el nodo perro")
		set_physics_process(false)
		return

	# Conectar detector de monedas
	if pickup_area == null:
		push_error("No se encontró perro/pickupArea")
	else:
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

	# MOVIMIENTO HORIZONTAL
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
	var quiere_saltar = Input.is_action_just_pressed("ui_up")

	if InputMap.has_action("saltar"):
		quiere_saltar = (
			quiere_saltar
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


	# APLICAR MOVIMIENTO
	move_and_slide()


# =====================================
# RECOGER MONEDAS
# =====================================

func _on_pickup_area_area_entered(area: Area2D):

	# MONEDA DE HELIO
	if area.is_in_group("moneda_helio"):

		if not area.monitoring:
			return

		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)

		var cantidad_helio: int = int(
			area.get("valor_helio")
		)

		helio += cantidad_helio

		# AUMENTAR SALTO
		fuerza_salto += aumento_salto_por_moneda

		actualizar_contador()

		mostrar_aviso(
			"+" + str(cantidad_helio) + " de helio"
		)

		area.queue_free()

		print("Helio: ", helio)
		print("Fuerza de salto: ", fuerza_salto)

		return

	# MONEDA DE CARBONO
	if area.is_in_group("moneda_carbono"):

		if not area.monitoring:
			return

		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)

		var cantidad_carbono: int = int(
			area.get("valor_carbono")
		)

		moneda_carbono -= cantidad_carbono

		# DISMINUIR SALTO
		fuerza_salto = maxf(
			100.0,
			fuerza_salto - aumento_salto_por_moneda
		)

		actualizar_contador()

		mostrar_aviso(
			"-" + str(cantidad_carbono) + " de carbono"
		)

		area.queue_free()

		print("Carbono: ", moneda_carbono)
		print("Fuerza de salto: ", fuerza_salto)


# =====================================
# ACTUALIZAR CONTADOR
# =====================================

func actualizar_contador():

	if contador != null:

		contador.text = (
			"Helio: " + str(helio)
			+ " | Carbono: " + str(moneda_carbono)
		)


# =====================================
# MENSAJE FLOTANTE
# =====================================

func mostrar_aviso(mensaje: String):

	var aviso = Label.new()

	aviso.text = mensaje
	aviso.position = Vector2(25, 60)

	aviso.add_theme_font_size_override(
		"font_size",
		24
	)

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
