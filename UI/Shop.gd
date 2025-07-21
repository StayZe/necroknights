extends CanvasLayer

@onready var shop_ui = $ShopUI
var is_shop_open = false

# Références aux éléments de l'interface
@onready var coins_label = $ShopUI/CoinsLabel
var close_button  # Sera initialisé dans _ready() avec get_node_or_null

# Références aux boutons du shop
@onready var atomic_bomb_button = $ShopUI/AtomicBombButton
@onready var medical_kit_button = $ShopUI/MedicalKitButton
@onready var skull_button = $ShopUI/SkullButton
@onready var speed_boost_button = $ShopUI/SpeedBoostButton
@onready var pistol_button = $ShopUI/PistolButton
@onready var rifle_button = $ShopUI/RifleButton
@onready var sniper_button = $ShopUI/SniperButton
@onready var shield_button1 = $ShopUI/ShieldButton1
@onready var shield_button2 = $ShopUI/ShieldButton2

# Prix des éléments
var item_prices = {
	"atomic_bomb": 200,
	"medical_kit": 75,
	"skull": 150,
	"speed_boost": 100,
	"pistol": 50,
	"rifle": 250,
	"sniper": 500,
	"shield_small": 250,
	"shield_large": 500
}

func _ready():
	# Cacher le shop au démarrage
	visible = false
	
	# DONNER LA PLUS HAUTE PRIORITÉ au shop
	layer = 999  # Layer très élevé pour être au-dessus de tout
	process_mode = Node.PROCESS_MODE_ALWAYS  # Toujours traiter les événements
	
	# Initialiser le bouton de fermeture
	close_button = get_node_or_null("ShopUI/CloseButton")
	if close_button:
		close_button.pressed.connect(close_shop)
	else:
		print("🏪 Aucun bouton de fermeture trouvé dans le shop")
	
	# Connecter tous les boutons du shop
	connect_shop_buttons()
	
	# Mettre à jour l'affichage des pièces
	if GameManager:
		GameManager.coins_changed.connect(_on_coins_changed)
		_on_coins_changed(GameManager.get_coins())
	
	# Debug : Vérifier que le shop est prêt
	print("🏪 Shop initialisé et prêt - process_mode: ", process_mode)
	print("🏪 Shop dans l'arbre: ", is_inside_tree())
	print("🏪 Test: Appuyez sur B pour ouvrir le shop")

func connect_shop_buttons():
	# Connecter tous les boutons d'achat
	if atomic_bomb_button:
		atomic_bomb_button.pressed.connect(func(): buy_item("atomic_bomb"))
	if medical_kit_button:
		medical_kit_button.pressed.connect(func(): buy_item("medical_kit"))
	if skull_button:
		skull_button.pressed.connect(func(): buy_item("skull"))
	if speed_boost_button:
		speed_boost_button.pressed.connect(func(): buy_item("speed_boost"))
	if pistol_button:
		pistol_button.pressed.connect(func(): buy_weapon("pistol"))
	if rifle_button:
		rifle_button.pressed.connect(func(): buy_weapon("rifle"))
	if sniper_button:
		sniper_button.pressed.connect(func(): buy_weapon("sniper"))
	if shield_button1:
		shield_button1.pressed.connect(func(): buy_item("shield_small"))
	if shield_button2:
		shield_button2.pressed.connect(func(): buy_item("shield_large"))

# Utiliser _input au lieu de _unhandled_input pour avoir la priorité
func _input(event):
	# Seule la touche B ouvre le shop
	if event is InputEventKey and event.pressed:
		if event.keycode == 66 or event.physical_keycode == 66:  # B
			print("🏪 Touche B détectée - Ouverture du shop")
			get_viewport().set_input_as_handled()
			toggle_shop()
			return
	
	# Fermeture avec Escape si le shop est ouvert
	if is_shop_open and visible and event.is_action_pressed("ui_cancel"):
		print("🏪 Fermeture du shop avec Escape")
		close_shop()
		get_viewport().set_input_as_handled()
		return

func toggle_shop():
	print("🏪 toggle_shop() - état actuel: ", is_shop_open)
	
	if is_shop_open:
		close_shop()
	else:
		open_shop()

func open_shop():
	print("🏪 Ouverture du shop...")
	
	# Vérifier si le jeu est déjà en pause (menu pause ouvert)
	if get_tree().paused:
		print("🏪 ÉCHEC: Le jeu est déjà en pause")
		return
	
	# Vérifier si le joueur existe et n'est pas mort
	var player = get_player()
	if not player:
		print("🏪 ÉCHEC: Aucun joueur trouvé")
		return
	
	if player.health <= 0:
		print("🏪 ÉCHEC: Le joueur est mort (", player.health, " HP)")
		return
	
	# Vérifier si l'écran de Game Over est affiché
	if is_game_over_screen_visible():
		print("🏪 ÉCHEC: Écran de Game Over affiché")
		return
	
	is_shop_open = true
	visible = true
	
	# Mettre le jeu en pause
	get_tree().paused = true
	
	# Mettre à jour les pièces
	if GameManager:
		_on_coins_changed(GameManager.get_coins())
	
	print("🏪 Shop ouvert - ", GameManager.get_coins(), " pièces disponibles")

