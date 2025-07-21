USE [master];
GO
-- Create SMK for backup encryption
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'PasswordHere';
GO
-- Create certificate for backup encryption
CREATE CERTIFICATE Cert_Enc WITH SUBJECT = 'Cert Subject';
GO
-- Include encryption in the backup command
BACKUP DATABASE DBWithBackupEnc TO DISK = N'Backup filepath'
	WITH ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = Cert_Enc );
GO
