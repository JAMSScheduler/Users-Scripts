##############################################################################

# Purpose       : "@(#) Purpose: Notification Job that emails BMC Remedy"

# Contributor   : 2016 United Natural Foods, Inc.

# Control       : "@(#) Revision: 1.0.0"

# History       : 2016/01/15 - 1.0.0 - KAV - Created

#               : 2016/01/15 - 2.0.0 - PWM - Heavily hacked upon

##############################################################################


Import-Module JAMS


$jobName         = "<<JAMS.NOTIFY.JOBNAME>>"

$jamsEntry       = "<<JAMS.NOTIFY.JAMSENTRY>>"

$setupName       = "<<JAMS.NOTIFY.SETUP.NAME>>"

$finalStatus     = "<<JAMS.NOTIFY.FINALSTATUS>>"

$finalSeverity   = "<<JAMS.NOTIFY.FINALSEVERITY>>"

$finalStatusCode = "<<JAMS.NOTIFY.FINALSTATUSCODE>>"

$jobLocation     = "<<JAMS.NOTIFY.JOB.PARENTFOLDER.QUALIFIEDNAME>>"

$setupLocation   = "<<JAMS.NOTIFY.SETUP.PARENTFOLDER.QUALIFIEDNAME>>"

$logFile         = "<<JAMS.NOTIFY.LOGFILENAME>>"

$lastSuccess     = '<<JAMS.NOTIFY.LASTSUCCESS("MM/dd/yyyy HH:mm:ss")>>'



$JAMSServer      = "<<JAMS.SMTPServer>>";

$senderAddress   = "<<SendAs>>";

$smtpServer      = "<<SMTPServer>>";

$criticalAddress = "<<CriticalAddress>>";

$highAddress     = "<<HighAddress>>";

$mediumAddress   = "<<MediumAddress>>";

$groupVar        = "AssignmentGroup";

$priorityVar     = "Priority";      # Critical, High, Medium

$thresholdVar    = "Threshold";     # How many errors to encounter before

                                    # sending an email

$uniqueVar       = "Unique";        # Yes, No


function find_parameter([string]$pname, [string]$fpath)

{

    if (! $fpath) {

        # We are trying for the parameter with this attempt

        $value = Get-JAMSParameter -Entry $jamsEntry -Server $JAMSServer -Name $pname -ErrorAction SilentlyContinue;

        if (! $value) {

            # Must not be there - look for the variable by providing the location to search

            return find_parameter $pname $setupLocation;

        }

        return $value; # otherwise we found it as a parameter - return the value

    } else {

        # We are trying for the variable with this attempt

        $variables = Get-ChildItem -path JAMS::${JAMSServer}${fpath} -ObjectType variable | Where-Object { $_.name -eq $pname };

      	if ($variables.Count -gt 0) {

            # Variable was found - return

	          return $variables.Value;

	      } else {

	          # We didn't find it - recurse to the parent of the current directory

            # If the current directory is the root, just return the default

	          if ($fpath -eq '\') {

      		      return "not found";

	          } else {

                # Recurse into the parent - split the path, drop the last element, rejoin it

		            [System.Collections.ArrayList]$components = $fpath.split('\');

		            $components.RemoveAt($components.count - 1);

		            $newpath = $components -join '\';

		            if ($newpath -eq '') {

                    # If the new path is blank, it means we want the root directory

		                $newpath = '\';

		            }

                # Check for the variable in the new path

		            return find_parameter $pname $newpath;

	          }

	      }

    }

}


write-host "job name          = $jobName";

write-host "job entry         = $jamsEntry";

write-host "setup name        = $setupName";

write-host "job status        = $finalStatus";

write-host "job severity      = $finalSeverity";

write-host "job status code   = $finalStatusCode";

write-host "job location      = $jobLocation";

write-host "setup location    = $setupLocation";

write-host "log file location = $logFile";


# Load the variables


$assignmentGroup = find_parameter($groupVar);

$priority        = find_parameter($priorityVar);

$threshold       = find_parameter($thresholdVar);

$unique          = find_parameter($uniqueVar);


if ($lastSuccess -like "*LASTSUCCESS*") {

    # We've never had a successful run, so we'll just pull the last 24 hours

    $lastSuccess     = (Get-Date).adddays(-1);

    $neverSuccessful = $True;

    write-host "Never successful"

    write-host "24 hour pull      = $lastSuccess";

} else {

    $neverSuccessful = $False;

    write-host "last success      = $lastSuccess";

}


# Get the count of bad jobs since the last successful run

$badJobs = (get-jamshistory -server $JAMSServer -name $jobName -setupName $setupName -setupFolderName $setupLocation -startDate $lastSuccess -status Bad).Count;


write-host "consecutive fails = $badJobs";


# Should we send a ticket?

if (($badJobs -eq $threshold) -or (($badJobs % $threshold -eq 0) -and (! $unique))) {

    $body = ("Job failure identified at " + (Get-Date) + "`n`n" +

             "Job name : $jobName`n" +

             "Entry ID : $jamsEntry`n" +

             "Job location : $jobLocation`n" +

             "Setup name : $setupName`n" +

             "Setup location : $setupLocation`n" +

             "Exit status : $finalStatus`n" +

             "Exit severity : $finalSeverity`n" +

             "Exit code : $finalStatusCode`n");

    if ($neverSuccessful) {

        $body += ("Last success : never`n" +

                  "24 hour error count : $badJobs`n");

    } else {

        $body += ("Last success : $lastSuccess`n" +

                  "Error count since : $badJobs`n");

    }

    $body += ("`nLog is attached`n`n" +

              "ASSIGNED SEVERITY : $priority`n" +

              "ASSIGNMENT GROUP : $assignmentGroup`n");

             

    if ($priority -eq "Critical") {

        $toAddress = $criticalAddress;

    } elseif ($priority -eq "High") {

        $toAddress = $highAddress;

    } else {

        $toAddress = $mediumAddress;

    }


    write-host "Sending email to $toAddress as $priority";

    send-mailmessage -to $toAddress -smtpserver $smtpServer -from $senderAddress -subject "Failed job: $jobLocation\$jobName" -body $body -attachments $logFile;

} else {

    write-host "Will not send email due to unfulfilled requirements";

}
