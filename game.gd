extends Node2D

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
