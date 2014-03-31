function ExpandZipArchive {
param (
	$File,
	$Destination
)	
	$archivePath = Resolve-Path $File
	$7zip = Resolve-Path $PSScriptRoot\..\Tools\7za.exe

	$arguments = "x -o`"$Destination`" -y `"$archivePath`""
    $process = [Diagnostics.Process]::Start($7zip, "x -o`"$Destination`" -y `"$archivePath`"")
    $process.WaitForExit()
}
