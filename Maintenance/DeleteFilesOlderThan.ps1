$dump_path = "C:\Program Files\Microsoft Power BI Report Server\PBIRS\LogFiles"
$max_age = "-7"
$curr_date = Get-Date
$del_date = $curr_date.AddDays($max_age)
Get-ChildItem -include *.mdmp $dump_path -Recurse |
Where-Object { $_.LastWriteTime -lt $del_date } |
Where-Object { -not ($_.psiscontainer) } |
Sort-Object CreationTime -Descending |
Select-Object -Skip 1 |
Foreach-Object {Remove-Item $_.FullName}
