extends Resource
class_name SaveFile



static func load_save_path(path: String) -> SaveFile:
	var save := FileAccess.get_file_as_bytes(path)
	return bytes_to_var_with_objects(save)
