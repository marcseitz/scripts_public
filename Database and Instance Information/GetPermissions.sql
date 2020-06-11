SELECT SP1.[name] AS 'Login', 'Role: ' + SP2.[name] COLLATE DATABASE_DEFAULT AS 'ServerPermission'  
FROM sys.server_principals SP1 
  JOIN sys.server_role_members SRM 
    ON SP1.principal_id = SRM.member_principal_id 
  JOIN sys.server_principals SP2 
    ON SRM.role_principal_id = SP2.principal_id 
     WHERE SP1.[name] NOT LIKE '%MS_%'
UNION ALL 
SELECT SP.[name] AS 'Login' , SPerm.state_desc + ' ' + SPerm.permission_name COLLATE DATABASE_DEFAULT AS 'ServerPermission'  FROM sys.server_principals SP  
  JOIN sys.server_permissions SPerm  
    ON SP.principal_id = SPerm.grantee_principal_id  
    WHERE NOT (SPerm.type = 'COSQ' AND SPerm.state = 'G')
    AND SP.name NOT LIKE '%MS_%'
ORDER BY [Login], [ServerPermission]; 