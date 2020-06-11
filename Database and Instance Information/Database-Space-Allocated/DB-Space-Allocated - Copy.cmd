echo "########## DB Growing Monitoring - started - ######################" >> Startup.log
echo "Create DB-Usage File..." >> Startup.log
"C:\Program Files\Microsoft SQL Server\100\Tools\Binn\OSQL.EXE"   /E /S DE-FRADBS911 /n /i "C:\Database-Space-Allocated\Database-Space-Allocated.sql" /o "C:\Database-Space-Allocated\Database-Space-Allocated.out" -w512
echo "Rename DB-Usage File..." >> Startup.log
ren Database-Space-Allocated.out DB-Space-Allocated_%date:~-4,4%%date:~-7,2%%date:~-10,2%-%time:~0,2%_Uhr.txt
echo "Move DB-Usage File..." >> Startup.log
move DB-Space-Allocated_%date:~-4,4%%date:~-7,2%%date:~-10,2%-%time:~0,2%_Uhr.txt ./Archiv/DB-Space-Allocated_%date:~-4,4%%date:~-7,2%%date:~-10,2%-%time:~0,2%_Uhr.txt
echo "+++++ ENDE um %time:~0,8%" >> Startup.log