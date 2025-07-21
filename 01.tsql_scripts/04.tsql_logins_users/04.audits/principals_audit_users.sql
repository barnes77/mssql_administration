/*
Created by: Mateusz Wierzbowski
Creation Date (v1.0): 2018/12/02
Creation Date (v2.0): 2019/03/25
Aim: Gathering all information about logins and users on instance level, preparing scripts for copying logins to other servers and managing orphaned users
*/
--Step1: Check if temptable exists
USE tempdb;
SET NOCOUNT ON;
 
IF OBJECT_ID('#dba_users_audit') IS NOT NULL BEGIN DROP TABLE #dba_users_audit; END
 
--Step2: Define and create temptable
 
CREATE TABLE #dba_users_audit (
	[database_name] sysname
	,[user_name] sysname
	,db_role sysname null
	,[type] nvarchar(30)
	,[sid] varbinary(85)
	,is_locked int
	,lockout_time nvarchar(30) null
	,is_orphaned int
	,mapped_to sysname null
	,expiration nvarchar(30)
	,[policy] nvarchar(30)
	,password_hash varbinary(256)
	,default_db sysname null
	,default_lang sysname null
	,recreate nvarchar(1000)
	,map_orphan_to_login nvarchar(500)
	,create_login_for_orphan nvarchar(1000)
);
 
--Step3: Create cursor for DBs to be checked
DECLARE @db_name sysname, @query nvarchar(3500);
 
DECLARE db_crsr CURSOR FOR
SELECT [name] FROM sys.databases 
WHERE 1=1 
	AND database_id > 4
--	AND replica_id IS NOT NULL -- Add this condition to check only AlwaysOn DBs
 
--Step4: Perform query for DBs to be checked
OPEN db_crsr;
	FETCH NEXT FROM db_crsr INTO @db_name
		WHILE @@FETCH_STATUS = 0
		BEGIN
		SET @query =
		'INSERT INTO #dba_users_audit
		SELECT
			'''+@db_name+''' AS [database_name]
			,sdpri1.name AS [user_name]
			,sdpri2.name AS db_role
			,spri.type_desc AS [type]
		,sus.[sid] AS [sid]
		,ISNULL(CAST(LOGINPROPERTY(sdpri1.name,N''IsLocked'') AS INT),0) AS is_locked
		,CASE
			WHEN CAST(LOGINPROPERTY(sdpri1.name,N''IsLocked'') AS INT) = 0 THEN 0
			ELSE ISNULL(CONVERT(CHAR(16),LOGINPROPERTY(sdpri1.name,N''LockoutTime''),20),0)
		END AS lockout_time
		,CASE
			WHEN spri.SID IS NULL AND sdpri2.authentication_type_desc = ''INSTANCE'' THEN 1
			ELSE 0
		END AS is_orphaned
		,spri.name AS mapped_to
		,ISNULL(sl.is_expiration_checked,0) AS expiration
		,ISNULL(sl.is_policy_checked,0) AS [policy]
		,sl.password_hash AS password_hash
		,spri.default_database_name AS default_db
		,spri.default_language_name AS default_lang
		,''CREATE LOGIN ''+sdpri1.name+'' ''
		+CASE
			WHEN spri.type IN (''U'', ''G'') THEN ''FROM WINDOWS ''
			ELSE ''''	
		END
		+ ''WITH ''
		+CASE
			WHEN spri.type = ''S'' THEN ''PASSWORD = '' + master.sys.fn_varbintohexstr(sl.password_hash) + '' HASHED, ''
				+ ''SID = '' + master.sys.fn_varbintohexstr(sl.[sid]) + '', ''
				+ ''CHECK_EXPIRATION = '' +	 CASE
					WHEN sl.is_expiration_checked > 0 THEN ''ON, ''
					ELSE ''OFF, ''
					END
				+ ''CHECK_POLICY = '' +	 CASE
					WHEN sl.is_policy_checked > 0 THEN ''ON, ''
					ELSE ''OFF, ''
					END
		ELSE ''''
		END
		+ ''DEFAULT_DATABASE = '' + spri.default_database_name
		+	 CASE
			WHEN LEN(spri.default_language_name) > 0 THEN '', DEFAULT_LANGUAGE = '' + spri.default_language_name + ''''
			ELSE ''''
			END AS recreate
		,''ALTER USER ''+sdpri1.name+'' WITH LOGIN = ''+sdpri1.name+'' ;'' AS map_orphan_to_login
		,''CREATE LOGIN ''+sdpri1.name+'' WITH PASSWORD = ''+''use_a_strong_password_here''+'', SID = ''+master.sys.fn_varbintohexstr(sus.[sid])+'';'' AS create_login_for_orphan
		FROM '+QUOTENAME(@db_name)+'.sys.sysusers AS sus
		LEFT JOIN '+QUOTENAME(@db_name)+'.sys.database_principals AS sdpri1 ON sus.name = sdpri1.name
		LEFT JOIN '+QUOTENAME(@db_name)+'.sys.database_role_members AS dbrm ON dbrm.member_principal_id = sdpri1.principal_id
		LEFT JOIN '+QUOTENAME(@db_name)+'.sys.database_principals AS sdpri2 ON dbrm.role_principal_id = sdpri2.principal_id
		LEFT JOIN '+QUOTENAME(@db_name)+'.sys.sql_logins AS sl ON sus.name COLLATE SQL_Latin1_General_CP1_CS_AS = sl.name COLLATE SQL_Latin1_General_CP1_CS_AS
		LEFT JOIN sys.server_principals spri ON sdpri1.[sid] = spri.[sid]
		WHERE UPPER(sdpri1.type) IN (''G'', ''U'', ''S'') AND UPPER(sdpri1.name) NOT in (''DBO'', ''GUEST'', ''SYS'', ''INFORMATION_SCHEMA'') AND ISNULL(sl.is_disabled,0) = 0';
		exec sp_sqlexec @query;
		FETCH NEXT FROM db_crsr INTO @db_name;
		END
CLOSE db_crsr;
DEALLOCATE db_crsr;
--Step5: Select the results
SELECT
	*
FROM #dba_users_audit
ORDER BY [database_name],[user_name];
--Step6: Drop the temp table
DROP TABLE #dba_users_audit;
