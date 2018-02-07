--Done
USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_SectionAvailabilityReport_List]    Script Date: 06/02/2018 2:11:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 02/02/2018
-- Description:	List for checking Availability of cabin sectionwise
-- =============================================

 
CREATE PROCEDURE [Stock].[usp_Appointment_SectionAvailabilityReport_List]
    
AS
BEGIN
	Declare @MySchedule TABLE (slot_id TINYINT identity(1,1), cabin_code tinyint, section_code smallint, section_id smallint, slotname varchar(16), from_time TIME, to_time TIME, isactive bit,no_of_person int)

	insert into @MySchedule ( cabin_code, section_code, section_id, slotname, from_time, to_time,no_of_person )
	SELECT CabinMast.cabin_code cabin_code, SectionMast.section_code section_code, section_id, 'Start' section_name, NULL from_time, CONVERT(TIME,Master.Fn_GetISTDATETIME()) to_time,0 no_of_person
	FROM Master.CABIN_MASTER CabinMast
	LEFT JOIN Master.SECTION_MASTER SectionMast on SectionMast.cabin_code = CabinMast.cabin_code
	LEFT JOIN Master.DAYS_MASTER DayMaster on DayMaster.DAY_NAME = DATENAME(weekday,Master.Fn_GetISTDATETIME())
	LEFT JOIN Master.SCHEDULE_MASTER ScheduleMast on ScheduleMast.DAY_ID = DayMaster.DAY_ID
	--where ScheduleMast.FROM_TIME >= CONVERT(TIME,Master.Fn_GetISTDATETIME())
	UNION ALL
	SELECT CabinMast.cabin_code, SectionMast.section_code, VisitDet.section_id, '' slotname, MAX(VisitDet.SECTION_SLOT_FROM_TIME), MAX(VisitDet.SECTION_SLOT_TO_TIME),
	party_contacts_count.count_party_contacts no_of_person
	FROM Master.CABIN_MASTER CabinMast
	LEFT JOIN Master.DAYS_MASTER DayMaster on DayMaster.DAY_NAME = DATENAME(weekday,Master.Fn_GetISTDATETIME())
	LEFT JOIN Master.SCHEDULE_MASTER ScheduleMast on ScheduleMast.DAY_ID = DayMaster.DAY_ID
	LEFT JOIN Master.CABIN_SLOT_MASTER CabinSlot on CabinSlot.cabin_code = CabinMast.cabin_code and CabinSlot.SCHEDULE_CODE = ScheduleMast.SCHEDULE_CODE
	LEFT JOIN Master.SECTION_MASTER SectionMast on SectionMast.cabin_code = CabinMast.cabin_code
	LEFT JOIN Stock.VISIT VisitMast on VisitMast.VISIT_DATE = CONVERT(DATE,Master.Fn_GetISTDATETIME()) and VisitMast.VISIT_FROM_TIME >= ScheduleMast.FROM_TIME and VisitMast.VISIT_TO_TIME <= ScheduleMast.TO_TIME
		And CONVERT(TIME,Master.Fn_GetISTDATETIME()) between ScheduleMast.FROM_TIME and ScheduleMast.TO_TIME
	LEFT JOIN Stock.VISIT_DETAIL VisitDet on VisitDet.VISIT_ID = VisitMast.VISIT_ID and VisitDet.SECTION_ID = SectionMast.section_id

	LEFT OUTER JOIN (SELECT VISIT_ID, COUNT(PARTY_CONTACTS_CODE) count_party_contacts FROM Stock.VISIT_CONTACTS  GROUP BY VISIT_ID) party_contacts_count
			ON party_contacts_count.VISIT_ID = VisitMast.VISIT_ID


	where VisitMast.VISIT_TO_TIME >= CONVERT(TIME,Master.Fn_GetISTDATETIME())
	Group by CabinMast.cabin_code, SectionMast.section_code, VisitDet.section_id,party_contacts_count.count_party_contacts
	UNION ALL
	SELECT CabinMast.cabin_code, SectionMast.section_code, section_id, 'Stop', ScheduleMast.TO_TIME, NULL,0
	FROM Master.CABIN_MASTER CabinMast
	LEFT JOIN Master.SECTION_MASTER SectionMast on SectionMast.cabin_code = CabinMast.cabin_code
	LEFT JOIN Master.DAYS_MASTER DayMaster on DayMaster.DAY_NAME = DATENAME(weekday,Master.Fn_GetISTDATETIME())
	LEFT JOIN Master.SCHEDULE_MASTER ScheduleMast on ScheduleMast.DAY_ID = DayMaster.DAY_ID
	where ScheduleMast.TO_TIME >= CONVERT(TIME,Master.Fn_GetISTDATETIME())
	order by cabin_code, section_code, from_time, to_time

	Select Avail.cabin_code, Avail.section_code, Avail.cabin_name, Avail.section_name, Avail.no_of_person, Avail.to_time, Avail.next_from_time, Avail.next_to_time, 
		DATEDIFF(MINUTE,CONVERT(TIME,Master.Fn_GetISTDATETIME()),to_time) availafter,
		CASE When (next_to_time is not null) THEN DATEDIFF(minute,CONVERT(TIME,Master.Fn_GetISTDATETIME()),next_from_time) ELSE 0 End availtill
	From (
		SELECT a.cabin_code, a.section_code,cabin_master.cabin_name,section_master.section_name, 
			MAX(a.no_of_person) no_of_person, MIN(a.to_time) to_time, MIN(b.from_time) next_from_time, MIN(b.to_time) next_to_time
		FROM @MySchedule a
		INNER JOIN @MySchedule b on a.cabin_code = b.cabin_code and a.section_code = b.section_code and a.slot_id = (b.slot_id -1)
		LEFT OUTER JOIN Master.CABIN_MASTER cabin_master ON a.cabin_code=cabin_master.cabin_code
		LEFT OUTER JOIN Master.SECTION_MASTER section_master ON a.cabin_code=section_master.cabin_code
																AND a.section_code=section_master.section_code
		Where DATEDIFF(minute,a.to_time, b.from_time) >= 5
		Group by a.cabin_code, a.section_code,cabin_master.cabin_name,section_master.section_name
	) As Avail

	--SELECT a.cabin_code, a.section_code,cabin_master.cabin_name,section_master.section_name,a.no_of_person, 
	--	   --RIGHT('0' + CAST(DATEDIFF(SECOND,CONVERT(TIME,Master.Fn_GetISTDATETIME()),a.to_time) / 3600 AS VARCHAR),2) + ':' +
	--	   --RIGHT('0' + CAST((DATEDIFF(SECOND,CONVERT(TIME,Master.Fn_GetISTDATETIME()),a.to_time) / 60) % 60 AS VARCHAR),2) + ':' +
	--	   --RIGHT('0' + CAST(DATEDIFF(SECOND,CONVERT(TIME,Master.Fn_GetISTDATETIME()),a.to_time) % 60 AS VARCHAR),2) availafterhr,

	--DATEDIFF(MINUTE,CONVERT(TIME,Master.Fn_GetISTDATETIME()),a.to_time) availafter,
	----Case When (b.to_time is not null) THEN DATEDIFF(minute,CONVERT(TIME,Master.Fn_GetISTDATETIME()),b.from_time) Else 0 End availtill,

	--	   CASE When (b.to_time is not null) THEN 
	--		DATEDIFF(minute,CONVERT(TIME,Master.Fn_GetISTDATETIME()),b.from_time) 
	--		--RIGHT('0' + CAST(DATEDIFF(minute,CONVERT(TIME,Master.Fn_GetISTDATETIME()),b.from_time)  / 3600 AS VARCHAR),2) + ':' +
	--		--RIGHT('0' + CAST((DATEDIFF(minute,CONVERT(TIME,Master.Fn_GetISTDATETIME()),b.from_time)  / 60) % 60 AS VARCHAR),2) + ':' +
	--		--RIGHT('0' + CAST(DATEDIFF(minute,CONVERT(TIME,Master.Fn_GetISTDATETIME()),b.from_time)  % 60 AS VARCHAR),2)
	--ELSE 0 End availtill,
	--a.from_time, a.to_time, b.from_time, b.to_time
	--FROM @MySchedule a
	--INNER JOIN @MySchedule b on a.cabin_code = b.cabin_code and a.section_code = b.section_code and a.slot_id = (b.slot_id -1)
	--LEFT OUTER JOIN Master.CABIN_MASTER cabin_master ON a.cabin_code=cabin_master.cabin_code
	--LEFT OUTER JOIN Master.SECTION_MASTER section_master ON a.cabin_code=section_master.cabin_code
	--														AND a.section_code=section_master.section_code
	--Where DATEDIFF(minute,a.to_time, b.from_time) >= 5
 
END
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Appointment_Upsert]    Script Date: 06/02/2018 2:11:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 17/01/2018
-- Description:	Save & Update Appointment
--CREATE TYPE [Stock].[STONEID] AS TABLE(
--	[stoneid] [VARCHAR](16) NULL
--)
--GO


-- =============================================

-- Drop Procedure Stock.usp_Appointment_Appointment_Upsert

CREATE PROCEDURE  [Stock].[usp_Appointment_Appointment_Upsert]
    @visit_id INT=0,
   
	@party_code int = 0,
    @visit_date datetime = '',
    @visit_from_time time = '',
    @visit_to_time time = '',
    @is_active bit = 0,
    @STONEID AS Stock.STONEID READONLY,
	@REMOVED_STONEID AS Stock.REMOVED_STONEID READONLY,
	@section_id smallint= 0,
    @remark_text varchar(512)= '',
    @tablevar_visit_contacts [Stock].[tablevar_visit_contacts] READONLY,
    @tablevar_visit_contacts_kam [Stock].[tablevar_visit_contacts_kam] READONLY,
	@customer_feedback_rating smallint=0,
	@cusotmer_feedback_remark varchar(512)='',
	@kam_feedback_rating smallint=0,
	@kam_feedback_remark varchar(512)='',
	@operation_type varchar(2)='',
    @apps_code tinyint = 0,
    @created_iplocation_id int= 0,
	@created_by smallint=0
