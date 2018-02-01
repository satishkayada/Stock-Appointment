/USE [srk_db]
GO
/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Inward_Update]    Script Date: 30/01/2018 12:38:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Satish Kayada
-- Create date: 25/01/2018
-- Description:	Appointment Stock Inward Save

--CREATE TYPE [Stock].[VISIT_ID_STONEID] AS TABLE(
--	[VISIT_ID] [int] NULL,
--	[STONEID] [varchar](16) NULL
--)

-- Action paramter specification
--			  
--		1)	  inward  -- Which is use to Receive Packet from Buyer  cabin to Stock 
--		2)	  holdinward   -- which is use to receive stock from buyer cabin and generate memo for clint because clint interested in
--			  that packet 
-- =============================================

Create PROCEDURE [Stock].[usp_Appointment_Stock_Inward_Update]
@visit_id_stoneid AS stock.visit_id_stoneid READONLY,
@action_name AS VARCHAR(16),
@apps_code TINYINT=0,
@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS 
BEGIN
	declare @msg AS VARCHAR(256)
	Declare @guarantor AS VARCHAR(20)= 'guarantor';
	DECLARE @stoneId AS VARCHAR(256)

	SELECT @stoneId=VISIT_DETAIL.stoneId
	FROM stock.VISIT_DETAIL
		LEFT JOIN @visit_id_stoneid stoneId ON stoneId.VISIT_ID = VISIT_DETAIL.VISIT_ID AND stoneId.STONEID = VISIT_DETAIL.STONEID
	WHERE NOT (VISIT_DETAIL.STONE_ISSUE_DATETIME IS NOT NULL AND VISIT_DETAIL.STONE_RECEIVED_DATETIME IS NULL)
	AND stoneId.VISIT_ID IS NOT NULL

	IF len(@stoneId)>0
	BEGIN
		SET @msg='Stone Id ' + @stoneId + ' Process Mismatch to receive so please check that stone';
		RAISERROR(@msg,18,1)
		RETURN;
    END

	BEGIN TRY
	BEGIN TRAN

		IF @action_name='inward'
		BEGIN
			INSERT INTO STOCK.VISIT_STONES_FOR_NEXTCABIN
			    ( visit_id ,
			        stoneid ,
					next_visit_id,
			        next_section_id ,
			        previous_section_id ,
			        apps_code ,
			        created_datetime ,
			        created_iplocation_id
			    )
			SELECT visit_id,
			multiple_view_request.stoneid,
			next_visit_id,
			next_section_id,
			privious_section_id,
			@apps_code,
			dbo.SOL_GetISTDATETIME(),
			@modified_iplocation_id
			FROM (
								SELECT 
								VISIT.VISIT_DATE,
								VISIT_DETAIL.VISIT_ID,VISIT_DETAIL.stoneid,
								VISIT_DETAIL.SECTION_ID AS privious_section_id
								FROM STOCK.VISIT_DETAIL	
									LEFT JOIN stock.VISIT ON VISIT_DETAIL.VISIT_ID=VISIT.VISIT_ID
									LEFT JOIN @visit_id_stoneid stoneid ON stoneid.STONEID = VISIT_DETAIL.STONEID AND stoneid.VISIT_ID = VISIT_DETAIL.VISIT_ID
								WHERE STONEID.stoneid IS NOT NULL 
								AND EXISTS(	
											SELECT 1 
											FROM Stock.view_Appointment_Stone_Details 
											WHERE view_Appointment_Stone_Details.VISIT_ID=view_Appointment_Stone_Details.VISIT_ID
												AND view_Appointment_Stone_Details.stoneid=view_Appointment_Stone_Details.stoneid
												AND view_Appointment_Stone_Details.waiting_stone>0
											)
				) AS multiple_view_request
					CROSS APPLY (
							SELECT TOP 1
								view_appointment_stones.visit_id AS next_visit_id
								,section_id AS next_section_id
							FROM Stock.view_appointment_stones
								LEFT Join Stock.view_Appointment_VisitParty_Details ON view_Appointment_VisitParty_Details.visit_id = view_appointment_stones.visit_id AND view_Appointment_VisitParty_Details.party_contacts_code IS NOT null
							WHERE view_appointment_stones.stoneid=multiple_view_request.STONEID
							AND multiple_view_request.VISIT_ID!=view_appointment_stones.visit_id 
							AND stone_issue_datetime IS NULL
							AND visit_start_time IS NOT null
							AND multiple_view_request.VISIT_DATE=view_appointment_stones.visit_date
							ORDER BY priority_no DESC,view_appointment_stones.visit_start_time
								) AS next_cabin

			UPDATE VISIT_DETAIL
			SET VISIT_DETAIL.STONE_RECEIVED_DATETIME=DBO.SOL_GetISTDATETIME(),
			MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
			MODIFIED_BY=@modified_by,
			MODIFIED_IPLOCATION_ID=@modified_iplocation_id
			FROM stock.VISIT_DETAIL VISIT_DETAIL
				LEFT JOIN  @visit_id_stoneid stoneid ON stoneid.STONEID = VISIT_DETAIL.VISIT_ID AND stoneid.VISIT_ID = VISIT_DETAIL.STONEID 
			WHERE VISIT_DETAIL.STONE_ISSUE_DATETIME IS NOT NULL
			AND VISIT_DETAIL.STONE_RECEIVED_DATETIME IS NULL

			UPDATE packet.STONE_DETAILS
			SET SECTION_ID=NULL,
			MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
			MODIFIED_BY=@modified_by,
			MODIFIED_IPLOCATION_ID=@modified_iplocation_id
			FROM packet.STONE_DETAILS
				INNER JOIN @visit_id_stoneid stoneid ON stoneid.STONEID = STONE_DETAILS.STONEID
			WHERE STONE_DETAILS.stoneid IS NOT NULL
		END
		ELSE
		BEGIN
			Rollback Transaction
			RAISERROR('Not Implement Yes',18,1);
			RETURN 
		END        
	COMMIT TRAN
	END TRY
	BEGIN CATCH
		Rollback Transaction
		SELECT  @msg =ERROR_MESSAGE()
		RAISERROR(@msg,18,1)
	END CATCH
END



