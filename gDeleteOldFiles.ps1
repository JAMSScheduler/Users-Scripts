$limit = (Get-Date).AddDays(-<<pNumberOfDays>>)
$path = "<<pShare>>\<<pFolder>>"
Write-Host "Looking for files older than <<pNumberOfDays>> in folder <<pShare>>\<<pFolder>>."
Write-Host "Recurse: <<pRecurse>>. WhatIf: <<pWhatIf>>. Delete Empty Folders:<<pDeleteEmptyFolders>>"

# Delete files older than the $limit.
Get-ChildItem -Path $path -Recurse:$<<pRecurse>> -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit } | Remove-Item -Force -WhatIf:$<<pWhatIf>> -verbose

# Delete any empty directories left behind after deleting the old files.
IF ($<<pDeleteEmptyFolders>> -eq $True)
{ 
	Write-Host "Deleting Empty SubFolders"
	Get-ChildItem -Path $path -Recurse:$<<pRecurse>> -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse -WhatIf:$<<pWhatIf>> -verbose
} 
