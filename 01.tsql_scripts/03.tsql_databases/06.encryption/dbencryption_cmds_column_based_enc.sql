-- Create SMK
CREATE SYMMETRIC KEY SMKNameHere WITH ALGORITHM = AES_256 /*or AES-128 or AES_192*/ ENCRYPTION BY PASSWORD = 'SMKPasswordHere';
GO
-- Open SMK (without opening it you won't be able to decrypt/encrypt data)
OPEN SYMMETRIC KEY SMKNameHere DECRYPTION BY PASSWORD = 'SMKPasswordHere';
GO
-- Verify open keys (valid only in the current session)
SELECT * FROM sys.openkeys;
GO
-- Insert into table with encrypting data
INSERT TableWithEncryption VALUES (Value01, Value02, ENCRYPTBYKEY(KEY_GUID('SMKNameHere'),'Value03ToBeEncrypted'));
GO
-- Query table with decrypted values
SELECT 
	CONVERT(VARCHAR, DECRYPTBYKEY(EncryptedColumn)) AS DecryptedEncryptedColumn
FROM TableWithEncryption;
GO
-- Close SMK
CLOSE SYMMETRIC KEY SMKNameHere
GO
-- Open SMK and query table with decrypted values
OPEN SYMMETRIC KEY SMKNameHere DECRYPTION BY PASSWORD = 'SMKPasswordHere';
	SELECT 
		CONVERT(VARCHAR, DECRYPTBYKEY(EncryptedColumn)) AS DecryptedEncryptedColumn
	FROM TableWithEncryption;
GO
