--In case of fixing BREAK MIRRORING from the principal
ALTER DATABASE [DBNAME] SET PARTNER OFF;
 
--Do a restore with no recovery on the mirror
--Establish mirroring (back)
--Mirror:
ALTER DATABASE [DBNAME] SET PARTNER = 'TCP://FQDN:portNo';
--Primary:
ALTER DATABASE [DBNAME] SET PARTNER = 'TCP://FQDN:portNo';
ALTER DATABASE [DBNAME] SET WITNESS = 'TCP://FQDN:portNo';
