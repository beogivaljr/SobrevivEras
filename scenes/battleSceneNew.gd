extends Control
var playerStamina:=0.0;var enemyStamina:=0.0
var playerSpr:=Sprite.new();var enemySpr:=Sprite.new()
var playerDefaultPos;var enemyDefaultPos
var playerAttacking:=false;var enemyAttacking:=false
var playerAttacked:=false;var enemyAttacked:=false
const durationAttack:=0.7
const durationReturn:=0.3
const durationRecoil:=1
const defaultDurationShake:=0.5
const hungryStaminaScaling:=1.1#0.75
var durationShake:=0.5
var turn:=1
var fighting:=true
var ended:=false
var iPlayerHpLoss:=-2
var iEnemyHpLoss:=-2
var goldToWin:=0
var offset:=0
var arenaFiles:=[
	"res://resource/Arena_Sand.png",
	"res://resource/Arena_Grass.png",
	"res://resource/Arena_Godfight.png"
]

const particlesImpactGPU:=preload("res://scenes/polish/particlesImpactGPU.tscn")
const particlesImpact:=preload("res://scenes/polish/particlesImpact.tscn")
const hitSfx:=preload("res://scenes/polish/hitSfx.tscn")
const damageNumbers:=preload("res://scenes/polish/damageNumbers.tscn")
const pigeonRectOffset:=Vector2(0,30)
onready var exitButton:=$marginCtn/battlePanel/ctnButtons/vBoxContainer/btnGoBack
onready var resetButton:=$marginCtn/battlePanel/ctnButtons/vBoxContainer/btnReset
onready var battleLogText:=$marginCtn/battlePanel/battlePanelMargin/hboxCtn/battleLog/battleLog/marginContainer/scrollContainer/marginContainer/richLabelBattleLog
onready var bgNode:=get_node("marginCtn/battlePanel/battlePanelMargin/BG")
onready var nPlayerStatBox:=$marginCtn/battlePanel/battlePanelMargin/hboxCtn/battleArea/battleArea/playerCtn/stats
onready var nEnemyStatBox:=$marginCtn/battlePanel/battlePanelMargin/hboxCtn/battleArea/battleArea/enemyCtn/stats#$marginCtn/battlePanel/battlePanelMargin/hboxCtn/battleArea/battleArea/enemyCtn/enemyStats

func calculateStaminaIncrement(x,isHungry=false):
	var staminaScaling=hungryStaminaScaling if isHungry else 1.0
	var externalScaling=1.0
	return externalScaling*(3.79643 + (0.9834812 - 3.79643)/(1 + pow((x/22.7243),1.642935))*staminaScaling)
func changeBgTexture():
	if global.level in [1,2,3,4]:bgNode.texture=load(arenaFiles[0])
	elif global.level in [5,6,7,8,9]:bgNode.texture=load(arenaFiles[1])
	elif global.level in [10]:
		bgNode.texture=load(arenaFiles[2])
		enemySpr.get_node('pigeon').scale.x=-1
		
func fadeInBgDarken():
	$colorRect.modulate.a=0
	$twnColorRectTransparency.interpolate_property($colorRect,"modulate:a",0,0.85,0.6,Tween.TRANS_CUBIC,Tween.EASE_IN_OUT)
	$twnColorRectTransparency.start()
	
func _ready():
	randomize()
	changeBgTexture()
	fadeInBgDarken()
	var pos=$marginCtn.rect_global_position
	$marginCtn.rect_global_position.y=-$marginCtn.rect_size.y
	$twnSelfPos.interpolate_property($marginCtn,"rect_global_position:y",-$marginCtn.rect_size.y,pos.y,0.4,Tween.TRANS_QUINT,Tween.EASE_OUT)
	$twnSelfPos.start()
	var _s1=$twnPlayer.connect("tween_all_completed",self,'checkPlayerTween')
	var _s2=$twnEnemy.connect("tween_all_completed",self,'checkEnemyTween')
	goldToWin=global.enemy.gold
	set_process(true)

