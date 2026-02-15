extends StaticBody2D

func etkilesime_gec():
	# Kayıt menüsünü bul ve aç
	var kayit_menusu = get_tree().current_scene.find_child("KayitMenusu")
	
	if kayit_menusu:
		# Player'ı bul
		var player = get_tree().current_scene.find_child("Player")
		if player:
			# Menüyü aç (pozisyon ve sahne bilgisiyle)
			kayit_menusu.menuyu_ac(
				player.global_position,
				get_tree().current_scene.scene_file_path
			)
	else:
		# Kayıt menüsü yoksa eski sistem
		var player = get_tree().current_scene.find_child("Player")
		if player:
			Global.oyunu_kaydet(player.global_position, get_tree().current_scene.scene_file_path, 1)
		
		# Diyalog göster
		var diyalog_kutusu = get_tree().current_scene.find_child("DiyalogKutusu")
		if diyalog_kutusu:
			diyalog_kutusu.baslat("Kayıt Noktası", [
				"Oyun kaydedildi!",
				"HP'n tam oldu!"
			])
