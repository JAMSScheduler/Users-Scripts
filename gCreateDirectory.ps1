param($pDirectoryPath)

Write-Host "Checking if path exists: " + $pDirectoryPath

If ((test-path $pDirectoryPath) -eq 0)
{
	Write-Host "It Doesn't. Creating folder"
	New-Item -ItemType directory -Path $pDirectoryPath
}