
Option Explicit
 'Constants for Server Configuration. Please update to your settings.
 'tblName needs to be the temporaray Table, in which the data is exportet.
 
Const Server = "SATURN\Test"
 Const Database = "test"
 Const tblName = "test.dbo.testtable"
 
Const user1 = "usr" 
Const pass1 = "pw"

'--Normally you don´t need to change anything below this line.
 
Sub SqlExport()
 
  Dim cnt As New ADODB.Connection, _
           rst As New ADODB.Recordset, _
           dbPath As String, _
           rngColHeads As Range, _
           rngTblRcds As Range, _
           colHead As String, _
           rcdDetail As String, _
           ch As Integer, _
           cl As Integer, _
           notNull As Boolean, _
           Datum As String, _
           Zeit As String, _
           aDate As String, _
           sql, _
           rs As New ADODB.Recordset
           
 
  'Setting Worksheet, Defining Headers
   'Defining Cell-Range for Recordset
       
   Worksheets("Upload_Rows").Activate
   
   Set rngColHeads = ActiveSheet.Range("A1:I1")
   Set rngTblRcds = ActiveSheet.Range("A2", "I" & ActiveCell.SpecialCells(xlLastCell).Row)
 
 'Concatenate a string with the names of the column headings if needed
  'replace the Data in the insert statement then...
  ' colHead = " (["
  ' For ch = 1 To rngColHeads.Count
  '     colHead = colHead & rngColHeads.Columns(ch).Value
  '     Select Case ch
  '         Case Is = rngColHeads.Count
  '            colHead = colHead & "])"
  '         Case Else
  '             colHead = colHead & "],["
  '     End Select
  ' Next ch
 
  'Open connection to the database
   
   cnt.connectionString = "DRIVER=SQL Server; SERVER=" & Server & ";UID=" & user1 & ";password=" & pass1 & ";DATABASE=" & Database
   cnt.Open
  
   If Err = -2147467259 Then
       Application.ScreenUpdating = True
           MsgBox "Datenaktualisierungsserver nicht erreichbar - bitte F&E Controlling informieren"
       Application.ScreenUpdating = False
   End If
        
   'Begin transaction processing
   On Error GoTo EndUpdate
      
   cnt.BeginTrans
   
   'getting SQL-Server Date&Time....quite complicated conversion , but working. Various Dateformats s... ;)
   Set rs = cnt.Execute("select getdate() as Uhrzeit")
   Datum = rs("Uhrzeit")
   Zeit = rs("Uhrzeit")
   Set rs = Nothing
   Datum = Format(Date, "yyyy-mm-dd")
   Zeit = Format(Time, "hh:mm:ss")
   aDate = Datum & " " & Zeit
 

  'Insert records into database from worksheet table
   For cl = 1 To rngTblRcds.Rows.Count
 
      'Assume record is completely Null, and open record string for concatenation
       notNull = False
       rcdDetail = "('"
 
      'Evaluate field in the record
       For ch = 1 To rngColHeads.Count
           Select Case rngTblRcds.Rows(cl).Columns(ch).Value
                   'if empty, append value of null to string
               Case Is = Empty
                   Select Case ch
                       Case Is = rngColHeads.Count
                           rcdDetail = Left(rcdDetail, Len(rcdDetail) - 1) & "NULL,'" & aDate & "')"
                       Case Else
                           rcdDetail = Left(rcdDetail, Len(rcdDetail) - 1) & "NULL,'"
                   End Select
 
                  'if not empty, set notNull to true, and append value to string
               Case Else
                   notNull = True
                   Select Case ch
                       Case Is = rngColHeads.Count
                           'rcdDetail = rcdDetail & rngTblRcds.Rows(cl).Columns(ch).Value & "')"
                           rcdDetail = rcdDetail & rngTblRcds.Rows(cl).Columns(ch).Value & "','" & aDate & "')"
                       Case Else
                           rcdDetail = rcdDetail & rngTblRcds.Rows(cl).Columns(ch).Value & "','"
                   End Select
           End Select
       Next ch
   
 
      'If record consists of only Null values, do not insert it to table, otherwise
       'insert the record
       Select Case notNull
           Case Is = True
               'cnt.Execute "INSERT INTO " & tblName & colHeads & " VALUES " & rcdDetail
                cnt.Execute "INSERT INTO " & tblName & " (Item_ID, [User], Project, Year_Name, Month_Name, Source_Table, Typ, Field, Value, addDate) VALUES " & rcdDetail
           Case Is = False
               'do not insert record
       End Select
   Next cl
 
EndUpdate:
   'Check if error was encounted
   If Err.Number <> 0 Then
       'Error encountered.  Rollback transaction and inform user
       On Error Resume Next
       cnt.RollbackTrans
       MsgBox "Update was not succesful!", vbCritical, "Error!"
   Else
       On Error Resume Next
       cnt.CommitTrans
       MsgBox "Update succesful!", vbInformation, "Success"
   End If
 
  'Close the ADO objects
   cnt.Close
   Set rst = Nothing
   Set cnt = Nothing
   On Error GoTo 0
 End Sub
