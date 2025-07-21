/*
Created by: Mateusz Wierzbowski
Creation date: 2024/02/29
Aim: alternative to PWDCOMPARE()
*/
DECLARE @login sysname, @header varbinary(4), @hash varbinary(max),@salt varbinary(4);
DECLARE @pwd1 nvarchar(max),@hash1 varbinary(max);
DECLARE @pwd2 nvarchar(max),@hash2 varbinary(max);
 
SET @login = 'sa'; --login to be checked
SET @pwd1 = 'SqlIstKrieg2024'; --first pwd here
SET @pwd2 = 'strong_password_here'; --second pwd here
 
SELECT @header = CONVERT(varbinary(4), SUBSTRING(CONVERT(nvarchar(MAX), password_hash), 1, 1)) FROM sys.sql_logins WHERE [name] = @login;
SELECT @hash = password_hash FROM sys.sql_logins WHERE [name] = @login;
SELECT @salt = CONVERT(varbinary(4), SUBSTRING(CONVERT(nvarchar(MAX), password_hash), 2, 2)) FROM sys.sql_logins WHERE [name] = @login;
 
IF @header = 0x200
BEGIN
	SET @hash1 = 0x200+@salt+HASHBYTES('SHA2_512',CAST(@pwd1 AS varbinary(MAX)) + @salt);
	SET @hash2 = 0x200+@salt+HASHBYTES('SHA2_512',CAST(@pwd2 AS varbinary(MAX)) + @salt);
END
ELSE BEGIN
	SET @hash1 = 0x100+@salt+HASHBYTES('SHA1',CAST(@pwd1 AS varbinary(MAX)) + @salt);
	SET @hash2 = 0x100+@salt+HASHBYTES('SHA1',CAST(@pwd2 AS varbinary(MAX)) + @salt);
END
 
SELECT
	[name]
	--,password_hash, @hash1 AS pwd1_hash, @hash2 AS pwd2_hash
	, CASE
		WHEN password_hash = @hash1 THEN @pwd1
		WHEN password_hash = @hash2 THEN @pwd2
		ELSE NULL
	END AS matched_password
FROM sys.sql_logins
WHERE [name] = @login;
