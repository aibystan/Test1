extends StaticBody2D

@export var sandik_ismi: String = "Sandık"
@export var icerik: ItemData 
var acik_mi = false
@onready var sprite = $Sprite2D

func etkilesime_gec():
	var diyalog_kutusu = get_tree().current_scene.find_child("DiyalogKutusu")
	if not diyalog_kutusu: return

	if acik_mi:
		diyalog_kutusu.baslat(sandik_ismi, ["Bu sandık boş.", "Daha önce açmışsın."])
		return
	
	if icerik == null:
		diyalog_kutusu.baslat(sandik_ismi, ["Sandık boş görünüyor..."])
		return
	
	# --- ENVANTER KAPASİTE KONTROLÜ ---
	if Global.envanter_dolu_mu():
		diyalog_kutusu.baslat(sandik_ismi, [
			"Sandıkta " + icerik.isim + " var!",
			"Ama çantan dolu... Yer açmalısın!"
		])
		return
	
	# --- EŞYAYı VER ---
	acik_mi = true
	Global.envantere_ekle(icerik)  # Yeni fonksiyonu kullan
	sprite.modulate = Color(0.5, 0.5, 0.5) # Görseli karart
	
	# Mesajı göster
	diyalog_kutusu.baslat(sandik_ismi, ["Sandığı açtın!", icerik.isim + " buldun!"])
