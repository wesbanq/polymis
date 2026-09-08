@tool
extends EditorScript

## Open this file in the Godot script editor and use File > Run (Ctrl+Shift+X) to run the
## tuning simulator without pressing Play. Writes CSVs to res://tuning_sim/ -- see
## tuning_sim.gd for what each column means.

func _run() -> void:
	print(TuningSim.run())
