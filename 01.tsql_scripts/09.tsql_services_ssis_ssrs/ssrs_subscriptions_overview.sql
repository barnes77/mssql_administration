/*
Created by: Mateusz Wierzbowski
Creation date: 2020-02-28
Aim: Get an overview of SSRS subscriptions
*/
USE ReportServer;
SET NOCOUNT ON;
 
SELECT
	e.[name] AS report_name
	,e.[path] AS report_path
	,us.UserName AS subscription_owner
	--,sub.SubscriptionID AS subscription_id
	,sub.ModifiedDate AS modified_date
	,us2.UserName AS modified_by
FROM dbo.reportschedule AS rs
JOIN dbo.subscriptions AS sub ON rs.subscriptionid = sub.subscriptionid
JOIN dbo.users AS us ON sub.ownerid = us.userid
JOIN dbo.users AS us2 ON sub.ModifiedByID = us2.userid
JOIN dbo.[catalog] AS e ON itemid = report_oid
WHERE 1=1
--	AND e.[name] like '%isotrak%'
ORDER BY report_name;
