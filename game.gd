extends Node2D

<<<<<<< HEAD
@export var bird_scene: PackedScene = preload("res://bird.tscn")
@export var cat_scene: PackedScene = preload("res://cat.tscn")
@export var blood_scene: PackedScene = preload("res://blood.tscn")
@onready var music = $smash

var cell_matrix = []
var previous_cell_states = []
var column_count = 55
var row_count = 30
var cell_width = 35
var move_timer = 0.2  
var move_speed = 15 
var numar_maxim_pasari = 0
var game_timer = Timer.new()
var max_cats= 20
var cats_spawn=0
var max_birds= 400
var birds_spawn=0
var bird_move_timer = Timer.new()

func _ready():
	max_birds=Global.max_birds_can
	max_cats=Global.max_cats_can
	cell_width = Global.grid_progres 
	initialize_grid()
	set_process(true)  
	game_timer.wait_time = 0.5  
	game_timer.autostart = true
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	bird_move_timer.wait_time = 0.1  
	bird_move_timer.autostart = true
	bird_move_timer.timeout.connect(_on_bird_move)
	add_child(bird_move_timer)

func _on_bird_move():
	move_birds()  

func _on_game_timer_timeout():
	apply_rules()
	move_birds() 
	move_cats()

func apply_rules():
	var next_state = []
	for column in range(column_count):
		var column_state = []
		for row in range(row_count):
			var is_alive = get_next_state(column, row)
			column_state.push_back(is_alive)
		next_state.push_back(column_state)
	previous_cell_states = next_state.duplicate(true)

func get_next_state(column: int, row: int) -> bool:
	var entity = cell_matrix[column][row]
	
	if entity and entity is Bird and has_cat_neighbor(column, row):
		Global.output_data="Bird was killed by cat ("+str(column) + ", "+ str(row)+")"
		play_blood_animation(column, row)  
		cell_matrix[column][row] = null 
		previous_cell_states[column][row] = false  
		entity.queue_free() 
		return false 

	if entity is Bird:
		var bird_count = count_neighboring_birds(column, row)
		if bird_count < 1 or bird_count > 4:
			Global.output_data="Bird dies due to overpopulation ("+str(column) + ", "+ str(row)+")"
			play_blood_animation(column, row)
			cell_matrix[column][row] = null
			previous_cell_states[column][row] = false
			entity.queue_free()  
			birds_spawn -= 1 
			return false
		else:
			if bird_count == 3 and birds_spawn < numar_maxim_pasari:
				Global.output_data="New Bird was spawned ("+str(column) + ", "+ str(row)+")"
				spawn_new_birds()
				return true  
		return true 
	return previous_cell_states[column][row]

func spawn_new_birds():
	var new_birds = []
	for column in range(column_count):
		for row in range(row_count):
			if cell_matrix[column][row] == null: 
				var bird_neighbors = count_neighboring_birds(column, row)
				if bird_neighbors == 3: 
					new_birds.append(Vector2(column, row))
	
	if birds_spawn + len(new_birds) > max_birds:
		new_birds = new_birds.slice(0, max_birds - birds_spawn) 
	for pos in new_birds:
		var new_bird = bird_scene.instantiate() 
		new_bird.position = Vector2(pos.x * cell_width, pos.y * cell_width)
		add_child(new_bird)
		cell_matrix[pos.x][pos.y] = new_bird
	birds_spawn += len(new_birds)

func count_neighboring_birds(column, row):
	var neighbors = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
		Vector2(-1,  0),               Vector2(1,  0),
		Vector2(-1,  1), Vector2(0,  1), Vector2(1, 1)
	]
	var bird_count = 0
	
	for offset in neighbors:
		var new_col = column + int(offset.x)
		var new_row = row + int(offset.y)
		if new_col >= 0 and new_col < column_count and new_row >= 0 and new_row < row_count:
			if cell_matrix[new_col][new_row] and cell_matrix[new_col][new_row] is Bird:
				bird_count += 1
	return bird_count

func has_cat_neighbor(column: int, row: int) -> bool:
	var neighbors = [
		Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)
	]  
	for offset in neighbors:
		var nx = column + int(offset.x)
		var ny = row + int(offset.y)
		if nx >= 0 and nx < column_count and ny >= 0 and ny < row_count:
			if cell_matrix[nx][ny] and cell_matrix[nx][ny] is Cat:
				return true
	return false

