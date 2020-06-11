use msdb
select SERVERPROPERTY('ComputerNamePhysicalNetBIOS'),j.originating_server, st.step_name, st.command 
 from sysjobsteps st
join sysjobs_view j on st.job_id = j.job_id
where command LIKE 'DEL%'