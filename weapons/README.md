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

# Armes dans NecroKnights

## Structure des armes

Les armes sont gérées par une classe de base `Weapon` qui contient les propriétés communes à toutes les armes :

- `fire_rate` : Cadence de tir
- `reload_time` : Temps de rechargement
- `ammo` : Munitions actuelles
- `max_ammo` : Munitions maximum
- `projectile_scene` : Scène du projectile
- `shoot_offset` : Décalage de spawn du projectile

## Types d'armes disponibles

### Pistol

- Arme de poing rapide et précise
- Munitions : 15
- Cadence de tir : Élevée
- Dégâts : Moyens

### Rifle

- Fusil d'assaut polyvalent
- Munitions : 30
- Cadence de tir : Élevée
- Dégâts : Moyens

### Sniper

- Fusil de précision à longue portée
- Munitions : 5
- Cadence de tir : Lente
- Dégâts : Élevés

## Système de récupération d'armes

Les armes peuvent être ramassées via les `WeaponPickup` qui gèrent :

- L'animation de flottaison
- L'interaction avec le joueur
- Le transfert de l'arme au joueur

## Contrôles

- **Clic gauche** : Tirer
- **R** : Recharger
- **E** : Ramasser une arme
- **F** : Déposer l'arme actuelle
- **& (touche 1)** : Équiper l'arme du slot 1 (clavier AZERTY)
- **é (touche 2)** : Équiper l'arme du slot 2 (clavier AZERTY)

## Système d'armes à 2 slots

Le joueur peut maintenant porter **2 armes** simultanément :

### Fonctionnement :

1. **Ramassage automatique** :

   - La première arme va dans le **slot 1**
   - La deuxième arme va dans le **slot 2**
   - Si les deux slots sont pleins, remplace l'arme actuellement équipée

2. **Navigation entre armes** :

   - **Touche & (1)** : Équipe l'arme du slot 1
   - **Touche é (2)** : Équipe l'arme du slot 2

3. **Gestion des slots** :
   - Seule l'arme active est visible et utilisable
   - Les autres armes restent en mémoire mais cachées
   - **Touche F** : Dépose l'arme actuellement équipée pour libérer un slot

### Exemple d'utilisation :

1. Ramasse un Pistolet → Va dans le slot 1 et s'équipe automatiquement
2. Ramasse un Fusil → Va dans le slot 2 et s'équipe automatiquement
3. Appuie sur **& (1)** → Remet le Pistolet en main
4. Appuie sur **é (2)** → Remet le Fusil en main
5. Appuie sur **F** → Dépose l'arme actuelle au sol
6. Ramasse une nouvelle arme → Remplit le slot libéré

Cette système permet une stratégie plus riche en permettant de combiner différents types d'armes selon les situations !
