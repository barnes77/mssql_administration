SET NOCOUNT ON;
SELECT TOP 10
	log_id
	,event_type
	,log_date
	,[description]
	,process_id
	,mailitem_id
	,account_id
	,last_mod_date
	,last_mod_user
FROM msdb.dbo.sysmail_event_log
ORDER BY log_id DESC;
 
SELECT TOP 10
	mailitem_id
	,profile_id
	,recipients
	,copy_recipients
	,blind_copy_recipients
	,[subject]
	,body
	,body_format
	,importance
	,[sensitivity]
	,file_attachments
	,attachment_encoding
	,query
	,execute_query_database
	,attach_query_result_as_file
	,query_result_header
	,query_result_width
	,query_result_separator
	,exclude_query_output
	,append_query_error
	,send_request_date
	,send_request_user
	,sent_account_id
	,sent_status
	,sent_date
	,last_mod_date
	,last_mod_user
FROM msdb.dbo.sysmail_mailitems
ORDER BY send_request_date DESC;
 
SELECT TOP 10
	mailitem_id
	,profile_id
	,recipients
	,copy_recipients
	,blind_copy_recipients
	,[subject]
	,body
	,body_format
	,importance
	,[sensitivity]
	,file_attachments
	,attachment_encoding
	,query
	,execute_query_database
	,attach_query_result_as_file
	,query_result_header
	,query_result_width
	,query_result_separator
	,exclude_query_output
	,append_query_error
	,send_request_date
	,send_request_user
	,sent_account_id
	,sent_status
	,sent_date
	,last_mod_date
	,last_mod_user
FROM msdb.dbo.sysmail_sentitems
ORDER BY send_request_date DESC;
 
SELECT TOP 10
	mailitem_id
	,profile_id
	,recipients
	,copy_recipients
	,blind_copy_recipients
	,[subject]
	,body
	,body_format
	,importance
	,[sensitivity]
	,file_attachments
	,attachment_encoding
	,query
	,execute_query_database
	,attach_query_result_as_file
	,query_result_header
	,query_result_width
	,query_result_separator
	,exclude_query_output
	,append_query_error
	,send_request_date
	,send_request_user
	,sent_account_id
	,sent_status
	,sent_date
	,last_mod_date
	,last_mod_user
FROM msdb.dbo.sysmail_allitems
ORDER BY send_request_date DESC;
