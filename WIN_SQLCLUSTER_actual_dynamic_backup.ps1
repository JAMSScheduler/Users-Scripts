add-pssnapin mvpsi.jams


  


$WHOST=hostname


write-host $WHOST

$a = Get-JAMSVariable -name ${WHOST}_INFO -ValueOnly
write-host "Using config file: $a"
cd c:\progra~1\Tivoli\tsm\tdpsql
$DoW=[Int] (Get-Date).DayOfWeek
if($DoW -eq 0)
{
   write-host "Doing a full backup"
   ./tdpsqlc backup * FULL /config=$a
} else
{
   write-host "Doing a differential backup"
   ./tdpsqlc backup * DIFF /config=$a
}
