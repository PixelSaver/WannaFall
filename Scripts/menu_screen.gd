extends Panel
class_name MenuScreen

@export var fade_out_duration := 0.2

@onready var main_scene : PackedScene = preload("res://Scenes/world.tscn")


func _ready() -> void:
	show()
	get_tree()
	#start.grab_focus()


# Menu Buttons
func _on_menu_continue_pressed() -> void:
	# TODO Add the begininning cutscene and stuff
	get_tree().paused = false
	close()
	await get_tree().create_timer(0.5).timeout
	
	get_tree().change_scene_to_packed(main_scene)
func _on_menu_options_pressed() -> void:
	#option_show()
	pass
func _on_menu_quit_pressed() -> void:
	get_tree().quit()
func menu_show():
	pass

func close() -> void:
	var tween := create_tween()
	get_tree().paused = false
	tween.tween_property(
		self,
		^"modulate:a",
		0.0,
		fade_out_duration
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		self,
		^"anchor_right",
		0.5,
		fade_out_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		self,
		^"anchor_left",
		-0.5,
		fade_out_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(hide)
	return
	
func _on_quit_button_pressed() -> void:
	if visible:
		get_tree().quit()
