extends Node

var player={
	"name":"Pombo",
	"gold":300,
	"hp":10,"maxHp":10,
	"energy":10,"maxEnergy":10,
	"pointsLeft":3,
	"strength":1,
	"defense":1,
	"speed":1
}

var shopDescription
var opponents=preload("res://scenes/opponentPanel.tscn")

func _ready():set_process(true)
func _process(delta):
	OS.set_window_title("Pigeon Ascent -- " + String(Engine.get_frames_per_second()) + "FPS")
func fight():
	print("hei")
	get_tree().root.add_child(opponents.instance())