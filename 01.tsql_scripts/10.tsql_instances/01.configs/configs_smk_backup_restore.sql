BACKUP SERVICE MASTER KEY TO FILE = '%filepath%\%instancename%_smk' ENCRYPTION BY PASSWORD = 'xxx' --run at old instance
RESTORE SERVICE MASTER KEY FROM FILE = '%filepath%\%instancename%_smk' DECRYPTION BY PASSWORD = 'xxx' FORCE; --run at new instance
