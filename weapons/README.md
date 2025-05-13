# Système d'Armes pour NecroKnights

Ce système permet de gérer les armes du jeu, leur ramassage et leur utilisation par le joueur.

## Comment ça fonctionne

### 1. Armes au sol

Les armes peuvent être placées au sol et ramassées par le joueur :
- Approchez-vous d'une arme au sol
- Appuyez sur la touche `E` pour la ramasser
- Appuyez sur la touche `F` pour poser l'arme que vous tenez actuellement

### 2. Utilisation des armes

Une fois une arme équipée :
- Cliquez avec le bouton gauche de la souris pour tirer
- Appuyez sur `R` pour recharger

### 3. Comment ajouter une arme au sol dans une scène 

Pour ajouter une arme au sol dans votre scène :

```gdscript
# 1. Instanciez le pickup d'arme
var weapon_pickup = preload("res://weapons/WeaponPickup.tscn").instantiate()

# 2. Définissez l'arme à spawner
weapon_pickup.weapon_scene = preload("res://weapons/Pistol.tscn") # ou votre propre arme

# 3. Positionnez-la dans la scène
weapon_pickup.position = Vector2(x, y)

# 4. Ajoutez-la à la scène
add_child(weapon_pickup)
```

Vous pouvez également utiliser l'exemple prêt à l'emploi :
```gdscript
var pistol_pickup = preload("res://weapons/WeaponPickupExample.tscn").instantiate()
pistol_pickup.position = Vector2(x, y)
add_child(pistol_pickup)
```

## Créer une nouvelle arme

Pour créer une nouvelle arme :

1. Créez un script qui hérite de `Weapon.gd`
2. Personnalisez les paramètres comme la cadence de tir, le temps de rechargement, etc.
3. Créez un pickup pour cette arme

Exemple :
```gdscript
extends Weapon

func _ready():
    fire_rate = 0.2  # Tir plus rapide que le pistolet
    reload_time = 2.0  # Recharge plus lente
    ammo = 30
    max_ammo = 30
    # Autres personnalisations
``` 