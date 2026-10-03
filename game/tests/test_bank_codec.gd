extends SceneTree

const BankCodec = preload("res://scripts/content/bank_codec.gd")

var _fails: Array[String] = []

func _init() -> void:
	_test_round_trip()
	_test_wrong_key_garbage()
	_test_empty_data()
	_test_symmetric()
	if _fails.is_empty():
		print("BANK_CODEC_PASS")
		quit(0)
	else:
		for f in _fails:
			printerr(f)
		quit(1)

func _test_round_trip() -> void:
	var original := '{"bankVersion": 1, "size": 4}'.to_utf8_buffer()
	var key := "candoku-2026-bank-key"
	var encoded := BankCodec.xor_transform(original, key)
	_assert(encoded != original, "encoded differs from original")
	var decoded := BankCodec.xor_transform(encoded, key)
	_assert(decoded == original, "decode matches original")

func _test_wrong_key_garbage() -> void:
	var original := '{"test": true}'.to_utf8_buffer()
	var encoded := BankCodec.xor_transform(original, "correct-key")
	var decoded := BankCodec.xor_transform(encoded, "wrong-key")
	_assert(decoded != original, "wrong key produces garbage")

func _test_empty_data() -> void:
	var empty := PackedByteArray()
	var result := BankCodec.xor_transform(empty, "key")
	_assert(result.size() == 0, "empty in empty out")

func _test_symmetric() -> void:
	var data := "Hello World 12345 !@#$%".to_utf8_buffer()
	var key := "test-key-abc"
	var a := BankCodec.xor_transform(data, key)
	var b := BankCodec.xor_transform(a, key)
	_assert(b == data, "double transform = identity")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		_fails.append("FAIL: " + label)
