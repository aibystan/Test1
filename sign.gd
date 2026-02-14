extends StaticBody2D

# İster tek cümle yaz, ister editörden cümleleri çoğalt
@export var isim = "Eski Tabela"
@export_multiline var yazi_listesi: Array[String] = [
	"Buralar eskiden hep dutluktu...",
	"Sonra sanayileşme başladı."
]

func etkilesime_gec():
	# 1. Ana sahnedeki Diyalog Kutusunu bul
	var diyalog_kutusu = get_tree().current_scene.find_child("DiyalogKutusu")
	
	if diyalog_kutusu:
		# 2. Kutuyu başlat (İsim ve Yazı Listesi gönder)
		diyalog_kutusu.baslat(isim, yazi_listesi)
	else:
		print("HATA: DiyalogKutusu bulunamadı!")
