extends TileMap

onready var player = $""../Player""	# ссылка на игрока
var StartPos := Vector2.ZERO		# глобальный вектор старт позиции
var Trueway := []				# the final way of cells
var OpenList := []				# priority queue of tiles, that will be used to find a way
var needsClearing := false		# вспомогательный триггер для очистки найденного пути для следующего запуска
var Cells := []					# all Cells objects
var isWorking := false			# триггер для блокировки сигнала
var iterCount := 0				# простой счетчик итераций


class Cell:
	var isClosed := false		# были ли мы здесь
	var pos := Vector2.ZERO		# 
	var CheapestPath = 1000000	# самый дешевый путь до этой клетки
	var Score = 1000000			# счет
	var h = -1					# отдельно h эвристика
	var CameFrom = null			# ссылка на предыдущую клетку

	func _init(Position) -> void:	# простенький конструктор
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
	


func _input(event: InputEvent) -> void:
	if(Input.is_action_just_pressed("LMB_Click")):		# Start searching
		if(!isWorking and !player.isMoving):
			if(!needsClearing):
				Cells.clear()
				for cell in get_used_cells():
					Cells.append(Cell.new(cell))
				StartPos = world_to_map(player.global_position)		# set the startPos of a player
				var mouse_pos = world_to_map(get_global_mouse_position())
				if(get_used_cells().has(mouse_pos)): # if our mouse is on some cell
					print(mouse_pos)
					StartSearching(mouse_pos)
			else:
				print("First clean previous path!")
	if(Input.is_action_just_pressed("RMB_Click")):		# Clear
		if(isWorking or player.isMoving):
			print("Algorith is running, wait some time!")
			return
		else:
			StartPos = Vector2.ZERO
			for cell in get_used_cells():
				set_cellv(cell, 3)
			Trueway.clear()
			OpenList.clear()
			isWorking = false
			iterCount = 0
			needsClearing = false
			print("All Cleared!")
		


# A*
func StartSearching(endPos) -> void:	
	isWorking = true
	
	StartPos = world_to_map(player.global_position)
	print("StartPos: ", StartPos,"EndPos: ", endPos)
	if(get_cellv(StartPos) != INVALID_CELL):
		set_cellv(StartPos, 4)
	if(get_cellv(endPos) != INVALID_CELL):
		set_cellv(endPos, 5)

	var curCell = FindCellByPos(StartPos)
	curCell.pos = StartPos
	curCell.CheapestPath = 0					# Путь до начальной точки - это 0
	if(curCell.pos == endPos):
		print("Find the EndPos!")
		return
	curCell.Score = h(curCell.pos, endPos)		# запускаем оценку для нач точки
	OpenList.append(curCell)					# добавляем нач точку
	
	print("\nSTART\n")
	while !OpenList.empty():			# Main loop
		CustomDraw()
		# f(n) = g(n) + h(n), n - next node to path, g(n) - уже пройденный путь, h - эвристика
		print("\nWhile iteration")
		curCell = FindMinScoreInOList()[1]			# функция находит клетку с минимальным Score во всем списке
		if(curCell.pos == endPos):
			set_cellv(curCell.pos, 5)				# фикс для тайла конечной клетки
			print("Find the EndPos!")
			break
		print("Now looking at:", curCell.pos)
		OpenList.remove(OpenList.find(curCell))		# удаляем текущий селл
		if(curCell.pos != StartPos):
			set_cellv(curCell.pos, 6)				# фикс для тайла начальной клетки		
		curCell.isClosed = true						# ставим метку, что уже были здесь
		
		var points_nearBy = [curCell.pos + Vector2.UP, curCell.pos + Vector2.RIGHT, curCell.pos + Vector2.DOWN, curCell.pos + Vector2.LEFT]
		for NearPo in points_nearBy:					# берем cell
			if(!get_used_cells().has(NearPo)):			# пропускаем клетку если она не принадлежит тайлмэпу
				continue
			var NearCell = FindCellByPos(NearPo)		# ищем сам селл
			if(NearCell.isClosed):						# пропускаем клетку, если мы уже рассматривали её
				continue
#			var NearCell = Cells[usedC.find(NearPo)]	# берем связанный Cell object
#			NearCell.pos = NearPo
			print("NearCellPos: ", NearCell.pos)
			var put = curCell.CheapestPath + 1			# cчитаем кратчайший путь до соседа (NearCell.pos - curCell.pos).length() будет всегда 1
			print("Put: ", put)
			if(put < NearCell.CheapestPath):			# если он оказался меньше
				NearCell.CameFrom = curCell				# ставим соседу откуда пришёл
				NearCell.CheapestPath = put				# задаём сам путь
				NearCell.h = ceil(h(NearPo, endPos))	# 68 for ceil, 75 for floor, 72 for nothing, 73 for round, 73 for stepify for 1.
				NearCell.Score = put + NearCell.h		# "Счет"
				
				if(!OpenList.has(NearCell)):
					OpenList.append(NearCell)
		
#		print("OpenList after appending: ", OpenList)
		print("OpenList after checking neighbours:")
		PrintOpenList()
		
		iterCount += 1
		yield(get_tree().create_timer(0.2), "timeout")
	
	print("\nWhile finished!")
	print("Number of iterations: ", iterCount)
	yield(get_tree().create_timer(1), "timeout")
	ReconstructWay(endPos)
	player.Start(Trueway)
	isWorking = false
	needsClearing = true
	pass


# Recursively goes through all path from the end to start, marking the cells
func ReconstructWay(endPos) -> void:
	var cell = FindCellByPos(endPos)
	while (cell.pos != StartPos):		# recursive from end to start
		cell.pos = map_to_world(cell.pos)
		cell.pos.x += 32		# for centering
		cell.pos.y += 32		# 
		Trueway.append(cell)
		cell = cell.CameFrom
		set_cellv(cell.pos, 8)
	set_cellv(cell.pos, 4)
	Trueway.append(cell)
	print("Reconstructing done")


# Prints--------------------------------------
func PrintOpenList() -> void:
	print("\nPrintOpenListPosAndScores:")
	for cell in OpenList:
		print(cell.pos, "; ", cell.Score,"; ", cell.h)

func PrintOpenListPos() -> void:
	print("\nPrintOpenListPos:")
	for cell in OpenList:
		print(cell.pos)

func PrintOpenListScores() -> void:
	print("\nPrintOpenListScores:")
	for cell in OpenList:
		print(cell.Score)
# --------------------------------------------


# Эвристическая функция оценки расстояния до цели (просто считает длину вектора из переданной точки до финальной)
func h(pos, endpos) -> float:
	print("h will return: ",(pos - endpos).length())
	return (pos - endpos).length()		# возвращает длину в клетках до цели


# Метод находит клетку в списке клеток по переданной позиции
func FindCellByPos(pos) -> Cell:
	for c in Cells:
		if(c.pos == pos):
			return c
	print("No cell was found by this positon: ", pos)
	return null


# Метод находит клетку с мин счётом и возвращает счет и её
func FindMinScoreInOList() -> Array:
	var minim = 1000000
	var c = null
	for cell in OpenList:
		if(cell.Score <= minim):
			c = cell
			minim = cell.Score
	return [minim, c]


# Подстветка для клеток в открытом списке (крестики)
func CustomDraw() -> void:
	if(!needsClearing):
#		for p in Closed:
#			set_cellv(p, 6)
		for cell in OpenList:
			if(cell.pos == StartPos):
				continue
			set_cellv(cell.pos, 7)
	pass
