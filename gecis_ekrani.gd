extends CanvasLayer

# Diğerlerinin okuyabileceği bir "Meşgul" değişkeni
var gecis_yapiliyor = false 

func sahne_degistir(hedef_dosya_yolu):
	gecis_yapiliyor = true # 1. KİLİDİ VUR 🔒
	
	$AnimationPlayer.play("karar")
	await $AnimationPlayer.animation_finished
	
	get_tree().change_scene_to_file(hedef_dosya_yolu)
	
	$AnimationPlayer.play("acil")
	await $AnimationPlayer.animation_finished
	
	gecis_yapiliyor = false # 2. KİLİDİ AÇ 🔓
