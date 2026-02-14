extends StaticBody2D

# Tabeladaki gibi etkileşime girince çalışacak fonksiyon
func etkilesime_gec():
	# 1. Player'ı bul
	# (Sahnedeki "Player" isimli düğümü arıyoruz)
	var player = get_tree().current_scene.find_child("Player")
	
	if player:
		# 2. Global'e "Bizi kaydet" emri ver
		Global.oyunu_kaydet(player.global_position, get_tree().current_scene.scene_file_path)
		
		# 3. Diyalog kutusunda mesaj göster
		return ["Oyun başarıyla kaydedildi.", "Artık güvendesin..."]
	else:
		return ["Hata: Oyuncu bulunamadı!"]
