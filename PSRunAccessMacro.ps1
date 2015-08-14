param($pFolderPath, $pAccessDB, $pMacro, $pComputerName)

$AccessPath=$pFolderPath + "\" + $pAccessDB
Write-Host "Checking for existence of MS Access DB: " + $AccessPath

if (test-path $AccessPath)
{
	Write-Host "It exists"
	Write-Host "Getting User Credentials"
	[System.Management.Automation.PSCredential]$userCredentials = Get-JAMSCredential -username svcMIAccess

	Write-Host "Got credentials for user: " + $userCredentials.username
	Write-Host "Establishing a remote Powershell session to " + $pComputerName
	
	$Session=new-PSSession -ComputerName $pComputerName -Authentication CredSSP -Credential $userCredentials <#Need CredSSP to access network shares#>
	
	Write-Host "Confirming delegated security account by giving directory listing of network share"
	invoke-command -Session $Session {param($pFolderPath) dir $pFolderPath} -ArgumentList $pFolderPath
	
	Write-Host "Opening MS Access"
	invoke-command -Session $Session {$MSAccess=New-Object -ComObject access.application}
	<# "Making it visible"
	invoke-command -Session $Session {$MSAccess.visible=$True} #>
		
	Write-Host "Opening database: " + $AccessPath
	invoke-command -Session $Session {param($AccessPath) $MSAccess.OpenCurrentDatabase($AccessPath)} -ArgumentList $AccessPath
	Write-Host "Running Macro " + $pMacro
	invoke-command -Session $Session {param($pMacro) $MSAccess.docmd.runmacro($pMacro)} -ArgumentList $pMacro 
	
	invoke-command -Session $Session {$MSAccess.CloseCurrentDatabase()}
	Write-Host "Quitting MS Access"
	invoke-command -Session $Session {$MSAccess.Quit()}
	
	Write-Host "Removing Session"
	Remove-PSSession -Session $Session
}
else
	{ throw [System.IO.FileNotFoundException]("Cannot find Access database:" + $AccessPath) }