func checkPlayerTween():
	if playerSpr.global_position!=playerDefaultPos:
		$twnPlayer.stop_all()
		$twnPlayer.interpolate_property(playerSpr,"global_position",playerSpr.global_position,playerDefaultPos,durationRecoil*rand_range(1.2,1.6),Tween.TRANS_BACK,Tween.EASE_IN_OUT)
		$twnPlayer.start()
func checkEnemyTween():
	if enemySpr.global_position!=enemyDefaultPos:
		$twnEnemy.stop_all()
		$twnEnemy.interpolate_property(enemySpr,"global_position",enemySpr.global_position,enemyDefaultPos,durationRecoil*rand_range(1.2,1.6),Tween.TRANS_BACK,Tween.EASE_IN_OUT)
		$twnEnemy.start()

func _process(delta):
	global.player.energy=clamp(global.player.energy,0,global.player.maxEnergy)
	global.enemy.energy=clamp(global.enemy.energy,0,global.enemy.maxEnergy)
	if self.offset!=0:
		self.rect_position=offset*Vector2(randf(),randf())
	if fighting:
		var fTargetScalePlayer = 1 if playerSpr.global_position.x<enemySpr.global_position.x else -1
		playerSpr.scale.x = lerp(playerSpr.scale.x,fTargetScalePlayer,0.2)
		playerStamina+=calculateStaminaIncrement(global.player.speed+global.player.extraSpeed,global.player.energy<=0)*delta*global.scaling.speed
		if playerStamina>100:
			playerStamina=0
			global.player.energy-=global.level
			global.player.energy=clamp(global.player.energy,0,global.player.maxEnergy)
			playerAttacked=true
			playerAttackAnim()
		enemyStamina+=calculateStaminaIncrement(global.enemy.speed,global.enemy.energy<=0)*delta*global.scaling.speed
		var fTargetScaleEnemy = -1 if playerSpr.global_position.x>enemySpr.global_position.x else 1
		enemySpr.scale.x = lerp(enemySpr.scale.x,fTargetScaleEnemy,0.2)
		if enemyStamina>100:
			enemyStamina=0
			global.enemy.energy-=global.level
			global.enemy.energy=clamp(global.enemy.energy,0,global.enemy.maxEnergy)
			enemyAttacked=true
			enemyAttackAnim()
	else:
		if not ended:
			if global.player.hp>0:
				global.player.gold+=goldToWin
				global.incrementLevel()
				global.player.pointsLeft+=3
				registerSameTurn(false, "")
				registerSameTurn(false, "[center][wave amp=100 freq=5]\n"+global.player.name + " sobreviveu! [/wave][/center]\n")
				registerSameTurn(false, "")
				registerSameTurn(false, "[center]Sua cidade acumulou [color=#ffe478][u]" + String(goldToWin) + "[/u][/color] de ouro.[/center]")#
				ended=true
				exitButton.modulate.a=0
				exitButton.visible=true
				resetButton.visible=false
			else:
				global.fadeMusicAway()
				registerSameTurn(false, "[center][shake rate=15 level=10]\n"+global.enemy.name + " destruiu sua cidade... [/shake][/center]\n")
				registerSameTurn(false, "[center][color=#b0305c]" + "Fim de jogo." + "[/color][/center]\n\n")
				registerSameTurn(false, "[center] Tentar novamente? [/center]")
				ended=true
				resetButton.modulate.a=0
				resetButton.visible=true
				exitButton.visible=false
		else:
			exitButton.modulate.a=1
			resetButton.modulate.a=1

