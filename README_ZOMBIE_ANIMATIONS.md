# Animations de Zombie - Mise à jour

## Modifications effectuées

J'ai mis à jour le système d'animation des zombies pour prendre en compte le nombre correct de frames pour chaque animation :

- **Animation de course (run)** : 8 frames à 15 FPS
- **Animation d'attente (idle)** : 6 frames à 10 FPS
- **Animation d'attaque (knocked)** : 6 frames à 12 FPS
- **Animation de dégât (hit)** : 3 frames à 6 FPS
- **Animation de mort (death)** : 8 frames à 10 FPS

## Changements techniques

1. **Dans entities/Zombie.tscn** :
   - Ajouté le bon nombre de frames pour chaque animation dans le SpriteFrames
   - Ajusté les vitesses de lecture pour chaque animation

2. **Dans entities/Zombie.gd** :
   - Ajouté des paramètres de configuration des animations dans la fonction _ready()
   - Supprimé la gestion redondante des animations dans _process()
   - Amélioré les transitions entre les états d'animation
   - Ajouté une attente de fin d'animation pour l'état d'attaque avant de revenir à l'état de poursuite

## Utilisation

Les animations se déclenchent automatiquement en fonction de l'état du zombie :
- Quand il est inactif → animation idle
- Quand il poursuit le joueur → animation run
- Quand il attaque le joueur → animation knocked
- Quand il est touché par un projectile → animation hit
- Quand il meurt → animation death

Toutes ces animations ont maintenant le bon nombre de frames et les bonnes vitesses pour un rendu fluide. 