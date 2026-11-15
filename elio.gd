
extends Area2D

@export var valor_helio: int = 10

@onready var sprite: Sprite2D = $Sprite2D

var tiempo: float = 0.0


func _ready():

	# Identificar esta moneda
	add_to_group("moneda_helio")

	# Activar detección
	monitoring = true
	monitorable = true


func _process(delta: float):

	tiempo += delta

	# Animación de giro
	sprite.rotation += 2.0 * delta

	# Animación de flotación
	sprite.position.y = sin(tiempo * 3.0) * 6.0
