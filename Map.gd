extends TileMap

onready var player = $Player
#var used_cells := []
var StartPos := Vector2.ZERO
#var usedC := []		# all cells in TileMap, indexes are same with Cells
var Trueway := []	# the final way of cells, connected with OpenQ
var OpenQ := []		# priority queue of tiles, that will be used to find a way, they are all neighbours of a Closed
#var Closed := []	# list of tiles that were checked
var needsClearing := false
var Cells := []		# all Cells objects in TileMap, indexes are same with usedC
var isWorking := false
# LIFO


class Cell:
	var pos := Vector2.ZERO
	var CheapestPath = 1000000
#	var neighbours
	var Score = 1000000
	var CameFrom = null

	func _init(Position) -> void:
		pos = Position



func _ready() -> void:
	var toggleDebug := true
	if(toggleDebug):
		OS.window_size = Vector2(1075,640)
		OS.window_position = Vector2(0,1200)
		OS.current_screen = 1
	var debugNout := false
	if(debugNout):
		OS.window_size = Vector2(800, 500)
		OS.window_position = Vector2(0,540)
	
	
	for cell in get_used_cells():
		Cells.append(Cell.new(cell))
	
	StartPos = world_to_map(player.global_position)		# set the startPos of a player
#	CheapestPaths[0] = 0 	# Cheapest path to the startPos
	pass


func _input(event: InputEvent) -> void:
	if(Input.is_action_just_pressed("LMB_Click")):
		if(!isWorking):
			var mouse_pos = world_to_map(get_global_mouse_position())
			if(get_used_cells().has(mouse_pos)): # if our mouse is on some cell
				print(mouse_pos)
				StartSearching(mouse_pos)
	if(Input.is_action_just_pressed("RMB_Click")):
		if(isWorking):
			print("Algorith is running, wait some time!")
			return
		# clear all the stuff


# Getting things ready to A*
func StartSearching(endPos) -> void:	
	isWorking = true
	
	StartPos = world_to_map(player.global_position)
	print("StartPos: ", StartPos,"EndPos: ", endPos)
	if(get_cellv(StartPos) != INVALID_CELL):
		set_cellv(StartPos, 4)
	if(get_cellv(endPos) != INVALID_CELL):
		set_cellv(endPos, 5)
#	var StartCell = Cell.new(StartPos)
	
#	var cur_point = StartPos
	
#	var curCell = Cells[usedC.find(cur_point)]	# ищем связанный селл
	var curCell = FindCellByPos(StartPos)
	curCell.pos = StartPos
	curCell.CheapestPath = 0					# Путь до начальной точки - это 0
	if(curCell.pos == endPos):
		print("Find the EndPos!")
		return
	curCell.Score = h(curCell.pos, endPos)		# запускаем оценку для нач точки
	OpenQ.push_front(curCell)					# добавляем нач точку
	
	
	while !OpenQ.empty():			# Main loop
		# f(n) = g(n) + h(n), n - next node to path, g(n) - уже пройденный путь, h - эвристика
		curCell = FindMinScoreInQ()[1]
		if(curCell.pos == endPos):
			print("Find the EndPos!")
			return
		
		OpenQ.remove(OpenQ.find(curCell))
		
		var points_nearBy = [curCell.pos + Vector2.UP, curCell.pos + Vector2.RIGHT, curCell.pos + Vector2.DOWN, curCell.pos + Vector2.LEFT]
		for NearPo in points_nearBy:					# берем cell
			if(!get_used_cells().has(NearPo)):						# выходим если клетка не тайлмэпа
				continue
			var NearCell = FindCellByPos(NearPo)		# ищем сам селл
#			var NearCell = Cells[usedC.find(NearPo)]# берем связанный Cell object
#			NearCell.pos = NearPo
			var put = curCell.CheapestPath + (NearPo - curCell.pos).length()	# cчитаем кратчайший путь до соседа
			if(put < NearCell.CheapestPath):			# если он оказался меньше
				NearCell.CameFrom = curCell			# ставим соседу откуда пришёл
				NearCell.CheapestPath = put			# задаём сам путь
				NearCell.Score = put + h(NearPo, endPos)		# функция оценки в очереди
				
				if(!OpenQ.has(NearCell)):
					OpenQ.append(NearCell)
			
		print("OpenQ after appending: ", OpenQ)
#		print("OpenQ pos-s:")
	
		CustomDraw()
#		update()
	pass


# Эвристическая функция оценки расстояния до цели (просто считает длину вектора из переданной точки до финальной)
func h(pos, endpos) -> float:
	print("h will return: ",(pos-endpos).length())
	return (pos - endpos).length()


func FindCellByPos(pos) -> Cell:
	for c in Cells:
		if(c.pos == pos):
			return c
	print("No cell was found by this positon: ", pos)
	return null


func FindMinScoreInQ() -> Array:
	var minim = 1000000
	var c = null
	for cell in OpenQ:
		if(cell.Score < minim):
			c = cell
			minim = cell.Score
	return [minim, c]


func CustomDraw() -> void:
	if(!needsClearing):
#		for p in Closed:
#			set_cellv(p, 6)
		for cell in OpenQ:
			set_cellv(cell.pos, 7)
	pass

#func _draw():
##	CanvasItem.show_on_top = true
#	if(!needsClearing):
#		for p in Closed:
#			draw_circle(map_to_world(p), 50, Color.aqua)
#		for p in OpenQ:
#			draw_circle(map_to_world(p), 50, Color.coral)
#		pass
#



#draw_line(last_point, current_point, DRAW_COLOR, BASE_LINE_WIDTH, true)
#		draw_circle(current_point, BASE_LINE_WIDTH * 2.0, DRAW_COLOR)


#func _draw():
#	if not _point_path:
#		return
#	var point_start = _point_path[0]
#	var point_end = _point_path[len(_point_path) - 1]
#
#	set_cell(point_start.x, point_start.y, 1)
#	set_cell(point_end.x, point_end.y, 2)
#
#	var last_point = map_to_world(Vector2(point_start.x, point_start.y)) + _half_cell_size
#	for index in range(1, len(_point_path)):
#		var current_point = map_to_world(Vector2(_point_path[index].x, _point_path[index].y)) + _half_cell_size
#		draw_line(last_point, current_point, DRAW_COLOR, BASE_LINE_WIDTH, true)
#		draw_circle(current_point, BASE_LINE_WIDTH * 2.0, DRAW_COLOR)
#		last_point = current_point

#func astar_connect_walkable_cells(points_array):
#	for point in points_array:
#		var point_index = calculate_point_index(point)
#		# For every cell in the map, we check the one to the top, right.
#		# left and bottom of it. If it's in the map and not an obstalce.
#		# We connect the current point with it.
#		fwffawfafwa
#		for point_relative in points_relative:
#			var point_relative_index = calculate_point_index(point_relative)
#			if is_outside_map_bounds(point_relative):
#				continue
#			if not astar_node.has_point(point_relative_index):
#				continue
#			# Note the 3rd argument. It tells the astar_node that we want the
#			# connection to be bilateral: from point A to B and B to A.
#			# If you set this value to false, it becomes a one-way path.
#			# As we loop through all points we can set it to false.
#			astar_node.connect_points(point_index, point_relative_index, false)
