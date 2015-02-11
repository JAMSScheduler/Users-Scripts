add-pssnapin mvpsi.jams
#Set-PSDebug -Trace 1



# had to do this once on each server to import the module that allows for cluster commands execution
#Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
#Import-Module FailoverClusters


#  OK, so this portion gets the SQL cluster information from the all servers in the SQL cluster at SAMC.  It then stores
#  this info into the variables clustername_INFO.  Info in these variables are the SQL server\instances that are currently
#  running on the node in the cluster.  Once that data has been stored in the variables, then the actual backup for
#  the databases in the instances are kicked off

$ccluster="x"
$bigstring="x"
get-clusternode | foreach {
   
   switch ($ccluster)
   {
      PINTSQLCLSTR1 { Set-JAMSVariable -Name PINTSQLCLSTR1_INFO -Value "$bigstring"}
      PINTSQLCLSTR2 { Set-JAMSVariable -Name PINTSQLCLSTR2_INFO -Value "$bigstring"}
      PINTSQLCLSTR5 { Set-JAMSVariable -Name PINTSQLCLSTR5_INFO -Value "$bigstring"}
   }

   $bigstring = "CLUSTER,$_|"
   $ccluster="$_"

   
   get-clusternode "$_" | get-clusterresource | Where-Object {$_.Name -like "*SQL Network Name*"} | Format-Table -Wrap -AutoSize | out-string -stream | foreach {
      if ($_ -Match "SQL Network Name") 
      { 
          while ($_.Contains("  ")){
             $_ = $_ -replace "  "," "
           }
          
          $server=$_.Split(" ")[3]
          $server = $server -replace "\(",""
          $server = $server -replace "\)",""
          $instance=$_.Split(" ")[7]
          $instance = $instance -replace "\(",""
          $instance = $instance -replace "\)",""
          
          $bigstring += "SERVER,$server|INSTANCE,$instance|"
          write-host "BIGSTRING: $bigstring"
      }
   }
   
  
     
  } 
  switch ($ccluster)
   {
      PINTSQLCLSTR1 { Set-JAMSVariable -Name PINTSQLCLSTR1_INFO -Value "$bigstring"}
      PINTSQLCLSTR2 { Set-JAMSVariable -Name PINTSQLCLSTR2_INFO -Value "$bigstring"}
      PINTSQLCLSTR5 { Set-JAMSVariable -Name PINTSQLCLSTR5_INFO -Value "$bigstring"}
   }

#  SO... the data has been stored, now kick off the jams job that will perform the actual backups.


Submit-JAMSEntry -Agent PINTSQLCLSTR1 -Name DB_BACKUPS\WIN_SQLCLUSTER_dynamic_backup -UserName jamsmo
Submit-JAMSEntry -Agent PINTSQLCLSTR2 -Name DB_BACKUPS\WIN_SQLCLUSTER_dynamic_backup -UserName jamsmo
Submit-JAMSEntry -Agent PINTSQLCLSTR5 -Name DB_BACKUPS\WIN_SQLCLUSTER_dynamic_backup -UserName jamsmo
