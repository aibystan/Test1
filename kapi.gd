extends Area2D

@export_file("*.tscn") var gidilecek_sahne
# Yeni Değişken: Diğer tarafta hangi isimli noktada doğacağız?
@export var hedef_spawn_ismi: String = "" 

func _on_body_entered(body):
	if body.name == "Player":
		if gidilecek_sahne:
			# Işınlanma bilgisini kaydet (Burası aynı)
			Global.gidilecek_kapi_ismi = hedef_spawn_ismi
			
			# --- ESKİ KODU SİL: ---
			# get_tree().change_scene_to_file(gidilecek_sahne)
			
			# --- YENİ KOD: ---
			# Bizim yazdığımız sinematik geçişi çağır:
			Gecis.sahne_degistir(gidilecek_sahne)
			
		else:
			print("HATA: Gidilecek sahne seçilmedi!")
