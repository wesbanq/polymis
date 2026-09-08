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
	var octave := step / PENTATONIC.size()
	var semitones := PENTATONIC[degree] + octave * 12
	return pow(2.0, semitones / 12.0)

## how many pentatonic scale steps the pitch climbs across one full flash sequence
## (shares last_flash_line/line_width with flash_time so the two stay in lockstep --
## they're describing progress through the same sequence of flashing blocks)
@export var pitch_span: int = 12

@warning_ignore("shadowed_variable_base_class")
func pitch(line_complete: int, block: int, line_width: int) -> float:
	var span := last_flash_line * line_width
	var progress := clampf(line_complete * line_width + block, 0, span) / float(span)
	return pentatonic_pitch(roundi(progress * pitch_span))