AS
    BEGIN

    DECLARE  @appointment_id INT = 0

	IF(@operation_type='I')
     BEGIN

			DECLARE   @WEEK_START_DATE DATETIME,
			@WEEK_END_DATE DATETIME;


			SELECT  @WEEK_START_DATE = DATEADD(DAY, 2 - 5, Master.Fn_GetISTDATETIME()),
					@WEEK_END_DATE = DATEADD(DAY, 8 - 5, Master.Fn_GetISTDATETIME());

			SELECT  @WEEK_START_DATE,@WEEK_END_DATE;

			SELECT  @APPOINTMENT_ID = ISNULL(( SELECT TOP 1
                                            APPOINTMENT_ID
                                   FROM     Stock.APPOINTMENT
                                   WHERE    PARTY_CODE = @PARTY_CODE
                                            AND CREATED_DATETIME BETWEEN @WEEK_START_DATE
                                                              AND
                                                              @WEEK_END_DATE
                                 ), 0)



			IF ( @APPOINTMENT_ID = 0 )
			BEGIN

					SELECT  @APPOINTMENT_ID = ( ISNULL(( SELECT MAX(APPOINTMENT_ID)
                                             FROM   Stock.APPOINTMENT
                                             WHERE  PARTY_CODE = @PARTY_CODE
                                           ), 0) ) + 1
					INSERT INTO Stock.APPOINTMENT
								( APPOINTMENT_ID,PARTY_CODE,APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID)
					VALUES(@APPOINTMENT_ID,@PARTY_CODE,@APPS_CODE,Master.Fn_GetISTDATETIME(),@created_by,@CREATED_IPLOCATION_ID)
			END;


			INSERT INTO Stock.VISIT
						( APPOINTMENT_ID,PARTY_CODE,VISIT_DATE,VISIT_FROM_TIME,VISIT_TO_TIME,IS_ACTIVE,
						  APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID )
			VALUES		(@APPOINTMENT_ID,@party_code,@VISIT_DATE,@VISIT_FROM_TIME,@VISIT_TO_TIME,@IS_ACTIVE,
						 @APPS_CODE,Master.Fn_GetISTDATETIME(),@created_by,@CREATED_IPLOCATION_ID)
		
			SELECT @visit_id = @@IDENTITY 

			INSERT INTO Stock.VISIT_DETAIL
						( VISIT_ID,STONEID,SECTION_ID,SECTION_SLOT_FROM_TIME,SECTION_SLOT_TO_TIME, APPS_CODE,
						  CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID )
			SELECT	  @visit_id, stoneid,@section_id,@visit_from_time,@visit_to_time,@apps_code,
					  Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id
					  FROM @STONEID--Master.Split(@stoneid_list,',')
	 
			INSERT INTO Stock.VISIT_CONTACTS
					   ( VISIT_ID,PARTY_CONTACTS_CODE,PARTY_ROLE_CODE,CONTACTS_LOCAL_COUNTRY_CODE,
						 CONTACTS_LOCAL_PHONE_NUMBER,APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID)
			SELECT @VISIT_ID,PARTY_CONTACTS_CODE,PARTY_ROLE_CODE,CONTACTS_LOCAL_COUNTRY_CODE,
					CONTACTS_LOCAL_PHONE_NUMBER,@apps_code,Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id
			FROM @tablevar_visit_contacts
	  

			INSERT INTO Stock.VISIT_CONTACTS_KAM
			        ( VISIT_CONTACTS_ID,PARTY_CONTACTS_KAM_CODE,APPS_CODE,CREATED_DATETIME,
					  CREATED_BY,CREATED_IPLOCATION_ID   )
			 SELECT visit_contact.VISIT_CONTACTS_ID,tablevar_visit_contacts_kam.PARTY_CONTACTS_KAM_CODE,@apps_code,Master.Fn_GetISTDATETIME(),
					@created_by,@created_iplocation_id
			 FROM @tablevar_visit_contacts_kam tablevar_visit_contacts_kam
			 INNER JOIN Stock.VISIT_CONTACTS visit_contact ON 
			 visit_contact.PARTY_CONTACTS_CODE = tablevar_visit_contacts_kam.PARTY_CONTACTS_CODE
			 WHERE visit_contact.VISIT_ID=@VISIT_ID

	 END
	 ELSE
	 BEGIN
		UPDATE Stock.VISIT SET VISIT_DATE=@visit_date,
		VISIT_FROM_TIME=@visit_from_time,VISIT_TO_TIME=@visit_to_time,
		IS_ACTIVE=@is_active,MODIFIED_BY=@created_by,MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
		MODIFIED_IPLOCATION_ID=@created_iplocation_id
		WHERE VISIT_ID=@visit_id

		DELETE FROM Stock.VISIT_DETAIL 
		WHERE STONEID IN (SELECT stoneid FROM @REMOVED_STONEID) AND VISIT_ID=@visit_id
		 
		 INSERT INTO Stock.VISIT_DETAIL
		         ( VISIT_ID ,STONEID ,SECTION_ID ,SECTION_SLOT_FROM_TIME ,SECTION_SLOT_TO_TIME ,
				   APPS_CODE ,MODIFIED_DATETIME ,MODIFIED_BY ,MODIFIED_IPLOCATION_ID  )
		 SELECT @visit_id, newstone.stoneid,@section_id,@visit_from_time,@visit_to_time,
				@apps_code,Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id
		FROM @STONEID newstone --Master.Split(@stoneid_list,',') 
		WHERE NOT EXISTS (  SELECT 1 FROM Stock.VISIT_DETAIL visit_detail
							WHERE visit_detail.STONEID = newstone.stoneid AND visit_detail.VISIT_ID=@visit_id
						  )


		  DELETE VISIT_CONTACTS_KAM FROM Stock.VISIT_CONTACTS_KAM VISIT_CONTACTS_KAM
		  LEFT OUTER JOIN Stock.VISIT_CONTACTS VISIT_CONTACTS ON VISIT_CONTACTS.VISIT_CONTACTS_ID = visit_contacts_kam.VISIT_CONTACTS_ID
		  LEFT OUTER JOIN @tablevar_visit_contacts_kam tablevar_visit_kam ON 
						  tablevar_visit_kam.party_contacts_kam_code = visit_contacts_kam.PARTY_CONTACTS_KAM_CODE 
						  --tablevar_visit_kam.party_contacts_code = visit_contacts_kam.PARTY_CONTACTS_CODE
		  WHERE VISIT_CONTACTS.VISIT_ID=@visit_id	AND tablevar_visit_kam.is_active=0

		  DELETE VISIT_CONTACTS FROM Stock.VISIT_CONTACTS  VISIT_CONTACTS
		  LEFT OUTER JOIN @tablevar_visit_contacts tabvar_visit_contacts ON 
						tabvar_visit_contacts.party_contacts_code = visit_contacts.PARTY_CONTACTS_CODE AND
						tabvar_visit_contacts.party_role_code = visit_contacts.PARTY_ROLE_CODE
		  WHERE visit_contacts.VISIT_ID=@visit_id AND tabvar_visit_contacts.is_active=0
		
		 
		 INSERT INTO Stock.VISIT_CONTACTS
		         ( VISIT_ID ,PARTY_CONTACTS_CODE ,PARTY_ROLE_CODE ,APPS_CODE ,
				   CREATED_DATETIME ,CREATED_BY ,CREATED_IPLOCATION_ID ,
				   CONTACTS_LOCAL_COUNTRY_CODE ,CONTACTS_LOCAL_PHONE_NUMBER )
		  
		  SELECT @visit_id,tablevar_visit_contacts.party_contacts_code,tablevar_visit_contacts.party_role_code,@apps_code,
				 Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id,
				 tablevar_visit_contacts.contacts_local_country_code,tablevar_visit_contacts.contacts_local_phone_number
		  FROM @tablevar_visit_contacts tablevar_visit_contacts
		  WHERE  NOT EXISTS (
						   SELECT 1
						    FROM Stock.VISIT_CONTACTS visit_contacts
						   WHERE visit_contacts.PARTY_CONTACTS_CODE=tablevar_visit_contacts.party_contacts_code
						   AND visit_contacts.PARTY_ROLE_CODE=tablevar_visit_contacts.party_role_code
						   AND visit_contacts.VISIT_ID=@visit_id
						) AND tablevar_visit_contacts.is_active=1


		UPDATE visit_contact
		SET visit_contact.CONTACTS_LOCAL_COUNTRY_CODE=tablevar_visit_contacts.contacts_local_country_code,
		visit_contact.CONTACTS_LOCAL_PHONE_NUMBER=tablevar_visit_contacts.contacts_local_phone_number
		  FROM @tablevar_visit_contacts tablevar_visit_contacts
		  LEFT OUTER JOIN Stock.VISIT_CONTACTS visit_contact ON visit_contact.PARTY_CONTACTS_CODE = tablevar_visit_contacts.party_contacts_code
		  AND visit_contact.PARTY_ROLE_CODE = tablevar_visit_contacts.party_role_code
		  WHERE  EXISTS (
						   SELECT 1
						   FROM Stock.VISIT_CONTACTS visit_contacts
						   WHERE visit_contacts.PARTY_CONTACTS_CODE=tablevar_visit_contacts.party_contacts_code
						   AND visit_contacts.PARTY_ROLE_CODE=tablevar_visit_contacts.party_role_code
						   AND visit_contacts.VISIT_ID=@visit_id
						) AND tablevar_visit_contacts.is_active=1
						 

		--INSERT INTO Stock.VISIT_CONTACTS_KAM
		--        ( VISIT_CONTACTS_ID ,PARTY_CONTACTS_KAM_CODE ,APPS_CODE ,CREATED_DATETIME ,
		--		  CREATED_BY ,CREATED_IPLOCATION_ID )
		SELECT visit_contact.VISIT_CONTACTS_ID,tablevar_visit_contacts_kam.party_contacts_kam_code,@apps_code,Master.Fn_GetISTDATETIME(),
				@created_by,@created_iplocation_id
		FROM @tablevar_visit_contacts_kam tablevar_visit_contacts_kam
		LEFT OUTER JOIN Stock.VISIT_CONTACTS visit_contact ON visit_contact.PARTY_CONTACTS_CODE = tablevar_visit_contacts_kam.party_contacts_code
		 
		WHERE  NOT  EXISTS (
							SELECT 1
							FROM Stock.VISIT_CONTACTS_KAM visit_contacts_kam
							INNER JOIN Stock.VISIT_CONTACTS visit_contacts ON visit_contacts.VISIT_CONTACTS_ID = visit_contacts_kam.VISIT_CONTACTS_ID
							WHERE visit_contacts.PARTY_CONTACTS_CODE=tablevar_visit_contacts_kam.party_contacts_code
							AND tablevar_visit_contacts_kam.party_contacts_kam_code=visit_contacts_kam.PARTY_CONTACTS_KAM_CODE
							AND visit_contacts.VISIT_ID=@visit_id
						)
				AND tablevar_visit_contacts_kam.is_active=1

			UPDATE visit_kam
			SET visit_kam.PARTY_CONTACTS_KAM_CODE=tablevar_visit_contacts_kam.party_contacts_kam_code
			
				FROM @tablevar_visit_contacts_kam tablevar_visit_contacts_kam
				LEFT JOIN Stock.VISIT_CONTACTS_KAM visit_kam ON visit_kam.PARTY_CONTACTS_KAM_CODE = tablevar_visit_contacts_kam.party_contacts_kam_code
		 
		WHERE    EXISTS (
							SELECT 1
							FROM Stock.VISIT_CONTACTS_KAM visit_contacts_kam
							INNER JOIN Stock.VISIT_CONTACTS visit_contacts ON visit_contacts.VISIT_CONTACTS_ID = visit_contacts_kam.VISIT_CONTACTS_ID
							WHERE visit_contacts.PARTY_CONTACTS_CODE=tablevar_visit_contacts_kam.party_contacts_code
							AND tablevar_visit_contacts_kam.party_contacts_kam_code=visit_contacts_kam.PARTY_CONTACTS_KAM_CODE
							AND visit_contacts.VISIT_ID=@visit_id
						)
				AND tablevar_visit_contacts_kam.is_active=1

		 
	 END
     



     

	 IF(@remark_text<>'')
	 BEGIN

	 
		INSERT INTO Stock.REMARKS
		        ( SOURCE_ID,REMARK_TEXT,REMARK_FROM,REMARK_TYPE_CODE,
				  APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID )

		VALUES  (@VISIT_ID,@remark_text,@created_by,Master.getRemarkCode('appointment_remark'),
		@apps_code,Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id)	 
	 END
     

	 IF(@customer_feedback_rating <> 0 OR @cusotmer_feedback_remark <>'')
	 BEGIN
		INSERT INTO Stock.FEEDBACK
		        ( SOURCE_ID ,FEEDBACK_REMARK ,FEEDBACK_RATING ,FEEDBACK_FROM ,FEEDBACK_CATEGORY_CODE ,
				  APPS_CODE ,CREATED_DATETIME ,CREATED_BY ,CREATED_IPLOCATION_ID )
		VALUES	(@VISIT_ID,@cusotmer_feedback_remark,@customer_feedback_rating,@created_by,Master.getFeedbackCode('customer_feedback'),
				@apps_code,Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id)
	 END 
	 

	  IF(@kam_feedback_rating <> 0 OR @kam_feedback_remark <>'')
	 BEGIN
		INSERT INTO Stock.FEEDBACK
		        ( SOURCE_ID ,FEEDBACK_REMARK ,FEEDBACK_RATING ,FEEDBACK_FROM ,FEEDBACK_CATEGORY_CODE ,
				  APPS_CODE ,CREATED_DATETIME ,CREATED_BY ,CREATED_IPLOCATION_ID )
		VALUES	(@VISIT_ID,@kam_feedback_remark,@kam_feedback_rating,@created_by,Master.getFeedbackCode('kam_remark_feedback'),
				@apps_code,Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id)
	 END 
     
    END

	--select * from Stock.VISIT_CONTACTS

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Appointment_Save]    Script Date: 06/02/2018 2:11:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 17/01/2018
-- Description:	Save Appointment
-- =============================================

