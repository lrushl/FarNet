
<#
.SYNOPSIS
	Test Far decription tools.
	Author: Roman Kuzmin

.DESCRIPTION
	The script shows how to get or set Far descriptions and copy, move, rename
	files and directories with their descriptions updated.

	The script works in the $env:TEMP directory, it creates a directory and a
	few files in it. If test is passed all temporary items are removed.
#>

Import-Module FarDescription

### setup: make a test directory and a file in it
$dirPath = "$env:TEMP\Test-Descript"
$filePath = "$dirPath\File 1"
if (Test-Path $dirPath) {
	Remove-Item $dirPath\*
}
else {
	$null = New-Item -Path $dirPath -ItemType Directory
}
$null = New-Item -Path $filePath -ItemType File

### get the directory and file items
# these items have extra members:
# -- property FarDescript (both)
# -- method FarMoveTo() (both)
# -- method FarCopyTo() (file)
$dirItem = Get-Item $dirPath
$fileItem = Get-Item $filePath

### set descriptions (use not ASCII text)
$dirItem.FarDescription = 'Тест описания папки'
$fileItem.FarDescription = 'Тест описания файла'
if (!(Test-Path "$dirPath\Descript.ion")) { throw }
if (!(Test-Path "$env:TEMP\Descript.ion")) { throw }
if ($dirItem.FarDescription -ne 'Тест описания папки') { throw }
if ($fileItem.FarDescription -ne 'Тест описания файла') { throw }

### copy the file with description
$fileItem2 = $fileItem.FarCopyTo("$filePath.txt")
if ($fileItem2.FarDescription -ne 'Тест описания файла') { throw }

### move (rename) the file with description
$fileItem2.FarMoveTo("$filePath.tmp")
if ($fileItem2.Name -ne 'File 1.tmp') { throw }
if ($fileItem2.FarDescription -ne 'Тест описания файла') { throw }

### drop the 1st file description; test 2nd file description
$fileItem.FarDescription = ''
if ($fileItem.FarDescription) { throw }
if (!(Test-Path "$dirPath\Descript.ion")) { throw }
if ($fileItem2.FarDescription -ne 'Тест описания файла') { throw }

### drop the 2nd file description; Descript.ion is dropped, too
$fileItem2.FarDescription = ''
if ($fileItem2.FarDescription) { throw }
if (Test-Path "$dirPath\Descript.ion") { throw }

### set the 1st description, then delete the file; Descript.ion is created, then dropped
$fileItem.FarDescription = 'Тест удаления с описанием'
if (!(Test-Path "$dirPath\Descript.ion")) { throw }
if ($fileItem.FarDescription -ne 'Тест удаления с описанием') { throw }
$fileItem.FarDelete()
if ($fileItem.FarDescription) { throw }
if (Test-Path "$dirPath\Descript.ion") { throw }

### move (rename) the directory with description
$dirItem.FarMoveTo("$dirPath.2")
if ($dirItem.Name -ne 'Test-Descript.2') { throw }
if ($dirItem.FarDescription -ne 'Тест описания папки') { throw }

### drop the directory description
$dirItem.FarDescription = ''
if ($dirItem.FarDescription) { throw }

### end
Remove-Item $dirItem.FullName -Recurse
'Test-Descript- has passed'
