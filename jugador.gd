
extends CharacterBody2D

@onready var sprite = $perro

# MOVIMIENTO
var velocidad: float = 300.0
var velocidad_carrera: float = 550.0
var gravedad: float = 1200.0

# SALTO
var fuerza_salto: float = 350.0
var fuerza_carga: float = 1000.0
var carga_maxima: float = 0.35

# DOBLE SALTO
var saltos_maximos: int = 2
var saltos_restantes: int = 2

# CARGA DEL SALTO
var tiempo_carga: float = 0.0
var cargando_salto: bool = false

# CARRERA
var tiempo_doble_toque: float = 0.30
var tiempo_desde_toque: float = 0.0
var ultima_direccion: int = 0
var corriendo: bool = false

# PODER DE REPULSIÓN
var puede_usar_poder: bool = true
var tiempo_recarga: float = 1.5
var radio_poder: float = 180.0
var fuerza_repulsion: float = 900.0


func _physics_process(delta: float):

	# GRAVEDAD
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		velocity.y = 0.0
		saltos_restantes = saltos_maximos

	# DOBLE PULSACIÓN
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

	# SALTO
	var quiere_saltar = Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("saltar")

	if quiere_saltar and saltos_restantes > 0:
		velocity.y = -fuerza_salto
		saltos_restantes -= 1
		tiempo_carga = 0.0
		cargando_salto = true

	# CARGAR SALTO
	if cargando_salto:
		if Input.is_action_pressed("ui_up"):
			tiempo_carga = min(tiempo_carga + delta, carga_maxima)
			velocity.y -= fuerza_carga * delta
		else:
			cargando_salto = false

	# PODER DE REPULSIÓN
	if Input.is_action_just_pressed("ui_down") and puede_usar_poder:
		usar_repulsion()

	# MOVIMIENTO Y COLISIONES
	move_and_slide()


# ACTIVAR REPULSIÓN
func usar_repulsion():

	puede_usar_poder = false

	# BUSCAR OBJETOS CERCANOS
	var objetos = get_tree().get_nodes_in_group("empujables")

	for objeto in objetos:

		if not objeto is RigidBody2D:
			continue

		var distancia = global_position.distance_to(objeto.global_position)

		if distancia <= radio_poder:

			var direccion = objeto.global_position - global_position

			if direccion.length() > 0:
				direccion = direccion.normalized()
			else:
				direccion = Vector2.UP

			var intensidad = fuerza_repulsion * (1.0 - distancia / radio_poder)

			objeto.apply_central_impulse(direccion * intensidad)

	# RECARGAR PODER
	await get_tree().create_timer(tiempo_recarga).timeout
	puede_usar_poder = true
