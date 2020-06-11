$path = "D:\Program Files\Microsoft SQL Server\MSSQL10.TWOFIVETHREEONE\MSSQL" 
$outfile = "c:\temp\restore-FULL-Sebastian-Mattar.sql"

# truncate existing output file
"" | out-file $outfile

# get all files with sbk-extensions (recursive)
$items = get-childitem $path -recurse -include *.sbk

# sort files with later timestamps to the front
$items = $items | sort -Property "Name"

# group by directory
$dirs = $items | Group-Object -Property "Directory" 

# get first file for each directory, sorted by creationtime
foreach ($dir in $dirs)
{
    $cur = ($dir.Group | sort -Property "CreationTimeUtc" -Desc)[0]
    
    # write SQL statements to output file
    "RESTORE DATABASE [$($cur.Directory.Name)]`r`n FROM  DISK = N'$($cur.FullName)'`r`n WITH  FILE = 1,  NORECOVERY, NOUNLOAD,  REPLACE,  STATS = 10`r`n`r`n" | out-file -Append $outfile
}