func attack(myself=global.player,target=global.enemy,_sprMyself=playerSpr,sprTarget=enemySpr):
	var is_city = myself.name == global.player.name
	var block=(1-(global.scaling.defenseBlock*target.defense/global.limits.defense)) # Is a value between 0.5 and 1
	var damage=calculateDamage(myself.strength+myself.extraStrength,target.defense)
	damage=max(ceil(damage*block),1)
	var strOrigin='Player' if myself==global.player else 'Enemy'
	var foodDamage=ceil(max(0,myself.speed+myself.extraSpeed-target.speed)*global.scaling.foodDamage)
	var bbName=myself.name
	var isCritical=false
	var canCritical=true
	var damageModifier=1
	var criticalChance=0.1
	var doubleStrike=false
	var dodged=false
	
	# Attack bonuses
	if myself.class==global.Classes.Stronga:damageModifier*=1.25
	elif myself.class==global.Classes.Whey:damageModifier*=1.5
	elif myself.class==global.Classes.Wyrm:
		damageModifier*=1.1
		doubleStrike=true
		canCritical=false
	elif myself.class==global.Classes.Hatoshi:doubleStrike=true
	elif myself.class==global.Classes.Platy:
		damageModifier*=1.1
	elif myself.class==global.Classes.GodPigeon:
		doubleStrike=true
		damageModifier*=1.05
		
	# Defense bonuses
	if target.class==global.Classes.Normal:canCritical=false
	elif target.class==global.Classes.Fridgeon:myself['extraSpeed']=-myself['speed']*0.33
	elif target.class==global.Classes.Crusader:
		damageModifier*=0.66
		canCritical=false
	elif target.class==global.Classes.Knight:damageModifier*=0.75
	elif target.class==global.Classes.Winged:
		dodged=randf()<0.2
	elif target.class==global.Classes.Winged2:
		dodged=randf()<0.4
	elif target.class==global.Classes.Platy:
		damageModifier*=0.9
	elif target.class==global.Classes.GodPigeon:
		damageModifier*=0.85
	#damage=int(ceil(damage))
	damage*=damageModifier*(1.0 if myself.energy>0 else 0.5)
	var bIsCritical=(randf()<criticalChance or target.energy<=0) and canCritical
	
	# Check for damage every turn
	var iMyselfHpLoss:=0
	if myself.energy<=0:
		if strOrigin=="Player":
			self.iPlayerHpLoss+=1
			iMyselfHpLoss=self.iPlayerHpLoss
		elif strOrigin=="Enemy":
			self.iEnemyHpLoss+=1
			iMyselfHpLoss=self.iEnemyHpLoss
	if iMyselfHpLoss>=1:
		registerSameTurn(is_city, "\n\nMorreram " + str(iMyselfHpLoss) + " habitantes por fome extrema...", Color.yellow)
		myself.hp-=int(iMyselfHpLoss)
		if myself.hp<=0:
			exitButton.rect_global_position.y=OS.window_size.y*1.2
			fighting=false
			myself.dead=true
			return
	
	# Finally, attack stuff
	if dodged:
		createDamageNumbers(enemySpr.global_position,1,"Miss", is_city, false,strOrigin)
		register(is_city, bbName + " não causou nenhum dano!")
	else:
		if bIsCritical:
			damage = max(int(2*damage),1)
			registerFast(is_city, "[shake rate=20 level=10]ATAQUE CRÍTICO![/shake]", Color.green if strOrigin=="Player" else Color.red)
			if foodDamage>0:
				registerSameTurnNoLineBreak(is_city, bbName + " matou " +String(damage)+ "mil habitantes")
				registerSameTurn(is_city, "e destruiu " +String(foodDamage)+ "Ton de comida")
				if not is_city:
					turn+=1
			else:
				registerSameTurn(is_city, bbName + " matou " +String(damage)+ "mil habitantes")
				if not is_city:
					turn+=1
			shakeHpBar(strOrigin)
			sprTarget.hit()
		else:
			#damage*=1.0 if myself.energy>0 else 0.5
			#damage = int(max(damage*damageModifier,1))
			damage = max(int(damage),1)
			register(is_city, bbName + " matou " +String(damage)+ "mil habitantes")
			if foodDamage>0:registerSameTurnNoLineBreak(is_city, "e destruiu " +String(foodDamage)+ "Ton de comida")
			shakeHpBar(strOrigin)
			sprTarget.hit()
			
		if doubleStrike:
			target.hp-=int(damage*0.66)
			createDamageNumbers(sprTarget.global_position+Vector2(16,-16),1,damage/2, is_city, isCritical,strOrigin)
			registerSameTurn(is_city, "e também matou mais "+str(int(damage/2))+"mil habitantes!")
		target.hp-=int(damage)
		target.energy-=int(foodDamage)
		createDamageNumbers(sprTarget.global_position, 1 if strOrigin=='Player' else -1, damage, is_city, isCritical,strOrigin)
		if target.hp<=0:
			exitButton.rect_global_position.y=OS.window_size.y*1.2
			fighting=false
			sprTarget.dead=true
			if strOrigin=='Player':
				$twnEnemy.stop_all()
			if strOrigin=='Enemy':
				$twnPlayer.stop_all()
			return

