##############################################################################
# Script        : Copy_HostKeys.dat
# Purpose       : "@(#) Purpose: Send HostKeys.dat file to standby server"
# Contributor   : 2016 United Natural Foods, Inc.
# Control       : "@(#) Revision: 1.0.0"
# Description   : Copies the HostKeys.dat file for SSH from the active to the
#               : standby server
# History       : 2016/01/15 - 1.0.0 - PWM - Created
##############################################################################

# Load the JAMS module
import-module jams

# Retrieve the current failover status
$status = get-jamsfailoverstatus -server localhost

# Only perform this activity if this is the ACTIVE node
if ($status.Status.Trim(" ") = "Active") {
	if ($status.Role = "Secondary") {
		# If this server is the Secondary server, our target will be the Primary.
		$target = $status.Primary.Trim(" ")
  } else {
		# If this server is the Primary server, our target will be the Secondary.
		$target = $status.Secondary.Trim(" ")
  }

  # Search for the HostKeys.dat file on the local system
  $sourceHostKeys = Get-ChildItem -Path "C:\ProgramData\IsolatedStorage" -Recurse -File -Force -Filter 'HostKeys.dat'
  # Search for the AssemFiles directory on the target system
  $targetHostKeys = Get-ChildItem -Path "\\$target\c$\ProgramData\IsolatedStorage" -Recurse -Directory -Force -Filter 'AssemFiles'

	# Copy the HostKeys.dat file to the target directory
  Copy-Item $sourceHostKeys.FullName $targetHostKeys.FullName
}
