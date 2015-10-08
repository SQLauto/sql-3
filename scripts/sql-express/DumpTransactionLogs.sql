USE [master]
GO
/****** Object:  StoredProcedure [dbo].[DumpTransactionLogs]    Script Date: 10/8/2015 12:34:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DumpTransactionLogs]
AS
BEGIN
	IF OBJECT_ID('tempdb..#TransactionLogFiles') IS NOT NULL DROP TABLE #TransactionLogFiles

CREATE TABLE #TransactionLogFiles (DatabaseName VARCHAR(150), LogFileName VARCHAR(150) )
-- step 1. get hold of the entire database names from the database server
DECLARE DataBaseList CURSOR FOR 
SELECT name FROM SYS.sysdatabases WHERE NAME NOT IN ('master','tempdb','model','msdb','distribution') AND [status] <> 512
DECLARE @DataBase VARCHAR(128)
DECLARE @SqlScript VARCHAR(MAX) 
-- step 2. insert all the database name and corresponding log files' names into the temp table
OPEN DataBaseList FETCH
NEXT FROM DataBaseList INTO @DataBase
WHILE @@FETCH_STATUS <> -1 
BEGIN

SET @SqlScript = 'USE [' + @DataBase + '] INSERT INTO #TransactionLogFiles(DatabaseName, LogFileName) SELECT '''
+ @DataBase + ''', Name FROM sysfiles WHERE FileID=2'
EXEC(@SqlScript) 
FETCH NEXT FROM DataBaseList INTO @DataBase END

DEALLOCATE DataBaseList

DECLARE TransactionLogList CURSOR FOR 
SELECT DatabaseName, LogFileName FROM #TransactionLogFiles 
DECLARE @LogFile VARCHAR(128) 

OPEN TransactionLogList FETCH
NEXT FROM TransactionLogList INTO @DataBase, @LogFile
WHILE @@FETCH_STATUS <> -1 
BEGIN 
	SELECT @SqlScript = 'USE [' + @DataBase + '] '
	+ 'ALTER DATABASE [' + @DataBase + '] SET RECOVERY SIMPLE WITH NO_WAIT '
	+ 'DBCC SHRINKFILE(N''' + @LogFile + ''', 1) '
	+ 'ALTER DATABASE [' + @DataBase + '] SET RECOVERY FULL WITH NO_WAIT'
EXEC(@SqlScript) 
--PRINT 'QUERY: ' + @SqlScript;

FETCH NEXT FROM TransactionLogList INTO @DataBase, @LogFile END
DEALLOCATE TransactionLogList
SELECT * FROM #TransactionLogFiles

-- step 4. clean up
DROP TABLE #TransactionLogFiles
END
