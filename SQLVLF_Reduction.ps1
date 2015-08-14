:connect <<pSQLServerName>>
print 'Executing on server: ' + @@ServerName

USE [<<pDatabase>>]
GO

DECLARE @query VARCHAR(1000) ,
    @count INT,
	  @file_name sysname ,
    @file_size INT ,
    @Chunk_Size INT ,
    @shrink_command NVARCHAR(MAX) ,
    @alter_command NVARCHAR(MAX)

CREATE TABLE #log_info
    (
      fileid TINYINT ,
      file_size BIGINT ,
      start_offset BIGINT ,
      FSeqNo INT ,
      [status] TINYINT ,
      parity TINYINT ,
      create_lsn NUMERIC(25, 0)
    )

SET @query = 'DBCC loginfo (' + '''' + DB_NAME() + ''') '

INSERT  INTO #log_info
        EXEC ( @query
            )

SET @count = @@rowcount

SELECT  DB_NAME() AS dbname ,
        @count AS num_of_VLFs
IF @Count > 50
    BEGIN
        SET @Chunk_Size = 0
        SELECT  @file_name = name ,
                @file_size = ( size / 128 )
        FROM    sys.database_files
        WHERE   type_desc = 'log'
        SELECT  @file_name AS LogFileName ,
                @file_size AS LogFileSizeMB
				
        IF @File_Size > 12000	--Large tran log so round up to next 4000MB
            SET @File_Size = ( (@File_Size-1) / 4000 ) * 4000 + 4000 --round up to next 4000MB			
        ELSE
            IF @File_Size > 6000 --Medium size to round up to next 1000MB
                SET @File_Size = ((@File_Size-1) / 1000 ) * 1000 + 1000 --round up to next 1000MB
            ELSE
                SET @File_Size = ( (@File_Size-1) / 100 ) * 100 + 100 --round up to next 100MB

        SELECT  @file_name AS LogFileName ,
                @file_size AS LogFileNewSizeMB
        SELECT  @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name
                + ''' , 0, TRUNCATEONLY)'
        RAISERROR (@shrink_command, 0, 1) WITH NOWAIT 
        EXEC sp_executesql @shrink_command

        SELECT  @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name
                + ''' , 0)'
        RAISERROR (@shrink_command, 0, 1) WITH NOWAIT 
        EXEC sp_executesql @shrink_command
        WHILE @Chunk_Size < @file_size
            BEGIN
                IF @File_Size - @Chunk_Size < 8000
                    SET @chunk_Size = @file_size 
                ELSE
                    SET @Chunk_Size = @Chunk_Size + 8000 --Grow in 8000MB chunks

                SELECT  @alter_command = 'ALTER DATABASE [' + DB_NAME()
                        + '] MODIFY FILE (NAME = N''' + @file_name
                        + ''', SIZE = ' + CAST(@chunk_size AS NVARCHAR)
                        + 'MB)'
                RAISERROR (@alter_command, 0, 1) WITH NOWAIT 
                EXEC sp_executesql @alter_command
            END

        INSERT  INTO #log_info
                EXEC ( @query
                    )

        SET @count = @@rowcount


        SELECT  DB_NAME() AS dbname ,
                @count AS num_of_VLFs
    END
DROP TABLE #log_info