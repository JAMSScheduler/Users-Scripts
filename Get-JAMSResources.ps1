function Get-JAMSResources {
    pushd
    Invoke-Sqlcmd -ServerInstance <jams_db_server> -Database <jams_db_name> -Query "SELECT M.resource_name, M.qty_available, IsNull((select SUM(U.qty_in_use) from dbo.ResourceInUse as U where U.resource_id = M.resource_id), 0) as InUse FROM dbo.ResourceM as M"
    popd
}
