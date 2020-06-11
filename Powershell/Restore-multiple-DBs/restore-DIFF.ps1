cls
$path = "D:\Backup\MSSQL11.srvtst001\MSSQL\Backup\DIFF" 
$outfile = "C:\Users\de-44197a\Documents\restore-DIFF.sql"
$exclude = ("master*","model*","msdb*")
# Wichtig ist bei Exludes der * nach dem DB Name

# truncate existing output file
"" | out-file $outfile

# get all files with sbk-extensions (recursive)
$items = get-childitem $path -exclude $exclude -recurse -include *.sbk 
$items

# sort files with later timestamps to the front
$items = $items | sort -Property "Name"

# group by directory
$dirs = $items | Group-Object -Property "Directory" 

# get first file for each directory, sorted by creationtime
foreach ($dir in $dirs)
{
    $dircount = $($dir.Group.Count)
   if ($dircount -gt 1){
    $cur = ($dir.Group | sort -Property "CreationTimeUtc" -Desc)[0]
   }
   else
   {
   $cur = ($dir.Group)[0]
   } 
    # write SQL statements to output file
    "RESTORE DATABASE [$($cur.Directory.Name)]`r`n FROM  DISK = N'$($cur.FullName)'`r`n WITH  FILE = 1, NOUNLOAD,  REPLACE,  STATS = 10`r`n`r`n" | out-file -Append $outfile
}