@tool
extends EditorPlugin

## Adds a dock that charts one TuningSim series at a time and redraws automatically whenever
## tune/game.tres, tune/shop.tres, or tune/effects.tres change -- no save, no re-running a
## command, no Play needed.
##
## Refresh is poll-driven (see chart_dock.gd's _process()), not signal-driven: Resource.changed
## does not reliably fire for a generic property edit on a plain custom Resource in the
## inspector (confirmed by the dock not updating when that was tried first). The .changed
## watching in _reload_watched() is kept as a harmless bonus in case it fires for some edits,
## but the poll is what actually guarantees the chart stays current.

const ChartDock := preload("res://addons/tuning_sim_dock/chart_dock.gd")

var dock: Control

func _enter_tree() -> void:
	dock = ChartDock.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree() -> void:
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
