extends StaticBody3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var heightmap = HeightMapShape3D.new();
	heightmap.map_width = $ImageLoader.width;
	heightmap.map_depth = $ImageLoader.height;
	heightmap.map_data = $ImageLoader.data;
	$CollisionShape3D.shape = heightmap;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
