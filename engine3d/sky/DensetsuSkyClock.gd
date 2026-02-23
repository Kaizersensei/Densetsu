@tool
extends Node
class_name DensetsuSkyClock

signal datetime_changed(year: int, month: int, day: int, hour: int, minute: int, second: int)
signal time_hours_changed(time_hours: float)

@export_group("Runtime")
## Advances in runtime. Disable to drive time manually.
@export var running: bool = true
## In-editor preview updates while not playing.
@export var editor_preview: bool = false
## Game seconds to in-game minutes multiplier.
@export_range(0.0, 1200.0, 0.01) var minutes_per_real_second: float = 10.0

@export_group("Calendar")
@export var year: int = 1
@export_range(1, 12, 1) var month: int = 1
@export_range(1, 31, 1) var day: int = 1
## Month lengths, index 0 = January.
@export var month_lengths: PackedInt32Array = PackedInt32Array([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])

@export_group("Time Of Day")
@export_range(0, 23, 1) var hour: int = 12
@export_range(0, 59, 1) var minute: int = 0
@export_range(0, 59, 1) var second: int = 0

var _second_accumulator: float = 0.0


func _ready() -> void:
	set_process(true)
	_clamp_datetime()
	_emit_time_signals()


func _process(delta: float) -> void:
	if not running:
		return
	if Engine.is_editor_hint() and not editor_preview:
		return
	if minutes_per_real_second <= 0.0:
		return
	# Accumulate in-game seconds for smooth low time-scale progression.
	_second_accumulator += delta * minutes_per_real_second * 60.0
	if _second_accumulator < 1.0:
		return

	var whole_seconds: int = int(floor(_second_accumulator))
	_second_accumulator -= float(whole_seconds)
	advance_seconds(whole_seconds)


func set_time_hours(value: float) -> void:
	var wrapped_hours: float = wrapf(value, 0.0, 24.0)
	var total_seconds: int = int(round(wrapped_hours * 3600.0))
	if total_seconds >= 86400:
		total_seconds = 86399
	var new_hour: int = total_seconds / 3600
	var new_minute: int = (total_seconds % 3600) / 60
	var new_second: int = total_seconds % 60
	hour = clampi(new_hour, 0, 23)
	minute = clampi(new_minute, 0, 59)
	second = clampi(new_second, 0, 59)
	_second_accumulator = 0.0
	_emit_time_signals()


func get_time_hours() -> float:
	var whole_seconds: int = hour * 3600 + minute * 60 + second
	var total_seconds: float = float(whole_seconds) + _second_accumulator
	total_seconds = fposmod(total_seconds, 86400.0)
	return total_seconds / 3600.0


func advance_minutes(amount: int) -> void:
	if amount == 0:
		return
	var total_minutes: int = hour * 60 + minute + amount

	while total_minutes >= 1440:
		total_minutes -= 1440
		_increment_day(1)
	while total_minutes < 0:
		total_minutes += 1440
		_increment_day(-1)

	hour = total_minutes / 60
	minute = total_minutes % 60
	_emit_time_signals()


func advance_seconds(amount: int) -> void:
	if amount == 0:
		return
	var total_seconds: int = hour * 3600 + minute * 60 + second + amount
	while total_seconds >= 86400:
		total_seconds -= 86400
		_increment_day(1)
	while total_seconds < 0:
		total_seconds += 86400
		_increment_day(-1)
	hour = total_seconds / 3600
	minute = (total_seconds % 3600) / 60
	second = total_seconds % 60
	_emit_time_signals()


func _clamp_datetime() -> void:
	year = max(year, 1)
	month = clampi(month, 1, max(1, month_lengths.size()))
	var max_day: int = _days_in_month(month)
	day = clampi(day, 1, max_day)
	hour = clampi(hour, 0, 23)
	minute = clampi(minute, 0, 59)
	second = clampi(second, 0, 59)


func _days_in_month(month_index_1_based: int) -> int:
	var idx: int = clampi(month_index_1_based - 1, 0, max(0, month_lengths.size() - 1))
	if month_lengths.is_empty():
		return 30
	var days: int = month_lengths[idx]
	return max(days, 1)


func _increment_day(step: int) -> void:
	if step == 0:
		return
	if month_lengths.is_empty():
		day += step
		while day > 30:
			day -= 30
			month += 1
			if month > 12:
				month = 1
				year += 1
		while day < 1:
			day += 30
			month -= 1
			if month < 1:
				month = 12
				year = max(1, year - 1)
		return
	day += step
	if step > 0:
		while day > _days_in_month(month):
			day -= _days_in_month(month)
			month += 1
			if month > month_lengths.size():
				month = 1
				year += 1
	else:
		while day < 1:
			month -= 1
			if month < 1:
				month = month_lengths.size()
				year = max(1, year - 1)
			day += _days_in_month(month)


func _emit_time_signals() -> void:
	datetime_changed.emit(year, month, day, hour, minute, second)
	time_hours_changed.emit(get_time_hours())
