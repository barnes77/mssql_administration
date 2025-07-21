USE DBWithEncryption;
GO
-- Create DMK database master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SMKPasswordHere'
-- Create certificate
CREATE CERTIFICATE Cert_Enc WITH SUBJECT = 'CertSubject';
GO
-- Create SMK
CREATE SYMMETRIC KEY SMKNameHere WITH ALGORITHM = AES_256 /*or AES-128 or AES_192*/ ENCRYPTION BY CERTIFICATE Cert_Enc;
GO
-- Create a column to store encrypted data
ALTER TABLE TableWithEncryption
	ADD EncryptedCol varbinary(128);
GO
-- Open the SMK to encrypt data
OPEN SYMMETRIC KEY SMKNameHere DECRYPTION BY CERTIFICATE Cert_Enc;
GO
-- Encrypt Bank Account Number
UPDATE TableWithEncryption
	SET EncryptedCol = EncryptByKey(Key_GUID('SMKNameHere'), OldCol);
GO
-- Close SMK
CLOSE SYMMETRIC KEY SMKNameHere
GO
