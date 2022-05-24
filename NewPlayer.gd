extends KinematicBody2D

var isMoving := false
onready var sprite := $Sprite
var way := []
export (int) var speed = 200
var target = Vector2()
var velocity = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.modulate = Color.beige
	set_physics_process(false)
	set_process(false)
	pass


func Stop() -> void:
	sprite.modulate = Color.beige
	isMoving = false
	set_physics_process(false)

func Start(_way : Array) -> void:
	_way.invert()
	way = _way
	sprite.modulate = Color.aqua
	isMoving = true
	way.pop_at(0)		# убираем точку на которой стоит игрок
	target = way[0].pos
	set_physics_process(true)
#	set_process(true)


func _physics_process(delta : float) -> void:
	velocity = position.direction_to(target) * speed
	# look_at(target)
	if position.distance_to(target) > 2:
		velocity = move_and_slide(velocity)
	else:
		way.remove(0)
		if(way.empty()):
			Stop()
			return
		target = way[0].pos
	
