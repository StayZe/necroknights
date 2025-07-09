extends Node
class_name AudioZoneCreator

# Utilitaire pour créer des zones audio facilement
# Peut être utilisé dans l'éditeur ou pendant le runtime

# Créer une zone audio avec des paramètres de base
static func create_audio_zone(
	parent_node: Node,
	zone_name: String,
	position: Vector2,
	size: Vector2,
	audio_stream: AudioStream = null,
	volume_db: float = 0.0,
	fade_in_duration: float = 1.0,
	fade_out_duration: float = 1.0
) -> AudioZone:
	
	# Créer le nœud Area2D avec le script AudioZone
	var audio_zone = AudioZone.new()
	audio_zone.name = zone_name
	audio_zone.position = position
	
	# Configurer les propriétés
	audio_zone.audio_stream = audio_stream
	audio_zone.volume_db = volume_db
	audio_zone.fade_in_duration = fade_in_duration
	audio_zone.fade_out_duration = fade_out_duration
	audio_zone.zone_name = zone_name
	
	# Créer la forme de collision
	var collision_shape = CollisionShape2D.new()
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.size = size
	collision_shape.shape = rectangle_shape
	
	# Assembler la hiérarchie
	audio_zone.add_child(collision_shape)
	parent_node.add_child(audio_zone)
	
	print("Zone audio créée: " + zone_name + " à la position " + str(position))
	return audio_zone

# Créer une zone audio circulaire
static func create_circular_audio_zone(
	parent_node: Node,
	zone_name: String,
	position: Vector2,
	radius: float,
	audio_stream: AudioStream = null,
	volume_db: float = 0.0,
	fade_in_duration: float = 1.0,
	fade_out_duration: float = 1.0
) -> AudioZone:
	
	# Créer le nœud Area2D avec le script AudioZone
	var audio_zone = AudioZone.new()
	audio_zone.name = zone_name
	audio_zone.position = position
	
	# Configurer les propriétés
	audio_zone.audio_stream = audio_stream
	audio_zone.volume_db = volume_db
	audio_zone.fade_in_duration = fade_in_duration
	audio_zone.fade_out_duration = fade_out_duration
	audio_zone.zone_name = zone_name
	
	# Créer la forme de collision circulaire
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	collision_shape.shape = circle_shape
	
	# Assembler la hiérarchie
	audio_zone.add_child(collision_shape)
	parent_node.add_child(audio_zone)
	
	print("Zone audio circulaire créée: " + zone_name + " à la position " + str(position))
	return audio_zone

# Créer plusieurs zones audio depuis un array de configuration
static func create_multiple_zones(parent_node: Node, zones_config: Array) -> Array[AudioZone]:
	var created_zones: Array[AudioZone] = []
	
	for config in zones_config:
		var zone = create_audio_zone(
			parent_node,
			config.get("name", "AudioZone"),
			config.get("position", Vector2.ZERO),
			config.get("size", Vector2(100, 100)),
			config.get("audio_stream", null),
			config.get("volume_db", 0.0),
			config.get("fade_in_duration", 1.0),
			config.get("fade_out_duration", 1.0)
		)
		created_zones.append(zone)
	
	return created_zones

# Exemple d'utilisation pour créer rapidement des zones de test
static func create_example_zones(parent_node: Node):
	var zones_config = [
		{
			"name": "ForestZone",
			"position": Vector2(0, 0),
			"size": Vector2(200, 200),
			"volume_db": -5.0,
			"fade_in_duration": 2.0,
			"fade_out_duration": 1.5
		},
		{
			"name": "CaveZone", 
			"position": Vector2(300, 0),
			"size": Vector2(150, 150),
			"volume_db": -8.0,
			"fade_in_duration": 1.5,
			"fade_out_duration": 2.0
		},
		{
			"name": "VillageZone",
			"position": Vector2(0, 300),
			"size": Vector2(250, 180),
			"volume_db": -3.0,
			"fade_in_duration": 1.0,
			"fade_out_duration": 1.0
		}
	]
	
	var created_zones = create_multiple_zones(parent_node, zones_config)
	print("Zones d'exemple créées: " + str(created_zones.size()) + " zones")
	
	return created_zones

# Fonction pour créer une zone audio depuis le code avec validation
static func create_validated_zone(
	parent_node: Node,
	zone_name: String,
	position: Vector2,
	size: Vector2,
	audio_file_path: String,
	volume_db: float = 0.0,
	fade_in_duration: float = 1.0,
	fade_out_duration: float = 1.0
) -> AudioZone:
	
	# Validation des paramètres
	if not parent_node:
		print("Erreur: parent_node est null")
		return null
	
	if zone_name.is_empty():
		print("Erreur: zone_name est vide")
		return null
	
	if size.x <= 0 or size.y <= 0:
		print("Erreur: size doit être positive")
		return null
	
	# Charger le fichier audio
	var audio_stream = null
	if not audio_file_path.is_empty():
		if ResourceLoader.exists(audio_file_path):
			audio_stream = load(audio_file_path)
			if not audio_stream:
				print("Erreur: Impossible de charger le fichier audio: " + audio_file_path)
		else:
			print("Erreur: Fichier audio non trouvé: " + audio_file_path)
	
	# Créer la zone
	return create_audio_zone(
		parent_node,
		zone_name,
		position,
		size,
		audio_stream,
		volume_db,
		fade_in_duration,
		fade_out_duration
	)

# Fonction pour créer rapidement une zone depuis un dictionnaire
static func create_zone_from_dict(parent_node: Node, config: Dictionary) -> AudioZone:
	return create_validated_zone(
		parent_node,
		config.get("name", "AudioZone"),
		config.get("position", Vector2.ZERO),
		config.get("size", Vector2(100, 100)),
		config.get("audio_path", ""),
		config.get("volume_db", 0.0),
		config.get("fade_in_duration", 1.0),
		config.get("fade_out_duration", 1.0)
	) 