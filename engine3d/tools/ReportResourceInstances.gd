@tool
extends SceneTree

const SCAN_EXTENSIONS: Array[String] = [
	"tscn",
	"tres",
	"res",
	"material",
]

const SKIP_DIRS: Array[String] = [
	".git",
	".godot",
	".import",
	"temp",
]

const DEFAULT_TOP: int = 120
const SCORE_INSTANCE_WEIGHT: int = 4

const HOT_SCORE_THRESHOLD: int = 80
const HOT_INSTANCE_THRESHOLD: int = 20
const WARM_SCORE_THRESHOLD: int = 20
const WARM_INSTANCE_THRESHOLD: int = 4

var _ext_resource_re: RegEx
var _ext_use_re: RegEx
var _res_path_re: RegEx
var _uid_re: RegEx


func _init() -> void:
	_init_regexes()

	var args: PackedStringArray = OS.get_cmdline_user_args()
	var config: Dictionary = _parse_args(args)
	var mode: String = str(config.get("mode", ""))
	if mode.is_empty():
		_print_usage()
		quit(1)
		return

	if mode == "all":
		var top_n: int = int(config.get("top", DEFAULT_TOP))
		var out_path: String = str(config.get("out", ""))
		var report_all: Dictionary = _new_all_report()
		_scan_project_all(report_all)
		var rows: Array = _build_sorted_rows(report_all)
		_print_all_report(report_all, rows, top_n)
		if not out_path.is_empty():
			_write_all_report(rows, report_all, out_path)
		quit(0)
		return

	var target: String = str(config.get("target", "")).strip_edges()
	if target.is_empty():
		_print_usage()
		quit(1)
		return

	var report_single: Dictionary = _new_single_report(target)
	_scan_project_single(target, report_single)
	_print_single_report(report_single)
	quit(0)


func _init_regexes() -> void:
	_ext_resource_re = RegEx.new()
	_ext_resource_re.compile("^\\[ext_resource\\s+.*path=\"([^\"]+)\".*id=\"([^\"]+)\"\\]")

	_ext_use_re = RegEx.new()
	_ext_use_re.compile("ExtResource\\(\"([^\"]+)\"\\)")

	_res_path_re = RegEx.new()
	_res_path_re.compile("(res://[^\\s\\\"'\\]\\)]+)")

	_uid_re = RegEx.new()
	_uid_re.compile("(uid://[A-Za-z0-9_]+)")


func _parse_args(args: PackedStringArray) -> Dictionary:
	var mode: String = ""
	var target: String = ""
	var top_n: int = DEFAULT_TOP
	var out_path: String = ""

	for arg: String in args:
		if arg == "--all":
			mode = "all"
			continue
		if arg.begins_with("--resource="):
			mode = "single"
			target = arg.substr("--resource=".length())
			continue
		if arg.begins_with("--target="):
			mode = "single"
			target = arg.substr("--target=".length())
			continue
		if arg.begins_with("--top="):
			top_n = maxi(1, int(arg.substr("--top=".length())))
			continue
		if arg.begins_with("--out="):
			out_path = arg.substr("--out=".length())
			continue
		if not arg.begins_with("--") and target.is_empty():
			mode = "single"
			target = arg

	return {
		"mode": mode,
		"target": target,
		"top": top_n,
		"out": out_path.strip_edges(),
	}


func _print_usage() -> void:
	print("Usage:")
	print("  Single target:")
	print("    godot --headless --path . -s res://engine3d/tools/ReportResourceInstances.gd -- --resource=res://path/to/resource.tres")
	print("    godot --headless --path . -s res://engine3d/tools/ReportResourceInstances.gd -- --resource=uid://abcdef12345")
	print("    godot --headless --path . -s res://engine3d/tools/ReportResourceInstances.gd -- res://path/to/resource.tscn")
	print("")
	print("  Full optimization snapshot (sorted on spot):")
	print("    godot --headless --path . -s res://engine3d/tools/ReportResourceInstances.gd -- --all")
	print("    godot --headless --path . -s res://engine3d/tools/ReportResourceInstances.gd -- --all --top=200 --out=res://temp/reports/resource_usage.tsv")


func _new_single_report(target: String) -> Dictionary:
	return {
		"target": target,
		"scanned_files": 0,
		"instance_total": 0,
		"reference_total": 0,
		"files": {},
	}


