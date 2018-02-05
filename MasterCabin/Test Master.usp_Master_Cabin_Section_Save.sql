DECLARE @TMP_CABIN_SLOT_MASTER  AS master.TMP_CABIN_SLOT_MASTER
DECLARE @tmp_section_master_withkamlist AS Master.TMP_SECTION_MASTER_WITHKAMLIST

SELECT * 
FROM @tmp_section_master_withkamlist
INSERT INTO @tmp_section_master_withkamlist
        ( cabin_code ,
          section_id ,
          section_name ,
          is_active ,
          kamid_List ,
          kamidRemove_List
        )
SELECT 1 Cabin_Code,
	   1 Section_id,
	   'abc' AS section_name,
	   1 active,
	   '',
	   '3,1,205,202'

UNION ALL

SELECT 1 Cabin_Code,
	   2 Section_id,
	   'xyz' AS section_name,
	   1 active,
	   '3,5,6,3,3,3,3,3,202',
	   ''
UNION ALL

SELECT 1 Cabin_Code,
	   3 Section_id,
	   'pqr' AS section_name,
	   1 active,
	   '5,6,3,3,3,3,3,3,3,3,202,3,3,3,3,3',
	   ''
UNION ALL

SELECT 1 Cabin_Code,
	   0 Section_id,
	   'New Section' AS section_name,
	   1 active,
	   '5,6,3,3,3,3,3,3,3,3,202,3,3,3,3,3',
	   ''

DECLARE @json NVARCHAR(MAX) ='{
	"schedule_details": [
							{
							  "schedule_code": 1,
							  "is_active": true,
							  "cabin_slot_id": 6,
							  "cabin_code": 1
							},
							{
							  "schedule_code": 2,
							  "is_active": true,
							  "cabin_slot_id": 7,
							  "cabin_code": 1
							},
							{
							  "schedule_code": 3,
							  "is_active": true,
							  "cabin_slot_id": 8,
							  "cabin_code": 1
							}
						]
							}'  

INSERT INTO @TMP_CABIN_SLOT_MASTER
SELECT *
FROM OPENJSON ( @json,'$.schedule_details')  
WITH (   
              cabin_slot_id int   ,  
              cabin_code int      ,       
              schedule_code  int  ,  
              is_active     bit     
			  
      ) AS Responce

EXEC [Master].[usp_Master_Cabin_Section_Save] 
	@cabin_code = 1, -- tinyint
    @cabin_name = 'First Cabin', -- varchar(32)
    @future_booking_day = 15, -- tinyint
    @is_active = 1, -- bit
    @time_slots_code = 11, -- tinyint
    @time_interval_code = 4, -- tinyint
    @remark_id = 0, -- int
    @remark = 'SDG', -- varchar(512)
    @apps_code = 13, -- tinyint
    @modified_by = 205, -- smallint
    @modified_iplocation_id = 127, -- int
    @tmp_cabin_slot_master = @TMP_CABIN_SLOT_MASTER, -- TMP_CABIN_SLOT_MASTER
    @tmp_section_master_withkamlist = @tmp_section_master_withkamlist -- TMP_SECTION_MASTER_WITHKAMLIST

SELECT * 
FROM  Master.SECTION_MASTER
WHERE CABIN_CODE=1

SELECT * 
FROM  Master.CABIN_SLOT_MASTER
WHERE CABIN_CODE=1