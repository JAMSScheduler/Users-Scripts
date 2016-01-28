#############################################################################

# Purpose       : "@(#) Purpose: Notification Job that emails BMC Remedy"

# Contributor   : 2016 United Natural Foods, Inc.

# Control       : "@(#) Revision: 2.0.1"

# History       : 2016/01/15 - 1.0.0 - KAV - Created

#               : 2016/01/15 - 2.0.0 - PWM - Heavily hacked upon

#               : 2016/01/22 - 2.0.1 - PWM - Introduced Recovery Instructions

#############################################################################

#

# CONFIGURATION

# Parameters on this job to be defined:

#   SendAs          - Fully qualified email address to send the email as.

#   SMTPServer      - Email server to use as a relay host.

#   CriticalAddress - Email address to send Critical priority alerts to.

#   HighAddress     - Email address to send High priority alerts to.

#   MediumAddres    - Email address to send Medium priority alerts to.

#

# Other parameters/variables to be defined:

#   AssignmentGroup - Group to assign the ticket to.

#   Priority        - The priority to assign to the ticket.

#   Threshold       - How many consecutive failures before opening a ticket.

#   Unique          - True:  The ticket should only be cut the first time the

#                            threshold is reached.

#                     False: A ticket should be cut every time the threshold

#                            is reached. This is determined via a modulus

#                            operation on the consecutive failures against

#                            the threshold definition.

#

#    These may be defined on any of the following, in reducing priority:

#      1. Parameter on the Executing Job

#      2. Variable in the directory for the Executing Setup

#      3. Variable in the parent directory for the Executing Setup

#      4. Continue through the parent directory tree through the root

#         directory

#      5. Failure to find a configuration will result in a value of "not

#         found"

#

# EXECUTION

# This script will take action based on the values presented in the provided

# configuration. The end result is sending an email to the appropriate

# recipient based on the priority setting. Included in the email will be the

# following criteria:

#

#   From: <defined sender>

#   To: <defined recipient>

#   Subject: Failed job: \path\to\failed\job\example_job

#   Job failure identified at 01/22/2016 08:34:12 AM

#

#   Job name : example_job

#   Entry ID : 1234

#   Job location : \path\to\failed\job

#   Setup name : example_setup

#   Setup location : \path\to\failed\setup

#   Exit status : fail

#   Exit severity : Error

#   Exit code : 1

#   Last success : 01/22/2016 07:35:00 AM

#   Error count since : 1

#

#   Log is attached

#

#   ======Job Recovery Instructions======

#   <contents of Recovery Instructions for the job>

#

#   ======Setup Recovery Instructions======

#   <contents of Recovery Instructions for the setup>

#

#   ASSIGNED PRIORITY : <priority setting>

#   ASSIGNED GROUP : <assignmentgroup setting>

#

# Note that the Recovery Instructions for both the job and the setup are

# included in the email. Additionally, the log for the failed job is also

# attached.

#############################################################################


Import-Module JAMS


$jobName                   = "<<JAMS.NOTIFY.JOBNAME>>";

$jamsEntry                 = "<<JAMS.NOTIFY.JAMSENTRY>>";

$setupName                 = "<<JAMS.NOTIFY.SETUP.NAME>>";

$finalStatus               = "<<JAMS.NOTIFY.FINALSTATUS>>";

$finalSeverity             = "<<JAMS.NOTIFY.FINALSEVERITY>>";

$finalStatusCode           = "<<JAMS.NOTIFY.FINALSTATUSCODE>>";

$jobLocation               = "<<JAMS.NOTIFY.JOB.PARENTFOLDER.QUALIFIEDNAME>>";

$setupLocation             = "<<JAMS.NOTIFY.SETUP.PARENTFOLDER.QUALIFIEDNAME>>";

$logFile                   = "<<JAMS.NOTIFY.LOGFILENAME>>";

$lastSuccess               = '<<JAMS.NOTIFY.LASTSUCCESS("MM/dd/yyyy HH:mm:ss")>>';

$jobRecoveryInstructions   = "<<JAMS.NOTIFY.JOB.RECOVERYINSTRUCTIONS>>";

$setupRecoveryInstructions = "<<JAMS.NOTIFY.SETUP.RECOVERYINSTRUCTIONS>>";


$JAMSServer      = "localhost";

$senderAddress   = "<<SendAs>>";          # Who to send an email as

$smtpServer      = "<<SMTPServer>>";      # Server to relay email through

