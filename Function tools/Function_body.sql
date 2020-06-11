CREATE OR REPLACE PACKAGE BODY BO4UPILOT.lic_summary_mod
AS

-----------------------------------------------------------------------
-- license functions
-----------------------------------------------------------------------
  FUNCTION summarize_lic_package_sets_mod(
    pn_license_id                    IN      NUMBER,
    pv_format                        IN      VARCHAR2,
    pv_delim                         in      varchar2)
                                    RETURN  VARCHAR2
  IS

   ss                              ism.summary.cur_summary;
  BEGIN
   OPEN ss FOR
      SELECT c.packset_specification_id id, c.name AS name
      FROM ism.lic_proddet lpd,
           ism.pds_packset h,
           ism.pds_packset_change c
      WHERE lpd.license_id = pn_license_id
        AND h.product_detail_set_id = lpd.product_detail_set_id
        AND h.product_id = lpd.product_id
        AND c.id= h.last_approved_change_id
      order by 2;

    RETURN ism.summary.format(ss, pv_format,pv_delim);
  END;


  FUNCTION summarize_lic_pds_mod(
    pn_license_id                   IN      NUMBER,
    pv_format                          IN      VARCHAR2,
    pv_delim                           IN      VARCHAR2)
                                    RETURN  VARCHAR2
  IS

   ss                              ism.summary.cur_summary;
  BEGIN
   OPEN ss FOR
      SELECT
        p.id AS id,
        p.name AS name
      FROM
        ism.lic_proddet pd,
        ism.product_detail_set p
      WHERE pd.license_id = pn_license_id
        AND p.id = pd.product_detail_set_id
      ORDER BY p.name;


    RETURN ism.summary.format(ss,pv_format,pv_delim);
  END;
END;
/
