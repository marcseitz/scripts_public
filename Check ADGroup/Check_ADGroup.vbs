'Script begins here
Dim objGroup, objUser, objFSO, objFile, strDomain, strGroup, Domain, Group
'Change DomainName to the name of the domain the group is in
strDomain = Inputbox ("Enter the Domain name", "Data needed", "PWC-DE")
'Change GroupName to the name of the group whose members you want to export
strGroup = InputBox ("Enter the Group name", "Data needed", "Default group name")
Set objFSO = CreateObject("Scripting.FileSystemObject")
'On the next line change the name and path of the file that export data will be written to.
Set objFile = objFSO.CreateTextFile(strGroup & ".txt")
Set objGroup = GetObject("WinNT://" & strDomain & "/" & strGroup & ",group")
For Each objUser In objGroup.Members
    objFile.WriteLine objUser.Name & " - " & objUser.Class & " - " & objUser.FullName
Next
objFile.Close
Set objFile = Nothing
Set objFSO = Nothing
Set objUser = Nothing
Set objGroup = Nothing
Wscript.Echo "Done"