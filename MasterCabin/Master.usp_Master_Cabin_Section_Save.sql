USE [srk_db]
GO

/****** Object:  StoredProcedure [Master].[usp_Master_Cabin_Section_Save]    Script Date: 03/02/2018 12:23:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Satish Kayada
-- Create date: 22/01/2018
-- Description:	This Procedure use to Save Cabin And Section Detail

-- [Master].[TMP_CABIN_SLOT_MASTER] AS TABLE(
--	[cabin_slot_id] [tinyint] NULL,
--	[cabin_code] [tinyint] NULL,
--	[schedule_code] [smallint] NULL,
--	[is_active] [bit] NULL
--)

--CREATE TYPE [Master].[TMP_SECTION_MASTER_WITHKAMLIST] AS TABLE(
--	[cabin_code] [tinyint] NULL,
--	[section_id] [tinyint] NULL,
--	[section_name] [varchar](32) NULL,
--	[is_active] [bit] NULL,
--	[kamid_List] [varchar](200) NULL,
--	[kamidRemove_List] [varchar](200) NULL
--)

-- =============================================

CREATE PROCEDURE [Master].[usp_Master_Cabin_Section_Save]

@cabin_code TINYINT,
@cabin_name VARCHAR(32),
@future_booking_day TINYINT,
@is_active BIT,
@time_slots_code TINYINT ,
@time_interval_code TINYINT,
@remark_id INT=	NULL,
@remark VARCHAR(512)=NULL,
@apps_code TINYINT=0,
@modified_by SMALLINT=0,
@modified_iplocation_id INT=0,
@tmp_cabin_slot_master Master.tmp_cabin_slot_master READONLY,
@tmp_section_master_withkamlist Master.tmp_section_master_withkamlist READONLY
AS 
BEGIN
	
	DECLARE @lactmp_section_master AS Master.TMP_SECTION_MASTER_WITHKAMLIST

	INSERT INTO @lactmp_section_master
	SELECT *
	FROM @tmp_section_master_withkamlist

	DECLARE @msg AS VARCHAR(256)

	--------------------------------------------------------------------------------
	-- variable for max value
	--------------------------------------------------------------------------------
	DECLARE @MAX_CABIN_SLOT_ID INT;
	DECLARE @MAX_REMARK_ID INT;

	DECLARE @MAX_RULE_ID INT;
	DECLARE @MAX_SECTION_ID INT;
	DECLARE @MAX_SECTION_CODE INT;

	IF Exists (SELECT 1 FROM Master.CABIN_MASTER WHERE CABIN_NAME=@cabin_name AND @cabin_code!=@cabin_code)
	BEGIN
		SET @msg='Same Cabin Name Already Exists';
		RAISERROR(@msg,18,1);
		RETURN;
    END
    IF @cabin_code>0 
	BEGIN
		IF Exists(
			SELECT 1
			FROM Master.CABIN_SLOT_MASTER
			WHERE CABIN_CODE=@cabin_code
			AND SCHEDULE_CODE IN (SELECT SCHEDULE_CODE FROM @tmp_cabin_slot_master WHERE  ISNULL(CABIN_SLOT_ID,0)=0)
			)
		BEGIN
			SET @msg='Section information Already Exists and Paramter have not pass Slot ID';
			RAISERROR(@msg,18,1);
			RETURN;
        END
	END
	-- Search if Cabin code is Zero Which means Cabin Entry Done First Time so i need to search Cabin Code
	-- At First Time operation You have to pass 0 cabin code so two user simultaneously add cabin.
	IF @cabin_code=0 
	BEGIN
		SELECT @cabin_code=MAX(Cabin_Code) FROM Master.CABIN_MASTER   
		SET @cabin_code=ISNULL(@cabin_code,0)+1
	END

	BEGIN TRY
	BEGIN TRAN
		--------------------------------------------------------------------------------
		-- For Cabin_Details
		--------------------------------------------------------------------------------
		--check cabin_id exists or not
		
		IF (EXISTS(SELECT * FROM [MASTER].[CABIN_MASTER] WHERE CABIN_CODE=@cabin_code))
		BEGIN
			--update the details of the cabin_id
			update [MASTER].[CABIN_MASTER]
			SET     IS_ACTIVE=@Is_Active,
					TIME_INTERVAL_CODE=@time_interval_code,
					FUTURE_BOOKING_DAY=@future_booking_day,
					TIME_SLOTS_CODE=@time_slots_code,
					MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
					MODIFIED_BY=@modified_by,
					MODIFIED_IPLOCATION_ID=@modified_iplocation_id
			WHERE   CABIN_CODE=@cabin_code
		END
		ELSE
		BEGIN
			INSERT INTO [MASTER].[CABIN_MASTER](CABIN_CODE,CABIN_NAME,IS_ACTIVE,TIME_SLOTS_CODE,TIME_INTERVAL_CODE,FUTURE_BOOKING_DAY,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID)
			VALUES(@cabin_code,@cabin_name,@Is_Active,@time_slots_code,@time_interval_code,@future_booking_day,Master.Fn_GetISTDATETIME(),@modified_by,@modified_iplocation_id)

		END

		--------------------------------------------------------------------------------
		-- For Update Section
		--------------------------------------------------------------------------------
		--update active status if working day present in the table
		  
		  UPDATE [MASTER].[SECTION_MASTER]  
		  SET    [MASTER].[SECTION_MASTER].IS_ACTIVE=ISNULL(tmpsection_master.IS_ACTIVE,0),
				 SECTION_MASTER.MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),SECTION_MASTER.MODIFIED_BY=@modified_by,SECTION_MASTER.MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		  FROM   [MASTER].[SECTION_MASTER] SECTION_MASTER
				INNER JOIN @lactmp_section_master AS tmpsection_master ON tmpsection_master.section_id=SECTION_MASTER.SECTION_ID
		  WHERE tmpsection_master.section_id=SECTION_MASTER.SECTION_ID
		  ------------------------------------------------------------------------------------------
		    --max cabin_slot_id
		 -----------------------------------------------------------------------------------------
		  select  @MAX_SECTION_ID = ISNULL(max(SECTION_ID),0) from [MASTER].[SECTION_MASTER] 
		  select  @MAX_SECTION_CODE = ISNULL(max(SECTION_CODE),0) from [MASTER].[SECTION_MASTER] WHERE CABIN_CODE=@cabin_code
		  --------------------------------------------------------------------------------------------------------
		  --if new field add than insert query
		  --------------------------------------------------------------------------------------------------------
		  INSERT INTO [MASTER].[SECTION_MASTER](SECTION_ID,CABIN_CODE,SECTION_CODE,SECTION_NAME,IS_ACTIVE,APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID)
		  SELECT  CAST(row_number() over (order by section_master_WithkamList.section_id) + @MAX_SECTION_ID as int) as cabin_slot_id,
		  		@cabin_code as cabin_code,
				CAST(row_number() over (order by section_master_WithkamList.section_id) + @MAX_SECTION_CODE as int),
				section_master_WithkamList.section_name,
				section_master_WithkamList.is_active,
				@apps_code,
				Master.Fn_GetISTDATETIME(),
				@modified_by,
				@modified_iplocation_id
		  From @lactmp_section_master section_master_WithkamList
		  WHERE ISNULL(section_master_WithkamList.section_id,0)=0


		--************************************************************
		--------------------------------------------------------------------------------
		-- For WORKING DAYS
		--------------------------------------------------------------------------------

		--update active status if working day present in the table
		  
		  UPDATE CABIN_SLOT_MASTER 
		  SET    CABIN_SLOT_MASTER.IS_ACTIVE=ISNULL(tmpcabin_slot_master.IS_ACTIVE,0)
				 ,CABIN_SLOT_MASTER.MODIFIED_DATETIME=Master.Fn_GetISTDATETIME()
				 ,CABIN_SLOT_MASTER.MODIFIED_BY=@modified_by
				 ,CABIN_SLOT_MASTER.MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		  FROM   [MASTER].[CABIN_SLOT_MASTER] CABIN_SLOT_MASTER 
				Left JOIN @tmp_cabin_slot_master tmpcabin_slot_master ON cabin_slot_master.CABIN_SLOT_ID=tmpcabin_slot_master.CABIN_SLOT_ID
		  WHERE  cabin_slot_master.CABIN_SLOT_ID=tmpcabin_slot_master.CABIN_SLOT_ID

		------------------------------------------------------------------------------------------
		   --max cabin_slot_id
		-----------------------------------------------------------------------------------------
		   select  @MAX_CABIN_SLOT_ID = ISNULL(max(CABIN_SLOT_ID),0) from [MASTER].[CABIN_SLOT_MASTER]
		--------------------------------------------------------------------------------------------------------
		  --if new field add than insert query
		--------------------------------------------------------------------------------------------------------
		  INSERT INTO [MASTER].[CABIN_SLOT_MASTER](CABIN_SLOT_ID,CABIN_CODE,SCHEDULE_CODE,IS_ACTIVE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID)
		  SELECT  CAST(row_number() over (order by schedule_code) + @max_cabin_slot_id as int) as cabin_slot_id,
		  		@cabin_code as cabin_code,
		  		cabin_slot_master.schedule_code as schedule_code,
		  		cabin_slot_master.is_active as is_active ,
				Master.Fn_GetISTDATETIME(),
				@modified_by ,
				@modified_iplocation_id
		  From @tmp_cabin_slot_master cabin_slot_master
		  WHERE ISNULL(cabin_slot_master.cabin_slot_id,0)=0

		----****************************************************************************
		-----------------------------------------------------------------------------------------
		----for remarks
		-----------------------------------------------------------------------------------------
		
		----------------------------------------------------------------------------------------------------------
		----remark id not found than insert
		----------------------------------------------------------------------------------------------------------
		
		IF (@remark_id is null)
		BEGIN
			INSERT INTO [STOCK].[REMARKS](REMARK_TEXT,SOURCE_ID,REMARK_TYPE_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID)
			VALUES(@remark,@cabin_code,MASTER.getRemarkCode('cabin_remark'),Master.Fn_GetISTDATETIME(),@modified_by,@modified_iplocation_id)
		END
		ELSE --if remark id found
		BEGIN
			UPDATE [STOCK].[REMARKS]
			SET  REMARK_TEXT=@remark,
			MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),MODIFIED_BY=@modified_by,MODIFIED_IPLOCATION_ID=@modified_iplocation_id
			WHERE SOURCE_ID=@cabin_code AND REMARK_ID=@remark_id
		END



		  UPDATE section_master_withkamlist 
		  SET section_master_withkamlist.section_id=Master.SECTION_MASTER.SECTION_ID
		  FROM  @lactmp_section_master section_master_withkamlist
				Left JOIN Master.SECTION_MASTER ON SECTION_MASTER.CABIN_CODE=@cabin_code AND SECTION_MASTER.SECTION_NAME=section_master_withkamlist.Section_Name
		  WHERE ISNULL(section_master_WithkamList.section_id,0)=0

		  

		DECLARE @max_rule_code   SMALLINT=0
		DECLARE @max_kam_slot_id SMALLINT=0

		SELECT @max_rule_code  = ISNULL(MAX(RULE_CODE),0)   FROM Master.KAM_VISIT_RULES_MASTER
		SELECT @max_kam_slot_id= ISNULL(MAX(KAM_SLOT_ID),0) FROM Master.KAM_SLOT_MASTER
  
		---- KAM Slot Master
		---- Insert And Update Of KAM Slot Master

		select  @MAX_RULE_ID = ISNULL(max(RULE_CODE),0) from [MASTER].KAM_VISIT_RULES_MASTER

		INSERT INTO Master.KAM_VISIT_RULES_MASTER
				( RULE_CODE ,
				  USER_CODE ,
				  SECTION_ID ,
				  IS_ACTIVE ,
				  APPS_CODE ,
				  CREATED_DATETIME ,
				  CREATED_BY,
				  CREATED_IPLOCATION_ID
				)
		SELECT 
		 CAST(ROW_NUMBER() OVER (ORDER BY TmpSec.section_id) + @MAX_RULE_ID AS INT) AS Rule_Code,
		 i.Value AS user_code,
		 TmpSec.section_id,
		 TmpSec.is_active AS IsActive,
		 @apps_code,
		 Master.Fn_GetISTDATETIME(),
		 @modified_by,
		 @modified_iplocation_id
		FROM @lactmp_section_master TmpSec
			CROSS APPLY dbo.split(TmpSec.kamid_List, ',') i
		WHERE NOT EXISTS(
							SELECT 1 
							FROM Master.KAM_VISIT_RULES_MASTER Kam
							WHERE Kam.SECTION_ID=TmpSec.section_id 
							AND Kam.USER_CODE=i.Value
						)

		UPDATE Master.KAM_VISIT_RULES_MASTER 
		SET KAM_VISIT_RULES_MASTER.IS_ACTIVE=1,
		KAM_VISIT_RULES_MASTER.MODIFIED_DATETIME=dbo.SOL_GetISTDATETIME(),
		KAM_VISIT_RULES_MASTER.MODIFIED_BY=@modified_by,
		KAM_VISIT_RULES_MASTER.MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		FROM Master.KAM_VISIT_RULES_MASTER 
			LEFT JOIN 
			(
				SELECT 
					i.Value AS user_code,
					TmpSec.section_id,
					TmpSec.is_active AS IsActive
				FROM @lactmp_section_master TmpSec
					CROSS APPLY dbo.split(TmpSec.kamid_List, ',') i
			) AS tmpSec ON tmpSec.section_id = KAM_VISIT_RULES_MASTER.SECTION_ID AND tmpSec.user_code = KAM_VISIT_RULES_MASTER.USER_CODE
		WHERE ISNULL(KAM_VISIT_RULES_MASTER.IS_ACTIVE,0)=0
		AND tmpSec.user_code IS NOT NULL


		UPDATE Master.KAM_VISIT_RULES_MASTER 
		SET KAM_VISIT_RULES_MASTER.IS_ACTIVE=0,
		KAM_VISIT_RULES_MASTER.MODIFIED_DATETIME=dbo.SOL_GetISTDATETIME(),
		KAM_VISIT_RULES_MASTER.MODIFIED_BY=@modified_by,
		KAM_VISIT_RULES_MASTER.MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		FROM Master.KAM_VISIT_RULES_MASTER 
			LEFT JOIN 
			(
				SELECT 
					i.Value AS user_code,
					TmpSec.section_id,
					TmpSec.is_active AS IsActive
				FROM @lactmp_section_master TmpSec
					CROSS APPLY dbo.split(TmpSec.kamidRemove_List, ',') i
			) AS tmpSec ON tmpSec.section_id = KAM_VISIT_RULES_MASTER.SECTION_ID AND tmpSec.user_code = KAM_VISIT_RULES_MASTER.USER_CODE
		WHERE ISNULL(KAM_VISIT_RULES_MASTER.IS_ACTIVE,0)=1
		AND tmpSec.user_code IS NOT NULL

	COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SELECT  @msg =ERROR_MESSAGE()
		RAISERROR(@msg,18,1)
	END CATCH

END
GO