-- Drop Procedure Stock.usp_Appointment_Appointment_Save

CREATE PROCEDURE [Stock].[usp_Appointment_Appointment_Save]
    @party_code int = 0,
    @visit_date datetime = NULL,
    @visit_from_time time = null,
    @visit_to_time time = null,
    @is_active bit = 0,
    @stoneid AS Stock.STONEID READONLY,
	@section_id smallint= 0,
    @remark_text varchar(512)= '',
    @tablevar_visit_contacts [Stock].[TABLEVAR_VISIT_CONTACTS] READONLY,
    @tablevar_visit_contacts_kam [Stock].[TABLEVAR_VISIT_CONTACTS_KAM] READONLY,
    @apps_code tinyint = 0,
    @user_code smallint= 0,
    @created_iplocation_id int= 0,
	@created_by smallint=0
AS
    BEGIN

         
DECLARE @VISIT_ID INT,
    @APPOINTMENT_ID INT = 0,
    @VISIT_CONTACT_ID INT,
    @WEEK_START_DATE DATETIME,
    @WEEK_END_DATE DATETIME;


SELECT  @WEEK_START_DATE = DATEADD(DAY, 2 - 5, Master.Fn_GetISTDATETIME()),
        @WEEK_END_DATE = DATEADD(DAY, 8 - 5, Master.Fn_GetISTDATETIME());

SELECT  @WEEK_START_DATE,
        @WEEK_END_DATE;

SELECT  @APPOINTMENT_ID = ISNULL(( SELECT TOP 1
                                            APPOINTMENT_ID
                                   FROM     Stock.APPOINTMENT
                                   WHERE    PARTY_CODE = @PARTY_CODE
                                            AND CREATED_DATETIME BETWEEN @WEEK_START_DATE
                                                              AND
                                                              @WEEK_END_DATE
                                 ), 0)



IF ( @APPOINTMENT_ID = 0 )
    BEGIN

        SELECT  @APPOINTMENT_ID = ( ISNULL(( SELECT MAX(APPOINTMENT_ID)
                                             FROM   Stock.APPOINTMENT
                                             WHERE  PARTY_CODE = @PARTY_CODE
                                           ), 0) ) + 1
		INSERT INTO Stock.APPOINTMENT
		        ( APPOINTMENT_ID,PARTY_CODE,APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID)
		VALUES(@APPOINTMENT_ID,@PARTY_CODE,@APPS_CODE,Master.Fn_GetISTDATETIME(),@created_by,@CREATED_IPLOCATION_ID)
    END;


	INSERT INTO Stock.VISIT
	        ( APPOINTMENT_ID,PARTY_CODE,VISIT_DATE,VISIT_FROM_TIME,VISIT_TO_TIME,IS_ACTIVE,
			  APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID )
	VALUES  (@APPOINTMENT_ID,@party_code,@VISIT_DATE,@VISIT_FROM_TIME,@VISIT_TO_TIME,@IS_ACTIVE,
			 @APPS_CODE,Master.Fn_GetISTDATETIME(),@created_by,@CREATED_IPLOCATION_ID)

	SELECT @VISIT_ID = @@IDENTITY 

	INSERT INTO Stock.VISIT_DETAIL
	        ( VISIT_ID,STONEID,SECTION_ID,SECTION_SLOT_FROM_TIME,SECTION_SLOT_TO_TIME, APPS_CODE,
			 CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID )
	SELECT	  @VISIT_ID,stoneid,@section_id,@visit_from_time,@visit_to_time,@apps_code,
	Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id
		 FROM @stoneid
	 
	 INSERT INTO Stock.VISIT_CONTACTS
	         ( VISIT_ID,PARTY_CONTACTS_CODE,PARTY_ROLE_CODE,CONTACTS_LOCAL_COUNTRY_CODE,
			   CONTACTS_LOCAL_PHONE_NUMBER,APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID)
	SELECT @VISIT_ID,PARTY_CONTACTS_CODE,PARTY_ROLE_CODE,CONTACTS_LOCAL_COUNTRY_CODE,
	CONTACTS_LOCAL_PHONE_NUMBER,@apps_code,Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id
	 FROM @tablevar_visit_contacts
	  

	INSERT INTO Stock.VISIT_CONTACTS_KAM
	        ( VISIT_CONTACTS_ID,PARTY_CONTACTS_KAM_CODE,APPS_CODE,CREATED_DATETIME,
			  CREATED_BY,CREATED_IPLOCATION_ID   )
	 SELECT visit_contact.VISIT_CONTACTS_ID,tablevar_visit_contacts_kam.PARTY_CONTACTS_KAM_CODE,@apps_code,Master.Fn_GetISTDATETIME(),
			@created_by,@created_iplocation_id
	  FROM @tablevar_visit_contacts_kam tablevar_visit_contacts_kam
	 INNER JOIN Stock.VISIT_CONTACTS visit_contact ON 
	 visit_contact.PARTY_CONTACTS_CODE = tablevar_visit_contacts_kam.PARTY_CONTACTS_CODE
	 WHERE visit_contact.VISIT_ID=@VISIT_ID

	 IF(@remark_text<>'')
	 BEGIN

	 DECLARE @REMARK_TYPE_CODE INT=0
		SELECT @REMARK_TYPE_CODE= REMARK_TYPE_CODE FROM Master.REMARK_TYPE_MASTER WHERE REMARK_TYPE_KEY='appointment_remark'

		INSERT INTO Stock.REMARKS
		        ( SOURCE_ID,REMARK_TEXT,REMARK_FROM,REMARK_TYPE_CODE,
				  APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID )

		VALUES  (@VISIT_ID,@remark_text,@user_code,@REMARK_TYPE_CODE,
		@apps_code,Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id)	 
	 End

     
    END

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_StoneDetails_List]    Script Date: 06/02/2018 2:11:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 27/01/2018
-- Description:	List Stone detail from appointment
-- =============================================

CREATE PROCEDURE [Stock].[usp_Appointment_StoneDetails_List]
   @STONEID Stock.STONEID READONLY
AS
    BEGIN

         
        SELECT s.stoneid ,issue_carat ,cut_short_name ,polish_short_name ,
			   symmetry_short_name ,floro_short_name,shape_name,color_short_name
		FROM Packet.view_Stone_Details s
		LEFT JOIN  @STONEID stone ON stone.stoneid = s.stoneid
		WHERE 1=1
			AND stone.stoneid = s.stoneid
		--WHERE stoneid IN (SELECT value FROM Master.Split(@stoneid_list,','))

     
    END

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_CountAvailableUnavailableStone_List]    Script Date: 06/02/2018 2:11:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 25/01/2018
-- Description:	Count Available and not available sotne with carat form appointment
-- =============================================

CREATE PROCEDURE [Stock].[usp_Appointment_CountAvailableUnavailableStone_List]
    @STONEID Stock.STONEID READONLY
AS
    BEGIN

         
        SELECT  ISNULL(sum(tmp.available_stone),0) count_availble_stone , ISNULL(sum(tmp.unavailable_stone),0) count_unavailble_stone ,
                ISNULL(SUM(tmp.available_stone_carat),0) count_available_stone_carat ,ISNULL(SUM(tmp.unavailable_stone_carat),0) count_unvaialble_stone_carat
        FROM    ( SELECT    stone_details.stoneid ,
                            ( CASE WHEN is_memo_lock = 0 AND memo_date IS NULL THEN 1 ELSE 0 END ) available_stone ,
                            ( CASE WHEN is_memo_lock = 1 THEN 1 ELSE 0 END ) unavailable_stone ,
                            ( CASE WHEN is_memo_lock = 0  AND memo_date IS NULL THEN stone_lab_details.issue_carat  ELSE 0 END ) available_stone_carat ,
                            ( CASE WHEN is_memo_lock = 1 THEN stone_lab_details.issue_carat ELSE 0 END ) unavailable_stone_carat
                  FROM      Packet.STONE_DETAILS stone_details
                            LEFT OUTER JOIN Packet.STONE_LAB_DETAILS stone_lab_details ON stone_lab_details.stoneid = stone_details.stoneid
                                                              AND stone_details.certificate_code = stone_lab_details.certificate_code
							LEFT JOIN @STONEID stone ON stone.stoneid = stone_details.stoneid
					WHERE stone.stoneid = stone_details.stoneid
                --WHERE     stone_details.stoneid IN (SELECT  Value FROM    Master.Split(@stoneid_list, ',') )
                ) AS tmp;
     
    END;

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_MultipleStoneViewRequestPriority_Update]    Script Date: 06/02/2018 2:11:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 24/01/2018
-- Description:	Update Stone Priority from viewrequest
-- =============================================

 
CREATE PROCEDURE [Stock].[usp_Appointment_MultipleStoneViewRequestPriority_Update]
	@visit_id INT=0,
	@stoneid BIGINT,
	@priority_no SMALLINT=0,
	@apps_code TINYINT=0,
	@created_by SMALLINT=0,
	@created_iplocation_id INT=0

