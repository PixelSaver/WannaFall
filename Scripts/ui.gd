extends CanvasLayer

@export_category("Crosshair")
@export var crosshair_left : TextureRect
@export var crosshair_right : TextureRect
@onready var player : Player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	player.connect("can_grab", _on_player_can_grab)

func _on_player_can_grab(hold_crosshair:Hold, l_hold:Hold, r_hold:Hold):
	if hold_crosshair:
		crosshair_left.modulate = Color.PALE_GREEN
		crosshair_right.modulate = Color.PALE_GREEN
	else:
		crosshair_left.modulate = Color.WHITE
		crosshair_right.modulate = Color.WHITE
		
	if l_hold:
		crosshair_left.modulate = Color.CORAL
	if r_hold:
		crosshair_right.modulate = Color.CORAL
