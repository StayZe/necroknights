# Corrections du système de collision et de dégâts

## Problèmes identifiés et corrigés

1. **Zombies ne prenant pas de dégâts**
   - Problème: Les projectiles ne détectaient pas correctement les zombies
   - Solution:
     - Ajout des zombies au groupe "enemy"
     - Configuration des masques de collision appropriés (projectiles: layer 4, mask 3)
     - Ajout de debug avec des messages dans la console pour tracer les dégâts

2. **Joueur ne prenant pas de dégâts**
   - Problème: La méthode de prise de dégâts n'était pas correctement appelée
   - Solution:
     - Configuration des masques de collision appropriés (joueur: layer 1, mask 2)
     - Ajout d'un affichage de santé au-dessus du joueur
     - Amélioration de la méthode take_damage pour afficher des messages de debug

3. **Renforcement du système de collision**
   - Problème: Les collisions n'étaient pas configurées correctement entre les entités
   - Solution:
     - Joueur: collision_layer = 1, collision_mask = 2
     - Zombies: collision_layer = 2, collision_mask = 5
     - Projectiles: collision_layer = 4, collision_mask = 3
     - Détecteur de zombies: collision_layer = 0, collision_mask = 1 (détecte uniquement le joueur)

## Nouvelles fonctionnalités

1. **Affichage de la santé**
   - Ajout d'une barre de santé au-dessus des zombies et du joueur
   - Mise à jour en temps réel lors de la prise de dégâts

2. **Indications visuelles**
   - Le joueur devient rouge lorsqu'il prend des dégâts
   - Messages de debug pour faciliter le développement et le débogage

3. **Scène de test améliorée**
   - Ajout d'un zombie statique pour tester le système de dégâts
   - Instructions affichées pour comprendre le fonctionnement
   - Toutes les connexions nécessaires sont configurées

## Structure de collision

Le jeu utilise maintenant les couches de collision suivantes:

| Entité     | Layer | Mask | Description                          |
|------------|-------|------|--------------------------------------|
| Joueur     | 1     | 2    | Détecte les zombies                  |
| Zombies    | 2     | 5    | Détecte le joueur et les projectiles |
| Projectiles| 4     | 3    | Détecte les zombies et les murs      |

Cela permet aux entités d'interagir correctement tout en évitant les collisions non désirées. 