AS
    BEGIN
        
		
		IF NOT EXISTS (SELECT TOP 1 STONEID FROM Stock.VISIT_STONE_PRIORITY WHERE STONEID=@stoneid AND VISIT_ID=@visit_id)
		BEGIN
			INSERT INTO Stock.VISIT_STONE_PRIORITY
			        ( VISIT_ID,STONEID,PRIORITY_NO,APPS_CODE,CREATED_DATETIME,CREATED_BY,CREATED_IPLOCATION_ID)
			VALUES  (@visit_id,@stoneid,@priority_no,@apps_code,Master.Fn_GetISTDATETIME(),@created_by,@created_iplocation_id)
		END
		ELSE
		BEGIN
		
			UPDATE Stock.VISIT_STONE_PRIORITY
			SET PRIORITY_NO=@priority_no,
			APPS_CODE=@apps_code,
			CREATED_DATETIME=Master.Fn_GetISTDATETIME(),
			CREATED_BY=@created_by,
			CREATED_IPLOCATION_ID=@created_iplocation_id
			WHERE VISIT_ID=@visit_id AND STONEID=@stoneid	
		
		END
     
    END

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_MultipleStoneViewRequest_Delete]    Script Date: 06/02/2018 2:11:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 24/01/2018
-- Description:	Delete stone from viewrequest
-- =============================================

 
CREATE PROCEDURE [Stock].[usp_Appointment_MultipleStoneViewRequest_Delete]
   @visit_id INT,
   @stoneid BIGINT
AS
    BEGIN
        
		
		DELETE FROM Stock.VISIT_DETAIL 
		WHERE STONEID=@stoneid AND VISIT_ID=@visit_id
     
    END;

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_MultipleStoneViewRequest_List]    Script Date: 06/02/2018 2:11:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 24/01/2018
-- Description:	Appointment multiple stone list
-- =============================================

 
CREATE PROCEDURE [Stock].[usp_Appointment_MultipleStoneViewRequest_List]
    @stoneid Stock.STONEID READONLY
AS
    BEGIN
       SELECT  -1+ROW_NUMBER() OVER ( PARTITION BY appointment_stone_details.stoneid ORDER BY stone_priority.PRIORITY_NO,appointment_stone_details.stoneid, appointment_stone_details.stone_issue_datetime ) stone_priority,
				appointment.appointment_id,party_master.party_name, user_master.user_fullname kam_name,
				cabin_master.cabin_code,section_master.section_code,cabin_master.cabin_name,section_master.section_name,
				appointment_stone_details.visit_id,appointment_stone_details.stoneid,
				stone_lab_details.issue_carat,lab_description.clarity_name,lab_description.color_name,
                case when dbo.sol_getistdatetime() > cast(appointment_stone_details.visit_date as datetime)
                          + cast(appointment_stone_details.visit_from_time as datetime)
                          and appointment_stone_details.stone_issue_datetime is not null
                          and appointment_stone_details.stone_received_datetime is null
                          and appointment_stone_details.is_active = 1
                     then 'ongoing'
                     else '' end appointment_status,
                case when dbo.sol_getistdatetime() > cast(appointment_stone_details.visit_date as datetime)
                          + cast(appointment_stone_details.visit_from_time as datetime)
                          and appointment_stone_details.stone_issue_datetime is not null
                          and appointment_stone_details.stone_received_datetime is null
                          and appointment_stone_details.is_active = 1
                     then 'In '+CAST(datediff(minute,cast(appointment_stone_details.visit_date as datetime)+ cast(appointment_stone_details.visit_from_time as datetime),master.fn_getistdatetime()) / 60 as varchar(5))
                          + ' hr' + '.' + right('0' + cast(datediff(minute,cast(appointment_stone_details.visit_date as datetime)+ cast(appointment_stone_details.visit_from_time as datetime),master.fn_getistdatetime()) % 60 as varchar(2)), 2)
                          + ' min'
                     when dbo.sol_getistdatetime() < cast(appointment_stone_details.visit_date as datetime) + cast(appointment_stone_details.visit_from_time as datetime)
                          and appointment_stone_details.is_active = 1
                     then 'In '+CAST(datediff(minute, master.fn_getistdatetime(), cast(appointment_stone_details.visit_date as datetime)+ cast(appointment_stone_details.visit_from_time as datetime))
                          / 60 as varchar(5)) + ' hr' + '.' + right('0'+ cast(datediff(minute,master.fn_getistdatetime(),cast(appointment_stone_details.visit_date as datetime) + cast(appointment_stone_details.visit_from_time as datetime)) % 60 as varchar(2)), 2) + ' min'
                     else ''
                end time_difference
        FROM    Stock.view_Appointment_Stone_Details appointment_stone_details
		LEFT OUTER JOIN Stock.VISIT VisitParty_Details ON VisitParty_Details.VISIT_ID=appointment_stone_details.visit_id
		LEFT OUTER JOIN Stock.APPOINTMENT appointment ON appointment.APPOINTMENT_ID = VisitParty_Details.APPOINTMENT_ID AND appointment.PARTY_CODE = VisitParty_Details.PARTY_CODE

		LEFT OUTER JOIN Sales.PARTY_MASTER party_master ON party_master.PARTY_CODE=VisitParty_Details.PARTY_CODE
		LEFT OUTER JOIN (SELECT MAX(VISIT_CONTACTS_ID) VISIT_CONTACTS_ID,VISIT_ID FROM Stock.VISIT_CONTACTS  GROUP BY VISIT_ID) visit_contacts ON visit_contacts.VISIT_ID = appointment_stone_details.VISIT_ID
		LEFT OUTER JOIN Stock.VISIT_CONTACTS_KAM visit_contacts_kam ON visit_contacts_kam.VISIT_CONTACTS_ID=visit_contacts.VISIT_CONTACTS_ID
		LEFT OUTER JOIN Master.USER_MASTER user_master ON user_master.user_code=visit_contacts_kam.PARTY_CONTACTS_KAM_CODE

		LEFT OUTER JOIN Master.SECTION_MASTER section_master ON section_master.SECTION_ID = appointment_stone_details.SECTION_ID
		LEFT OUTER JOIN Master.CABIN_MASTER cabin_master ON cabin_master.CABIN_CODE = section_master.CABIN_CODE
		LEFT OUTER JOIN Packet.STONE_DETAILS stone_details ON stone_details.stoneid = appointment_stone_details.stoneid
		LEFT OUTER JOIN Packet.STONE_LAB_DETAILS stone_lab_details ON stone_lab_details.stoneid = stone_details.stoneid
													AND stone_lab_details.certificate_code = stone_details.certificate_code
		LEFT OUTER JOIN Packet.STONE_LAB_DESCRIPTION lab_description ON stone_details.stoneid = lab_description.stoneid
													AND stone_details.certificate_code = lab_description.certificate_code
		LEFT OUTER JOIN Stock.VISIT_STONE_PRIORITY stone_priority ON stone_priority.STONEID=appointment_stone_details.stoneid AND stone_priority.VISIT_ID=appointment_stone_details.VISIT_ID
		LEFT OUTER JOIN @stoneid stone ON stone.stoneid =appointment_stone_details.stoneid
        WHERE   waiting_stone = 1 
		--AND (@stoneid='' OR stone_details.stoneid IN (SELECT value FROM Master.Split(@stoneid,',')))
		AND stone.stoneid =appointment_stone_details.stoneid

     
    END;

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_VisitSummaryInGridView_List]    Script Date: 06/02/2018 2:11:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 20/01/2018
-- Description:	Fill List for displaying visit summary in Gridview
-- =============================================

--Stock.usp_Appointment_VisitSummaryInGridView_List '01/20/2018' 
CREATE PROCEDURE [Stock].[usp_Appointment_VisitSummaryInGridView_List]
    @visit_date DATE=NULL