func initialize_grid():
	var rng = RandomNumberGenerator.new()
	for column in range(column_count):
		if column >= cell_matrix.size():
			cell_matrix.push_back([])
			previous_cell_states.push_back([])
			
		for row in range(row_count):
			if row >= previous_cell_states[column].size():
				previous_cell_states[column].push_back(rng.randi_range(0, 1) == 1)
			if row >= cell_matrix[column].size():
				cell_matrix[column].push_back(null) 
			var entity
			if rng.randi_range(0, 100) < 1 and cats_spawn < max_cats and ((row>12 and column >22) or ( row<12)): 
				cats_spawn += 1
				entity = cat_scene.instantiate()
			elif rng.randi_range(0, 100) < 15 and birds_spawn < max_birds:
				birds_spawn += 1
				entity = bird_scene.instantiate()
			if entity:
				if column < column_count and row < row_count:
					cell_matrix[column][row] = entity 
					add_child(entity)
					entity.position = Vector2(column * cell_width, row * cell_width)
					entity.visible = !previous_cell_states[column][row] && !is_edge(column, row)
					var animated_sprite = entity.get_node("AnimatedSprite2D")
					if entity is Bird:
						animated_sprite.play("flying")
					elif entity is Cat:
						animated_sprite.play("running")
	numar_maxim_pasari=birds_spawn

func is_edge(column: int, row: int) -> bool:
	return column == 0 || row == 0 || column == column_count - 1 || row == row_count - 1

func play_blood_animation(column: int, row: int):
	var blood = blood_scene.instantiate()
	blood.position = Vector2(column * cell_width, row * cell_width)
	add_child(blood)
	var animated_sprite = blood.get_node("AnimatedSprite2D")
	if Global.sound_on:
		music.play()
	animated_sprite.play("death")  
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5 
	timer.one_shot = true
	timer.timeout.connect(func(): _on_blood_timeout(blood))
	timer.start()

func _on_blood_timeout(blood: Node):
	blood.queue_free() 

