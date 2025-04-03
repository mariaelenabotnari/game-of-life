extends Node2D

@onready var choice_1 = $choice/Control/HBoxContainer/MainButton
@onready var music_off = $choice/Control/HBoxContainer/Music_Button
@onready var music = $music
@onready var sound = $choice/Control/HBoxContainer/Music_Button2
@onready var decrise = $choice/Control/HBoxContainer2/ArrowLeft
@onready var incrise = $choice/Control/HBoxContainer2/ArrowRight
@onready var generation_status =$choice/Control/HBoxContainer2/TextEdit
@onready var confirma = $choice/Control/HBoxContainer3/Confirm
@onready var text_grid = $choice/Control/HBoxContainer4/TextEdit2
@onready var text_output = $choice/Control/PanelContainer/VBoxContainer/RichTextLabel

var last_output_data = "salut"

func _ready() -> void:
	generation_status.text = "       GENERATION: " + str(Global.generation_progres)
	text_grid.text = str(Global.grid_progres)
	
	if Global.music_on != 1 and Global.touched:
		Global.touched=false
		music_off.text = "MUSIC: ON "
		music.volume_db = -20
		music.play()
		var tween = get_tree().create_tween()  
		tween.tween_property(music, "volume_db", 0, 3)
	else:
		music_off.text = "MUSIC: OFF"
		
	choice_1.connect("pressed", Callable(self, "on_main"))
	music_off.connect("pressed",Callable(self, "off_on"))
	sound.connect("pressed",Callable(self,"off_sound"))
	decrise.connect("pressed",Callable(self,"descreste"))
	incrise.connect("pressed",Callable(self,"creste"))
	confirma.connect("pressed",Callable(self,"game_update"))
	
func  _process(delta: float) -> void:
	if last_output_data != Global.output_data:
		text_output.text += Global.output_data + "\n"
		last_output_data=Global.output_data
	
func creste():
	Global.generation_progres+=1
	generation_status.text = "       GENERATION: " + str(Global.generation_progres)
	
func descreste():
	if Global.generation_progres>1:
		Global.generation_progres += -1
	generation_status.text = "       GENERATION: " + str(Global.generation_progres)
	
func off_sound():
	if Global.sound_on:
		sound.text="SOUND: OFF"
		Global.sound_on = 0
	else:
		Global.sound_on = 1
		sound.text="SOUND: ON "

func game_update():
	Global.max_cats_can = randi_range(5, 10) 
	Global.max_birds_can= randi_range(200,400) 
	Global.grid_progres = int(text_grid.text)
	get_tree().change_scene_to_packed(load("res://game.tscn"))
	
func on_main():
	get_tree().change_scene_to_packed(load("res://MainMenu.tscn"))

func off_on():
	if Global.music_on != 1:
		music.stop()
		music_off.text = "MUSIC: OFF"
		Global.music_on = 1
	else:
		Global.touched=true
		Global.music_on = 0
		music_off.text = "MUSIC: ON "
		music.volume_db = -20 
		music.play()
		var tween = get_tree().create_tween()  
		tween.tween_property(music, "volume_db", 0, 3)