$criticalAddress = "<<CriticalAddress>>"; # Recipient for Critical alerts

$highAddress     = "<<HighAddress>>";     # Recipient for High alerts

$mediumAddress   = "<<MediumAddress>>";   # Recipient for Medium alerts


# Name the configurations to use

$groupVar        = "AssignmentGroup"; # Who to assign the ticket to

$priorityVar     = "Priority";        # Critical, High, Medium

$thresholdVar    = "Threshold";       # How many errors to encounter before

                                      #   sending an email?

$uniqueVar       = "Unique";          # True or False


#############################################################################

# Function: find_configuration

# Parameters: cname - The name of the configuration to look for

#             spath - the path to search for the configuration as a variable

# Description:

#  This function will consult the job that executed for a parameter matching

#  the cname value. If it is not found on the job it will search recursively

#  search from the directory the setup is located in up to the root directory.

#  Failure to find a match will return the value "not found"

#############################################################################

function find_configuration([string]$cname, [string]$spath)

{

    if (! $spath) {

        # We are trying for the parameter with this attempt

        $value = Get-JAMSParameter -Entry $jamsEntry -Server $JAMSServer -Name $cname -ErrorAction SilentlyContinue;

        if (! $value) {

            # Must not be there - look for the variable by providing the location to search

            return find_configuration $cname $setupLocation;

        }

        return $value; # otherwise we found it as a parameter - return the value

    } else {

        # We are trying for the variable with this attempt

        $variables = Get-ChildItem -path JAMS::${JAMSServer}${spath} -ObjectType variable | Where-Object { $_.name -eq $cname };

      	if ($variables.Count -gt 0) {

            # Variable was found - return

	          return $variables.Value;

	      } else {

	          # We didn't find it - recurse to the parent of the current directory

            # If the current directory is the root, just return the default

	          if ($spath -eq '\') {

      		      return "not found";

	          } else {

                # Recurse into the parent - split the path, drop the last element, rejoin it

		            [System.Collections.ArrayList]$components = $spath.split('\');

		            $components.RemoveAt($components.count - 1);

		            $newpath = $components -join '\';

		            if ($newpath -eq '') {

                    # If the new path is blank, it means we want the root directory

		                $newpath = '\';

		            }

                # Check for the variable in the new path

		            return find_configuration $cname $newpath;

	          }

	      }

    }

}


# Write the operating environment out to the log


write-host "job name          = $jobName";

write-host "job entry         = $jamsEntry";

write-host "setup name        = $setupName";

write-host "job status        = $finalStatus";

write-host "job severity      = $finalSeverity";

write-host "job status code   = $finalStatusCode";

write-host "job location      = $jobLocation";

write-host "setup location    = $setupLocation";

write-host "log file location = $logFile";


# Load the configurations


$assignmentGroup = find_configuration $groupVar;

$priority        = find_configuration $priorityVar;

$threshold       = find_configuration $thresholdVar;

$unique          = find_configuration $uniqueVar;


# Write to the log when the last successful execution was

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


# Write to the log the number of failed jobs and the recovery instructions

write-host "consecutive fails = $badJobs";

write-host "job recovery instructions:`n$jobRecoveryInstructions";

write-host "setup recovery instructions:`n$setupRecoveryInstructions";


# Should we send a ticket?

if (($badJobs -eq $threshold) -or (($badJobs % $threshold -eq 0) -and (! $unique))) {

    # Yes - build the body

    $body = ("Job failure identified at " + (Get-Date) + "`n" +

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

              "======Job Recovery Instructions======`n$jobRecoveryInstructions`n`n" +

              "======Setup Recovery Instructions======`n$setupRecoveryInstructions`n`n" +

              "ASSIGNED PRIORITY : $priority`n" +

              "ASSIGNMENT GROUP : $assignmentGroup`n");


    # Determine the recipient to use based on the priority

    if ($priority -eq "Critical") {

        $toAddress = $criticalAddress;

    } elseif ($priority -eq "High") {

        $toAddress = $highAddress;

    } else {

        $toAddress = $mediumAddress;

    }


    # Write to the log that an email is being sent

    write-host "Sending email to $toAddress as $priority";


    # Send the email

    send-mailmessage -to $toAddress -smtpserver $smtpServer -from $senderAddress -subject "Failed job: $jobLocation\$jobName" -body "$body" -attachments $logFile;

} else {

    # We are not sending an email, so just log that

    write-host "Will not send email due to unfulfilled requirements";

}
