:Connect <<pSQLServerName>>
Print @@Servername
Print 'Backing up [<<pDBName>>] to K:\SQLBackup\<<pDBName>>.bak'
BACKUP DATABASE [<<pDBName>>] TO  DISK = N'K:\sqlbackup\<<pDBName>>.bak' WITH NOFORMAT, INIT,  NAME = N'<<pDBName>>-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10, CHECKSUM
GO