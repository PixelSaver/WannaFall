extends CanvasLayer

@export_category("Crosshair")
@export var crosshair_left : TextureRect
@export var crosshair_right : TextureRect
@onready var player : Player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	player.connect("stamina_changed", _on_stamina_changed)

func _on_stamina_changed(l_color:Color, r_color:Color):
	#print("left: %s\nright: %s" % [l_color, r_color])
	crosshair_left.modulate = l_color
	crosshair_right.modulate = r_color
