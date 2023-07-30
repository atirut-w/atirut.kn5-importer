@tool
extends EditorPlugin


var importer: KNImporter


func _enter_tree() -> void:
	importer = KNImporter.new()
	add_import_plugin(importer)


func _exit_tree() -> void:
	remove_import_plugin(importer)
	importer = null
