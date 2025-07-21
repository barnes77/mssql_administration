USE [master];
GO
-- Backup SMK
BACKUP SERVICE MASTER KEY TO FILE = 'FilePath to *.key file' ENCRYPTION BY PASSWORD = 'PasswordHere';
GO
-- Backup DMK
BACKUP MASTER KEY TO FILE = 'FilePath to *.key file' ENCRYPTION BY PASSWORD = 'PasswordHere';
GO
-- Backup TDECertificate
BACKUP CERTIFICATE TDECertificate TO FILE = 'FilePath to *.cer file' WITH PRIVATE KEY(
	FILE = 'FilePath to *.key file', ENCRYPTION BY PASSWORD = 'PasswordHere');
GO
