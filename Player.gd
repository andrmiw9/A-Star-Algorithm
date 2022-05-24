extends Sprite

var isMoving := false
var way := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate = Color.beige
	set_process(false)
	pass


func Stop() -> void:
	modulate = Color.beige

func Start(_way : Array) -> void:
	_way.invert()
	way = _way
	modulate = Color.aqua
	isMoving = true
	set_process(true)


func _process(delta: float) -> void:
	if(way[0].pos == position):
		way.remove(0)
		if(way.empty()):
			Stop()
	var velocity = Vector2.ZERO # The player's movement vector.
	velocity = velocity.normalized() * 1
	
	position += velocity * delta

