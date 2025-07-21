-- Show all logins where the password was changed within the last x days
SET NOCOUNT ON;
 
SELECT [name], LOGINPROPERTY([name],'PasswordLastSetTime') AS pass_changed
FROM sys.sql_logins
WHERE 1=1
	AND LOGINPROPERTY([name],'PasswordLastSetTime') > DATEADD(dd, -1, GETDATE());
 
-- Show all logins where the password is over 60 days old
 
SELECT [name], LOGINPROPERTY([name],'PasswordLastSetTime') AS pass_changed
FROM sys.sql_logins
WHERE 1=1
	AND LOGINPROPERTY([name],'PasswordLastSetTime') < DATEADD(dd, -60, GETDATE())
	AND NOT (LEFT([name],2) = '##' AND RIGHT([name],2) = '##');
