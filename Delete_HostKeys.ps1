##############################################################################
# Script        : Delete_HostKeys.dat
# Purpose       : "@(#) Purpose: Delete HostKeys.dat file from Active server"
# Copyright     : 2016 United Natural Foods, Inc.
# Control       : "@(#) Revision: 1.0.0"
# Description   : Deletes the HostKeys.dat file from the Active server if needed
# History       : 2016/01/15 - 1.0.0 - PWM - Created
##############################################################################

# Load the JAMS module
import-module jams

# Retrieve the current failover status
$status = get-jamsfailoverstatus -server localhost

# Only perform this activity if this is the ACTIVE node
if ($status.Status.Trim(" ") = "Active") {
  # Search and delete the HostKeys.dat file on the local system
  Get-ChildItem -Path "C:\ProgramData\IsolatedStorage" -Recurse -File -Force -Filter 'HostKeys.dat' | Remove-Item
}
