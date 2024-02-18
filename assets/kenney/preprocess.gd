@tool
extends EditorScript

# Open the kenney library.tscn file in the 3D editor, then open this tool script
# immediately after.
#
# Press Ctrl-Shift-X (or File -> Run) to run the tool script to re-generate all
# the trimesh collision shapes for every mesh.
#
# Generation might break with Godot 4.3, see
# https://github.com/godotengine/godot/pull/87923#issuecomment-1951042114

var whitespace = RegEx.create_from_string("\\s+")

# list of name patterns to skip generating collision shapes for. (whitespaces are removed)
var no_collision = RegEx.create_from_string(whitespace.sub("
	  ^grass2$
	| ^grass_
	| ^plant_
	| ^flower_
	| ^mushroom_
	| ^flowers2$
	| ^flowersLow2$
", "", true))

func _run():
	var import_root = get_scene().get_node("skip/IMPORT")
	var meshes = import_root.get_children()
	for mesh in meshes:
		if mesh.get_class() == "Node3D":
			preprocess_mesh(mesh)

func preprocess_mesh(object: Node3D):
	if object.name == "skip" || object.name == "IMPORT":
		return
	var child = object.get_child(0)
	if child && child.get_class() != "MeshInstance3D":
		child = child.get_child(0)
	if child && child.get_class() != "MeshInstance3D":
		child = child.get_child(0)
	if child && child.get_class() != "MeshInstance3D":
		child = child.get_child(0)
	if !child || child.get_class() != "MeshInstance3D":
		print("failed object ", object)
		return

	var mesh: MeshInstance3D = child.duplicate()
	mesh.name = object.name
	var existing = get_scene().get_node_or_null(NodePath(mesh.name))
	if existing:
		existing.get_parent().remove_child(existing)
		existing.owner = get_scene()

	var add_collider = true

	if no_collision.search(mesh.name):
		add_collider = false

	if add_collider:
		mesh.create_trimesh_collision()
	var p = mesh.get_parent()
	if p:
		p.remove_child(mesh)
	get_scene().add_child(mesh)
	own_recursive(mesh)

func own_recursive(node: Node3D):
	node.owner = get_scene()
	for child in node.get_children():
		own_recursive(child)
