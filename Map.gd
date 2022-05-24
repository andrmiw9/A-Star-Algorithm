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

var iterCount := 0


class Cell:
	var isClosed := false
	var pos := Vector2.ZERO
	var CheapestPath = 1000000
#	var neighbours
	var Score = 1000000
	var h = -1
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
	
	print("\nSTART\n")
	while !OpenQ.empty():			# Main loop
		CustomDraw()
		# f(n) = g(n) + h(n), n - next node to path, g(n) - уже пройденный путь, h - эвристика
		print("\nWhile iteration")
		curCell = FindMinScoreInQ()[1]
		if(curCell.pos == endPos):
			set_cellv(curCell.pos, 5)
			print("Find the EndPos!")
			break
		print("Now looking at:", curCell.pos)
		OpenQ.remove(OpenQ.find(curCell))
		if(curCell.pos != StartPos):
			set_cellv(curCell.pos, 6)
		curCell.isClosed = true
		
		var points_nearBy = [curCell.pos + Vector2.UP, curCell.pos + Vector2.RIGHT, curCell.pos + Vector2.DOWN, curCell.pos + Vector2.LEFT]
		for NearPo in points_nearBy:					# берем cell
			if(!get_used_cells().has(NearPo)):			# пропускаем клетку если она не принадлежит тайлмэпу
				continue
			var NearCell = FindCellByPos(NearPo)		# ищем сам селл
			if(NearCell.isClosed):						# пропускаем клетку, если мы уже рассматривали её
				continue
#			var NearCell = Cells[usedC.find(NearPo)]# берем связанный Cell object
#			NearCell.pos = NearPo
			print("NearCellPos: ", NearCell.pos)
			var put = curCell.CheapestPath + 1	# cчитаем кратчайший путь до соседа (NearCell.pos - curCell.pos).length() будет всегда 1
			print("Put: ", put)
			if(put < NearCell.CheapestPath):			# если он оказался меньше
				NearCell.CameFrom = curCell			# ставим соседу откуда пришёл
				NearCell.CheapestPath = put			# задаём сам путь
				NearCell.h = ceil(h(NearPo, endPos))	# 68 for ceil, 75 for floor, 72 for nothing, 73 for round, 73 for stepify for 1.
				NearCell.Score = put + NearCell.h		# функция оценки в очереди
				
				if(!OpenQ.has(NearCell)):
					OpenQ.append(NearCell)
				
			
#		print("OpenQ after appending: ", OpenQ)
		print("OpenQ after checking neighbours:")
		PrintOpenQ()
#		PrintOpenQScores()
#		OpenQ.sort_custom(CustomSorter, "sort_ascending")
#		print("OpenQ after sorting: ", OpenQ)
#		PrintOpenQScores()
		
		iterCount += 1
		yield(get_tree().create_timer(0.1), "timeout")
#		update()
	
	
	print("\nWhile finished!")
	print("Number of iterations: ", iterCount)
	ReconstructWay()
	needsClearing = true
	pass


func ReconstructWay() -> void:
	
	pass


# Prints--------------------------------------
func PrintOpenQ() -> void:
	print("\nPrintOpenQPosAndScores:")
	for cell in OpenQ:
		print(cell.pos, "; ", cell.Score,"; ", cell.h)

func PrintOpenQPos() -> void:
	print("\nPrintOpenQPos:")
	for cell in OpenQ:
		print(cell.pos)

func PrintOpenQScores() -> void:
	print("\nPrintOpenQScores:")
	for cell in OpenQ:
		print(cell.Score)
# --------------------------------------------


# Эвристическая функция оценки расстояния до цели (просто считает длину вектора из переданной точки до финальной)
func h(pos, endpos) -> float:
	print("h will return: ",(pos - endpos).length())
	return (pos - endpos).length()		# возвращает длину в клетках до цели


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
		if(cell.Score <= minim):
			c = cell
			minim = cell.Score
	return [minim, c]


func CustomDraw() -> void:
	if(!needsClearing):
#		for p in Closed:
#			set_cellv(p, 6)
		for cell in OpenQ:
			if(cell.pos == StartPos):
				continue
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
#		draw_circle(current_point, BASE_LINE_WIDTH * 2.0, DRAW_COLOR