AS
BEGIN
			SELECT appointment_id,view_appointment_stone_details.visit_date,
					party_master.party_name,
					user_master.user_fullname kam_name,
					view_Appointment_Stone_Details.VISIT_ID visit_id,
					COUNT(view_Appointment_Stone_Details.stoneid) total_stone,
					SUM(stone_lab_details.issue_carat) total_carat,
					sum(view_appointment_stone_details.not_available_stone) total_not_available_stone,
					cabin_master.cabin_code,cabin_master.cabin_name,section_master.section_id,section_master.section_code,section_master.section_name,
					sum(view_appointment_stone_details.viewed_stone) total_seen_stone,
					sum(view_appointment_stone_details.pending_stone) total_pending_stone,
					sum(view_appointment_stone_details.on_table_stone) total_active_stone,
					SUM(view_Appointment_Stone_Details.on_another_cabin_stone) total_other_table_stone,
					sum(view_appointment_stone_details.waiting_stone) total_multiple_stone,
					
					party_contacts_count.count_party_contacts no_of_person,
					'' grade,
					CASE WHEN dbo.sol_getistdatetime()>cast(view_Appointment_Stone_Details.visit_date as datetime)+cast(visit.visit_from_time as datetime)  	and 
					SUM(view_Appointment_Stone_Details.on_table_stone)>1 and
					view_Appointment_Stone_Details.is_active=1 THEN 'On Going'
					WHEN dbo.sol_getistdatetime()<cast(view_Appointment_Stone_Details.visit_date as datetime)+cast(visit.visit_from_time as datetime)  	and 
					view_Appointment_Stone_Details.is_active=1 THEN 'Up Coming'
					WHEN dbo.sol_getistdatetime()<cast(view_Appointment_Stone_Details.visit_date as datetime)+cast(visit.visit_from_time as datetime)  	and 
					SUM(viewed_stone)=SUM(view_Appointment_Stone_Details.available_stone) AND view_Appointment_Stone_Details.VISIT_COMPLETED_TIME IS NOT NULL  and
					view_Appointment_Stone_Details.is_active=1  THEN 'Completed'
					WHEN view_Appointment_Stone_Details.VISIT_CLOSED_DATETIME IS NOT NULL THEN
					'Canceled'
					WHEN dbo.sol_getistdatetime()>cast(view_Appointment_Stone_Details.visit_date as datetime)+cast(visit.visit_from_time as datetime)  
					and SUM(view_Appointment_Stone_Details.pending_stone)=0
					THEN 'No Show'
					ELSE
					''
					END appointment_status,remarks.remark_text,view_Appointment_Stone_Details.visit_from_time,view_Appointment_Stone_Details.visit_to_time,
					'' final_status, '' limit_quantity,'' limit_carat,'' limit_remaining
		
		FROM Stock.VISIT visit
		LEFT OUTER JOIN Sales.PARTY_MASTER party_master ON party_master.PARTY_CODE = visit.PARTY_CODE

		LEFT OUTER JOIN (SELECT VISIT_ID, COUNT(PARTY_CONTACTS_CODE) count_party_contacts FROM Stock.VISIT_CONTACTS  GROUP BY VISIT_ID) party_contacts_count
		ON party_contacts_count.VISIT_ID = visit.VISIT_ID
		
		LEFT OUTER JOIN (SELECT MAX(VISIT_CONTACTS_ID) VISIT_CONTACTS_ID,VISIT_ID FROM Stock.VISIT_CONTACTS  GROUP BY VISIT_ID) visit_contacts ON visit_contacts.VISIT_ID = visit.VISIT_ID
		LEFT OUTER JOIN Stock.VISIT_CONTACTS_KAM visit_contacts_kam ON visit_contacts_kam.VISIT_CONTACTS_ID=visit_contacts.VISIT_CONTACTS_ID
		

		LEFT OUTER JOIN Master.USER_MASTER user_master ON user_master.user_code=visit_contacts_kam.PARTY_CONTACTS_KAM_CODE

		LEFT OUTER JOIN Stock.view_Appointment_Stone_Details  view_Appointment_Stone_Details ON view_Appointment_Stone_Details.VISIT_ID = visit.visit_id
		LEFT OUTER JOIN Packet.STONE_DETAILS stone_details ON stone_details.stoneid = view_Appointment_Stone_Details.stoneid
		LEFT OUTER JOIN Packet.STONE_LAB_DETAILS stone_lab_details ON stone_details.stoneid=stone_lab_details.stoneid AND stone_details.certificate_code=stone_lab_details.certificate_code
		LEFT OUTER JOIN Master.SECTION_MASTER section_master ON view_Appointment_Stone_Details.SECTION_ID=section_master.SECTION_ID
		LEFT OUTER JOIN Master.CABIN_MASTER cabin_master ON cabin_master.CABIN_CODE = section_master.CABIN_CODE
		LEFT JOIN Stock.REMARKS remarks on remarks.SOURCE_ID = visit.VISIT_ID 
				  AND remarks.REMARK_ID IN (SELECT MAX(REMARK_ID) REMARK_ID FROM Stock.REMARKS RM WHERE RM.SOURCE_ID = remarks.SOURCE_ID Group by SOURCE_ID)
		WHERE view_Appointment_Stone_Details.visit_date=@visit_date
		GROUP BY appointment_id,view_Appointment_Stone_Details.VISIT_DATE,
		view_Appointment_Stone_Details.VISIT_ID,
		
		cabin_master.CABIN_CODE,cabin_master.CABIN_NAME,section_master.SECTION_ID,section_master.SECTION_CODE,section_master.SECTION_NAME,
		view_Appointment_Stone_Details.VISIT_FROM_TIME,
		view_Appointment_Stone_Details.is_active,view_Appointment_Stone_Details.VISIT_COMPLETED_TIME,view_Appointment_Stone_Details.VISIT_CLOSED_DATETIME,
		remarks.remark_text,view_Appointment_Stone_Details.VISIT_TO_TIME,visit.visit_from_time
		,party_master.party_name,party_contacts_count.count_party_contacts,user_master.user_fullname
 
 

 
 
    
END

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_VisitStoneDetailsWithStoneStatus_List]    Script Date: 06/02/2018 2:11:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 22/01/2018
-- Description:	Display appointment's Stone Detail with stone status like available,on table,
--pass @stone_status=available,not_available,confirmed_stone,tobe_decided_stone,rejected_stone,stone_viewed,on_table_stone,pending_stone,
--waiting_stone,hold_stone,in_cabin_stone,verified_stone
-- =============================================
--Stock.usp_Appointment_VisitStoneDetailsWithStoneStatus_List '152','01/31/2018','pending'
CREATE PROCEDURE [Stock].[usp_Appointment_VisitStoneDetailsWithStoneStatus_List]
    @visit_id INT=0,
	@visit_date DATE=NULL,
	@stone_status VARCHAR(32)=''
AS
    BEGIN
 
	DECLARE 
	@available_stone VARCHAR(2)= '' ,
    @not_available_stone VARCHAR(2)= '' ,
    @confirmed_stone VARCHAR(2)= '' ,
    @tobe_decided_stone VARCHAR(2)= '' ,
    @rejected_stone VARCHAR(2)= '' ,
    @stone_viewed VARCHAR(2)= '' ,
    @on_table_stone VARCHAR(2)= '' ,
    @pending_stone VARCHAR(2)= '' ,
    @waiting_stone VARCHAR(2)= '' ,
    @hold_stone VARCHAR(2)= '' ,
    @in_cabin_stone VARCHAR(2)= '' ,
    @verified_stone VARCHAR(2)= ''

	IF @stone_status='available'
	BEGIN 
		SET @available_stone='1'
	END
	ELSE IF @stone_status='not_available'
	BEGIN
		SET @not_available_stone='1'
	END
	ELSE IF @stone_status='confirmed'
	BEGIN
		SET @confirmed_stone='1'
	END
	ELSE IF @stone_status='tobe_decided'
	BEGIN
		SET @tobe_decided_stone='1'
	END
	ELSE IF @stone_status='rejected'
	BEGIN
		SET @rejected_stone='1'
	END
	ELSE IF @stone_status='viewed'
	BEGIN
		SET @stone_viewed='1'
	END
	ELSE IF @stone_status='on_table'
	BEGIN
		SET @on_table_stone='1'
	END
	ELSE IF @stone_status='pending'
	BEGIN
		SET @pending_stone='1'
	END
	ELSE IF @stone_status='waiting'
	BEGIN
		SET @waiting_stone='1'
	END 
	ELSE IF @stone_status='hold'
	BEGIN
		SET @hold_stone='1'
	END 
	ELSE IF @stone_status='in_cabin'
	BEGIN
		SET @in_cabin_stone='1'
	END     
	ELSE IF @stone_status='verified'
	BEGIN
		SET @verified_stone='1'
	END 
    
	 	SELECT  party_master.party_name,user_master.user_fullname kam_name, visit.visit_id,visit.stoneid,visit.waiting_stone is_stone_mutltiple_request,
			stone_lab_description.certificate_name,stone_lab_description.shape_name,
			stone_lab_description.clarity_name,stone_lab_description.color_name,stone_lab_details.issue_carat,
			stone_details.packet_rate ,stone_details.packet_percentage ,
			stone_details.packet_rate*stone_lab_details.issue_carat amount,stone_lab_description.cut_short_name,stone_lab_description.polish_short_name,
			stone_lab_description.symmetry_short_name,stone_lab_description.floro_short_name,stone_details.packet_base_rate ,
			CASE 
			--WHEN visit.available_stone=1 THEN  'Available'
			WHEN visit.not_available_stone=1 THEN	'Not Avaialble'
			WHEN visit.visit_confirm_stone=1 THEN   'Confirm'
			WHEN visit.tobe_decided_stone=1 THEN    'To Be Decided'
			WHEN visit.rejected_stone=1 THEN		'Rejected'
			WHEN visit.stones_viewed=1 THEN			'Stone Viewed'
			WHEN visit.on_table_stone=1 THEN		'On Table'
			WHEN visit.pending_stone=1 THEN			'Pending'
			WHEN visit.waiting_stone=1 THEN			'Waiting'
			WHEN visit.hold_stone=1 THEN			'Hold'
			WHEN visit.viewed_stone=1 THEN			'Verified'
			END stone_status
	FROM    Stock.view_Appointment_Stone_Details visit
	LEFT OUTER JOIN Packet.STONE_DETAILS stone_details ON stone_details.stoneid=visit.stoneid
	
	LEFT OUTER JOIN Packet.STONE_LAB_DESCRIPTION stone_lab_description ON visit.stoneid = stone_lab_description.stoneid
	AND stone_lab_description.certificate_code = stone_details.certificate_code
	LEFT OUTER JOIN Packet.STONE_LAB_DETAILS stone_lab_details ON stone_details.stoneid=stone_lab_details.stoneid
	AND stone_details.certificate_code=stone_lab_details.certificate_code
	
	LEFT OUTER JOIN Stock.VISIT VisitParty_Details ON VisitParty_Details.VISIT_ID=visit.visit_id
	LEFT OUTER JOIN Sales.PARTY_MASTER party_master ON party_master.PARTY_CODE=VisitParty_Details.PARTY_CODE


	LEFT OUTER JOIN (SELECT MAX(VISIT_CONTACTS_ID) VISIT_CONTACTS_ID,VISIT_ID FROM Stock.VISIT_CONTACTS  GROUP BY VISIT_ID) visit_contacts ON visit_contacts.VISIT_ID = visit.VISIT_ID
		LEFT OUTER JOIN Stock.VISIT_CONTACTS_KAM visit_contacts_kam ON visit_contacts_kam.VISIT_CONTACTS_ID=visit_contacts.VISIT_CONTACTS_ID
		

		LEFT OUTER JOIN Master.USER_MASTER user_master ON user_master.user_code=visit_contacts_kam.PARTY_CONTACTS_KAM_CODE


	WHERE  ( @visit_id=0 OR visit.VISIT_ID=@visit_id  )
			AND ( @available_stone = '' OR available_stone = @available_stone )
	        AND ( @not_available_stone = '' OR not_available_stone = @not_available_stone)
	        AND ( @confirmed_stone = '' OR visit_confirm_stone = @confirmed_stone)
			AND( @tobe_decided_stone='' OR tobe_decided_stone=@tobe_decided_stone)
			AND (@rejected_stone='' OR rejected_stone=@rejected_stone)
			AND (@stone_viewed='' OR stones_viewed=@stone_viewed)
			AND (@on_table_stone='' OR on_table_stone=@on_table_stone)
			AND (@pending_stone='' OR pending_stone=@pending_stone)
			AND (@waiting_stone='' OR waiting_stone=@waiting_stone)
			AND (@hold_stone='' OR hold_stone=@hold_stone)
			AND (@in_cabin_stone='' OR on_table_stone=@in_cabin_stone)
			AND (@verified_stone='' OR viewed_stone=@verified_stone)
			AND (  @visit_date=visit.VISIT_DATE)

     
    END

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_AvailableSlotKAMWise_List]    Script Date: 06/02/2018 2:11:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 21/01/2018
-- Description:	Available slot and alloted slot KAM wise
-- =============================================

 

CREATE PROCEDURE [Stock].[usp_Appointment_AvailableSlotKAMWise_List]
 @USER_CODE INT=0,
 @DATE DATE = NULL
AS
 BEGIN
---======
DECLARE @EndTime TIME 
DECLARE @StartTime TIME 
DECLARE @INTERVAL SMALLINT = 0

DECLARE @DAYID TINYINT=0

--DECLARE 

SELECT @DAYID=DAY_ID FROM [MASTER].DAYS_MASTER WHERE DAY_NAME = DATENAME(DW,@DATE)
SELECT @StartTime = [FROM_TIME], @EndTime = [TO_TIME], @INTERVAL=[INTERVAL_TIME]  FROM [Master].[SCHEDULE_MASTER] WHERE DAY_ID=@DAYID AND IS_ACTIVE=1

