class_name EffectTuning
extends Tuning

@export var flash_curve: Curve
@export var last_flash_line: int = 1

func flash_time(line_complete: int, block: int, line_width: int) -> float:
	#var r := clampf(0.9 ** (3.05*(line_complete + block)), 0.05, 0.5)
	#print("spd: ", r)
	return flash_curve.sample_baked(clampf(line_complete*line_width + block, 0, last_flash_line*line_width) / (last_flash_line*line_width))

const PENTATONIC: Array[int] = [0, 2, 4, 7, 9]
static func pentatonic_pitch(step: int) -> float:
	var degree := step % PENTATONIC.size()
	var octave := step / float(PENTATONIC.size())
	var semitones := PENTATONIC[degree] + octave * 12
	return pow(2.0, semitones / 12.0)

@export var pitch_curve: Curve
@export var last_pitch_line: int = 1

@warning_ignore("shadowed_variable_base_class")
func pitch(line_complete: int, block: int, line_width: int) -> float:
	#var r2 := floori((block+line_complete*line_width)*.1)
	#@warning_ignore("static_called_on_instance")
	#var r := SFX.calc_pentatonic_pitch(r2)
	#print("spd: ", r, "ps: ", r2)
	return pitch_curve.sample_baked(clampf(line_complete*line_width + block, 0, last_flash_line*line_width) / (last_flash_line*line_width))
