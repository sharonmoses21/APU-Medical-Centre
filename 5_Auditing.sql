-- Creating Server Audit for DDL Activities
USE master;
GO
CREATE SERVER AUDIT DDLActivities_Audit TO FILE ( FILEPATH = 'C:\YandexDisk\Malaysia\Courses\y3s2\DBS\Assignment\AuditLogs\DDLActivities' );
GO
ALTER SERVER AUDIT DDLActivities_Audit WITH (STATE = ON);
GO

-- Creating Server Audit Specification for DDL Activities
CREATE SERVER AUDIT SPECIFICATION DDLActivities_Audit_Specification
FOR SERVER AUDIT DDLActivities_Audit
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP)
WITH (STATE=ON);
GO

-- Creating Server Audit for DML Activities
USE master;
GO
CREATE SERVER AUDIT AllTables_DML TO FILE ( FILEPATH = 'C:\YandexDisk\Malaysia\Courses\y3s2\DBS\Assignment\AuditLogs\DMLActivities' );
GO
ALTER SERVER AUDIT AllTables_DML WITH (STATE = ON);
GO

-- Creating Database Audit Specification for DML Activities
USE MedicalInfoSystem;
GO
CREATE DATABASE AUDIT SPECIFICATION AllTables_DML_Specification
FOR SERVER AUDIT AllTables_DML
ADD (INSERT, UPDATE, DELETE, SELECT ON DATABASE::[MedicalInfoSystem] BY public)
WITH (STATE = ON);
GO

-- Example of Reading Audit Logs for DDL Activities
DECLARE @AuditFilePath VARCHAR(8000);
SELECT @AuditFilePath = audit_file_path FROM sys.dm_server_audit_status WHERE name = 'DDLActivities_Audit';
SELECT event_time, database_name, database_principal_name, object_name, statement
FROM sys.fn_get_audit_file(@AuditFilePath, default, default);
GO

-- Example of Reading Audit Logs for DML Activities
DECLARE @AuditFilePath VARCHAR(8000);
SELECT @AuditFilePath = audit_file_path FROM sys.dm_server_audit_status WHERE name = 'AllTables_DML';
SELECT event_time, database_name, database_principal_name, object_name, statement
FROM sys.fn_get_audit_file(@AuditFilePath, default, default);
GO