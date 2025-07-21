/*
Created by: Mateusz Wierzbowski
Creation date: 2021/04/21
Aim: Get details about current max DOP settings, verify what is the highest possible max DOP, verify if the current DOP is not too high based on wait types
*/
USE tempdb;
SET NOCOUNT ON;
 
DECLARE @max_dop smallint, @ctp smallint, @cxpacket_per decimal(10,2) = 0.00, @latch_per decimal(10,2) = 0.00, @message nvarchar(2000);
--Gather details about CPU on OS level and calculate the highest Max DOP per MS recommendations
SELECT @max_dop = CAST([value] AS smallint) FROM sys.configurations WHERE [name] = 'max degree of parallelism';
SELECT @ctp = CAST([value] AS smallint) FROM sys.configurations WHERE [name] = 'cost threshold for parallelism';
SELECT
	CASE
		WHEN os_priority_class = 32 THEN 'normal priority base'
		ELSE 'high priority base'
	END AS os_priority_class_desc
	--,max_workers_count
	--,scheduler_total_count
	,affinity_type_desc
	,cpu_count -- number of logical CPUs
	-- all below applicable for SQL 2016 SP2 +
	,softnuma_configuration_desc,socket_count,numa_node_count,cores_per_socket
	--softnuma in SQL2014SP2+ are created whenever SQL detects more then 8 CPU cores
	--numa_node_count includes both physical and soft numa nodes
	,@max_dop AS max_dop
	,@ctp AS ctp
	,CASE
		WHEN SERVERPROPERTY('ProductMajorVersion') > 12 THEN ((cores_per_socket+16)+ABS(cores_per_socket-16))/2
		WHEN SERVERPROPERTY('ProductMajorVersion') < 13 THEN ((cores_per_socket+8)+ABS(cores_per_socket-8))/2
		ELSE 0
	END AS highest_max_dop
FROM sys.dm_os_sys_info;
 
--Verify if current Max DOP is not set too high
IF (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE wait_type LIKE 'CXPACK%' AND wait_time_ms >= 1) > 0
	BEGIN
		SELECT @cxpacket_per = CAST(wait_time_ms * 100.0 / SUM(wait_time_ms) OVER() AS decimal(10,2)) FROM sys.dm_os_wait_stats WHERE wait_type LIKE 'CXPACK%'AND wait_time_ms >= 1;
	END
IF (SELECT SUM(wait_time_ms) FROM sys.dm_os_wait_stats WHERE (wait_type LIKE 'LATCH_%' OR wait_type LIKE 'PAGEIOLATCH_%' OR wait_type LIKE 'SOS_SCHEDULER_YIELD%') AND wait_time_ms >= 1) > 0
	BEGIN
		SELECT @latch_per = CAST(wait_time_ms * 100.0 / SUM(wait_time_ms) OVER() AS DECIMAL(10,2)) FROM sys.dm_os_wait_stats WHERE (wait_type LIKE 'LATCH_%' OR wait_type LIKE 'PAGEIOLATCH_%' OR wait_type LIKE 'SOS_SCHEDULER_YIELD%') AND wait_time_ms >= 1;
	END
 
IF @cxpacket_per > 50.00
	BEGIN
		IF @latch_per >5.00
			BEGIN
				SET @message = 'Reducing Max DOP is strongly recommended. CXPACKET waits are over 50% of total waits and are accompanied by LATCH*/PAGEIOLATCH*/SCHEDULER_YIELD* waits.';
			END
		ELSE
			BEGIN
				SET @message = 'Reducing Max DOP is recommended. CXPACKET waits are over 50% of total waits.';
			END
	END
ELSE
	BEGIN
		SET @message = 'No need to reduce Max DOP based on wait types.';
	END
--Gather info about possible reduction of Max DOP
SELECT
	@message AS max_dop_verification
	,@cxpacket_per AS [cxpacket_vs_total_waits%]
	,@latch_per AS [latch*/pageiolatch*/scheduler_yield*_vs_total_waits%];