func _new_all_report() -> Dictionary:
	return {
		"scanned_files": 0,
		"instance_total": 0,
		"reference_total": 0,
		"resources": {},
	}


func _scan_project_single(target: String, report: Dictionary) -> void:
	var root_abs: String = ProjectSettings.globalize_path("res://")
	_scan_directory_single(root_abs, target, report)


func _scan_project_all(report: Dictionary) -> void:
	var root_abs: String = ProjectSettings.globalize_path("res://")
	_scan_directory_all(root_abs, report)


func _scan_directory_single(abs_dir: String, target: String, report: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(abs_dir)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == "..":
			continue
		if SKIP_DIRS.has(name):
			continue

		var child_abs: String = abs_dir.path_join(name)
		if dir.current_is_dir():
			_scan_directory_single(child_abs, target, report)
			continue

		var ext: String = name.get_extension().to_lower()
		if not SCAN_EXTENSIONS.has(ext):
			continue

		_scan_file_single(child_abs, target, report)
	dir.list_dir_end()


func _scan_directory_all(abs_dir: String, report: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(abs_dir)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == "..":
			continue
		if SKIP_DIRS.has(name):
			continue

		var child_abs: String = abs_dir.path_join(name)
		if dir.current_is_dir():
			_scan_directory_all(child_abs, report)
			continue

		var ext: String = name.get_extension().to_lower()
		if not SCAN_EXTENSIONS.has(ext):
			continue

		_scan_file_all(child_abs, report)
	dir.list_dir_end()


func _read_file_lines(abs_path: String) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var file: FileAccess = FileAccess.open(abs_path, FileAccess.READ)
	if file == null:
		return lines
	while not file.eof_reached():
		lines.append(file.get_line())
	file.close()
	return lines


func _scan_file_single(abs_path: String, target: String, report: Dictionary) -> void:
	var lines: PackedStringArray = _read_file_lines(abs_path)
	report["scanned_files"] = int(report.get("scanned_files", 0)) + 1
	var res_path: String = ProjectSettings.localize_path(abs_path)
	var ext: String = res_path.get_extension().to_lower()

	if ext == "tscn":
		_scan_scene_file_single(res_path, lines, target, report)
	else:
		_scan_generic_file_single(res_path, lines, target, report)


func _scan_file_all(abs_path: String, report: Dictionary) -> void:
	var lines: PackedStringArray = _read_file_lines(abs_path)
	report["scanned_files"] = int(report.get("scanned_files", 0)) + 1
	var res_path: String = ProjectSettings.localize_path(abs_path)
	var ext: String = res_path.get_extension().to_lower()

	if ext == "tscn":
		_scan_scene_file_all(res_path, lines, report)
	else:
		_scan_generic_file_all(res_path, lines, report)


func _scan_scene_file_single(file_path: String, lines: PackedStringArray, target: String, report: Dictionary) -> void:
	var ext_ids: PackedStringArray = PackedStringArray()
	var id_to_path: Dictionary = {}

	for i: int in range(lines.size()):
		var line: String = lines[i]
		var match: RegExMatch = _ext_resource_re.search(line)
		if match == null:
			continue
		var res_path: String = match.get_string(1)
		var ext_id: String = match.get_string(2)
		id_to_path[ext_id] = res_path
		if res_path == target:
			ext_ids.append(ext_id)
			_add_single_hit(report, file_path, "reference", i + 1, line)
		elif target.begins_with("uid://") and line.find(target) >= 0:
			ext_ids.append(ext_id)
			_add_single_hit(report, file_path, "reference", i + 1, line)

	if ext_ids.is_empty():
		return

	for i: int in range(lines.size()):
		var line: String = lines[i]
		if line.begins_with("[ext_resource "):
			continue
		var matches: Array = _ext_use_re.search_all(line)
		if matches.is_empty():
			continue
		for match_value in matches:
			var use_match: RegExMatch = match_value as RegExMatch
			if use_match == null:
				continue
			var ext_id: String = use_match.get_string(1)
			if not ext_ids.has(ext_id):
				continue
			var kind: String = "reference"
			if line.begins_with("[node ") and line.find("instance=ExtResource(\"%s\")" % ext_id) >= 0:
				kind = "instance"
			_add_single_hit(report, file_path, kind, i + 1, line)


func _scan_generic_file_single(file_path: String, lines: PackedStringArray, target: String, report: Dictionary) -> void:
	for i: int in range(lines.size()):
		var line: String = lines[i]
		if line.find(target) < 0:
			continue
		_add_single_hit(report, file_path, "reference", i + 1, line)


func _scan_scene_file_all(file_path: String, lines: PackedStringArray, report: Dictionary) -> void:
	var id_to_path: Dictionary = {}

	for i: int in range(lines.size()):
		var line: String = lines[i]
		var match: RegExMatch = _ext_resource_re.search(line)
		if match == null:
			continue
		var res_path: String = match.get_string(1).strip_edges()
		var ext_id: String = match.get_string(2)
		id_to_path[ext_id] = res_path
		_add_all_hit(report, res_path, file_path, "reference")

	for i: int in range(lines.size()):
		var line: String = lines[i]
		if line.begins_with("[ext_resource "):
			continue
		var matches: Array = _ext_use_re.search_all(line)
		if matches.is_empty():
			continue
		for match_value in matches:
			var use_match: RegExMatch = match_value as RegExMatch
			if use_match == null:
				continue
			var ext_id: String = use_match.get_string(1)
			if not id_to_path.has(ext_id):
				continue
			var res_path: String = str(id_to_path[ext_id])
			var kind: String = "reference"
			if line.begins_with("[node ") and line.find("instance=ExtResource(\"%s\")" % ext_id) >= 0:
				kind = "instance"
			_add_all_hit(report, res_path, file_path, kind)


func _scan_generic_file_all(file_path: String, lines: PackedStringArray, report: Dictionary) -> void:
	for i: int in range(lines.size()):
		var line: String = lines[i]
		var seen_tokens: Dictionary = {}

		var path_matches: Array = _res_path_re.search_all(line)
		for match_value in path_matches:
			var path_match: RegExMatch = match_value as RegExMatch
			if path_match == null:
				continue
			var token: String = path_match.get_string(1).strip_edges()
			if token.is_empty() or seen_tokens.has(token):
				continue
			seen_tokens[token] = true
			_add_all_hit(report, token, file_path, "reference")

		var uid_matches: Array = _uid_re.search_all(line)
		for match_value in uid_matches:
			var uid_match: RegExMatch = match_value as RegExMatch
			if uid_match == null:
				continue
			var uid_token: String = uid_match.get_string(1).strip_edges()
			if uid_token.is_empty() or seen_tokens.has(uid_token):
				continue
			seen_tokens[uid_token] = true
			_add_all_hit(report, uid_token, file_path, "reference")


func _add_single_hit(report: Dictionary, file_path: String, kind: String, line_no: int, line_text: String) -> void:
	var files: Dictionary = report.get("files", {}) as Dictionary
	var entry: Dictionary = {}
	if files.has(file_path):
		entry = files[file_path] as Dictionary
	if entry.is_empty():
		entry = {
			"instances": 0,
			"references": 0,
			"lines": PackedStringArray(),
		}

	if kind == "instance":
		entry["instances"] = int(entry.get("instances", 0)) + 1
		report["instance_total"] = int(report.get("instance_total", 0)) + 1
	else:
		entry["references"] = int(entry.get("references", 0)) + 1
		report["reference_total"] = int(report.get("reference_total", 0)) + 1

	var lines: PackedStringArray = entry.get("lines", PackedStringArray()) as PackedStringArray
	lines.append("%d | %s | %s" % [line_no, kind, line_text.strip_edges()])
	entry["lines"] = lines
	files[file_path] = entry
	report["files"] = files


func _add_all_hit(report: Dictionary, resource_key: String, file_path: String, kind: String) -> void:
	if resource_key.is_empty():
		return

	var resources: Dictionary = report.get("resources", {}) as Dictionary
	var entry: Dictionary = {}
	if resources.has(resource_key):
		entry = resources[resource_key] as Dictionary
	if entry.is_empty():
		entry = {
			"instances": 0,
			"references": 0,
			"files": {},
		}

	var files: Dictionary = entry.get("files", {}) as Dictionary
	var file_entry: Dictionary = {}
	if files.has(file_path):
		file_entry = files[file_path] as Dictionary
	if file_entry.is_empty():
		file_entry = {
			"instances": 0,
			"references": 0,
		}

	if kind == "instance":
		entry["instances"] = int(entry.get("instances", 0)) + 1
		file_entry["instances"] = int(file_entry.get("instances", 0)) + 1
		report["instance_total"] = int(report.get("instance_total", 0)) + 1
	else:
		entry["references"] = int(entry.get("references", 0)) + 1
		file_entry["references"] = int(file_entry.get("references", 0)) + 1
		report["reference_total"] = int(report.get("reference_total", 0)) + 1

	files[file_path] = file_entry
	entry["files"] = files
	resources[resource_key] = entry
	report["resources"] = resources


func _build_sorted_rows(report: Dictionary) -> Array:
	var rows: Array = []
	var resources: Dictionary = report.get("resources", {}) as Dictionary
	for key_value in resources.keys():
		var resource_key: String = str(key_value)
		var entry: Dictionary = resources[key_value] as Dictionary
		var instances: int = int(entry.get("instances", 0))
		var references: int = int(entry.get("references", 0))
		var score: int = instances * SCORE_INSTANCE_WEIGHT + references
		var files: Dictionary = entry.get("files", {}) as Dictionary
		var tier: String = _tier_for(score, instances)
		rows.append({
			"resource": resource_key,
			"instances": instances,
			"references": references,
			"score": score,
			"file_count": files.size(),
			"tier": tier,
			"files": files,
		})

	rows.sort_custom(_sort_rows_desc)
	return rows


func _sort_rows_desc(a: Dictionary, b: Dictionary) -> bool:
	var score_a: int = int(a.get("score", 0))
	var score_b: int = int(b.get("score", 0))
	if score_a == score_b:
		var instances_a: int = int(a.get("instances", 0))
		var instances_b: int = int(b.get("instances", 0))
		if instances_a == instances_b:
			return str(a.get("resource", "")) < str(b.get("resource", ""))
		return instances_a > instances_b
	return score_a > score_b


func _tier_for(score: int, instances: int) -> String:
	if score >= HOT_SCORE_THRESHOLD or instances >= HOT_INSTANCE_THRESHOLD:
		return "HOT_PERSIST_OR_STREAM"
	if score >= WARM_SCORE_THRESHOLD or instances >= WARM_INSTANCE_THRESHOLD:
		return "WARM_STREAM_OR_POOL"
	return "COLD_MAP_LOCAL"


func _print_single_report(report: Dictionary) -> void:
	var target: String = str(report.get("target", ""))
	var scanned_files: int = int(report.get("scanned_files", 0))
	var instance_total: int = int(report.get("instance_total", 0))
	var reference_total: int = int(report.get("reference_total", 0))
	var files: Dictionary = report.get("files", {}) as Dictionary

	print("")
	print("Resource Usage Report")
	print("Target: ", target)
	print("Scanned files: ", scanned_files)
	print("Instance hits: ", instance_total)
	print("Reference hits: ", reference_total)
	print("Files with hits: ", files.size())
	print("")

	if files.is_empty():
		print("No hits found.")
		return

	var file_keys: PackedStringArray = PackedStringArray()
	for key_value in files.keys():
		file_keys.append(str(key_value))
	file_keys.sort()

	for file_path: String in file_keys:
		var entry: Dictionary = files[file_path] as Dictionary
		var instances: int = int(entry.get("instances", 0))
		var references: int = int(entry.get("references", 0))
		print("- ", file_path)
		print("  instances: ", instances, " | references: ", references)
		var lines: PackedStringArray = entry.get("lines", PackedStringArray()) as PackedStringArray
		for hit_line: String in lines:
			print("    ", hit_line)
		print("")


func _print_all_report(report: Dictionary, rows: Array, top_n: int) -> void:
	var scanned_files: int = int(report.get("scanned_files", 0))
	var instance_total: int = int(report.get("instance_total", 0))
	var reference_total: int = int(report.get("reference_total", 0))
	var resource_count: int = rows.size()

	var hot_count: int = 0
	var warm_count: int = 0
	var cold_count: int = 0
	for row_value in rows:
		var row: Dictionary = row_value as Dictionary
		var tier: String = str(row.get("tier", ""))
		if tier == "HOT_PERSIST_OR_STREAM":
			hot_count += 1
		elif tier == "WARM_STREAM_OR_POOL":
			warm_count += 1
		else:
			cold_count += 1

	print("")
	print("Resource Optimization Snapshot")
	print("Scanned files: ", scanned_files)
	print("Resource keys discovered: ", resource_count)
	print("Instance hits: ", instance_total)
	print("Reference hits: ", reference_total)
	print("Tier counts: HOT=", hot_count, " | WARM=", warm_count, " | COLD=", cold_count)
	print("")

	if rows.is_empty():
		print("No resource hits found.")
		return

	var limit: int = mini(top_n, rows.size())
	print("Top ", limit, " resources by score (instances*", SCORE_INSTANCE_WEIGHT, " + references):")
	print("")

	for i: int in range(limit):
		var row: Dictionary = rows[i] as Dictionary
		var resource_key: String = str(row.get("resource", ""))
		var instances: int = int(row.get("instances", 0))
		var references: int = int(row.get("references", 0))
		var score: int = int(row.get("score", 0))
		var tier: String = str(row.get("tier", ""))
		var file_count: int = int(row.get("file_count", 0))
		print("%d. %s" % [i + 1, resource_key])
		print("   tier=", tier, " | score=", score, " | instances=", instances, " | references=", references, " | files=", file_count)

		var files: Dictionary = row.get("files", {}) as Dictionary
		var file_rows: Array = []
		for file_key_value in files.keys():
			var file_path: String = str(file_key_value)
			var file_entry: Dictionary = files[file_key_value] as Dictionary
			var file_instances: int = int(file_entry.get("instances", 0))
			var file_references: int = int(file_entry.get("references", 0))
			var file_score: int = file_instances * SCORE_INSTANCE_WEIGHT + file_references
			file_rows.append({
				"path": file_path,
				"score": file_score,
				"instances": file_instances,
				"references": file_references,
			})
		file_rows.sort_custom(_sort_file_rows_desc)
		var file_limit: int = mini(3, file_rows.size())
		for file_i: int in range(file_limit):
			var frow: Dictionary = file_rows[file_i] as Dictionary
			print("   - ", frow.get("path", ""), " | score=", int(frow.get("score", 0)), " | i=", int(frow.get("instances", 0)), " r=", int(frow.get("references", 0)))
		print("")


func _sort_file_rows_desc(a: Dictionary, b: Dictionary) -> bool:
	var score_a: int = int(a.get("score", 0))
	var score_b: int = int(b.get("score", 0))
	if score_a == score_b:
		return str(a.get("path", "")) < str(b.get("path", ""))
	return score_a > score_b


func _write_all_report(rows: Array, report: Dictionary, out_path: String) -> void:
	var normalized_out: String = out_path.strip_edges()
	if normalized_out.is_empty():
		return

	var abs_out: String = normalized_out
	if normalized_out.begins_with("res://"):
		abs_out = ProjectSettings.globalize_path(normalized_out)

	var base_dir: String = abs_out.get_base_dir()
	DirAccess.make_dir_recursive_absolute(base_dir)

	var file: FileAccess = FileAccess.open(abs_out, FileAccess.WRITE)
	if file == null:
		push_error("ReportResourceInstances: failed to write report: " + abs_out)
		return

	file.store_line("# Resource Optimization Snapshot")
	file.store_line("# generated_at=" + Time.get_datetime_string_from_system())
	file.store_line("# scanned_files=%d resources=%d instances=%d references=%d" % [
		int(report.get("scanned_files", 0)),
		rows.size(),
		int(report.get("instance_total", 0)),
		int(report.get("reference_total", 0)),
	])
	file.store_line("resource\ttier\tscore\tinstances\treferences\tfiles")
	for row_value in rows:
		var row: Dictionary = row_value as Dictionary
		file.store_line("%s\t%s\t%d\t%d\t%d\t%d" % [
			str(row.get("resource", "")),
			str(row.get("tier", "")),
			int(row.get("score", 0)),
			int(row.get("instances", 0)),
			int(row.get("references", 0)),
			int(row.get("file_count", 0)),
		])
	file.close()
	print("Saved optimization report: ", abs_out)
