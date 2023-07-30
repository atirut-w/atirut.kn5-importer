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
var materials: Array[KNMaterial]

var _file: FileAccess


func load(path: String) -> Error:
    _file = FileAccess.open(path, FileAccess.READ)
    if _file == null:
        return FileAccess.get_open_error()

    if _file.get_buffer(6).get_string_from_ascii() != "sc6969": # Nice
        return ERR_FILE_UNRECOGNIZED
    version = _file.get_32()

    for i in _file.get_32(): # Textures
        var tex := KNTexture.new()
        tex.type = _file.get_32()
        tex.name = _get_p_string()
        tex.size = _file.get_32()
        tex.offset = _file.get_position()

        _file.seek(tex.offset + tex.size)
        textures.append(tex)
    
    for i in _file.get_32(): # Materials
        var mat := KNMaterial.new()
        mat.name = _get_p_string()
        mat.shader = _get_p_string()

        # The original loader just does this, I don't know what's skipped over,
        # but it's not like there's an official docs for it. /shrug
        _file.get_16()
        if version > 4:
            _file.get_32()
        
        for j in _file.get_32(): # Properties
            var prop_name := _get_p_string()
            var prop_value := _file.get_float()
            mat.properties[prop_name] = prop_value

            _file.seek(_file.get_position() + 36) # WHAT
        
        for j in _file.get_32(): # Textures
            var sample_name := _get_p_string()
            _file.get_32()
            var tex_name := _get_p_string()

            mat.textures[sample_name] = tex_name
        
        materials.append(mat)

    return OK


func _get_p_string() -> String:
    var len := _file.get_32()
    return _file.get_buffer(len).get_string_from_ascii()


class KNTexture extends RefCounted:
    var type: int
    var name: String
    var size: int
    var offset: int


class KNMaterial extends RefCounted:
    var name: String
    var shader: String
    var properties: Dictionary
    var textures: Dictionary
