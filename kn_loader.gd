class_name KNLoader
extends RefCounted
## Loader class for the KN5 format.
##
## Because of how little documentation there is on the KN5 format, this importer
## is mostly based on [url=https://github.com/RaduMC/kn5-converter]an existing
## program that converts KN5 to FBX and OBJ[/url]. The original program's output
## is a little screwed up (more specifically the normals), but the codes are
## very readable and easy to understand.


var base_dir: String

var version: int
var textures: Array[KNTexture]
var materials: Array[KNMaterial]
var root_node: KNNode

var _file: FileAccess


func load(path: String) -> Error:
	_file = FileAccess.open(path, FileAccess.READ)
	if _file == null:
		return FileAccess.get_open_error()
	base_dir = path.get_base_dir()

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
	
	root_node = _load_node(true)

	return OK


func _load_node(root: bool, parent: KNNode = null) -> KNNode:
	var node := KNNode.new()
	node.type = _file.get_32()
	node.name = _get_p_string()
	var child_count := _file.get_32() # This is somehow not right before child nodes
	_file.get_8() # Unknown yet again

	match node.type:
		1: # Dummy node
			for row in 4:
				for col in 4:
					node.transform_matrix[row][col] = _file.get_float()
			
			node.translation = Vector3(node.transform_matrix[3][0], node.transform_matrix[3][1], node.transform_matrix[3][2])
			node.rotation = _to_euler(node.transform_matrix)
			node.scale = _to_scale(node.transform_matrix)
		2: # Mesh
			for i in 3:
				_file.get_8() # Unknown

			for i in _file.get_32(): # Vertices
				var position: Vector3
				var normal: Vector3
				var uv: Vector2

				position.x = _file.get_float()
				position.y = _file.get_float()
				position.z = _file.get_float()

				normal.x = _file.get_float()
				normal.y = _file.get_float()
				normal.z = _file.get_float()

				uv.x = _file.get_float()
				uv.y = _file.get_float()

				node.positions.append(position)
				node.normals.append(normal)
				node.uvs.append(uv)

				_file.seek(_file.get_position() + 12) # Tangents
			
			for i in _file.get_32(): # Indices
				node.indices.append(_file.get_16())
			
			node.material_id = _file.get_32()
			_file.seek(_file.get_position() + 29) # Unknown
		3: # Animated mesh
			for i in 3:
				_file.get_8() # Unknown
			
			for i in _file.get_32(): # Bone names
				var bone_name := _get_p_string()
				_file.seek(_file.get_position() + 64) # Transform matrix
			
			for i in _file.get_32(): # Vertices
				var position: Vector3
				var normal: Vector3
				var uv: Vector2

				position.x = _file.get_float()
				position.y = _file.get_float()
				position.z = _file.get_float()

				normal.x = _file.get_float()
				normal.y = _file.get_float()
				normal.z = _file.get_float()

				uv.x = _file.get_float()
				uv.y = _file.get_float()

				node.positions.append(position)
				node.normals.append(normal)
				node.uvs.append(uv)

				_file.seek(_file.get_position() + 44) # Tangents and weights
			
			for i in _file.get_32(): # Indices
				node.indices.append(_file.get_16())
			
			node.material_id = _file.get_32()
			_file.seek(_file.get_position() + 12) # Unknown

	if root:
		node.hierarchy_matrix = node.transform_matrix
	else:
		node.hierarchy_matrix = _matrix_mult(node.transform_matrix, parent.hierarchy_matrix)
	
	for i in child_count:
		node.children.append(_load_node(false, node))

	return node


func _get_p_string() -> String:
	var len := _file.get_32()
	return _file.get_buffer(len).get_string_from_ascii()


func _to_euler(transform: Array) -> Vector3:
	var heading: float
	var attitude: float
	var bank: float

	if transform[0][1] > 0.998:
		heading = atan2(-transform[1][0], transform[1][1])
		attitude = -PI / 2
		bank = 0
	elif transform[0][1] < -0.998:
		heading = atan2(-transform[1][0], transform[1][1])
		attitude = PI / 2
		bank = 0
	else:
		heading = atan2(transform[0][1], transform[0][0])
		bank = atan2(transform[1][2], transform[2][2])
		attitude = asin(-transform[0][2])

	attitude *= 180 / PI
	heading *= 180 / PI
	bank *= 180 / PI
	return Vector3(bank, attitude, heading)


func _to_scale(transform: Array) -> Vector3:
	var x := sqrt(transform[0][0] * transform[0][0] + transform[1][0] * transform[1][0] + transform[2][0] * transform[2][0])
	var y := sqrt(transform[0][1] * transform[0][1] + transform[1][1] * transform[1][1] + transform[2][1] * transform[2][1])
	var z := sqrt(transform[0][2] * transform[0][2] + transform[1][2] * transform[1][2] + transform[2][2] * transform[2][2])
	return Vector3(x, y, z)


func _matrix_mult(mat_a: Array, mat_b: Array) -> Array:
	var result := []
	for row in 4:
		result.append([0.0, 0.0, 0.0, 0.0])
	
	for i in 4:
		for j in 4:
			result[i][j] = mat_a[i][0] * mat_b[0][j] + mat_a[i][1] * mat_b[1][j] + mat_a[i][2] * mat_b[2][j] + mat_a[i][3] * mat_b[3][j]
	
	return result


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


class KNNode extends RefCounted:
	var type: int
	var name: String
	var children: Array[KNNode]
	
	var transform_matrix: Array
	var hierarchy_matrix: Array
	var translation: Vector3
	var rotation: Vector3
	var scale: Vector3

	# For mesh nodes
	var positions: Array[Vector3]
	var normals: Array[Vector3]
	var uvs: Array[Vector2]
	var indices: Array[int]
	var material_id: int

	# For animated mesh nodes
	var bone_count: int


	func _init() -> void:
		for row in 4:
			transform_matrix.append([0.0, 0.0, 0.0, 0.0])
			hierarchy_matrix.append([0.0, 0.0, 0.0, 0.0])
