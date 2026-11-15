extends Node2D

@export var plataforma_escena: PackedScene

@export var distancia_entre_plataformas: float = 150.0
@export var ancho_mapa: float = 900.0
@export var cantidad_inicial: int = 15
@export var plataformas_por_generacion: int = 8

var siguiente_altura: float = 0.0
var plataformas: Array[Node2D] = []


func _ready():
	# Generar plataformas iniciales
	for i in range(cantidad_inicial):
		generar_plataforma()


func _process(_delta):

	# Buscar al jugador
	var jugador = get_tree().get_first_node_in_group("jugador")

	if jugador == null:
		return

	# Generar más mapa cuando el jugador sube
	while jugador.global_position.y < siguiente_altura + 900:
		for i in range(plataformas_por_generacion):
			generar_plataforma()

	# Eliminar plataformas muy abajo
	for plataforma in plataformas.duplicate():
		if plataforma.global_position.y > jugador.global_position.y + 1200:
			plataforma.queue_free()
			plataformas.erase(plataforma)


func generar_plataforma():

	if plataforma_escena == null:
		return

	var plataforma = plataforma_escena.instantiate()

	add_child(plataforma)

	var posicion_x = randf_range(50.0, ancho_mapa - 50.0)

	plataforma.global_position = Vector2(
		posicion_x,
		siguiente_altura
	)

	plataformas.append(plataforma)

	siguiente_altura -= distancia_entre_plataformas
