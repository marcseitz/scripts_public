DECLARE @owner_name varchar(50)

SET @owner_name = (select name from sys.server_principals where principal_id = 1)

if @owner_name = 'pwcsysop'
BEGIN 
ALTER LOGIN [pwcsysop] WITH PASSWORD=N'insertpasswordhere'
END
GO