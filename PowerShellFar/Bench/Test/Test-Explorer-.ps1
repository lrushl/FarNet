
<#
.SYNOPSIS
	Test scripted explorers with panels.
	Author: Roman Kuzmin

.DESCRIPTION
	PowerExplorer is the fully functional explorer designed for scripts. Interface
	methods have related script block properties. Each method calls its script.

	This script shows a complex tree with explorers depending on top nodes.
	Technical details are explained in comments.

	It is important for testing that two explorers use the same source data. As
	a result, the FarNet search panel contains a lot of files with same names.
	This is a tough case for native panels but it works fine in FarNet panels.

.EXAMPLE
	Examples show how Start-FarSearch works with this panel:

	# Invoke from Flat or use -Recurse from Root:
	>: Start-FarSearch *help*
	>: Start-FarSearch { $_.Data.Definition -match 'throw' }

	# Invoke from Root: the 1st uses -Mask, the 2nd uses -Script:
	>: Start-FarSearch -Recurse -Directory *explore*
	>: Start-FarSearch -Recurse -Directory { $_.Name -like *explore* }
#>

# Root explorer - complex data tree with different explorers. It works like a
# menu where each item opens a different explorer in its own child panel.
function global:New-TestRootExplorer
{
	New-Object PowerShellFar.PowerExplorer '4fba4f3c-00c3-4aa1-be67-893fba6b9e29' -Property @{
		Location = 'Root'
		AsGetFiles = {
			New-FarFile -Name 'Flat' -Description 'Flat explorer' -Attributes 'Directory'
			New-FarFile -Name 'Tree' -Description 'Tree explorer' -Attributes 'Directory'
			New-FarFile -Name 'Path' -Description 'Path explorer' -Attributes 'Directory'
			New-FarFile -Name 'Location' -Description 'Location explorer' -Attributes 'Directory'
		}
		AsExploreDirectory = {
			switch($_.File.Name) {
				'Flat' { New-TestFlatExplorer }
				'Tree' { New-TestTreeExplorer HKCU:\Software\Far2\Plugins }
				'Path' { New-TestPathExplorer $env:FARHOME\FarNet }
				'Location' { New-TestLocationExplorer $env:FARHOME\FarNet }
			}
		}
		AsCreatePanel = {
			New-Object FarNet.Panel $this -Property @{
				Title = 'Root'
				ViewMode = 'Descriptions'
				SortMode = 'Unsorted'
			}
		}
	}
}

# Flat data explorer. It is designed to show just one panel with some files,
# that is why it does not have the AsExploreX scripts.
# *) It allows to edit, view, and [CtrlQ] by AsExportFile and AsImportFile.
# *) Editors/viewers are not modal and work even when the panel has closed.
function global:New-TestFlatExplorer
{
	New-Object PowerShellFar.PowerExplorer '0024d0b7-c96d-443b-881a-d7f221182386' -Property @{
		Functions = 'DeleteFiles, ExportFile, ImportText'
		Location = 'Flat'
		# Files are PowerShell functions
		AsGetFiles = {
			Get-ChildItem Function: | %{ New-FarFile -Name $_.Name -Description $_.Definition -Data $_ }
		}
		# Deletes selected functions
		AsDeleteFiles = {
			$_.Files | Remove-Item -LiteralPath { "Function:\$($_.Name)" }
		}
		# Allows to edit, view and [CtrlQ] the function definition
		AsExportFile = {
			$_.CanImport = $this.AsImportText -ne $null # for testing
			$_.UseText = $_.File.Data.Definition
			$_.UseFileExtension = '.ps1'
		}
		# Updates the function when it is edited
		AsImportText = {
			Set-Content "Function:\$($_.File.Name)" ($_.Text.TrimEnd())
		}
		# The panel
		AsCreatePanel = {
			New-Object FarNet.Panel $this -Property @{
				Title = 'Flat: Functions'
			}
		}
	}
}

