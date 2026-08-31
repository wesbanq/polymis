extends Node
#class_name SFX

var sfx_bus_idx: int
var ost_bus_idx: int

#var _blk_plr := AudioStreamPlayer.new()
#var _score_plr := AudioStreamPlayer.new()
#
#var _blk_str := AudioStreamRandomizer.new()
#var _score_str := AudioStreamRandomizer.new()

@warning_ignore("unused_private_class_variable")
var _ost_plr := AudioStreamPlayer.new()
var _sfx_plr := AudioStreamPlayer.new()

var _sfx_poly: AudioStreamPlaybackPolyphonic

const _line_sfx: AudioStreamMP3 = preload("res://sfx/line.mp3")
const _score_sfx: AudioStreamMP3 = preload("res://sfx/score.mp3")
const _count_sfx: AudioStreamOggVorbis = preload("res://sfx/count-up.ogg")
const _blk_sfx: Array[AudioStreamMP3] = [
	preload("res://sfx/block-1.mp3"),
	preload("res://sfx/block-2.mp3"),
	preload("res://sfx/block-3.mp3"),
]

func play_count(pitch: float = 1.0) -> void:
	_sfx_poly.play_stream(_count_sfx, 0, 0, pitch)

func play_blk(pitch: float = 1.0) -> void:
	_sfx_poly.play_stream(_blk_sfx.pick_random(), 0, 0, pitch)

func play_score(pitch: float = 1.0, variation: float = 0.05) -> void:
	_sfx_poly.play_stream(_score_sfx, 0, 0, pitch + randf_range(-variation, variation))

func play_line(pitch: float = 1.0, variation: float = 0.05) -> void:
	_sfx_poly.play_stream(_line_sfx, 0, 0, pitch + randf_range(-variation, variation))

func _ready() -> void:
	sfx_bus_idx = AudioServer.bus_count
	AudioServer.add_bus(sfx_bus_idx)
	AudioServer.set_bus_name(sfx_bus_idx, &"sfx")
	ost_bus_idx = AudioServer.bus_count
	AudioServer.add_bus(ost_bus_idx)
	AudioServer.set_bus_name(ost_bus_idx, &"ost")
	
	_sfx_plr.bus = &"sfx"
	_sfx_plr.max_polyphony = 32
	_sfx_plr.stream = AudioStreamPolyphonic.new()
	add_child(_sfx_plr)
	_sfx_plr.play()
	_sfx_poly = _sfx_plr.get_stream_playback()
	
	#_blk_plr.bus = &"sfx"
	#_blk_plr.max_polyphony = 1000
	#_blk_plr.stream = _blk_str
	#for stream in _blk_sfx: _blk_str.add_stream(-1, stream)
	#_score_plr.bus = &"sfx"
	#_score_plr.max_polyphony = 1000
	#_score_plr.stream = _score_str
	#_score_str.add_stream(-1, _score_sfx)
