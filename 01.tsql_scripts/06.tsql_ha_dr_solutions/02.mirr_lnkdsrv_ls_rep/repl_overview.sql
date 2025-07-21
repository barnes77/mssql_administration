SET NOCOUNT ON;
 
SELECT
	[name]
	,is_published
	,is_subscribed
	,is_merge_published
	,is_distributor
	,is_cdc_enabled
	,log_reuse_wait_desc
FROM sys.databases
WHERE 1=0
	OR is_published = 1 
	OR is_subscribed = 1 
	OR is_merge_published = 1 
	OR is_distributor = 1
	OR log_reuse_wait_desc = 'REPLICATION'
	OR is_cdc_enabled = 1; --Use to verify if CDC is enabled on not-replicated DBs
