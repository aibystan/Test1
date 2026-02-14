extends StaticBody2D

@export var icerik: ItemData 
var acik_mi = false
@onready var sprite = $Sprite2D

func etkilesime_gec():
	var diyalog_kutusu = get_tree().current_scene.find_child("DiyalogKutusu")
	if not diyalog_kutusu: return

	if acik_mi:
		diyalog_kutusu.baslat("Sandık", ["Bu sandık boş.", "Daha önce açmışsın."])
		return
	
	if icerik == null:
		diyalog_kutusu.baslat("Sandık", ["Sandık boş görünüyor..."])
		return
	
	# --- EKSİK OLAN KISIM GERİ GELDİ ---
	acik_mi = true
	Global.inventory.append(icerik) # Eşyayı ver
	sprite.modulate = Color(0.5, 0.5, 0.5) # Görseli karart
	
	# Mesajı göster
	diyalog_kutusu.baslat("Sandık", ["Sandığı açtın!", icerik.isim + " buldun!"])
