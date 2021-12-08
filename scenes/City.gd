extends Sprite

func _ready():
	texture = load(global.pigeonDict[global.player.class].sprite)
