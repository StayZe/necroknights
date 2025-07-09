# Système de Zones Audio 🎵

Ce système permet de créer des zones dans lesquelles une musique se joue en boucle quand le joueur est présent, avec des transitions fluides entre les zones.

## Configuration initiale

### 1. Ajouter le gestionnaire global

1. Ouvrez **Project > Project Settings > Autoload**
2. Ajoutez une nouvelle entrée :
   - **Path**: `res://AudioZoneManager.gd`
   - **Node Name**: `AudioZoneManager`
   - **Enabled**: ✓

### 2. Créer une zone audio

1. **Créez un nouveau nœud Area2D** dans votre scène
2. **Renommez-le** (ex: "ForestZone", "CaveZone", etc.)
3. **Attachez le script** `AudioZone.gd` au nœud
4. **Ajoutez un enfant CollisionShape2D** pour définir la zone
5. **Configurez la forme** (RectangleShape2D, CircleShape2D, etc.)

## Configuration des paramètres

### Dans l'inspecteur de votre AudioZone :

| Propriété             | Description                    | Valeur par défaut   |
| --------------------- | ------------------------------ | ------------------- |
| **Audio Stream**      | Le fichier audio à jouer       | `null` (à assigner) |
| **Volume Db**         | Volume de la zone (-80 à 0 dB) | `0.0`               |
| **Fade In Duration**  | Durée du fondu d'entrée        | `1.0` seconde       |
| **Fade Out Duration** | Durée du fondu de sortie       | `1.0` seconde       |
| **Zone Name**         | Nom de la zone pour le debug   | `"AudioZone"`       |

## Utilisation

### Étapes pour ajouter une zone :

1. **Créer la zone** comme décrit ci-dessus
2. **Glisser votre fichier audio** dans le champ "Audio Stream"
3. **Ajuster le volume** selon vos besoins
4. **Redimensionner la CollisionShape2D** pour couvrir la zone désirée
5. **Tester** en lançant la scène

### Exemple d'organisation :

```
Main Scene
├── Player
├── Map
├── AudioZones
│   ├── ForestZone (AudioZone)
│   │   └── CollisionShape2D
│   ├── CaveZone (AudioZone)
│   │   └── CollisionShape2D
│   └── VillageZone (AudioZone)
│       └── CollisionShape2D
└── ... autres éléments
```

## Fonctionnalités

### ✅ Ce que fait le système :

- **Détection automatique** : Joue la musique quand le joueur entre dans la zone
- **Fondu fluide** : Transitions douces entre les zones
- **Gestion des chevauchements** : Si deux zones se chevauchent, la plus récente est priorisée
- **Arrêt automatique** : La musique s'arrête quand le joueur sort de la zone
- **Performance optimisée** : Une seule musique joue à la fois

### 🎛️ Transitions :

- **Zone A → Zone B** : Fondu croisé entre les deux musiques
- **Zone → Extérieur** : Fondu de sortie vers le silence
- **Extérieur → Zone** : Fondu d'entrée depuis le silence

## Conseils d'utilisation

### 🎵 Audio :

- Utilisez des **fichiers en boucle** (loop) pour de meilleurs résultats
- **Formats recommandés** : `.ogg` (plus petit) ou `.wav` (meilleure qualité)
- **Volume** : Commencez avec 0 dB et ajustez selon vos besoins

### 🗺️ Placement :

- **Évitez les zones trop petites** : Le joueur pourrait entrer/sortir trop rapidement
- **Prévoyez des marges** : Laissez de l'espace entre les zones pour les transitions
- **Testez les chevauchements** : Assurez-vous que les transitions sont fluides

### 🐛 Debug :

- Appuyez sur **F9** en jeu pour voir l'état actuel des zones
- Vérifiez la console pour les messages de debug
- Les noms de zones apparaissent dans les logs

## Exemple de configuration typique

```gdscript
# Configuration pour une zone de forêt
Zone Name: "Forêt Mystique"
Audio Stream: res://songs/forest_ambience.ogg
Volume Db: -5.0
Fade In Duration: 2.0
Fade Out Duration: 1.5
```

## Problèmes courants

| Problème                      | Solution                                                       |
| ----------------------------- | -------------------------------------------------------------- |
| **Pas de son**                | Vérifiez que l'Audio Stream est assigné                        |
| **Transitions brusques**      | Augmentez les durées de fondu                                  |
| **Son ne s'arrête pas**       | Vérifiez que la CollisionShape2D est correctement configurée   |
| **Plusieurs sons simultanés** | Vérifiez que l'AudioZoneManager est bien configuré en autoload |

## API pour les développeurs

### Fonctions utiles :

```gdscript
# Arrêter toutes les zones
AudioZoneManager.stop_all_zones()

# Changer la durée de fondu globale
AudioZoneManager.set_global_fade_duration(2.0)

# Obtenir des infos sur l'état actuel
var info = AudioZoneManager.get_current_zone_info()

# Debug
AudioZoneManager.debug_print_status()
```

## Améliorations possibles

- **Zones avec priorité** : Certaines zones peuvent avoir la priorité sur d'autres
- **Variations temporelles** : Musique différente selon l'heure du jour
- **Effets audio** : Réverbération, filtre, etc.
- **Zones multiples** : Plusieurs couches audio par zone

---

_Créé pour le projet NecroKnights_ 🧟‍♂️⚔️
