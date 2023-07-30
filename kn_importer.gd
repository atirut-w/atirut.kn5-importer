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
	
	var scene := Node3D.new()

	# TODO: Implement
	
	var packed := PackedScene.new()
	err = packed.pack(scene)
	if err != OK:
		return err
	
	return ResourceSaver.save(packed, "%s.%s" % [save_path, _get_save_extension()])
