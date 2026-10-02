extends RefCounted

static func xor_transform(data: PackedByteArray, key: String) -> PackedByteArray:
	if data.is_empty() or key.is_empty():
		return data.duplicate()
	var key_bytes := key.to_utf8_buffer()
	var key_len := key_bytes.size()
	var result := data.duplicate()
	for i in range(result.size()):
		result[i] = result[i] ^ key_bytes[i % key_len]
	return result
