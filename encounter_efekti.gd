extends CanvasLayer

@onready var ust = $Ust
@onready var alt = $Alt
@onready var sol = $Sol
@onready var sag = $Sag
@onready var flash = $Flash

func _ready():
	visible = false

func oynat(hedef_sahne: String):
	visible = true
	
	var W = 640.0
	var H = 360.0
	
	# Başlangıç konumları
	ust.size = Vector2(W, 0)
	ust.position = Vector2(0, 0)
	
	alt.size = Vector2(W, 0)
	alt.position = Vector2(0, H)
	
	sol.size = Vector2(0, H)
	sol.position = Vector2(0, 0)
	
	sag.size = Vector2(0, H)
	sag.position = Vector2(W, 0)
	
	flash.modulate.a = 0.0
	
	# --- FAZ 1: Çizgiler merkeze kapanır ---
	var yarih = H / 2.0
	var yariw = W / 2.0
	var sure = 0.20
	var ease_in = Tween.EASE_IN
	var trans = Tween.TRANS_QUART
	
	var tw = create_tween().set_parallel(true)
	# Üst aşağı büyür
	tw.tween_property(ust, "size:y", yarih, sure).set_trans(trans).set_ease(ease_in)
	# Alt yukarı büyür (pozisyonu yukarı kayar)
	tw.tween_property(alt, "size:y", yarih, sure).set_trans(trans).set_ease(ease_in)
	tw.tween_property(alt, "position:y", H - yarih, sure).set_trans(trans).set_ease(ease_in)
	# Sol sağa büyür
	tw.tween_property(sol, "size:x", yariw, sure).set_trans(trans).set_ease(ease_in)
	# Sağ sola büyür (pozisyonu sola kayar)
	tw.tween_property(sag, "size:x", yariw, sure).set_trans(trans).set_ease(ease_in)
	tw.tween_property(sag, "position:x", W - yariw, sure).set_trans(trans).set_ease(ease_in)
	await tw.finished
	
	# --- FAZ 2: Flash ---
	var tw2 = create_tween()
	tw2.tween_property(flash, "modulate:a", 1.0, 0.06)
	await tw2.finished
	
	# --- Sahne değiştir ---
	get_tree().change_scene_to_file(hedef_sahne)
