# Système de Zombies - Documentation

## Vue d'ensemble
Ce système ajoute des zombies ennemis qui chassent et attaquent le joueur. Les zombies apparaissent via des "spawners" placés dans le niveau lorsque le joueur s'approche d'eux.

## Caractéristiques
- **Zombies avec 100 HP**
- **Vitesse identique au joueur (100 unités/s)**
- **Inflige 25 dégâts par attaque**
- **Animations pour différents états**: idle, run, hit, knocked (attaque), et death
- **Spawners de zombies** qui génèrent des ennemis quand le joueur est à 30 pixels ou moins
- **Dégâts des armes**: Pistolet (20 HP), Fusil d'assaut (25 HP), Sniper (100 HP)

## Fichiers principaux
- `entities/Zombie.gd` - Logique du zombie (états, déplacements, attaques)
- `entities/Zombie.tscn` - Scène du zombie avec tous les composants
- `entities/ZombieSpawner.gd` - Logique du spawner (détection du joueur, génération des zombies)
- `entities/ZombieSpawner.tscn` - Scène du spawner
- `scenes/ZombieTest.tscn` - Scène de test avec spawners et joueur

## Comment utiliser
1. Ajoutez des `ZombieSpawner` dans votre niveau
2. Assurez-vous que le joueur a le script `Player.gd` avec sa gestion de la santé
3. Assurez-vous que les armes (Pistol.gd, Rifle.gd, Sniper.gd) sont configurées avec les bons dégâts
4. Lancez le jeu et testez l'interaction avec les zombies!

## États du Zombie
- **IDLE**: Quand aucun joueur n'est détecté
- **CHASE**: Poursuit le joueur lorsqu'il est détecté
- **HIT**: État temporaire quand le zombie prend des dégâts
- **ATTACK**: Attaque le joueur lorsqu'il est suffisamment proche
- **DEATH**: Animation de mort lorsque la santé atteint 0

## Comment tester
Ouvrez et lancez la scène `scenes/ZombieTest.tscn` pour tester le système. Cette scène contient:
- 4 spawners de zombies aux coins de l'écran
- Le joueur au centre
- Une arme (pistolet) pour tester les dégâts

## Modifications futures possibles
- Ajouter différents types de zombies
- Ajouter un système de vagues d'ennemis
- Ajouter des effets sonores pour les zombies
- Ajouter des objets à collecter quand un zombie meurt 