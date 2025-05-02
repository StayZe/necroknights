extends Weapon  # Hérite de la classe Weapon

func _ready():
    fire_rate = 0.4  # Tir rapide
    reload_time = 1.2  # Temps de recharge rapide
    ammo = 12
    max_ammo = 12
