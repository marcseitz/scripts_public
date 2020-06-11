create table dbo.fin_help_Nums
(
    n int NOT NULL PRIMARY KEY
)
;
declare @max as int, @i as int;
set @max = 10000;
set @i = 1;
insert into dbo.fin_help_Nums
values
    (1);
while @i * 2 <= @max
begin
    insert into dbo.fin_help_Nums
    select n + @i
    from dbo.fin_help_Nums;
    set @i = @i * 2;
end


insert into dbo.fin_help_Nums
select n + @i
from dbo.fin_help_Nums
where n + @i <= @max;
go
