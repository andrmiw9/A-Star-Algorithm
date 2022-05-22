extends Sprite

var isMoving := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate = Color.beige
	set_process(false)
#	Start()
#	Stop()
	pass


func Stop() -> void:
	modulate = Color.beige



func Start() -> void:
	modulate = Color.aqua