# Tree explorer. It navigates through the data tree where each node panel is a
# child of its parent panel. The core knows how to navigate to parents or to
# the root, the explorer does not have to worry.
# Navigation notes (compare with the Path explorer):
# *) [Ctrl\] navigates to the Root panel.
# *) [Esc] is the same as [CtrlPgUp]: it opens the parent panel.
function global:New-TestTreeExplorer($Path)
{
	New-Object PowerShellFar.PowerExplorer 'ed2e169e-852d-4934-8ec2-ec10fec11acd' -Property @{
		Location = $Path
		# The files represent file system directories and files
		AsGetFiles = {
			Get-ChildItem $this.Location | %{
				New-FarFile $_.PSChildName -Attributes 'Directory' -Description "$($_.Property)" -Data $_
			}
		}
		# Gets another explorer for the requested directory
		AsExploreDirectory = {
			$_.NewPanel = $true
			New-TestTreeExplorer $_.File.Data.PSPath
		}
		# The panel
		AsCreatePanel = {
			New-Object FarNet.Panel $this -Property @{
				Title = "Tree: $($this.Location)"
			}
		}
	}
}

# Path explorer. It navigates through the data tree using paths. Navigation
# includes root and parent steps.
# Navigation notes (compare with the Tree explorer):
# *) [Ctrl\] navigates to the drive root, not to the Root panel.
# *) [Esc] closes the Path panel and opens the parent Root panel.
function global:New-TestPathExplorer($Path)
{
	New-Object PowerShellFar.PowerExplorer 'fd00a7cc-5ec1-4279-b659-541bbb5b2a00' -Property @{
		Functions = 'ExportFile, ImportFile'
		Location = $Path
		# The files represent file system directories and files
		AsGetFiles = {
			Get-ChildItem -LiteralPath $this.Location | New-FarFile
		}
		# Gets another explorer for the requested directory
		AsExploreDirectory = {
			New-TestPathExplorer $_.File.Data.FullName
		}
		# Gets the root explorer
		AsExploreRoot = {
			New-TestPathExplorer ([IO.Path]::GetPathRoot($this.Location))
		}
		# Gets the parent explorer or nothing
		AsExploreParent = {
			$path = [IO.Path]::GetDirectoryName($this.Location)
			if ($path) {
				New-TestPathExplorer $path
			}
		}
		# Allows to edit, view and [CtrlQ]
		AsExportFile = {
			$_.CanImport = $true
			$_.UseFileName = Join-Path $this.Location $_.File.Name
		}
		# Updates the panel title when explorers change
		AsEnterPanel = {
			$_.Title = "Path: $($this.Location)"
		}
	}
}

# Location explorer. It also navigates through the data tree using paths. But
# with the 'ExploreLocation' function it works with pure files with no data.
# Navigation notes are the same as for the "Path" example.
function global:New-TestLocationExplorer($Path)
{
	New-Object PowerShellFar.PowerExplorer '594e5d2e-1f00-4f25-902d-9464cba1d4a2' -Property @{
		Functions = 'ExploreLocation'
		Location = $Path
		# The files represent file system directories and files
		AsGetFiles = {
			Get-ChildItem -LiteralPath $this.Location | %{
				New-Object FarNet.SetFile $_, $false
			}
		}
		# Gets another explorer for the requested location
		AsExploreLocation = {
			$Path = if ($_.Location.Contains(':')) { $_.Location } else { Join-Path $this.Location $_.Location }
			New-TestLocationExplorer $Path
		}
		# Gets the parent explorer or nothing
		AsExploreParent = {
			$path = [IO.Path]::GetDirectoryName($this.Location)
			if ($path) {
				New-TestLocationExplorer $path
			}
		}
		# Gets the root explorer
		AsExploreRoot = {
			New-TestLocationExplorer ([IO.Path]::GetPathRoot($this.Location))
		}
		# Updates the panel title when explorers change
		AsEnterPanel = {
			$_.Title = "Location: $($this.Location)"
		}
	}
}

### Open the explorer panel
(New-TestRootExplorer).OpenPanel()