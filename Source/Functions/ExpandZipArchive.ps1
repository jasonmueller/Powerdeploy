function ExpandZipArchive {
param (
	$File,
	$Destination
)	
	$archivePath = Resolve-Path $File
	$7zip = Resolve-Path $PSScriptRoot\..\Tools\7za.exe

	$arguments = "x -o`"$Destination`" -y `"$archivePath`""
    Start-Process "$7zip" -ArgumentList "x -o`"$Destination`" -y `"$archivePath`"" -Wait
}
