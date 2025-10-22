extends StaticBody3D
## Class that describes the hold on the wall
class_name Hold

enum Click {
	LEFT,
	RIGHT,
	NONE,
}

var click_held : Click
