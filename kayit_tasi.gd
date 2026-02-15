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
	
	# ÖNEMLİ: Diyalog döndürme! Kayıt menüsü açılacak, diyalog değil.
	# Boş return veya hiç return olmamalı
