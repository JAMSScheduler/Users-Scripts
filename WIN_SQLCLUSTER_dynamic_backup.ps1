add-pssnapin mvpsi.jams

function dobackup
{
   write-host "==============================================================================="
   write-host "doing SQL backup for $server\$instance"
   write-host "==============================================================================="
   $global:NUM++

    # the following code simply creates the tdpsqlc config file that will be used The code following will set the actual 
    #  variable that the actual backup job will use to perform the backup, and the variable will be the actual config
    #  filename for that job to use.
   
   "LOCALDSMAgentnode sqlcluster1.samcmo.com" | Out-File c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii
   "BACKUPMETHod legacy" | Out-File -append c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii
   "ALWAYSONNode  SQLCLUSTER1" | Out-File -append c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii
   "BUFFERS 8" | Out-File -append c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii
   "BUFFERSIZE 8192" | Out-File -append c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii
   "SQLBUFFERS 24" | Out-File -append c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii
   "SQLBUFFERSIZE 4096" | Out-File -append c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii
   "SQLSERVER ${server}.SAMCMO.COM\${instance}" | Out-File -append c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii
   "FROMSQLserver SQLCLUSTER1.samcmo.com" | Out-File -append c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii
   "SqlCompression Yes" | Out-File -append c:\Progra~1\Tivoli\TSM\TDPSql\config${global:NUM}.cfg -encoding ascii


    # ok, so here, set the variable to reflect the actual config file to use for the actual backup.

    Set-JAMSVariable -name ${WHOST}_INFO -Value "config${global:NUM}.cfg"
    Submit-JAMSEntry -name WIN_SQLCLUSTER_actual_dynamic_backup -Agent ${WHOST} -UserName jamsmo
    Start-Sleep 30
}


$WHOST=hostname
$global:NUM=0

write-host $WHOST

$a = Get-JAMSVariable -name ${WHOST}_INFO -ValueOnly

$a.split("|") | foreach {
   $wa=$_.split(",")
   switch ($wa[0]){
      SERVER {$server=$wa[1];break}
      INSTANCE{$instance=$wa[1];dobackup;break}
   }
}
