IF EXISTS(SELECT 1 FROM sys.databases WHERE [name]='YourDB' AND UPPER(state_desc)='ONLINE')
BEGIN
    BACKUP LOG [YourDB] TO DISK = ''
    --, DISK = ''
    WITH COMPRESSION, STATS=5
    --, DIFFERENTIAL
    --, COPY_ONLY
 
    ALTER DATABASE [YourDB] SET OFFLINE WITH ROLLBACK IMMEDIATE
END
GO
 
RESTORE DATABASE [YourDB] FROM DISK=''
, DISK=''
WITH MOVE 'YourDB.mdf' TO 'filepath_to_mdf'
, MOVE 'YourDB.ndf' TO 'filepath_to_ndf'
, MOVE 'YourDB.ldf' TO 'filepath_to_ldf'
, REPLACE, STATS=5
, NORECOVERY;
--, RECOVERY; -- in case you don't use diff or log after
--, STOPAT ''
GO
