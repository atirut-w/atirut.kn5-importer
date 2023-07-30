class_name KNLoader
extends RefCounted
## Loader class for the KN5 format.
##
## Because of how little documentation there is on the KN5 format, this importer
## is mostly based on [url=https://github.com/RaduMC/kn5-converter]an existing
## program that converts KN5 to FBX and OBJ[/url]. The original program's output
## is a little screwed up (more specifically the normals), but the codes are
## very readable and easy to understand.


var version: int
var textures: Array[KNTexture]

var _file: FileAccess


func load(path: String) -> Error:
    _file = FileAccess.open(path, FileAccess.READ)
    if _file == null:
        return FileAccess.get_open_error()

    if _file.get_buffer(6).get_string_from_ascii() != "sc6969": # Nice
        return ERR_FILE_UNRECOGNIZED
    version = _file.get_32()

    var texture_count := _file.get_32()
    for i in texture_count:
        var tex := KNTexture.new()
        tex.type = _file.get_32()
        tex.name = _get_p_string()
        tex.size = _file.get_32()
        tex.offset = _file.get_position()

        _file.seek(tex.offset + tex.size)
        textures.append(tex)

    return OK


func _get_p_string() -> String:
    var len := _file.get_32()
    return _file.get_buffer(len).get_string_from_ascii()


class KNTexture extends RefCounted:
    var type: int
    var name: String
    var size: int
    var offset: int
