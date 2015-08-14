param($pTo,$pAttachments,$pMsgBody,$pFrom, $pSubject,$pHyperlink)

$smtpServer = "<<gSMTPServer>>"

$msgBody=$pMsgBody + "<BR><a href=""" + $pHyperlink + """>" + $pHyperlink + "</a><BR><BR><small>Sent by JAMS node " + $env:computername + "<BR>Setup <<JAMS.Setup.ParentFolderName>>\<<JAMS.Setup.Name>></small>"
$ToArray=$pTo.split(";") ##split the list of e-mail addresses into an array of string recipients bases on ;
"SMTP Server: " + $smtpserver
"To: " + $ToArray
"From: " + $pFrom
"Subject: " + $pSubject
"Attachments: " + $pAttachments
"Message: "
$msgBody
if ($pAttachments -eq "")
	{ Send-MailMessage -To $ToArray -From $pFrom -Subject $pSubject -BodyAsHtml $msgBody -SMTPServer $smtpServer }
Else
	{ Send-MailMessage -To $ToArray -From $pFrom -Subject $pSubject -BodyAsHtml $msgBody -SMTPServer $smtpServer -Attachments $pAttachments}