# Messages
func register(is_city, string,color:=Color.white):
	if is_city:
		return
	var message= "\n\n#"+String(turn)+"> " + "[color=#" + color.to_html(false) + "]"+string+"[/color]"
	battleLogText.appendMessage(message)
	turn+=1

func registerFast(is_city, string,color:=Color.white):
	if is_city:
		return
	var message="\n\n#"+String(turn)+"> "+"[color=#" + color.to_html(false) + "]"+string+"[/color]"
	battleLogText.appendMessage(message)

func registerWithoutLineEnd(is_city, string,color:=Color.white):
	if is_city:
		return
	var message="\n\n#"+String(turn)+"> "+"[color=#" + color.to_html(false) + "]"+string+"[/color]"
	battleLogText.appendMessage(message)

func registerSameTurn(is_city, string,color:=Color.white):
	if is_city:
		return
	var message= " [color=#" + color.to_html(false) + "]"+string+"[/color]"
	battleLogText.appendMessage(message)
	
func registerSameTurnNoLineBreak(is_city, string,color:=Color.white):
	if is_city:
		return
	var message= " [color=#" + color.to_html(false) + "]"+string+"[/color]"
	battleLogText.appendMessage(message)

# Anims, effects, etc
func playerAttackAnim():
	if not playerAttacking:
		playerAttacking=true
		var localDurationAttack=durationAttack*(1+global.player.speed/30)
		var isAtEnemy=abs(playerSpr.global_position.x - enemyDefaultPos.x)<5
		var targetPosition=enemyDefaultPos if not isAtEnemy else playerDefaultPos#enemyDefaultPos if not isAtEnemy else playerDefaultPos
		$twnPlayer.stop_all()
		$twnPlayer.interpolate_property(playerSpr,"global_position",playerSpr.global_position,targetPosition,localDurationAttack,Tween.TRANS_BACK,Tween.EASE_IN)
		$twnPlayer.start()
	else:
		var isAtEnemy=abs(playerSpr.global_position.x - enemyDefaultPos.x)<5
		if isAtEnemy:
			playerAttacking=false
			var localDurationAttack=durationAttack*(1+global.player.speed/30)
			var targetPosition=playerDefaultPos#enemyDefaultPos if not isAtEnemy else playerDefaultPos
			$twnPlayer.stop_all()
			$twnPlayer.interpolate_property(playerSpr,"global_position",playerSpr.global_position,targetPosition,localDurationAttack,Tween.TRANS_BACK,Tween.EASE_IN)
			$twnPlayer.start()
func enemyAttackAnim():
	if not enemyAttacking:
		enemyAttacking=true
		var localDurationAttack=durationAttack*(1+global.enemy.speed/30)
		var isAtPlayer=abs(enemySpr.global_position.x - playerDefaultPos.x)<5
		var targetPosition=playerDefaultPos if not isAtPlayer else enemyDefaultPos
		$twnEnemy.stop_all()
		$twnEnemy.interpolate_property(enemySpr,"global_position",enemySpr.global_position,targetPosition,localDurationAttack,Tween.TRANS_BACK,Tween.EASE_IN)
		$twnEnemy.start()
	else:
		var isAtPlayer=abs(enemySpr.global_position.x - playerDefaultPos.x)<5
		if isAtPlayer:
			enemyAttacking=false
			var localDurationAttack=durationAttack*(1+global.enemy.speed/30)
			var targetPosition=enemyDefaultPos
			$twnEnemy.stop_all()
			$twnEnemy.interpolate_property(enemySpr,"global_position",enemySpr.global_position,targetPosition,localDurationAttack,Tween.TRANS_BACK,Tween.EASE_IN)
			$twnEnemy.start()
			
