@tool
extends EditorPlugin

## Adds a dock that charts one TuningSim series at a time and redraws automatically whenever
## tune/game.tres, tune/shop.tres, tune/effects.tres, or their Curve sub-resources (fall_speed,
## flash_curve) change in the inspector -- no save, no re-running a command, no Play needed.
##
## NOTE: this is the least-tested piece of the tuning tooling (the CSV/console-command side
## of TuningSim was validated numerically before being trusted; this dock's redraw wiring
## has not been run against a live editor). If the chart doesn't update on an edit, check
## whether the edited property is a nested sub-resource (like a Curve control point) that
## isn't being watched below -- see _reload_watched().

const ChartDock := preload("res://addons/tuning_sim_dock/chart_dock.gd")

var dock: Control

func _enter_tree() -> void:
	dock = ChartDock.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree() -> void:
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
