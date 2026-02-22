extends Node2D

@onready var battle_manager = $BattleManager
@onready var battle_ui = $BattleUI
@onready var timing_bar = $TimingBar
@onready var grid_node = $GridKonumlari
@onready var player_node = $SavasOyuncusu

func _ready():
	# Referansları bağla
	battle_manager.battle_ui = battle_ui
	battle_manager.timing_bar = timing_bar
	battle_manager.grid_node = grid_node
	battle_manager.player_node = player_node
	
	# MessageBox'ı UIArkaplan'dan al
	var ui_arkaplan = get_node_or_null("UIArkaplan")
	if ui_arkaplan and ui_arkaplan.has_node("MessageBox"):
		battle_manager.message_box = ui_arkaplan.get_node("MessageBox")
	
	battle_ui.battle_manager = battle_manager
	
	# Global'den düşman listesini al
	if Global.has_meta("battle_enemies"):
		var dusman_listesi = Global.get_meta("battle_enemies")
		Global.remove_meta("battle_enemies")  # Temizle
		battle_manager.savas_baslat(dusman_listesi)
	else:
		# Fallback - test savaşı
		print("UYARI: Global'de düşman listesi yok, test savaşı başlatılıyor")
		test_savas_basla()

func test_savas_basla():
	var slime = load("res://Enemies/enemy_slime.tres")
	var goblin = load("res://Enemies/enemy_goblin.tres")
	
	if slime and goblin:
		battle_manager.savas_baslat([slime, goblin])
	else:
		print("HATA: Düşman dosyaları bulunamadı!")
		var dummy_enemy = EnemyData.new()
		dummy_enemy.isim = "Test Düşman"
		dummy_enemy.max_hp = 30
		dummy_enemy.current_hp = 30
		dummy_enemy.atk = 5
		battle_manager.savas_baslat([dummy_enemy])
