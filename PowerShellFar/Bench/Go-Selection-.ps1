
<#
.Synopsis
	Goes to the current selection start/end position
	Author: Roman Kuzmin

.Description
	Many popular editors on [Left]/[Right] put cursor to the start/end position
	of the selected text and drop the selection. The script does this in the
	current editor, command line, or edit box.

	Since the macro function Editor.Sel() exists macros are more effective for
	this job. The script is kept as an example.
#>

param
(
	[switch]$End
)

if ($Far.Window.Kind -eq 'Editor') {
	$Editor = $Far.Editor
	$Place = $Editor.SelectionPlace
	if ($Place.Top -ge 0) {
		if ($End) {
			$Editor.GoTo($Place.Right + 1, $Place.Bottom)
		}
		else {
			$Editor.GoTo($Place.Left, $Place.Top)
		}
		$Editor.UnselectText()
	}
}
else {
	$Line = $Far.Line
	if ($Line) {
		$span = $Line.SelectionSpan
		if ($span.Start -ge 0) {
			if ($End) {
				$Line.Caret = $span.End
			}
			else {
				$Line.Caret = $span.Start
			}
			$Line.UnselectText()
		}
	}
}
