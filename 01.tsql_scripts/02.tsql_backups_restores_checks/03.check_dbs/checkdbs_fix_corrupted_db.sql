/* Make sure you save the outcome of the command below in a text file or in a worklog of the ticket 
(the customer may decide to simply drop corrupted table or index, indexes with ID 2-250 can be simply scripted out and recreated)
This will include a lowest repair option: repair_rebuild or repair_allow_data_loss
Contact the DM and customer to get approval for running both options: both of them will require downtime and the former will mean a data loss */
 
DBCC CHECKDB([YourDatabase]) WITH NO_INFOMSGS, ALL_ERRORMSGS; --DATA_PURITY is redundant for DBs created after SQL2000 or older ones for which data_purity has been executed at least once, hence for all DBs with dbi_dbccFlags = 2
 
/* If possible and approved by customer, restore the database from the last known good backup instead of repair_allow_data_loss */
 
/* This is the exact command for the fix procedure */
ALTER DATABASE [YourDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
 
/* Consider running all of the statements below in a transaction, so you can easily rollback */
--DBCC CHECKDB ([YourDatabase], REPAIR_REBUILD); --for less severe errors which do not involve a data loss while fixing
--DBCC CHECKDB ([YourDatabase], REPAIR_ALLOW_DATA_LOSS); --for more severe errors which involves a data loss while fixing
--DBCC CHECKTABLE([YourTable], REPAIR_REBUILD); --for less severe errors which do not involve a data loss while fixing, limited to a particular table
--DBCC CHECKTABLE ([YourTable], REPAIR_ALLOW_DATA_LOSS); --for more severe errors which involves a data loss while fixing, limited to a particular table
 
/* If the database is fixed, set it back to multi user */
ALTER DATABASE [YourDatabase] SET MULTI_USER;
 
/* Run the CHECKDB to be double sure, for relatively smaller DBs you can use option WITH DATA_PURITY */
 
DBCC CHECKDB([YourDatabase]) --WITH DATA_PURITY;