SELECT  @DATE [date], @STARTTIME office_start_time, @ENDTIME office_end_time, @INTERVAL slot_interval

DECLARE @SLOT TABLE( 
 VISIT_ID INT NOT NULL, 
 SECTION_ID SMALLINT NOT NULL,
 SECTION_SLOT_FROM_TIME TIME(7),
 SECTION_SLOT_TO_TIME TIME(7),
 FROM_TIME TIME(7) ,
 TO_TIME TIME(7),
 DURATION_VALUE VARCHAR(5),
 SECTION_SLOT_TO_TIME_WITH_INTERVAL TIME(7) 
); 

INSERT INTO @SLOT
 SELECT DISTINCT vd.visit_id,vd.section_id,section_slot_from_time,section_slot_to_time,
 s.from_time,s.to_time,  d.duration_value, 
 dateadd(minute,convert(int,d.duration_value),section_slot_to_time) section_slot_to_time_with_interval
 FROM [Stock].[VISIT_DETAIL] VD
 INNER JOIN [STOCK].[VISIT] V ON V.VISIT_ID=VD.VISIT_ID AND V.VISIT_DATE=@DATE AND V.IS_ACTIVE=1
 INNER JOIN (
     SELECT SECTION_ID,S.FROM_TIME,S.TO_TIME
     FROM [Master].[KAM_VISIT_RULES_MASTER] R
     INNER JOIN [MASTER].[KAM_SLOT_MASTER] S ON S.DAY_ID=@DAYID AND S.RULE_CODE=R.RULE_CODE AND S.IS_ACTIVE=1
     WHERE R.USER_CODE=@USER_CODE AND R.IS_ACTIVE=1
    ) S ON S.SECTION_ID=VD.SECTION_ID
 Inner Join [Master].[SECTION_MASTER] SM On SM.SECTION_ID=VD.SECTION_ID AND SM.IS_ACTIVE=1
 INNER JOIN [Master].[CABIN_MASTER] C On C.CABIN_CODE=SM.CABIN_CODE AND C.IS_ACTIVE=1
 INNER JOIN [Master].[DURATION_MASTER] D On D.DURATION_CODE=C.TIME_INTERVAL_CODE AND D.IS_ACTIVE=1
 INNER JOIN [Master].[DURATION_TYPE_MASTER] E On D.DURATION_TYPE_CODE=E.DURATION_TYPE_CODE AND E.DURATION_TYPE_CODE=2

--select * from @SLOT

 ;WITH gaps
 AS
 (
    SELECT T.SECTION_ID,
     T.SECTION_SLOT_TO_TIME_WITH_INTERVAL As timeStart, 
     LEAD(T.SECTION_SLOT_FROM_TIME, 1, TO_TIME) OVER (PARTITION BY T.SECTION_ID ORDER BY T.SECTION_SLOT_FROM_TIME) AS timeEnd
    FROM @SLOT T   
 ),
 minStart
 AS
 (
    SELECT SECTION_ID, MIN(FROM_TIME) As timeStart, MIN(SECTION_SLOT_TO_TIME) AS timeEnd
    FROM @SLOT   
    GROUP BY SECTION_ID
    HAVING MIN(FROM_TIME) < MIN(SECTION_SLOT_FROM_TIME)  
 )

 SELECT AVAILABLE_SLOT.*, SM.section_name, C.cabin_name, C.cabin_code FROM
 (
   SELECT 0 visit_id, section_id, timestart, timeend
   FROM gaps
   WHERE DATEDIFF(mi, timeStart, timeEnd) > 0
   UNION 
   SELECT 0 visit_id,section_id,  timeStart, timeEnd
   FROM minStart
 
 ) AVAILABLE_SLOT 
 Inner Join [Master].[SECTION_MASTER] SM On SM.SECTION_ID=AVAILABLE_SLOT.SECTION_ID AND SM.IS_ACTIVE=1
 INNER JOIN [Master].[CABIN_MASTER] C On C.CABIN_CODE=SM.CABIN_CODE AND C.IS_ACTIVE=1

 SELECT visit_id, BOOKED_SLOT.section_id, SECTION_SLOT_FROM_TIME timestart, SECTION_SLOT_TO_TIME timeend, 
 SM.section_name, C.cabin_name,c.cabin_code
 FROM @SLOT BOOKED_SLOT
 Inner Join [Master].[SECTION_MASTER] SM On SM.SECTION_ID=BOOKED_SLOT.SECTION_ID AND SM.IS_ACTIVE=1
 INNER JOIN [Master].[CABIN_MASTER] C On C.CABIN_CODE=SM.CABIN_CODE AND C.IS_ACTIVE=1


 END
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_CanceledVisit_Update]    Script Date: 06/02/2018 2:11:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 17/01/2018
-- Description:	Cancel Appointment 
-- =============================================

CREATE PROCEDURE [Stock].[usp_Appointment_CanceledVisit_Update]
    @visit_id INT = 0 ,
    @apps_code TINYINT = 0 ,
    @modified_by SMALLINT = 0 ,
    @modified_iplocation_id INT = 0
AS
    BEGIN

         
        UPDATE  Stock.VISIT
        SET     IS_ACTIVE=0,VISIT_CLOSED_DATETIME=Master.Fn_GetISTDATETIME(),APPS_CODE = @apps_code ,
				MODIFIED_BY = @modified_by ,MODIFIED_DATETIME = Master.Fn_GetISTDATETIME() ,
				MODIFIED_IPLOCATION_ID = @modified_iplocation_id
        WHERE   VISIT_ID = @visit_id

     
    END

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_CloseVisit_Update]    Script Date: 06/02/2018 2:11:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 17/01/2018
-- Description:	Clsoed Appointment if issued stone and recevived process is done
-- =============================================

CREATE PROCEDURE [Stock].[usp_Appointment_CloseVisit_Update]
    @visit_id INT = 0 ,
    @apps_code TINYINT = 0 ,
    @modified_by SMALLINT = 0 ,
    @modified_iplocation_id INT = 0
AS
    BEGIN

         
        UPDATE  Stock.VISIT
        SET     VISIT_COMPLETED_TIME =CONVERT(TIME, Master.Fn_GetISTDATETIME()) ,APPS_CODE = @apps_code ,
				MODIFIED_BY = @modified_by ,MODIFIED_DATETIME = Master.Fn_GetISTDATETIME() ,
				MODIFIED_IPLOCATION_ID = @modified_iplocation_id
        WHERE   VISIT_ID = @visit_id

     
    END;

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_VisitWiseDetail_List]    Script Date: 06/02/2018 2:11:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 17/01/2018
-- Description:	Fill detail of appointment summary from visit id in calendar control
-- Log for visit is remaing this process will come after stock inward - outward process
-- =============================================

--[Stock].[usp_Appointment_VisitWiseDetail_List] 153

