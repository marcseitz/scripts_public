$path = "D:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup" 
$outfile = "c:\temp\restore.sql"

# truncate existing output file
"" | out-file $outfile

# get all files with sbk-extensions (recursive)
$items = get-childitem $path -recurse -include *.sbf

# sort files with later timestamps to the front
$items = $items | sort -Property "Name" -Descending

# group by directory
$dirs = $items | Group-Object -Property "Directory" | sort -Property "Name"

# get first file for each directory
foreach ($dir in $dirs)
{
    $cur = $dir.Group[0]
    
    # write SQL statements to output file
    "RESTORE DATABASE [$($cur.Directory.Name)]`r`n FROM  DISK = N'$($cur.FullName)'`r`n WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10`r`n`r`n" | out-file -Append $outfile
}