func shakeHpBar(origin='Player'):
	print_debug(origin)
	if origin=='Player':shakeEnemyHpBar(25)
	else:shakePlayerHpBar(25)
func exitBattle():
	self.set_process(false)
	if global.level==11:
		var _sc1=get_tree().change_scene("res://scenes/end.tscn")
	global.player.extraStrength=0
	global.player.extraDefense=0
	global.player.extraSpeed=0
	self.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if not global.bHasItem:
		if(global.level==4):
			global.createEvolvePanel()
		elif(global.level==7):
			global.createEvolvePanel()
	var _s1=$twnSelfPos.connect("tween_completed",self,"killMe")
	$twnSelfPos.interpolate_property($marginCtn,"rect_global_position:y",$marginCtn.rect_global_position.y,-$marginCtn.rect_size.y,0.4,Tween.TRANS_QUINT,Tween.EASE_OUT)
	$twnSelfPos.start()
	$twnColorRectTransparency.interpolate_property($colorRect,"modulate:a",0.85,0,0.3,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	$twnColorRectTransparency.start()
func applyDamage(target,damage):target.hp-=damage
func killMe(_h,_m):self.queue_free()
func createDamageNumbers(position,direction,damage, is_city: bool,critical=false,origin=""):
	if is_city:
		return
	var i=damageNumbers.instance()
	i.global_position=position
	i.direction=direction
	i.damage=damage
	i.critical=critical
	i.origin=origin
	add_child(i)
func effects(area):
	particlesAndWindowshake(area)
	knockback()
func knockback():
	if playerAttacked:
		attack(global.player,global.enemy,playerSpr,enemySpr)
		playerAttacked=false
		playerAttacking=false
	elif enemyAttacked:
		attack(global.enemy,global.player,enemySpr,playerSpr)
		enemyAttacked=false
		enemyAttacking=false
	#randomize()
	playerSpr.global_position.y*=rand_range(0.8,1.2)
	enemySpr.global_position.y*=rand_range(0.8,1.2)
	$twnPlayer.stop_all()
	$twnPlayer.interpolate_property(playerSpr,"global_position",playerSpr.global_position*Vector2(rand_range(0.9,1.1),rand_range(0.9,1.1)),playerDefaultPos,durationRecoil*rand_range(0.8,1.2),Tween.TRANS_BACK,Tween.EASE_OUT)
	$twnPlayer.start()
	$twnEnemy.stop_all()
	$twnEnemy.interpolate_property(enemySpr,"global_position",enemySpr.global_position*Vector2(rand_range(0.9,1.1),rand_range(0.9,1.1)),enemyDefaultPos,durationRecoil*rand_range(0.8,1.2),Tween.TRANS_BACK,Tween.EASE_OUT)
	$twnEnemy.start()
func particlesAndWindowshake(area):
	createHitSfx()
	particles(area)
#	windowShake(16)
func createHitSfx():self.add_child(hitSfx.instance())
func particles(_area:Area2D):
	var i=particlesImpact.instance()
	i.global_position=_area.global_position
	#i.global_position=0.5*(playerSpr.get_node("area2D").global_position+enemySpr.get_node("area2D").global_position)
	i.emitting=true
	add_child(i)
func windowShake(newOffset=32):
	self.offset=newOffset*(-1 if randf()<0.5 else 1)
	self.durationShake=self.defaultDurationShake*rand_range(0.7,1.0)
	$twnShake.interpolate_property(self,"offset",self.offset,0,self.durationShake,Tween.TRANS_QUAD,Tween.EASE_OUT)
	$twnShake.start()
func calculateDamage(strength,defense,minDamage=1):return int(max(rand_range(1.0,1.2)*strength*global.scaling.strength-defense*global.scaling.defense,minDamage))
func colorizeString(string,color="#ffffff"):return "[color="+color+"]"+String(string)+"[/color]"
func shakePlayerHpBar(_intensity=5):self.nPlayerStatBox.shakeHp()
func shakeEnemyHpBar(_intensity=5):self.nEnemyStatBox.shakeHp()
func gameOver():
	global.level=1
	var _sc1=get_tree().change_scene("res://scenes/intro.tscn")
	self.queue_free()