CREATE PROCEDURE [Stock].[usp_Appointment_VisitWiseDetail_List] 
@visit_id INT = 0
AS
    BEGIN
	 
	 

       
       SELECT 
             DISTINCT   appointment.appointment_id,visit.visit_id,visit.visit_date,
			   CONVERT(varchar(2), datepart(dd, visit.visit_date)) + '-'+ datename(mm, visit.visit_date) display_visit_date,
			   visit.visit_from_time,visit.visit_to_time,visit.visit_start_time,
			   CASE WHEN  visit.VISIT_START_TIME IS NOT NULL AND visit.VISIT_COMPLETED_TIME IS NULL AND visit.VISIT_CLOSED_DATETIME IS NULL
			   THEN 'On Going'
			   WHEN visit.VISIT_COMPLETED_TIME IS NOT NULL AND visit.VISIT_START_TIME IS NOT NULL AND visit.VISIT_CLOSED_DATETIME IS NULL
			   THEN 'Compeleted'
			   WHEN visit.IS_ACTIVE=1 AND visit_detail.stone_issue_datetime is null
					AND CONVERT(date, master.fn_getistdatetime()) = convert(date, visit.visit_date)
					AND CONVERT(time, master.fn_getistdatetime()) between visit_detail.section_slot_from_time AND visit_detail.section_slot_to_time
			   THEN 'Up Coming'
			   WHEN  visit.VISIT_CLOSED_DATETIME IS NOT NULL AND visit.IS_ACTIVE=0 
			   THEN 'Closed'
			   ELSE 'No Show' END visit_status,cabin_master.cabin_name,section_master.section_name,visit_detail.section_id,
			   cabin_master.cabin_code,section_master.section_code,visit.party_code,party_master.party_name party_name,'' grade
			   
        FROM    Stock.VISIT visit
                LEFT OUTER JOIN Stock.APPOINTMENT appointment ON appointment.APPOINTMENT_ID = visit.APPOINTMENT_ID AND appointment.PARTY_CODE = visit.PARTY_CODE
                LEFT OUTER JOIN Stock.VISIT_DETAIL visit_detail ON visit.VISIT_ID = visit_detail.VISIT_ID
                LEFT OUTER JOIN Sales.PARTY_MASTER party_master ON visit.PARTY_CODE = party_master.PARTY_CODE
                LEFT OUTER JOIN Master.SECTION_MASTER section_master ON section_master.SECTION_ID = visit_detail.SECTION_ID
                LEFT OUTER JOIN Master.CABIN_MASTER cabin_master ON cabin_master.CABIN_CODE = section_master.CABIN_CODE
            WHERE   visit.VISIT_ID = @visit_id;





		 SELECT 
               distinct appointment.appointment_id,visit.visit_id,
			party_conatcs.party_contacts_code,party_role_master.ROLE_NAME party_role_name,party_conatcs.first_name + ' ' + party_conatcs.last_name contact_person_name,
			   party_contacts_phone.country_phone_code contacts_country_phone_code,party_contacts_phone.phone_number contacts_phone_number,
			   party_contacts_email.email_address contacts_email_address,user_master.user_name kam_name,kam_email.email_address kam_email_address,
			   visit_contacts.contacts_local_country_code,visit_contacts.contacts_local_phone_number,visit_contacts.party_role_code,
			   visit_contacts_kam.visit_contacts_kam_id,kam_phone.COUNTRY_PHONE_CODE kam_country_code,
			   kam_phone.PHONE_NUMBER kam_phone_number
        FROM    Stock.VISIT visit
                LEFT OUTER JOIN Stock.APPOINTMENT appointment ON appointment.APPOINTMENT_ID = visit.APPOINTMENT_ID
                 LEFT OUTER JOIN Stock.VISIT_CONTACTS visit_contacts ON visit_contacts.VISIT_ID = visit.VISIT_ID
                LEFT OUTER JOIN Stock.VISIT_CONTACTS_KAM visit_contacts_kam ON visit_contacts_kam.VISIT_CONTACTS_ID = visit_contacts.VISIT_CONTACTS_ID
                LEFT OUTER JOIN Sales.PARTY_CONTACTS party_conatcs ON party_conatcs.PARTY_CONTACTS_CODE = visit_contacts.PARTY_CONTACTS_CODE
                LEFT OUTER JOIN Sales.PHONE party_contacts_phone ON visit_contacts.PARTY_CONTACTS_CODE = party_contacts_phone.SOURCE_CODE
                                                              AND party_contacts_phone.SOURCE_TYPE_CODE = Master.getSourceCode('contact_person_phone')
                                                              AND party_contacts_phone.IS_PRIMARY = 1
                LEFT OUTER JOIN Sales.EMAILS party_contacts_email ON visit_contacts.PARTY_CONTACTS_CODE = party_contacts_email.SOURCE_CODE
                                                              AND party_contacts_email.SOURCE_CODE = Master.getSourceCode('contact_person_mail')
                                                              AND party_contacts_email.IS_PRIMARY = 1
                LEFT OUTER JOIN Sales.PARTY_CONTACTS_KAMS party_contacts_kam ON visit_contacts.PARTY_CONTACTS_CODE = party_contacts_kam.PARTY_CONTACTS_CODE
                                                              AND party_contacts_kam.IS_PRIMARY = 1
                LEFT OUTER JOIN Master.USER_MASTER user_master ON party_contacts_kam.USER_CODE = user_master.user_code
                LEFT OUTER JOIN Sales.EMAILS kam_email ON kam_email.SOURCE_CODE = user_master.user_code
                                                          AND kam_email.SOURCE_TYPE_CODE = Master.getSourceCode('kam_email_Address')
                                                          AND kam_email.IS_PRIMARY = 1
				LEFT OUTER JOIN Sales.PARTY_ROLES party_roles ON party_roles.PARTY_ROLE_CODE = visit_contacts.PARTY_ROLE_CODE
				LEFT OUTER JOIN Master.PARTY_ROLE_MASTER party_role_master ON party_role_master.ROLE_CODE = party_roles.ROLE_CODE
				LEFT OUTER JOIN Sales.PHONE kam_phone ON kam_phone.SOURCE_CODE=visit_contacts_kam.PARTY_CONTACTS_KAM_CODE
														  AND kam_phone.SOURCE_TYPE_CODE=master.getSourceCode('solitaire_user_phone')
														  AND kam_phone.IS_PRIMARY=1
		 WHERE   visit.VISIT_ID = @visit_id;


        SELECT  SUM(available_stone) available_stone,SUM(not_available_stone) not_available_stone,
			    SUM(visit_confirm_Stone) visit_confirm_Stone,SUM(tobe_decided_stone) tobe_decided_stone,
				SUM(rejected_stone) rejected_stone,SUM(stones_viewed) stones_viewed,SUM(on_table_stone) on_table_stone,
				SUM(pending_stone) pending_stone,SUM(waiting_Stone) waiting_Stone,
				SUM(hold_stone) hold_stone,SUM(viewed_stone) viewed_stone
        FROM    Stock.view_Appointment_Stone_Details
        WHERE   visit_id = @visit_id;



        SELECT  remarks.remark_text,
		CONVERT(varchar(2), datepart(dd, remarks.created_datetime))+ '-' + datename(mm, remarks.created_datetime) created_date,
		CASE when remarks.created_by = 0 then '' else 'kam ' + user_master.user_fullname END remark_by
        FROM    Stock.REMARKS remarks
                LEFT OUTER JOIN Stock.VISIT visit ON visit.VISIT_ID = remarks.SOURCE_ID
                                                     AND remarks.REMARK_TYPE_CODE = Master.getRemarkCode('appointment_remark')
                LEFT OUTER JOIN Master.USER_MASTER user_master ON user_master.user_code = remarks.CREATED_BY
        WHERE   visit.VISIT_ID = @visit_id
        ORDER BY remarks.CREATED_DATETIME DESC;




        SELECT  feedback.feedback_remark,feedback.feedback_rating,
				CONVERT(varchar(2), datepart(dd, feedback.created_datetime))+ '-' + datename(mm, feedback.created_datetime) created_date,
				CASE when feedback.created_by = 0 then '' else 'kam ' + user_master.user_fullname END feedback_by
        FROM    Stock.FEEDBACK feedback
                LEFT OUTER JOIN Stock.VISIT visit ON visit.VISIT_ID = feedback.SOURCE_ID
                                                     AND feedback.FEEDBACK_CATEGORY_CODE = [Master].[getFeedbackCode]('customer_feedback')
                LEFT OUTER JOIN Master.USER_MASTER user_master ON user_master.user_code = feedback.CREATED_BY
        WHERE   visit.VISIT_ID = @visit_id;


        SELECT  feedback.feedback_remark,feedback.feedback_rating,
				CONVERT(varchar(2), datepart(dd, feedback.created_datetime))+ '-' + datename(mm, feedback.created_datetime) created_date,
				CASE when feedback.created_by = 0 then '' else 'kam ' + user_master.user_fullname END feedback_by
        FROM    Stock.FEEDBACK FEEDBACK
                LEFT OUTER JOIN Stock.VISIT visit ON visit.VISIT_ID = FEEDBACK.SOURCE_ID
                                                     AND FEEDBACK.FEEDBACK_CATEGORY_CODE = [Master].[getFeedbackCode]('kam_remark_feedback')
                LEFT OUTER JOIN Master.USER_MASTER user_master ON user_master.user_code = FEEDBACK.CREATED_BY
        WHERE   visit.VISIT_ID = @visit_id;

		

		DECLARE @stoneid_list VARCHAR(MAX)=''

		SELECT @stoneid_list=@stoneid_list+','+STONEID  FROM Stock.VISIT_DETAIL WHERE VISIT_ID=@visit_id

		SELECT RIGHT(@stoneid_list, LEN(@stoneid_list) - 1) stoneid_list  

    END;

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_OverView_list]    Script Date: 06/02/2018 2:11:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- author:		satish kayada
-- create date: 21/01/2018
-- description:	fill appointment overview
-- =============================================
CREATE procedure [Stock].[usp_Appointment_OverView_list]
@view_date as date=null
as 
		declare @todaydate as date;
		declare @cabinpercentage as numeric(4,2)
		declare @averageavailable as numeric(8,2)
		set @todaydate=case when(@view_date is null) then dbo.sol_getistdatetime() else @view_date end

		select @averageavailable=[stock].getaverageavailabilityofcabin(@todaydate,0)

		select 
		@averageavailable			As availablepercentage,
		sum(totalappointment   )	As totalappointment   ,
		sum(totalappointmentcarat ) As totalappointmentcarat ,

		--sum(totalissuepcs      ) as totalissuepcs      ,
		--sum(totalreceivepcs    ) as totalreceivepcs    ,
		--sum(totalrequestpcs    ) as totalrequestpcs    ,

		sum(ongoing            ) as ongoing            ,
		sum(ongoingcarat       ) as ongoingcarat       ,
		sum(upcomming          ) as upcomming          ,
		sum(upcomingcarat      ) as upcomingcarat      ,
		sum(completed          ) as completed          ,
		sum(completedcarat     ) as completedcarat     ,
		sum(cancel             ) as cancel             ,
		sum(cancelcarat        ) as cancelcarat        ,
		sum(notseen            ) as notseen            ,
		sum(notseencarat       ) as notseencarat       ,
		
		SUM(totalontablepcs    ) as totalontablepcs    ,
		sum(totalpendingpcs    ) as totalpendingpcs    ,
		sum(totalwaitingpcs    ) as totalwaitingpcs    ,
		sum(totalrejectedpcs   ) as totalrejectedpcs   ,
		sum(totalholdpcs       ) as totalholdpcs       ,
		sum(totalconfirmpcs    ) as totalconfirmpcs    ,
		sum(totalontablecarat  ) as totalontablecarat  ,
		sum(totalpendingcarat  ) as totalpendingcarat  ,
		sum(totalwaitingcarat  ) as totalwaitingcarat  ,
		sum(totalrejectedcarat ) as totalrejectedcarat ,
		sum(totalholdcarat     ) as totalholdcarat     ,
		sum(totalconfirmcarat  ) as totalconfirmcarat  
		from (
				select totcarat.visit_id,
				count(*) as totalappointment,
				sum(totcarat.issuecarat) as totalappointmentcarat,
				sum(totcarat.totalissuepcs) as totalissuepcs, 
				sum(totcarat.totalreceivepcs) as totalreceivepcs,
				sum(totcarat.totalrequestpcs) as totalrequestpcs,
				-- ongoing
				case when(		
							stock.visit.visit_start_time is not null
							and is_active=1
						 )
						 then 1
						 else 0 
				end ongoing,
				case when(
							stock.visit.visit_start_time is not null
							and is_active=1
						 )
						 then sum(totcarat.issuecarat)
						 else 0 
				end ongoingcarat,
				-- upcoming
				case when(
								Master.fn_getistdatetime()<cast(visit_date as datetime)+cast(visit_from_time as datetime)  -- on going visit
								AND visit_start_time is null
								AND is_active=1
						 )
						 then 1
						 else 0 
				end upcomming,
				case when(
								Master.fn_getistdatetime()<cast(visit_date as datetime)+cast(visit_from_time as datetime)  -- on going visit
								AND visit_start_time is null
								AND is_active=1
						 )
						 then sum(totcarat.issuecarat)
						 else 0 
				end upcomingcarat,
				case when(
								visit_start_time IS NOT NULL
								AND 
								visit_completed_time IS NOT NULL
								and is_active=1
						 )
						 then 1
						 else 0 
				end completed,
				case when(
								visit_start_time IS NOT NULL
								AND 
								visit_completed_time IS NOT NULL
								and is_active=1
						 )
						 then sum(totcarat.issuecarat)
						 else 0 
				end completedcarat,
				-- cancel 
				case when(visit.is_active=0)
						 then 1
						 else 0 
				end cancel,
				case when(visit.is_active=0)
						 then sum(totcarat.issuecarat)
						 else 0 
				end cancelcarat,
				-- not seeen
				case when(
								Master.Fn_GetISTDATETIME()>cast(visit_date as datetime)+cast(visit_to_time as datetime)  -- on going visit
								AND 
								VISIT_START_TIME IS null
								AND 
								IS_ACTIVE=1
						 )
						 then 1
						 else 0 
				end notseen,
				case when(
								Master.Fn_GetISTDATETIME()>cast(visit_date as datetime)+cast(visit_to_time as datetime)  -- on going visit
								AND 
								VISIT_START_TIME IS null
								AND 
								IS_ACTIVE=1
						 )
						 then sum(totcarat.issuecarat)
						 else 0 
				end notseencarat,
				sum(totcarat.totalontablepcs)			 totalontablepcs,
				sum(isnull(pending.totalpendingpcs,0))   totalpendingpcs,
				sum(isnull(pending.totalpendingpcs,0))	 totalwaitingpcs,
				sum(totcarat.totalrejectedpcs)			 totalrejectedpcs,
				sum(totcarat.totalholdpcs)				 totalholdpcs,
				sum(totcarat.totalconfirmpcs)			 totalconfirmpcs,
				sum(totcarat.totalontablecarat)			 totalontablecarat,
				sum(isnull(pending.totalpendingcarat,0)) totalpendingcarat,
				sum(isnull(pending.totalpendingcarat,0)) totalwaitingcarat,
				sum(totcarat.totalrejectedcarat)		 totalrejectedcarat,
				sum(totcarat.totalholdcarat)			 totalholdcarat,
				sum(totcarat.totalconfirmcarat)			 totalconfirmcarat
				from stock.visit
					left join
						(
							select visit_detail.visit_id,
							sum(1) totalrequestpcs,
							sum(case when (visit_detail.stone_issue_datetime is not null) then 1 else 0 end) totalissuepcs,
							sum(case when (visit_detail.stone_received_datetime is not null) then 1 else 0 end) totalreceivepcs,
							sum(case when (visit_detail.stone_issue_datetime is not null and stock.visit_detail.stone_received_datetime is null)  
									then 1 else 0 end) 
							as totalontablepcs,
							sum(case when (
												visit_detail.stone_issue_datetime is not null 
											and stock.visit_detail.stone_received_datetime is not null 
											and (packet.stone_details.is_memo_lock=0 OR packet.STONE_DETAILS.party_code!=visit.PARTY_CODE)
										  ) then 1 else 0 end) 
								as totalrejectedpcs,
							sum(case when (visit_detail.stone_issue_datetime is not null and packet.stone_details.memo_date IS NOT NULL AND packet.STONE_DETAILS.party_code=visit.PARTY_CODE) then 1 else 0 end) 
							as totalholdpcs,
							sum(case when (visit_detail.stone_issue_datetime is not null and packet.stone_details.is_memo_lock=1 AND packet.STONE_DETAILS.party_code=visit.PARTY_CODE) then 1 else 0 end) 
							as totalconfirmpcs,
						
							sum(stone_lab_details.issue_carat) as issuecarat,
							sum(case when (visit_detail.stone_received_datetime is not null) then stone_lab_details.issue_carat else 0 end) totalreceiveCarat,
						
							sum(case when (visit_detail.stone_issue_datetime is not null and stock.visit_detail.stone_received_datetime is null)  
									then stone_lab_details.issue_carat else 0 end) 
							as totalontablecarat,

							sum(case when (
												visit_detail.stone_issue_datetime is not null 
											and stock.visit_detail.stone_received_datetime is not null 
											and (packet.stone_details.is_memo_lock=0 OR packet.STONE_DETAILS.party_code!=visit.PARTY_CODE)
										  ) then stone_lab_details.issue_carat else 0 end) 
								as  totalrejectedcarat,

							sum(case when (visit_detail.stone_issue_datetime is not null and packet.stone_details.memo_date IS NOT NULL AND packet.STONE_DETAILS.party_code=visit.PARTY_CODE) 
								then stone_lab_details.issue_carat else 0 end) 
							as totalholdcarat,
							sum(case when (visit_detail.stone_issue_datetime is not null and packet.stone_details.is_memo_lock=1 AND packet.STONE_DETAILS.party_code=visit.PARTY_CODE) 
								then stone_lab_details.issue_carat else 0 end) 
							as totalconfirmcarat
							from stock.visit_detail	
								left join stock.visit on visit.visit_id=visit_detail.visit_id
								left join packet.stone_details on stone_details.stoneid = visit_detail.stoneid
								left join packet.stone_lab_details on stone_lab_details.stoneid = visit_detail.stoneid and stone_lab_details.certificate_code= stone_details.certificate_code
							where visit_date=@todaydate
							group by visit_detail.visit_id
					) as totcarat  on totcarat.visit_id = visit.visit_id
					left join (
								select visit_id,
									count(*) as totalpendingpcs,
									sum(pending.issue_carat) as totalpendingcarat
								from (
										select a.visit_id,a.stoneid,max(packet.stone_lab_details.issue_carat) as issue_carat
										from stock.visit_detail	a 
											left join packet.stone_details on stone_details.stoneid = a.stoneid
											left join packet.stone_lab_details on stone_lab_details.stoneid = a.stoneid and stone_lab_details.certificate_code= stone_details.certificate_code
											left join stock.visit on visit.visit_id=a.visit_id
											left join stock.visit_detail as b	on a.stoneid=b.stoneid and a.visit_id!=b.visit_id and cast(dbo.sol_getistdatetime() as time) >= a.section_slot_from_time 
											left join stock.visit v on b.visit_id=v.visit_id
										where 1=1
										and visit.visit_date=@todaydate
										and v.is_active=1
										and b.stoneid is not null
										and a.stone_issue_datetime is not null and a.stone_received_datetime is null
										group by a.visit_id,a.stoneid
									) as pending
								group by pending.visit_id
								) as pending on pending.visit_id = visit.visit_id
				where visit_date=@todaydate
				group by totcarat.visit_id
				,visit_date
				,visit_from_time
				,is_active
				,visit_start_time
				,visit_to_time
				,visit_completed_time
			) as visit


GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_VisitSummaryIncalendarView_List]    Script Date: 06/02/2018 2:11:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Rushita 
-- Create date: 20/01/2018
-- Description:	Fill List for displaying visit summary in calendarview
-- =============================================

 
CREATE PROCEDURE [Stock].[usp_Appointment_VisitSummaryIncalendarView_List]
    @visit_date DATE=NULL,
	@appointment_status VARCHAR(32)=''
AS
BEGIN
		
		SELECT  days_master.day_name,schedula_master.from_time,schedula_master.to_time,
				schedula_master.interval_time
		FROM    Master.DAYS_MASTER days_master
		        LEFT OUTER JOIN Master.SCHEDULE_MASTER schedula_master ON schedula_master.DAY_ID = days_master.DAY_ID
		WHERE   DAY_NAME = DATENAME(dw, @visit_date)
		
		SELECT  cabin_master.cabin_code,cabin_master.cabin_name,
				[Stock].[getAverageAvailabilityofCabin](@visit_date,cabin_master.CABIN_CODE) occupancy_available ,
				section_master.section_id,
				section_master.section_code,section_master.section_name
		FROM    Master.CABIN_MASTER cabin_master
		        LEFT OUTER JOIN Master.SECTION_MASTER section_master ON section_master.CABIN_CODE = cabin_master.CABIN_CODE
		                                                              AND section_master.IS_ACTIVE = 1
		WHERE   cabin_master.IS_ACTIVE = 1
		
		
		
		 SELECT DISTINCT visit_summary.cabin_code,visit_summary.cabin_name,visit_summary.section_code,visit_summary.section_name,
						visit_summary.section_id,visit_from_time,visit_summary.visit_to_time,visit_summary.visit_id,
						visit_summary.party_name,COUNT(DISTINCT visit_summary.party_contacts_code) total_party_contacts,
						COUNT(visit_summary.stoneid) total_stoneid,appointment_status
		FROM    ( SELECT    VisitParty_Details.visit_id,VisitParty_Details.appointment_id,VisitParty_Details.party_code,
							VisitParty_Details.party_name,visit_detail.section_slot_from_time visit_from_time,
							visit_detail.section_slot_to_time visit_to_time,visit_detail.stoneid,
							visit_detail.section_id,section_master.section_code,section_master.section_name,
							cabin_master.cabin_code,cabin_master.cabin_name,VisitParty_Details.party_contacts_code,
							VisitParty_Details.party_contacts_first_name first_name,
							CASE WHEN dbo.sol_getistdatetime()>CAST(VisitParty_Details.visit_date AS DATETIME)+CAST(visit_from_time AS DATETIME)  	AND 
					SUM(Appointment_Stone_Details.on_table_stone)>1 AND
					Appointment_Stone_Details.is_active=1 THEN 'ongoing'
					WHEN dbo.sol_getistdatetime()<CAST(Appointment_Stone_Details.visit_date AS DATETIME)+CAST(Appointment_Stone_Details.visit_from_time AS DATETIME)  	AND 
					Appointment_Stone_Details.is_active=1 THEN 'upcoming'
					WHEN dbo.sol_getistdatetime()<CAST(Appointment_Stone_Details.visit_date AS DATETIME)+CAST(Appointment_Stone_Details.visit_from_time AS DATETIME)  	AND 
					SUM(Appointment_Stone_Details.viewed_stone)=SUM(Appointment_Stone_Details.available_stone) AND Appointment_Stone_Details.VISIT_COMPLETED_TIME IS NOT NULL  AND
					Appointment_Stone_Details.is_active=1  THEN 'completed'
					WHEN Appointment_Stone_Details.VISIT_CLOSED_DATETIME IS NOT NULL THEN
					'canceled'
					WHEN dbo.sol_getistdatetime()>CAST(Appointment_Stone_Details.visit_date AS DATETIME)+CAST(Appointment_Stone_Details.visit_from_time AS DATETIME)  
					AND SUM(Appointment_Stone_Details.pending_stone)=0
					THEN 'noshow'
					ELSE
					''
					END appointment_status
		          FROM      stock.view_Appointment_Stone_Details Appointment_Stone_Details
							LEFT OUTER JOIN Stock.VISIT_DETAIL visit_detail ON visit_detail.STONEID = Appointment_Stone_Details.stoneid AND visit_detail.VISIT_ID = Appointment_Stone_Details.VISIT_ID
		                    LEFT OUTER JOIN stock.view_Appointment_VisitParty_Details VisitParty_Details ON VisitParty_Details.visit_id = Appointment_Stone_Details.VISIT_ID 
		                    LEFT OUTER JOIN Master.SECTION_MASTER section_master ON section_master.SECTION_ID = Appointment_Stone_Details.SECTION_ID
		                    LEFT OUTER JOIN Master.CABIN_MASTER cabin_master ON cabin_master.CABIN_CODE = section_master.CABIN_CODE
		          WHERE     VisitParty_Details.VISIT_DATE = CONVERT(DATE, @visit_date)
				  GROUP BY

				   VisitParty_Details.visit_id,VisitParty_Details.appointment_id,VisitParty_Details.party_code,
							VisitParty_Details.party_name,visit_detail.section_slot_from_time ,
							visit_detail.section_slot_to_time ,visit_detail.stoneid,
							visit_detail.section_id,section_master.section_code,section_master.section_name,
							cabin_master.cabin_code,cabin_master.cabin_name,VisitParty_Details.party_contacts_code,
							VisitParty_Details.party_contacts_first_name ,VisitParty_Details.visit_date,Appointment_Stone_Details.VISIT_FROM_TIME,
							Appointment_Stone_Details.is_active,Appointment_Stone_Details.VISIT_DATE,Appointment_Stone_Details.VISIT_COMPLETED_TIME,
							Appointment_Stone_Details.VISIT_CLOSED_DATETIME

		        ) AS visit_summary
		WHERE (@appointment_status='' OR visit_summary.appointment_status=@appointment_status)
		GROUP BY visit_summary.cabin_code,visit_summary.cabin_name,visit_summary.section_code,visit_summary.section_name,visit_summary.section_id,
		visit_from_time,visit_summary.visit_to_time,visit_summary.visit_id,visit_summary.party_name,visit_summary.appointment_status
 
    
END

GO


