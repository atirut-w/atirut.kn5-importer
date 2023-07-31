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
	
	var scene := _gen_node(loader)
	_set_node_owners(scene, scene)
	
	var packed := PackedScene.new()
	err = packed.pack(scene)
	if err != OK:
		return err
	
	return ResourceSaver.save(packed, "%s.%s" % [save_path, _get_save_extension()])


func _gen_node(loader: KNLoader, original: KNLoader.KNNode = null) -> Node3D:
	if original == null:
		original = loader.root_node

	var node := Node3D.new()
	node.name = original.name

	match original.type:
		1:
			node.position = original.translation
			node.rotation_degrees = original.rotation
			node.scale = original.scale

			for child in original.children:
				node.add_child(_gen_node(loader, child))
		2, 3:
			var vertices := PackedVector3Array()
			var normals := PackedVector3Array()
			var uvs := PackedVector2Array()

			for index in original.indices.size() / 3:
				var i0 := original.indices[index * 3 + 0]
				var i1 := original.indices[index * 3 + 1]
				var i2 := original.indices[index * 3 + 2]

				# Reverse the winding order
				vertices.push_back(original.positions[i0])
				vertices.push_back(original.positions[i2])
				vertices.push_back(original.positions[i1])

				normals.push_back(original.normals[i0])
				normals.push_back(original.normals[i2])
				normals.push_back(original.normals[i1])

				uvs.push_back(original.uvs[i0])
				uvs.push_back(original.uvs[i2])
				uvs.push_back(original.uvs[i1])
			
			var imesh := ImporterMesh.new()
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_TEX_UV] = uvs
			imesh.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)

			var kmat := loader.materials[original.material_id]
			var mat := StandardMaterial3D.new()
			if "txDiffuse" in kmat.textures:
				var tex: KNLoader.KNTexture
				for t in loader.textures:
					if t.name == kmat.textures["txDiffuse"]:
						tex = t
						break

			var instance := MeshInstance3D.new()
			instance.mesh = imesh.get_mesh()
			instance.name = "MESH_" + node.name
			node.add_child(instance)


	return node


func _set_node_owners(node: Node3D, owner: Node3D) -> void:
	if node != owner:
		node.owner = owner

	for child in node.get_children():
		_set_node_owners(child, owner)
