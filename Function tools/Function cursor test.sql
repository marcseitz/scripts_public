-- initial sqL from function
     SELECT h.id,c.id,c.packset_specification_id id, c.name AS name
      FROM ism.lic_proddet lpd,
           ism.pds_packset h,
           ism.pds_packset_change c
      WHERE lpd.license_id = 109345
        AND h.product_detail_set_id = lpd.product_detail_set_id
        AND h.product_id = lpd.product_id
        AND c.id= h.last_approved_change_id;         
     
     --test SQL
     --only from LIC_PROD_DET
     SELECT 
        lpd.ID, lpd.license_id, lpd.product_detail_set_id, lpd.packset_specification_id, lpd.*
     FROM 
        ism.lic_proddet lpd
     WHERE 
        lpd.license_id = 109345  --2 lines for 2 PACKSET_SPECIFICATION_ID for same PRODUCT_DETAIL_SET_ID 
        
     --only PRODUCT DETAIL SET ID
     SELECT * from ism.pds_packset WHERE product_detail_set_id = 82312 -- 3 RECORDS, 2 of them are the last approved, one for each packset_specification_id
     
     --with LIC_PROD_DET, PDS_PACK_SET   
     SELECT 
        lpd.ID, lpd.license_id, lpd.product_detail_set_id, lpd.packset_specification_id, --lpd.*,
        h.ID, h.Product_id, H.PRODUCT_DETAIL_SET_ID, H.PACKSET_SPECIFICATION_ID
     FROM 
        ism.lic_proddet lpd, ism.pds_packset h
     WHERE 
        lpd.product_detail_set_id = h.product_detail_set_id
        AND h.product_id = lpd.product_id
        --AND LPD.PACKSET_SPECIFICATION_ID = H.PACKSET_SPECIFICATION_ID --extra join added to test
        AND lpd.license_id = 109345
        
     --with LIC_PROD_DET, PDS_PACK_SET, PDS_PACKSET_CHANGE    
     SELECT
        c.packset_specification_id function_id, c.name AS function_name, 
        lpd.ID, lpd.license_id, lpd.product_detail_set_id, lpd.packset_specification_id, --lpd.*,
        h.ID, h.Product_id, H.PRODUCT_DETAIL_SET_ID, H.PACKSET_SPECIFICATION_ID,
        c.ID
     FROM 
        ism.lic_proddet lpd, ism.pds_packset h, ism.pds_packset_change c
     WHERE 
        lpd.product_detail_set_id = h.product_detail_set_id
        AND h.product_id = lpd.product_id
        AND LPD.PACKSET_SPECIFICATION_ID = H.PACKSET_SPECIFICATION_ID --extra join added to test
        AND c.id= h.last_approved_change_id
        AND lpd.license_id = 109345
        
        
        --other tests   
       SELECT c.packset_specification_id id, c.name AS name
      FROM 
           ism.pds_packset h,
           ism.pds_packset_change c
      WHERE 
      C.ID in (82345, 82337)
        AND c.id= h.last_approved_change_id;

select * from ism.license
where id = 109345

select * from ism.lic_proddet
where license_id = 109345

select * from ism.pds_packset
where product_detail_set_id = 82312

select id, packset_specification_id, name from ism.pds_PACKSET_CHANGE
where packset_specification_id = 82336 or packset_specification_id =82344

