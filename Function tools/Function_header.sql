CREATE OR REPLACE PACKAGE BO4UPILOT.lic_summary_mod
AS

   procedure test;
 
  FUNCTION summarize_lic_package_sets_mod(
   pn_license_id                    IN      NUMBER,
   pv_format                        IN      VARCHAR2,
   pv_delim                         in      varchar2)
                                   RETURN  VARCHAR2;

  FUNCTION summarize_lic_pds_mod(
    pn_license_id                   IN      NUMBER,
    pv_format                          IN      VARCHAR2,
    pv_delim                           IN      VARCHAR2)
                                    RETURN  VARCHAR2;


END;
/
