param($pTriggerName, $pTo, $pLookBackMins)

$LookBack = [DateTime]::Now.AddMinutes(-$pLookBackMins)

Write-Host "Jams Server: " + $JAMSDefaultServer

$pFolderPath = "<<pFolderPath>>" ## to pick up if pFolderPath contains a variable such as <<JAMS.Setup.ParentFolderName>>
Write-Host "Looking back " + $pLookBackMins + " mins at trigger " + $pTriggerName + " in folder " + $pFolderPath
$TriggerLastFired = (Get-childitem JD:\$pFolderPath\$pTriggerName).LastFired
$pTriggerName + " has fired on " + $TriggerLastFired.datetime

if ($TriggerLastFired -gt $LookBack)
	{ Write-Host "It fired so we're cool" }
Else
	{
	Write-Host "Trigger Not Fired. Composing Email"
	$ToArray=$pTo.split(";") ##split the input string into an array of email addresses, assuming seperation by ;
	
	$smtpServer = "<<gSMTPServer>>"
	$From = $JAMSDefaultServer + "@ageas50.co.uk"
	$Subject = "JAMS trigger " + $pTriggerName + " has not fired in the last " + $pLookBackMins + " minutes"
	$msgBody = "Something has failed to arrive/happen.<BR><BR><small>Sent by JAMS node " + $env:computername + "<BR>Setup <<JAMS.Setup.ParentFolderName>>\<<JAMS.Setup.Name>></small>"
	"SMTP Server: " + $smtpserver
	"To: " + $ToArray
	"From: " + $From
	"Subject: " + $Subject
	"Message: " $msgBody
	
	Send-MailMessage -To $ToArray -From $From -Subject $Subject -BodyAsHtml $msgBody -SMTPServer $smtpServer 
}





