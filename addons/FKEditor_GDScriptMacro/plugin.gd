# Created by Freeknight
# Date: 2021/12/10
# Desc： 代码宏
# @category: main
#--------------------------------------------------------------------------------------------------
tool
extends EditorPlugin
### Member Variables and Dependencies -------------------------------------------------------------
#--- signals --------------------------------------------------------------------------------------
#--- enums ----------------------------------------------------------------------------------------
#--- constants ------------------------------------------------------------------------------------
const MACRO_PATH := "res://addons/FKEditor_GDScriptMacro/Macros.txt"
#--- public variables - order: export > normal var > onready --------------------------------------
var script_editor : TextEdit
var macroStr := {}
var macroArgs := {}
var macroDate : int
#--- private variables - order: export > normal var > onready -------------------------------------
var _is_useful := false
var _cursor_line := -1
### -----------------------------------------------------------------------------------------------

### Built in Engine Methods -----------------------------------------------------------------------
func _enter_tree():
	_is_useful = true
	pass
# ------------------------------------------------------------------------------
func _exit_tree():
	_is_useful = false
	pass
# ------------------------------------------------------------------------------
func _init_macro_file() -> void:
	var file := File.new()

	var date := file.get_modified_time(MACRO_PATH)
	if date == macroDate:
		return
	macroDate = date

	file.open(MACRO_PATH, File.READ)
	var keyword : String

	while true:
		var line := file.get_line()
		if line.begins_with("[macro]"):
			if keyword:
				macroStr[keyword] = macroStr[keyword].trim_suffix("\n")
			# 新Keyword
			keyword = line.trim_prefix("[macro]")
			# 提取参数
			var splitLine : Array = Array(keyword.split(" ", false))
			keyword = splitLine.pop_front()
			# 参数列表
			macroArgs[keyword] = []
			for i in splitLine:
				macroArgs[keyword].append(i)
			macroStr[keyword] = ""
		else:
			if !file.eof_reached():
				if keyword:
					macroStr[keyword] += line + "\n"
			else:
				if keyword:
					macroStr[keyword] += line
				break
	file.close()
# ------------------------------------------------------------------------------
func _ready():
	get_viewport().connect("gui_focus_changed", self, "_on_gui_focus_changed")
	_init_macro_file()
# ------------------------------------------------------------------------------
func _notification(what: int):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		_init_macro_file()
# ------------------------------------------------------------------------------
func _on_cursor_changed():
	if !_is_useful:
		return
	if is_instance_valid(script_editor):
		if _cursor_line != script_editor.cursor_get_line():
			check_macro(_cursor_line)
			_cursor_line = script_editor.cursor_get_line()
# ------------------------------------------------------------------------------
func _on_gui_focus_changed(node: Node):
	if !_is_useful:
		return
	if node is TextEdit:
		if is_instance_valid(script_editor):
			script_editor.disconnect("cursor_changed", self, "_on_cursor_changed")
		script_editor = node
		script_editor.connect("cursor_changed", self, "_on_cursor_changed")
### -----------------------------------------------------------------------------------------------

### Public Methods --------------------------------------------------------------------------------
func check_macro(line: int) -> void:
	var writtenLine := script_editor.get_line(line)

	var keyword = writtenLine.strip_edges(true, true)
	var splitLine = Array(keyword.split(" ", false))
	keyword = splitLine.pop_front()
	var givenArgs = splitLine
	if macroStr.has(keyword):
		if givenArgs.size() != macroArgs[keyword].size(): 
			return
		var constructLine = writtenLine
		var indent = get_indentation(writtenLine)
		constructLine = indent + macroStr[keyword]
		constructLine = constructLine.replace('\n', '\n' + indent)
		if macroArgs.has(keyword):
			for i in givenArgs.size():
				constructLine = constructLine.replace(macroArgs[keyword][i], givenArgs[i])
		script_editor.set_line(line, constructLine)

		if constructLine.ends_with("\n"):
			script_editor.cursor_set_line(line+1)
# ------------------------------------------------------------------------------
func get_indentation(string: String) -> String:
	var indentation := ""
	for i in string:
		if i == '\t' or i == ' ':
			indentation += i
		else:
			break
	return indentation
### -----------------------------------------------------------------------------------------------

### Private Methods -------------------------------------------------------------------------------
### -----------------------------------------------------------------------------------------------
