@tool
class_name KNImporter
extends EditorImportPlugin
## Main KN5 importer class.
##
## For the actual loader code, see [KNLoader]. This class only converts parsed
## data into a scene tree.


func _get_importer_name() -> String:
	return "atirut.kb5-importer"


func _get_visible_name() -> String:
	return "Assetto Corsa KN5"


func _get_recognized_extensions() -> PackedStringArray:
	return ["kn5"]


func _get_save_extension() -> String:
	return "tscn"


func _get_priority() -> float:
	return 1.0


func _get_import_order() -> int:
	return 0


func _get_resource_type() -> String:
	return "PackedScene"


func _get_preset_count() -> int:
	return 1


func _get_preset_name(preset_index: int) -> String:
	return "Default"


func _get_import_options(path: String, preset_index: int) -> Array:
	return []


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var err: Error = 0
	
	var loader := KNLoader.new()
	err = loader.load(source_file)
	if err != OK:
		return err
	
	var scene := _gen_node(loader.root_node)
	_set_node_owners(scene, scene)
	
	var packed := PackedScene.new()
	err = packed.pack(scene)
	if err != OK:
		return err
	
	return ResourceSaver.save(packed, "%s.%s" % [save_path, _get_save_extension()])


func _gen_node(original: KNLoader.KNNode) -> Node3D:
	var node := Node3D.new()
	node.name = original.name

	match original.type:
		1:
			node.position = original.translation
			node.rotation_degrees = original.rotation
			node.scale = original.scale

			for child in original.children:
				node.add_child(_gen_node(child))
		2, 3:
			var vertices := PackedVector3Array()

			for index in original.indices:
				vertices.push_back(original.positions[index])
			
			var mesh := ArrayMesh.new()
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

			var instance := MeshInstance3D.new()
			instance.mesh = mesh
			instance.name = "MESH_" + node.name
			node.add_child(instance)


	return node


func _set_node_owners(node: Node3D, owner: Node3D) -> void:
	if node != owner:
		node.owner = owner

	for child in node.get_children():
		_set_node_owners(child, owner)
