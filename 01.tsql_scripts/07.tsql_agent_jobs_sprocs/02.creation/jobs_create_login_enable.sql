/*
Created by: Mateusz Wierzbowski
Creation date: 2019/02/18
Aim: Check status of login and unlock it
*/
DECLARE @is_disabled bit;
 
SELECT @is_disabled = is_disabled FROM sys.server_principals WHERE [name] = 'YourLogin';
 
IF (@is_disabled = 1)
BEGIN
	ALTER LOGIN YourLogin ENABLE;
END