func close_shop():
	print("🏪 Fermeture du shop")
	is_shop_open = false
	visible = false
	
	# Reprendre le jeu SEULEMENT si c'est nous qui l'avons mis en pause
	if get_tree().paused:
		get_tree().paused = false
	
	print("🏪 Shop fermé")

func _on_coins_changed(new_amount: int):
	if coins_label:
		coins_label.text = str(new_amount)

# Fonctions d'achat

func buy_item(item_type: String):
	var price = item_prices.get(item_type, 0)
	
	if not can_afford(price):
		print("🏪 Pas assez de pièces pour acheter ", item_type, " (Prix: ", price, ", Pièces: ", GameManager.get_coins(), ")")
		return
	
	# Déduire le coût
	GameManager.add_coins(-price)
	print("🏪 Achat de ", item_type, " pour ", price, " pièces!")
	
	# Appliquer l'effet de l'objet
	apply_item_effect(item_type)

func buy_weapon(weapon_type: String):
	var price = item_prices.get(weapon_type, 0)
	
	if not can_afford(price):
		print("🏪 Pas assez de pièces pour acheter ", weapon_type, " (Prix: ", price, ", Pièces: ", GameManager.get_coins(), ")")
		return
	
	# Déduire le coût
	GameManager.add_coins(-price)
	print("🏪 Achat de ", weapon_type, " pour ", price, " pièces!")
	
	# Donner l'arme au joueur
	give_weapon_to_player(weapon_type)

func can_afford(price: int) -> bool:
	return GameManager.get_coins() >= price

func apply_item_effect(item_type: String):
	var player = get_player()
	if not player:
		print("🏪 Erreur: Joueur non trouvé pour appliquer l'effet de ", item_type)
		return
	
	match item_type:
		"atomic_bomb":
			# Tuer tous les zombies
			var zombies = get_tree().get_nodes_in_group("enemy")
			for zombie in zombies:
				if zombie.has_method("take_damage"):
					zombie.take_damage(9999)
			print("💣 Bombe atomique utilisée! Tous les zombies sont morts!")
			
		"medical_kit":
			# Soigner le joueur complètement
			if player.has_method("heal_to_full"):
				player.heal_to_full()
			else:
				player.health = player.max_health
				player.update_health_display()
			print("🏥 Kit médical utilisé! Santé restaurée à 100%!")
			
		"skull":
			# Boost de dégâts pour one-shot kill
			if player.has_method("apply_damage_boost"):
				player.apply_damage_boost(9999, 30.0)
			print("💀 Boost de crâne activé! Dégâts énormes pendant 30 secondes!")
			
		"speed_boost":
			# Boost de vitesse
			if player.has_method("apply_speed_boost"):
				player.apply_speed_boost(1.5, 30.0)
			print("⚡ Boost de vitesse activé! +50% de vitesse pendant 30 secondes!")
			
		"shield_small":
			# Ajouter 50 HP (shield petit)
			player.health = min(player.max_health + 50, player.max_health + 100)
			player.max_health = min(player.max_health + 50, 200)  # Limiter à 200 HP max
			player.update_health_display()
			print("🛡️ Bouclier petit utilisé! +50 HP (max 200)")
			
		"shield_large":
			# Ajouter 100 HP (shield grand)
			player.health = min(player.max_health + 100, player.max_health + 200)
			player.max_health = min(player.max_health + 100, 300)  # Limiter à 300 HP max
			player.update_health_display()
			print("🛡️ Bouclier grand utilisé! +100 HP (max 300)")

func give_weapon_to_player(weapon_type: String):
	var player = get_player()
	if not player:
		print("🏪 Erreur: Joueur non trouvé pour donner l'arme ", weapon_type)
		return
	
	# Construire le chemin de l'arme
	var weapon_path = ""
	match weapon_type:
		"pistol":
			weapon_path = "res://weapons/Pistol.tscn"
		"rifle":
			weapon_path = "res://weapons/Rifle.tscn"
		"sniper":
			weapon_path = "res://weapons/Sniper.tscn"
	
	if weapon_path == "":
		print("🏪 Erreur: Type d'arme inconnu: ", weapon_type)
		return
	
	# Simuler un ramassage d'arme
	if player.has_method("pickup_weapon_from_path"):
		player.pickup_weapon_from_path(weapon_path)
		print("🔫 Arme ", weapon_type, " donnée au joueur!")
	else:
		print("🏪 Erreur: Le joueur n'a pas la méthode pickup_weapon_from_path")

func get_player():
	# Chercher le joueur dans la scène
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

# Vérifier si l'écran de Game Over est visible
func is_game_over_screen_visible() -> bool:
	# Chercher l'écran de Game Over dans la scène
	var game_over_screens = get_tree().get_nodes_in_group("game_over")
	for screen in game_over_screens:
		if screen.visible:
			return true
	
	# Méthode alternative : chercher par nom
	var game_over_screen = get_node_or_null("/root/*/GameOverScreen")
	if game_over_screen and game_over_screen.visible:
		return true
	
	# Dernière méthode : vérifier via le GameManager
	if GameManager and GameManager.game_over_screen and GameManager.game_over_screen.visible:
		return true
	
	return false 
