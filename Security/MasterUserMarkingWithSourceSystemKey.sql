USE Lego_Security
GO

Select --top 100
--distinct
       tblMasterUser.MasterUserName
	  ,tblMarkingAccess.MarkingRoleName
	  ,tblUniqueLabelMarking.UniqueLabelID
	  ,tblUniqueLabelMarking.CategoryID
	  ,CASE 
	        WHEN tblUniqueLabelMarking.CategoryID = 2 THEN ODS_MEDIA_AGENCY.MediaAgencySourceSystemUniqueKey
	        WHEN tblUniqueLabelMarking.CategoryID = 3 THEN ODS_CLIENT.ClientSourceSystemUniqueKey 
	        WHEN tblUniqueLabelMarking.CategoryID = 4 THEN ODS_MEDIA_TYPE.MediaTypeSourceSystemUniqueKey
	   END As SourceSystemKey
,*
  from dbo.tblMarkingAccess
  join dbo.tblMasterUser
    on tblMarkingAccess.MasterUserID = tblMasterUser.MasterUserID
  join dbo.tblUniqueLabelMarking
    on tblMarkingAccess.MarkingRoleName = tblUniqueLabelMarking.MarkingRoleName
  left join Lego_ODS.dbo.ODS_MEDIA_AGENCY
    on tblUniqueLabelMarking.UniqueLabelID = ODS_MEDIA_AGENCY.AgencySecurityLabelID
   and tblUniqueLabelMarking.CategoryID = 2
  left join Lego_ODS.dbo.ODS_CLIENT
    on tblUniqueLabelMarking.UniqueLabelID = ODS_CLIENT.ClientSecurityLabelID
   and tblUniqueLabelMarking.CategoryID = 3
  left join Lego_ODS.dbo.ODS_MEDIA_TYPE
    on tblUniqueLabelMarking.UniqueLabelID = ODS_MEDIA_TYPE.MediaTypeSecurityLabelID
   and tblUniqueLabelMarking.CategoryID = 4
 --where tblUniqueLabelMarking.CategoryID = 4
 where 1 = 1
--   and MasterUserName = 'ad\abarkmin'
--   and tblMarkingAccess.CategoryID = 2