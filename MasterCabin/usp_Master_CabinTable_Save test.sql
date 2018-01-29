DECLARE @tmp_cabin_slot_master Master.TMP_CABIN_SLOT_MASTER -- TMP_CABIN_SLOT_MASTER
DECLARE @tmp_section_master_withkamlist Master.TMP_SECTION_MASTER_WITHKAMLIST -- TMP_SECTION_MASTER_WITHKAMLIST

INSERT INTO @tmp_cabin_slot_master( CABIN_SLOT_ID ,CABIN_CODE ,SCHEDULE_CODE ,IS_ACTIVE)
VALUES  ( 22 , 17 , 1 ,0 )
INSERT INTO @tmp_cabin_slot_master( CABIN_SLOT_ID ,CABIN_CODE ,SCHEDULE_CODE ,IS_ACTIVE)
VALUES  ( 23 , 17 , 2 ,0 )
INSERT INTO @tmp_cabin_slot_master( CABIN_SLOT_ID ,CABIN_CODE ,SCHEDULE_CODE ,IS_ACTIVE)
VALUES  ( 24 , 17 , 3 ,1 )
INSERT INTO @tmp_cabin_slot_master( CABIN_SLOT_ID ,CABIN_CODE ,SCHEDULE_CODE ,IS_ACTIVE)
VALUES  ( 25 , 17 , 4 ,1 )

SELECT * 
FROM @tmp_cabin_slot_master

INSERT INTO @tmp_section_master_withkamlist
Values  ( 17 ,10 ,'Table One' ,0 ,'1,2,3' ,'')
INSERT INTO @tmp_section_master_withkamlist
Values  ( 17 ,11 ,'Table Two' ,1 ,'4,5,6' ,'')
INSERT INTO @tmp_section_master_withkamlist
Values  ( 17 ,12 ,'Table Three' ,1 ,'4,5,6' ,'')

SELECT *
FROM @tmp_section_master_withkamlist

EXEC dbo.usp_Master_CabinTable_Save 
	@time_slots_code = 1, -- tinyint
    @time_interval_code = 4, -- tinyint
    @future_booking_day = 15, -- tinyint
    @is_active = 1, -- bit
    @cabin_code = 17, -- tinyint
    @cabin_name = 'First Cabin', -- varchar(32)
    @comment_id = 0, -- int
    @comment = 'This Is My First Commet', -- varchar(512)
    @tmp_cabin_slot_master = @tmp_cabin_slot_master, -- TMP_CABIN_SLOT_MASTER
    @tmp_section_master_withkamlist = @tmp_section_master_withkamlist, -- TMP_SECTION_MASTER_WITHKAMLIST
    @apps_code = 0, -- tinyint
    @modified_by = 0, -- smallint
    @modified_iplocation_id = 0 -- int
	
	
