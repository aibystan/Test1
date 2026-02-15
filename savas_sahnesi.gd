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
	
	battle_ui.battle_manager = battle_manager
	
	# Test: 2 düşmanla savaş başlat
	test_savas_basla()

func test_savas_basla():
	var slime = load("res://enemy_slime.tres")
	var goblin = load("res://enemy_goblin.tres")
	
	if slime and goblin:
		battle_manager.savas_baslat([slime, goblin])
	else:
		print("HATA: Düşman dosyaları bulunamadı!")
		# Fallback - boş savaş
		var dummy_enemy = EnemyData.new()
		dummy_enemy.isim = "Test Düşman"
		dummy_enemy.max_hp = 30
		dummy_enemy.current_hp = 30
		dummy_enemy.atk = 5
		battle_manager.savas_baslat([dummy_enemy])
