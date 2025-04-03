extends Node3D
@onready var start_button = $CanvasLayer/Control/VBoxContainer/CenterContainer/VBoxContainer/NEWGAME
@onready var quit_button = $CanvasLayer/Control/VBoxContainer/CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.connect("pressed", Callable(self, "on_start_pressed"))
	quit_button.connect("pressed", Callable(self, "on_quit_pressed"))

func on_start_pressed():
	get_tree().change_scene_to_packed(load("res://game.tscn"))

func on_quit_pressed():
	get_tree().quit()
