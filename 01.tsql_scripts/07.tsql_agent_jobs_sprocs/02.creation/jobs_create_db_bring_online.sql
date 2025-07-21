/*
Created by: Mateusz Wierzbowski
Creation date: 2019/02/22
Aim: Check status of DB and try to bring it back online
*/
DECLARE @is_online bit;
SELECT @is_online = [state] FROM sys.databases WHERE [name] = '%YourDB%'
 
IF (@is_online <> 0)
BEGIN
	ALTER DATABASE [YourDB] SET ONLINE;
END