func move_cats():
	for column in range(column_count):
		for row in range(row_count):
			var entity = cell_matrix[column][row]
			if entity and entity is Cat:
				var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				if direction.length() > 0:
					var target_position = entity.position + direction * move_speed
					target_position.x = clamp(target_position.x, 0, column_count * cell_width)
					target_position.y = clamp(target_position.y, 0, row_count * cell_width)
					var animated_sprite = entity.get_node("AnimatedSprite2D")
					animated_sprite.play("running")
					if direction.x > 0:
						animated_sprite.scale.x = 1
					elif direction.x < 0:
						animated_sprite.scale.x = -1
					var tween = get_tree().create_tween()
					tween.tween_property(entity, "position", target_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					cell_matrix[column][row] = null
					var new_column = int(target_position.x / cell_width)
					var new_row = int(target_position.y / cell_width)
					if new_column < column_count and new_row < row_count:
						cell_matrix[new_column][new_row] = entity
						previous_cell_states[new_column][new_row] = true

func move_birds():
	for column in range(column_count):
		for row in range(row_count):
			var entity = cell_matrix[column][row]
			if entity and entity is Bird:
				var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				if direction.length() > 0:
					var target_position = entity.position + direction * move_speed
					target_position.x = clamp(target_position.x, 0, (column_count - 1) * cell_width)
					target_position.y = clamp(target_position.y, 0, (row_count - 1) * cell_width)
					var new_column = int(target_position.x / cell_width)
					var new_row = int(target_position.y / cell_width)
					if new_column < column_count and new_row < row_count and not cell_matrix[new_column][new_row]:
						var animated_sprite = entity.get_node("AnimatedSprite2D")
						animated_sprite.play("flying")
						if direction.x > 0:
							animated_sprite.scale.x = -1
						elif direction.x < 0:
							animated_sprite.scale.x = 1
						var tween = get_tree().create_tween()
						tween.tween_property(entity, "position", target_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
						cell_matrix[column][row] = null
						cell_matrix[new_column][new_row] = entity
						previous_cell_states[column][row] = false
						previous_cell_states[new_column][new_row] = true
=======
@export var bird_scene: PackedScene
@export var blood_scene: PackedScene
@export var line_edit: LineEdit

# Grid settings
var row_count: int = 95
var column_count: int = 140
var cell_width: int = 38
var cell_matrix: Array = []  
var previous_cell_states: Array = []  
var game_paused: bool = true  

var nr_birds_beginning: int = 30
var current_generation: int = 0
var generations: int = 0  

func _ready():
	line_edit = $LineEdit
	if line_edit:
		print("LineEdit node assigned successfully")
	else:
		print("LineEdit node is null. Check the node path.")
	line_edit.text_submitted.connect(_on_line_edit_text_submitted)

	initialize_grid()
	setup_timer()

func initialize_grid():
	var rng = RandomNumberGenerator.new()

	for column in range(column_count):
		cell_matrix.push_back([])
		previous_cell_states.push_back([])

		for row in range(row_count):
			var bird = bird_scene.instantiate()
			cell_matrix[column].push_back(bird)
			previous_cell_states[column].push_back(rng.randi_range(0, 1) == 1)

			add_child(bird)
			bird.position = Vector2(column * cell_width, row * cell_width)

			bird.visible = !previous_cell_states[column][row] && !is_edge(column, row)

			if bird.visible:
				var animated_sprite = bird.get_node("AnimatedSprite2D")
				animated_sprite.play("flying")

func setup_timer():
	var timer = Timer.new()
	timer.wait_time = 0.5 
	timer.autostart = true
	timer.timeout.connect(_on_Timer_timeout)
	add_child(timer)

func _on_line_edit_text_submitted(text: String):
	if text.is_valid_int():
		generations = text.to_int()
		print("Generations set to: ", generations)
		current_generation = 0
		game_paused = false  
	else:
		print("Invalid input. Please enter a valid number.")

func is_edge(column: int, row: int) -> bool:
	return row == 0 || column == 0 || row == row_count - 1 || column == column_count - 1

func _on_Timer_timeout():
	if game_paused:
		return

	if current_generation >= generations:
		print("Simulation stopped: Reached maximum generations (", generations, ")")
		game_paused = true
		line_edit.text = ""  
		return

	current_generation += 1
	print("Generation: ", current_generation)

	var next_state = calculate_next_state()

	update_grid(next_state)

func calculate_next_state() -> Array:
	var next_state = []
	for column in range(column_count):
		next_state.push_back([])
		for row in range(row_count):
			next_state[column].push_back(get_next_state(column, row))
	return next_state

func update_grid(next_state: Array):
	for column in range(column_count):
		for row in range(row_count):
			var bird = cell_matrix[column][row]
			if bird:
				var was_alive = previous_cell_states[column][row]
				var is_alive = next_state[column][row]

				bird.visible = is_alive
				previous_cell_states[column][row] = is_alive

				var animated_sprite = bird.get_node("AnimatedSprite2D")
				if is_alive:
					animated_sprite.play("flying")
				else:
					animated_sprite.stop()
					if was_alive && !is_alive:
						play_blood_animation(column, row)  # Play blood animation on death
						

func play_blood_animation(column: int, row: int):
	var blood = blood_scene.instantiate()
	add_child(blood)
	blood.position = Vector2(column * cell_width, row * cell_width)

	var blood_animation = blood.get_node("AnimatedSprite2D")
	blood_animation.play("death")

	blood_animation.connect("animation_finished", Callable(self, "_on_blood_animation_finished").bind(blood))

func _on_blood_animation_finished(blood):
	blood.visible = false
	blood.queue_free()
	blood.visible = false

func get_next_state(column: int, row: int) -> bool:
	var current = previous_cell_states[column][row]
	var neighbours_alive = get_count_of_alive_neighbours(column, row)

	if current:
		return neighbours_alive == 2 || neighbours_alive == 3
	else:
		return neighbours_alive == 3

func get_count_of_alive_neighbours(column: int, row: int) -> int:
	var count = 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			if !(x == 0 && y == 0):  
				var nx = column + x
				var ny = row + y
				if nx >= 0 && ny >= 0 && nx < column_count && ny < row_count:
					if previous_cell_states[nx][ny]:
						count += 1
	return count


func _on_blood_frame_changed(blood):
	var blood_animation = blood.get_node("AnimatedSprite2D")

	if blood_animation.frame == 18:
		blood_animation.visible = false  
>>>>>>> f8c9b3229bbe13fa4cc8a91dad77a2c49eb7d144
