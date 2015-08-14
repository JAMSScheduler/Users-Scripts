$pSourceFolder = "<<pSourceFolder>>"
$pSourceFiles = "<<pSourceFolder>>\<<pFileSpec>>"
$pDestinationFolder = "<<pDestinationFolder>>"

Write-Host "Checking if path exists: " + $pDestinationFolder
If ((test-path $pDestinationFolder) -eq 0)
{
	Write-Host "It Doesn't. Creating folder"
	New-Item -ItemType directory -Path $pDestinationFolder
}

Write-Host "Moving files from " + $pSourceFiles + " to " + $pDestinationFolder
Move-Item $pSourceFiles $pDestinationFolder -verbose -ErrorAction SilentlyContinue
