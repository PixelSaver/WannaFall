extends Control

func _ready() -> void:
	get_tree().paused = true

func go_world():
	
	var t = create_tween().set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT).set_parallel(true)
	t.tween_property(self, "modulate:a", 0, 0.5)
	t.tween_property(self, "position:y", 300, 0.5)
	
	await t.finished
	get_tree().paused = false
	queue_free()
