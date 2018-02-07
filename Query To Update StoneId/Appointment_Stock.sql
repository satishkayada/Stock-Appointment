--Done
USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Inward_List]    Script Date: 06/02/2018 1:59:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Satish Kayada
-- Create date: 25/01/2018
-- Description:	Appointment Stock Inward List

--CREATE TYPE [Stock].[RFID_TAG] AS TABLE(
--	[rfid_tag] [varchar](16) NULL
--)

-- =============================================

CREATE PROCEDURE [Stock].[usp_Appointment_Stock_Inward_List]
@rfid_tag AS Stock.RFID_TAG READONLY
AS 
BEGIN

	DECLARE @tmpstoneId AS stock.STONEID
	INSERT INTO @tmpstoneId
		    ( STONEID )
	SELECT STONEID
	FROM Packet.STONE_DETAILS
	WHERE rfid_tag IN (SELECT RFID_TAG FROM @rfid_tag)

	declare @msg AS VARCHAR(256)
	Declare @guarantor AS VARCHAR(20)= 'guarantor';

	SELECT 
	'' details,
	stoneId.stoneid,
	view_appointment_stones.shape_name,
	view_appointment_stones.clarity_name,
	view_appointment_stones.color_name,
	view_appointment_stones.issue_carat,
	view_appointment_stones.packet_rate,
	view_appointment_stones.visit_id,
    next_cabin_name ,
	next_section_name ,
	kam_short,
	packet_rate*issue_carat AS packet_amount
	FROM @tmpstoneid AS StoneId
		LEFT JOIN stock.view_appointment_stones on view_appointment_stones.stoneid = StoneId.STONEID AND view_appointment_stones.stone_issue_datetime IS NOT NULL AND view_appointment_stones.stone_received_datetime IS NULL
		LEFT JOIN stock.view_Appointment_Stone_Details ON view_Appointment_Stone_Details.VISIT_ID = view_appointment_stones.visit_id
		AND view_Appointment_Stone_Details.stoneid = view_appointment_stones.stoneid
		OUTER APPLY (
					SELECT TOP 1 
					cabin_name next_cabin_name,
					section_name next_section_name
					FROM Stock.VISIT_DETAIL
						LEFT JOIN Stock.VISIT on VISIT.VISIT_ID=Stock.VISIT_DETAIL.VISIT_ID
						LEFT JOIN Stock.VISIT_STONE_PRIORITY ON VISIT_STONE_PRIORITY.VISIT_ID=Stock.VISIT_DETAIL.VISIT_ID
						LEFT JOIN Master.SECTION_MASTER ON SECTION_MASTER.SECTION_ID = VISIT_DETAIL.SECTION_ID
						LEFT JOIN Master.CABIN_MASTER ON CABIN_MASTER.CABIN_CODE = SECTION_MASTER.CABIN_CODE
					WHERE VISIT_DETAIL.STONEID=StoneId.STONEID
					AND Visit.VISIT_START_TIME IS NOT NULL
					AND view_Appointment_Stone_Details.VISIT_ID != VISIT.VISIT_ID
                    AND vISIT.VISIT_DATE=CAST(DBO.SOL_GetISTDATETIME() AS DATE)
					ORDER BY VISIT_STONE_PRIORITY.PRIORITY_NO DESC,VISIT_START_TIME
				  ) AS nextcabinname
	WHERE view_appointment_stones.stone_issue_datetime IS NOT NULL AND view_appointment_stones.stone_received_datetime IS NULL
END
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Inward_To_Outward_Header_Text]    Script Date: 06/02/2018 1:59:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Satish Kayada
-- Create date: 01/02/2018
-- Description:	Display Header on Tab of Inward outward Page only
-- =============================================

Create PROC [Stock].[usp_Appointment_Stock_Inward_To_Outward_Header_Text]
AS
BEGIN
        Select Count(*) As totalparty,sum(stonecount) as totalstone 
        From (
		SELECT Distinct Visit.PARTY_CODE,StoneId.stoneid,
        1 As stonecount
		FROM Stock.VISIT_STONES_FOR_NEXTCABIN StoneId
            left join Stock.VISIT on Stock.VISIT.visit_id=StoneId.visit_id
        ) as stone
END;
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Inward_To_Outward_Box_ButtonAction]    Script Date: 06/02/2018 1:59:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Satish Kayada
-- Create date: 01/02/2018
-- Description:	Use to Work on Button 

-- CREATE TYPE [Stock].[VISIT_ID_STONEID] AS TABLE(
-- 	[visit_id] [int] NULL,
-- 	[stoneid] [varchar](16) NULL
-- )

-- =============================================
CREATE PROC [Stock].[usp_Appointment_Stock_Inward_To_Outward_Box_ButtonAction]
@visit_id INT,
@Visit_id_stoneId stock.VISIT_ID_STONEID READONLY,
@action_name AS VARCHAR(30),

@apps_code TINYINT=0,

@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS 
BEGIN
	DECLARE @msg AS VARCHAR(256)
	DECLARE @stone_Id AS VARCHAR(16)
	DECLARE @Servity AS INT
	DECLARE @level AS INT
    /*
    Put Validation for Stone must be recently return from buyer cabin.
    */
    IF EXISTS
    (
		SELECT 1
		FROM @visit_id_stoneId visit_id_stoneId
			LEFT JOIN Stock.VISIT_STONES_FOR_NEXTCABIN ON next_visit_id=visit_id_stoneId.visit_Id AND VISIT_STONES_FOR_NEXTCABIN.stoneid=visit_id_stoneId.stoneId
		WHERE VISIT_STONES_FOR_NEXTCABIN.stoneid IS null
	)
	BEGIN
		SET @msg='Stone Status is Not Buyer Inward To outWard'
		RAISERROR(@msg,18,1);
		RETURN;
    END
	
    IF @action_name='removestones'
	BEGIN
		SELECT TOP 1 @stone_Id=VISIT_DETAIL.STONEID
		FROM Stock.VISIT_DETAIL
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = VISIT_DETAIL.STONEID AND Visit_Id_stoneId.VISIT_ID = VISIT_DETAIL.VISIT_ID 
		WHERE 1=1
		AND STONE_ISSUE_DATETIME IS NOT NULL
		IF LEN(@stone_Id)>0
		BEGIN
			SET @msg='Stone Id' + @stone_Id + ' Send To Buyer Cabin Done so You can not Delete Appointment !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END
		Delete Stock.VISIT_DETAIL 
		WHERE EXISTS (
				SELECT 1 
				FROM @Visit_Id_stoneId Visit_Id_stoneId 
				WHERE Visit_Id_stoneId.VISIT_ID=VISIT_DETAIL .VISIT_ID 
				AND Visit_Id_stoneId.STONEID=VISIT_DETAIL .STONEID
				     )
    END
	IF @action_name='sendtobuyer'
	BEGIN
		SELECT TOP 1 @stone_Id=VISIT_DETAIL.STONEID
		FROM Stock.VISIT_DETAIL
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = VISIT_DETAIL.STONEID AND Visit_Id_stoneId.VISIT_ID = VISIT_DETAIL.VISIT_ID
		WHERE STONE_ISSUE_DATETIME IS NOT NULL

		IF LEN(@stone_Id)>0
		BEGIN	
			SET @msg='Stone Id' + @stone_Id + ' Already in Buyer Cabin or Issue Process Done so You can not send to Buyer !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END

		SELECT TOP 1 @stone_Id=VISIT_DETAIL.STONEID
		FROM Stock.VISIT_DETAIL
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = VISIT_DETAIL.STONEID AND Visit_Id_stoneId.VISIT_ID = VISIT_DETAIL.VISIT_ID 
		WHERE CHECK_SCAN_STATUS!=2
		IF LEN(@stone_Id)>0
		BEGIN	
			SET @msg='Stone Id' + @stone_Id + ' Not Properly Veirfy !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END

		Begin TRY
		Begin TRAN

		UPDATE Stock.VISIT_DETAIL
		SET 
		STONE_ISSUE_DATETIME=dbo.SOL_GetISTDATETIME(),
		MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
		MODIFIED_BY=@modified_by,
		MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		FROM Stock.VISIT_DETAIL
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = VISIT_DETAIL.STONEID AND Visit_Id_stoneId.VISIT_ID = VISIT_DETAIL.VISIT_ID 
		WHERE 1=1

		UPDATE PACKET.STONE_DETAILS
		SET 
		PACKET.STONE_DETAILS.SECTION_ID=Stock.VISIT_DETAIL.SECTION_ID,
		PACKET.STONE_DETAILS.VISIT_ID=Visit_Id_stoneId.visit_id,
		MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
		MODIFIED_BY=@modified_by,
		MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		FROM PACKET.STONE_DETAILS
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = STONE_DETAILS.stoneid 
			JOIN Stock.VISIT_DETAIL ON Visit_Id_stoneId.VISIT_ID=Stock.VISIT_DETAIL.VISIT_ID AND Visit_Id_stoneId.STONEID=Stock.VISIT_DETAIL.STONEID
		WHERE 1=1

		Delete
		From STOCK.VISIT_STONES_FOR_NEXTCABIN
		wHERE EXISTS(
						SElect 1
						From @Visit_Id_stoneId Visit_Id_stoneId
						Where Visit_Id_stoneId.stoneid=VISIT_STONES_FOR_NEXTCABIN.stoneId
						And Visit_Id_stoneId.visit_id=VISIT_STONES_FOR_NEXTCABIN.next_visit_id
					)

		COMMIT TRAN
		End TRY
		Begin CATCH
			ROLLBACK TRANSACTION
			SET @msg =ERROR_MESSAGE()
			SET @Servity=ERROR_SEVERITY()
			SET @level=ERROR_STATE()
			RAISERROR(@msg,@Servity,@level);
		End CATCH
    End
End

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Inward_To_outward_Box_UpdateStatus]    Script Date: 06/02/2018 1:59:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Satish Kayada
-- Create date: 01/02/2018
-- Description:	To Update Status of Stone Id Inward to Outward Tab


--CREATE TYPE [Stock].[VISIT_ID_STONEID] AS TABLE(
--	[VISIT_ID] INT,
--	[STONEID] [VARCHAR](16) NULL
--)

-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Inward_To_outward_Box_UpdateStatus]
@visit_id_stoneId stock.VISIT_ID_STONEID READONLY,
@status_Code TINYINT,
@apps_code TINYINT=0,
@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS 
BEGIN
	DECLARE @msg AS VARCHAR(256)
	
	DECLARE @VISIT_START_TIME AS TIME
	IF EXISTS
    (
		SELECT 1
		FROM (
				SELECT DISTINCT VISIT_ID
				FROM @visit_id_stoneId
			 ) AS VISIT_ID_STONEID
			 LEFT JOIN Stock.VISIT ON VISIT.VISIT_ID = VISIT_ID_STONEID.VISIT_ID
		WHERE STOCK.VISIT.VISIT_ID IS NOT NULL
		AND STOCK.VISIT.VISIT_START_TIME IS NULL
	)
	BEGIN
		SET @msg='Appointment is Not Started yes so you can not start issue Process'
		RAISERROR(@msg,18,1);
		RETURN;
    END
	IF EXISTS
    (
		SELECT VISIT_ID_STONEID.VISIT_ID
		FROM @visit_id_stoneId VISIT_ID_STONEID
				LEFT JOIN Stock.VISIT_DETAIL ON VISIT_DETAIL.VISIT_ID = VISIT_ID_STONEID.VISIT_ID
		WHERE STONE_ISSUE_DATETIME IS NOT NULL
	)
	BEGIN
		SET @msg='Appointment is Started and Stone issue Done so you can not change status of stone'
		RAISERROR(@msg,18,1);
		RETURN;
    END
	IF EXISTS
    (
		SELECT 1
		FROM @visit_id_stoneId visit_id_stoneId
			LEFT JOIN Stock.VISIT_STONES_FOR_NEXTCABIN ON next_visit_id=visit_id_stoneId.visit_Id AND VISIT_STONES_FOR_NEXTCABIN.stoneid=visit_id_stoneId.stoneId
		WHERE VISIT_STONES_FOR_NEXTCABIN.stoneid IS null
	)
	BEGIN
		SET @msg='Stone Status is Not Buyer Inward To outWard'
		RAISERROR(@msg,18,1);
		RETURN;
    END

	UPDATE Stock.VISIT_DETAIL
	SET 
	CHECK_SCAN_STATUS=@Status_Code,
	IS_SCAN_BY_RFID=CASE WHEN(@Status_Code=1) THEN 1 ELSE IS_SCAN_BY_RFID END,
	MODIFIED_DATETIME=DBO.SOL_GetISTDATETIME(),
	MODIFIED_BY=@modified_by,
	MODIFIED_IPLOCATION_ID=@modified_iplocation_id
	FROM @visit_id_stoneId VISIT_ID_STONEID
		JOIN Stock.VISIT_DETAIL ON VISIT_DETAIL.STONEID = VISIT_ID_STONEID.STONEID AND VISIT_DETAIL.VISIT_ID = VISIT_ID_STONEID.VISIT_ID
	WHERE VISIT_DETAIL.VISIT_ID IS NOT null
END


GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Inward_To_Outward_List]    Script Date: 06/02/2018 1:59:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Satish Kayada
-- Create date: 01/02/2018
-- Description:	Display Header on Tab of Inward outward Page only
-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Inward_To_Outward_List]
AS
BEGIN
		SELECT *
		FROM Stock.VISIT_STONES_FOR_NEXTCABIN StoneId
			outer apply (
							SELECT 
							ROW_NUMBER() OVER (ORDER BY priority_no DESC,visit_start_time)  AS rno,
							view_appointment_stones.visit_id,
							party_name,party_code,
							view_appointment_stones.kam_name,
							view_appointment_stones.party_contacts_kam_code,
							cabin_name,
							check_scan_status,
							is_scan_by_rfid,
							'' AS Detail,
							box_name,
							STONEID,
							shape_name,
							clarity_name,
							color_name,
							issue_carat,
							packet_rate,
							packet_rate*issue_carat AS packet_amount
							FROM Stock.view_appointment_stones
								LEFT JOIN Stock.view_Appointment_VisitParty_Details ON view_Appointment_VisitParty_Details.visit_id = view_appointment_stones.visit_id
							WHERE view_appointment_stones.stoneid=StoneId.STONEID
							AND stone_issue_datetime IS NULL
			) AS Stone
		ORDER BY party_name
				
END;
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Inward_Update]    Script Date: 06/02/2018 1:59:34 PM ******/
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




GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_Box_UpdateStatus]    Script Date: 06/02/2018 1:59:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Satish Kayada
-- Create date: 26/01/2018
-- Description:	To Update Status of Stone Id Visit Id Wise


--CREATE TYPE [Stock].[VISIT_ID_STONEID] AS TABLE(
--	[VISIT_ID] INT,
--	[STONEID] [VARCHAR](16) NULL
--)

-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_Box_UpdateStatus]
@visit_id_stoneId stock.VISIT_ID_STONEID READONLY,
@status_Code TINYINT,
@apps_code TINYINT=0,
@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS 
BEGIN
	DECLARE @msg AS VARCHAR(256)
	
	DECLARE @VISIT_START_TIME AS TIME
	
	IF EXISTS
    (
		SELECT 1
		FROM (
				SELECT DISTINCT VISIT_ID
				FROM @visit_id_stoneId
			 ) AS VISIT_ID_STONEID
			 LEFT JOIN Stock.VISIT ON VISIT.VISIT_ID = VISIT_ID_STONEID.VISIT_ID
		WHERE STOCK.VISIT.VISIT_ID IS NOT NULL
		AND STOCK.VISIT.VISIT_START_TIME IS NULL
	)
	BEGIN
		SET @msg='Appointment is Not Started yes so you can not start issue Process'
		RAISERROR(@msg,18,1);
		RETURN;
    END
	IF EXISTS
    (
		SELECT VISIT_ID_STONEID.VISIT_ID
		FROM @visit_id_stoneId VISIT_ID_STONEID
				LEFT JOIN Stock.VISIT_DETAIL ON VISIT_DETAIL.VISIT_ID = VISIT_ID_STONEID.VISIT_ID
		WHERE STONE_ISSUE_DATETIME IS NOT NULL
	)
	BEGIN
		SET @msg='Appointment is Started and Stone issue Done so you can not change status of stone'
		RAISERROR(@msg,18,1);
		RETURN;
    END

	UPDATE Stock.VISIT_DETAIL
	SET 
	CHECK_SCAN_STATUS=@Status_Code,
	IS_SCAN_BY_RFID=CASE WHEN(@Status_Code=1) THEN 1 ELSE IS_SCAN_BY_RFID END,
	MODIFIED_DATETIME=DBO.SOL_GetISTDATETIME(),
	MODIFIED_BY=@modified_by,
	MODIFIED_IPLOCATION_ID=@modified_iplocation_id
	FROM @visit_id_stoneId VISIT_ID_STONEID
		JOIN Stock.VISIT_DETAIL ON VISIT_DETAIL.STONEID = VISIT_ID_STONEID.STONEID AND VISIT_DETAIL.VISIT_ID = VISIT_ID_STONEID.VISIT_ID
	WHERE VISIT_DETAIL.VISIT_ID IS NOT null
END


GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_Box_ButtonAction]    Script Date: 06/02/2018 1:59:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Satish Kayada
-- Create date: 24/01/2018
-- Description:	Use to Work on Button 

--CREATE TYPE [Stock].[VISIT_ID_STONEID] AS TABLE(
--	[visit_id] [int] NULL,
--	[stoneid] [varchar](16) NULL
--)

--action name
--removestones
--sendtobuyer

-- =============================================
CREATE PROC [Stock].[usp_Appointment_Stock_Outward_Box_ButtonAction]
@Visit_id_stoneId stock.VISIT_ID_STONEID READONLY,
@action_name AS VARCHAR(30),

@apps_code TINYINT=0,

@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS 
BEGIN
	DECLARE @msg AS VARCHAR(256)
	DECLARE @stone_Id AS VARCHAR(16)

	IF @action_name='removestones'
	BEGIN
		SELECT TOP 1 @stone_Id=VISIT_DETAIL.STONEID
		FROM Stock.VISIT_DETAIL
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = VISIT_DETAIL.STONEID AND Visit_Id_stoneId.VISIT_ID = VISIT_DETAIL.VISIT_ID 
		WHERE 1=1
		AND STONE_ISSUE_DATETIME IS NOT NULL
		IF LEN(@stone_Id)>0
		BEGIN
			SET @msg='Stone Id' + @stone_Id + ' Send To Buyer Cabin Done so You can not Delete Appointment !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END
		Delete Stock.VISIT_DETAIL 
		WHERE EXISTS (
				SELECT 1 
				FROM @Visit_Id_stoneId Visit_Id_stoneId 
				WHERE Visit_Id_stoneId.VISIT_ID=VISIT_DETAIL .VISIT_ID 
				AND Visit_Id_stoneId.STONEID=VISIT_DETAIL .STONEID
				)
    END
	IF @action_name='sendtobuyer'
	BEGIN
		SELECT TOP 1 @stone_Id=VISIT_DETAIL.STONEID
		FROM Stock.VISIT_DETAIL
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = VISIT_DETAIL.STONEID AND Visit_Id_stoneId.VISIT_ID = VISIT_DETAIL.VISIT_ID
		WHERE STONE_ISSUE_DATETIME IS NOT NULL

		IF LEN(@stone_Id)>0
		BEGIN	
			SET @msg='Stone Id' + @stone_Id + ' Already in Buyer Cabin or Issue Process Done so You can not send to Buyer !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END

		SELECT TOP 1 @stone_Id=VISIT_DETAIL.STONEID
		FROM Stock.VISIT_DETAIL
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = VISIT_DETAIL.STONEID AND Visit_Id_stoneId.VISIT_ID = VISIT_DETAIL.VISIT_ID 
		WHERE CHECK_SCAN_STATUS!=2
		IF LEN(@stone_Id)>0
		BEGIN	
			SET @msg='Stone Id' + @stone_Id + ' Not Properly Veirfy !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END

		UPDATE Stock.VISIT_DETAIL
		SET 
		STONE_ISSUE_DATETIME=dbo.SOL_GetISTDATETIME(),
		MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
		MODIFIED_BY=@modified_by,
		MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		FROM Stock.VISIT_DETAIL
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = VISIT_DETAIL.STONEID AND Visit_Id_stoneId.VISIT_ID = VISIT_DETAIL.VISIT_ID 
		WHERE 1=1

		UPDATE PACKET.STONE_DETAILS
		SET 
		PACKET.STONE_DETAILS.SECTION_ID=Stock.VISIT_DETAIL.SECTION_ID,
		PACKET.STONE_DETAILS.VISIT_ID=Visit_Id_stoneId.visit_id,
		MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
		MODIFIED_BY=@modified_by,
		MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		FROM PACKET.STONE_DETAILS
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = STONE_DETAILS.stoneid 
			JOIN Stock.VISIT_DETAIL ON Visit_Id_stoneId.VISIT_ID=Stock.VISIT_DETAIL.VISIT_ID AND Visit_Id_stoneId.STONEID=Stock.VISIT_DETAIL.STONEID
		WHERE 1=1
    End
End


select  top 1 * from Stock.VISIT_DETAIL
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_UpdateStatus]    Script Date: 06/02/2018 1:59:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Satish Kayada
-- Create date: 24/01/2018
-- Description:	To Update Stauts of Stone Id 


--CREATE TYPE [Stock].[STONEID] AS TABLE(
--	[STONEID] [VARCHAR](16) NULL
--)

-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_UpdateStatus]
@visit_id INT,
@stoneid stock.STONEID READONLY,
@status_code TINYINT,
@apps_code TINYINT=0,
@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS 
BEGIN

	DECLARE @tmpstone_Id AS VARCHAR(16)
	DECLARE @msg AS VARCHAR(256)
	
	IF @visit_id=0 OR @visit_id IS NULL 
	BEGIN
		SET @msg='';
		RAISERROR('Invalid Visit Id Pass',18,1);
		RETURN;
	END
	DECLARE @guarantor AS VARCHAR(20)= 'guarantor';

	DECLARE @VISIT_START_TIME AS TIME
	SELECT @VISIT_START_TIME=VISIT_START_TIME
	FROM Stock.VISIT
	WHERE VISIT_ID=@visit_id 
	IF @VISIT_START_TIME IS NULL
	BEGIN
		SET @msg='Appointment is Not Started yes so you can not start issue Process'
		RAISERROR(@msg,18,1);
		RETURN;
    END

	SELECT TOP 1 @tmpstone_Id=STONEID
	FROM Stock.VISIT_DETAIL
	WHERE VISIT_ID=@visit_id AND STONEID IN (SELECT StoneId FROM @stoneId)
	AND STONE_ISSUE_DATETIME IS NOT NULL
	IF LEN(@tmpstone_Id)>0
	BEGIN
		SET @msg= 'Process Issue Done for ' +@tmpstone_Id+ ' Stone so you can not change status of this Stone.'
		RAISERROR(@msg,18,1);
		RETURN;
	END
    
	UPDATE Stock.VISIT_DETAIL
	SET  
	CHECK_SCAN_STATUS=@Status_Code,
	IS_SCAN_BY_RFID=CASE WHEN(@Status_Code=1) THEN 1 ELSE IS_SCAN_BY_RFID END
	WHERE VISIT_ID=@visit_id AND STONEID IN (SELECT STONEID FROM @stoneId)
END
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_Box_List]    Script Date: 06/02/2018 1:59:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================n
-- Author:		Satish Kayada
-- Create date: 25/01/2018
-- Description:	Appointment Stock Outward Box Wise List

--CREATE TYPE [Stock].[RFID_TAG] AS TABLE(
--	[rfid_tag] [varchar](16) NULL
--)

--action List
--all
--buyercabin
--businessprocess
--confirm
--free

-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_Box_List]
@rfid_tag AS Stock.rfid_tag READONLY,
@list_name as varchar(15)
AS
BEGIN

    DECLARE @Today AS DATE= dbo.SOL_GetISTDATETIME();
    DECLARE @msg AS VARCHAR(256);
	DECLARE @tmpStoneId AS stock.STONEID
	INSERT INTO @tmpStoneId
	SELECT STONEID
	FROM Packet.STONE_DETAILS
	WHERE rfid_tag IN (SELECT rfid_tag FROM @rfid_tag)
	
	Select *
	From (
			select 'buyercabin' AS tab_name,
					stoneid.stoneid parastoneid,	stone.rno ,
											stone.visit_id ,
											stone.party_name ,
											stone.party_code ,
											stone.kam_name ,
											stone.party_contacts_kam_code ,
											stone.cabin_name ,
											stone.check_scan_status ,
											stone.is_scan_by_rfid ,
											stone.detail ,
											stone.box_name ,
											stone.stoneid ,
											stone.shape_name ,
											stone.clarity_name ,
											stone.color_name ,
											stone.issue_carat ,
											stone.packet_rate ,
											stone.packet_amount
			from @tmpstoneid stoneid
				CROSS apply (
								select 
								row_number() over (order by priority_no desc,visit_start_time)  as rno,
								view_appointment_stones.visit_id,
								party_name,party_code,
								view_appointment_stones.kam_name,
								view_appointment_stones.party_contacts_kam_code,
								cabin_name,
								check_scan_status,
								is_scan_by_rfid,
								'' as detail,
								box_name,
								stoneid,
								shape_name,
								clarity_name,
								color_name,
								issue_carat,
								packet_rate,
								packet_rate*issue_carat as packet_amount
								from stock.view_appointment_stones
									left join stock.view_appointment_visitparty_details on view_appointment_visitparty_details.visit_id = view_appointment_stones.visit_id and view_appointment_visitparty_details.party_contacts_code is not null
								where view_appointment_stones.stoneid=stoneid.stoneid
								and view_appointment_stones.visit_date=dbo.sol_getistdate()
								and stone_issue_datetime is null
				) as stone
			where  (@list_name='all' or  @list_name='buyercabin')

			UNION ALL
			select  tab_name,
					stoneid.stoneid parastoneid, stone.rno ,
											stone.visit_id ,
											stone.party_name ,
											stone.party_code ,
											stone.kam_name ,
											stone.party_contacts_kam_code ,
											stone.cabin_name ,
											stone.check_scan_status ,
											stone.is_scan_by_rfid ,
											stone.detail ,
											stone.box_name ,
											stone.stoneid ,
											stone.shape_name ,
											stone.clarity_name ,
											stone.color_name ,
											stone.issue_carat ,
											stone.packet_rate ,
											stone.packet_amount
			from @tmpstoneid stoneid
				CROSS apply (
								select 
								CASE WHEN(STONE_DETAILS.memo_date IS NOT NULL AND is_memo_lock=0) THEN 'businessprocess'
									WHEN(STONE_DETAILS.memo_date IS NOT NULL AND is_memo_lock=1) THEN 'confirm'
									WHEN(STONE_DETAILS.memo_date IS NULL AND is_memo_lock=0 AND SECTION_MASTER.section_id IS NULL) THEN 'free'
								ELSE '' END AS tab_name,
								row_number() over (order by Packet.STONE_DETAILS.stoneid)  as rno,
								Packet.STONE_DETAILS.visit_id,
								STONE_DETAILS.party_code,
								PARTY_MASTER.party_name,
								stone_details.user_code party_contacts_kam_code,
								USER_MASTER.user_short_name kam_name,
								cabin_name,
								0 check_scan_status,
								is_scan_by_rfid,
								'' as detail,
								box_name,
								stone_details.stoneid,
								shape_name,
								clarity_name,
								color_name,
								issue_carat,
								packet_rate,
								packet_rate*issue_carat as packet_amount
								from packet.STONE_DETAILS	
									LEFT JOIN Sales.PARTY_MASTER ON PARTY_MASTER.PARTY_CODE = STONE_DETAILS.party_code
									LEFT JOIN packet.STONE_LAB_DETAILS ON STONE_LAB_DETAILS.stoneid = STONE_DETAILS.stoneid AND STONE_LAB_DETAILS.certificate_code = STONE_DETAILS.certificate_code
									LEFT JOIN packet.STONE_LAB_DESCRIPTION ON stone_Details.stoneid = packet.stone_lab_description.stoneid 
									AND stone_lab_description.certificate_code = STONE_LAB_DETAILS.certificate_code
									LEFT JOIN Master.USER_MASTER ON USER_MASTER.user_code=stone_details.user_code
									LEFT JOIN Stock.visit_detail ON Stock.VISIT_DETAIL.VISIT_ID=packet.STONE_DETAILS.visit_id
									LEFT JOIN stock.visit ON VISIT.VISIT_ID = STONE_DETAILS.visit_id
									LEFT join stock.view_appointment_visitparty_details on view_appointment_visitparty_details.visit_id = STONE_DETAILS.visit_id AND view_appointment_visitparty_details.party_contacts_code IS NOT NULL
									LEFT JOIN Master.SECTION_MASTER ON SECTION_MASTER.section_id = STONE_DETAILS.section_id
									LEFT JOIN master.CABIN_MASTER ON CABIN_MASTER.cabin_code = SECTION_MASTER.cabin_code
									LEFT JOIN master.BOX_RFID_MASTER ON Packet.STONE_DETAILS.box_rfid=Master.BOX_RFID_MASTER.box_rfid
								WHERE packet.STONE_DETAILS.stoneid=stoneid.stoneid
								AND 
								(
									(STONE_DETAILS.memo_date IS NOT NULL AND is_memo_lock=0) OR 
									(STONE_DETAILS.memo_date IS NOT NULL AND is_memo_lock=1) OR 
									(STONE_DETAILS.memo_date IS NULL AND is_memo_lock=0 AND SECTION_MASTER.section_id IS NULL)
								)
				) as stone
			) AS packet
		where (tab_name=@list_name or @list_name='' or @list_name='all')
END;






GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_ButtonAction]    Script Date: 06/02/2018 1:59:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Satish Kayada
-- Create date: 24/01/2018
-- Description:	Use to Work on Button For Box Wise

--CREATE TYPE [Stock].[STONEID] AS TABLE(
--	[STONEID] [VARCHAR](16) NULL
--)

-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_ButtonAction]
@visit_id INT,
@stoneid stock.STONEID READONLY,
@action_name AS VARCHAR(30),

@apps_code TINYINT=0,

@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS 
BEGIN
	DECLARE @msg AS VARCHAR(256)
	DECLARE @stone_Id AS VARCHAR(16)
	IF @visit_id=0 OR @visit_id IS NULL 
	BEGIN
		SET @msg='';
		raiserror('Invalid Visit Id Pass',18,1);
		RETURN;
        
	END

	IF @action_name='removeappointment'
	BEGIN
		DECLARE @VISIT_START_TIME AS TIME
		SELECT @VISIT_START_TIME=VISIT_START_TIME
		FROM Stock.VISIT
		WHERE VISIT_ID=@visit_id 
		IF @VISIT_START_TIME IS NOT NULL
		BEGIN
			SET @msg='Appointment Already Started so you can not delete !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END
		Delete Stock.VISIT_STONE_PRIORITY WHERE VISIT_ID=@visit_id
		Delete Stock.VISIT_CONTACTS_KAM WHERE  VISIT_CONTACTS_ID IN (SELECT VISIT_CONTACTS_ID FROM STOCK.VISIT_CONTACTS WHERE VISIT_ID=@visit_id)
		Delete Stock.VISIT_CONTACTS WHERE VISIT_ID=@visit_id
		Delete Stock.VISIT_DETAIL WHERE VISIT_ID=@visit_id
		DELETE stock.VISIT WHERE VISIT_ID=@visit_id
    END
	IF @action_name='removestones'
	BEGIN
		SELECT TOP 1 @stone_Id=STONEID
		FROM Stock.VISIT_DETAIL
		WHERE VISIT_ID=@visit_id AND stoneId IN (SELECT StoneId FROM @stoneId)
		AND STONE_ISSUE_DATETIME IS NOT NULL
		IF LEN(@stone_Id)>0
		BEGIN
			SET @msg='Stone Id' + @stone_Id + ' Send To Buyer Cabin Done so You can not Delete Appointment !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END
		Delete Stock.VISIT_DETAIL WHERE VISIT_ID=@visit_id AND STONEID IN (SELECT STONEID FROM @stoneId)
    END
	IF @action_name='sendtobuyer'
	BEGIN
		SELECT TOP 1 @stone_Id=STONEID
		FROM Stock.VISIT_DETAIL
		WHERE VISIT_ID=@visit_id AND stoneId IN (SELECT StoneId FROM @stoneId)
		AND STONE_ISSUE_DATETIME IS NOT NULL

		IF LEN(@stone_Id)>0
		BEGIN	
			SET @msg='Stone Id' + @stone_Id + ' Already in Buyer Cabin so You can not send to Buyer !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END

		SELECT TOP 1 @stone_Id=STONEID
		FROM Stock.VISIT_DETAIL
		WHERE VISIT_ID=@visit_id AND stoneId IN (SELECT StoneId FROM @stoneId)
		AND CHECK_SCAN_STATUS!=2
		IF LEN(@stone_Id)>0
		BEGIN	
			SET @msg='Stone Id ' + @stone_Id + ' Not Properly Veirfy !!!'
			RAISERROR(@msg,18,1);
			RETURN;
        END

		UPDATE Stock.VISIT_DETAIL
		SET 
		STONE_ISSUE_DATETIME=dbo.SOL_GetISTDATETIME(),
		MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
		MODIFIED_BY=@modified_by,
		MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		WHERE VISIT_ID=@visit_id AND  STONEID IN (SELECT STONEID FROM @stoneId)

		UPDATE PACKET.STONE_DETAILS
		SET PACKET.STONE_DETAILS.SECTION_ID=Stock.VISIT_DETAIL.SECTION_ID,
			PACKET.STONE_DETAILS.VISIT_ID=@visit_id
		FROM PACKET.STONE_DETAILS
			INNER JOIN Stock.VISIT_DETAIL ON STONE_DETAILS.stoneid=Stock.VISIT_DETAIL.STONEID
		WHERE VISIT_DETAIL.visit_id=@visit_id aND visit_detail.stoneid IN (SELECT STONEID FROM @stoneId)
    End
End


GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_Box_Summary_List]    Script Date: 06/02/2018 1:59:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Satish Kayada
-- Create date: 25/01/2018
-- Description:	Appointment Stock Outward Header Count 
-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_Box_Summary_List]
AS
    BEGIN

        SELECT  COUNT(*) AS allStone ,
                SUM(CASE WHEN ( Packet.STONE_DETAILS.SECTION_ID IS NOT null
                              ) THEN 1
                         ELSE 0
                    END) AS buyercabin ,
                SUM(CASE WHEN ( Packet.STONE_DETAILS.memo_date IS NOT NULL
                                AND is_memo_lock = 0
                              ) THEN 1
                         ELSE 0
                    END) AS totalbusinessprocess ,
                SUM(CASE WHEN ( Packet.STONE_DETAILS.memo_date IS NOT NULL
                                AND is_memo_lock = 1
                              ) THEN 1
                         ELSE 0
                    END) AS totalconfirmstone ,
                SUM(CASE WHEN ( Packet.STONE_DETAILS.SECTION_ID IS NULL
 								AND Packet.STONE_DETAILS.memo_date IS NULL
                                AND is_memo_lock = 0
                              ) THEN 1
                         ELSE 0
                    END)
				AS freestone
        FROM    Packet.STONE_DETAILS
    END;




GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_Summary_List]    Script Date: 06/02/2018 1:59:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_Summary_List]
AS
BEGIN
	DECLARE @guarantor AS VARCHAR(20)= 'guarantor';
		SELECT  
			ISNULL(COUNT(*),0)							AS total_appointments,
			ISNULL(SUM(stonedetail.total_stones),0)     AS total_stones ,
            IsNull(SUM(stonedetail.pending_stones),0)   AS pending_stones ,
            IsNull(SUM(stonedetail.allocated_stones),0) AS allocated_stones ,
            IsNull(SUM(stonedetail.waiting_stones),0)   AS waiting_stones ,
            IsNull(SUM(stonedetail.rejected_stones),0)  AS rejected_stones
        FROM    Stock.VISIT
                LEFT JOIN ( SELECT  VISIT_ID ,
                                    section_id ,
                                    COUNT(*) total_stones ,
                                    SUM(pending_stone) AS pending_stones ,
                                    SUM(waiting_stone) AS waiting_stones ,
                                    SUM(visit_confirm_stone) AS confirm_stones ,
                                    SUM(on_table_stone) AS allocated_stones ,
                                    SUM(rejected_stone) AS rejected_stones ,
                                    SUM(pending_stone + waiting_stone) AS client_pending_stones
                            FROM    Stock.view_Appointment_Stone_Details
                            GROUP BY VISIT_ID ,
                                    section_id
                          ) AS stonedetail ON stonedetail.VISIT_ID = VISIT.VISIT_ID
        WHERE   client_pending_stones > 0
		AND Visit.VISIT_START_TIME IS NOT null
		AND visit.VISIT_DATE=CAST (dbo.SOL_GetISTDATETIME() AS DATE)
END;

GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_List]    Script Date: 06/02/2018 1:59:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Satish Kayada
-- Create date: 23/01/2018
-- Description:	Inward outWard Summary of Visit List
-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_List]
@visit_id INT
AS 
BEGIN
	DECLARE @msg AS VARCHAR(256)
	IF @visit_id=0 OR @visit_id IS NULL 
	BEGIN
		SET @msg='';
		raiserror('Invalid Visit Id Pass',18,1);
		RETURN;
        
	END
	Declare @guarantor AS VARCHAR(20)= 'guarantor';

	SELECT
	visit.visit_id,
	visit.party_code,
	sales.party_master.party_name
	,guarantor.party_code guarantorcode
	,guarantor.party_name guarantorname
	,visitcontact.visit_contacts_id
	,party_contacts_kam_code
	,user_master.user_short_name AS kam_short
	,cabinDetail.cabin_name
	,cabinDetail.section_name
	,cabinDetail.visit_date
	,section_slot_from_time 
	,section_slot_to_time
	,stonedetail.total_stones
	,stonedetail.pending_stones
	,allocated_stones
	,stonedetail.waiting_stones
	,stonedetail.rejected_stones
	,visit.is_active
	,CabinDetail.section_id 
	FROM STOCK.VISIT
		LEFT JOIN SALES.PARTY_MASTER ON party_master.party_code = visit.party_code
		CROSS APPLY (
						SELECT TOP 1 visit_contacts.visit_contacts_id
						FROM stock.visit_contacts
						WHERE visit_contacts.visit_id=visit.visit_id 
					) AS visitcontact
		CROSS APPLY (
						SELECT TOP 1 visit_contacts_kam_id,visit_contacts_kam.party_contacts_kam_code
						FROM stock.visit_contacts_kam
						WHERE stock.visit_contacts_kam.visit_contacts_id IN (  SELECT visit_contacts_id
																				FROM stock.visit_contacts
																				WHERE visit_contacts.visit_id=visit.visit_id 
																				  )
					) AS visitkam
		OUTER APPLY (
						SELECT TOP 1 party_roles.party_code,party_name 
						FROM sales.party_relations
							LEFT JOIN sales.party_roles ON party_roles.party_role_code = party_relations.party_role_code 
							LEFT JOIN sales.party_master ON party_master.party_code = party_roles.party_code
						WHERE sales.party_relations.party_code=visit.party_code AND sales.party_roles.role_code=master.getrolecode(@guarantor)
					) AS guarantor
		LEFT JOIN master.user_master ON user_master.user_code=visitkam.party_contacts_kam_code
		LEFT JOIN (
						SELECT visit_id,section_id,
						 COUNT(*) total_stones
						,SUM(pending_stone) AS pending_stones
						,SUM(waiting_stone) AS waiting_stones
						,SUM(visit_confirm_stone) AS confirm_stones
						,SUM(on_table_stone) AS allocated_stones
						,SUM(rejected_stone) AS rejected_stones
						,SUM(pending_stone+waiting_stone) AS client_pending_stones
						FROM stock.view_appointment_stone_details
						GROUP BY visit_id,section_id
				  ) AS stonedetail ON stonedetail.visit_id = visit.visit_id
		OUTER APPLY (
						SELECT TOP 1 VISIT_DETAIL.VISIT_ID,Stock.VISIT_DETAIL.SECTION_ID,
						CABIN_MASTER.cabin_name,
						SECTION_NAME section_name,
						VISIT.VISIT_DATE,
						Stock.VISIT_DETAIL.SECTION_SLOT_FROM_TIME , 
						Stock.VISIT_DETAIL.SECTION_SLOT_TO_TIME  
						FROM Stock.VISIT_DETAIL
							LEFT JOIN Stock.VISIT ON VISIT.VISIT_ID = VISIT_DETAIL.VISIT_ID
							LEFT JOIN Master.SECTION_MASTER ON SECTION_MASTER.SECTION_ID = VISIT_DETAIL.SECTION_ID
							LEFT JOIN master.CABIN_MASTER ON CABIN_MASTER.CABIN_CODE = SECTION_MASTER.CABIN_CODE
						WHERE Stock.VISIT_DETAIL.VISIT_ID=visit.VISIT_ID AND stonedetail.section_id=Stock.VISIT_DETAIL.SECTION_ID
				  ) AS cabinDetail
		WHERE client_pending_stones>0 AND visit.VISIT_ID=@visit_id

		SELECT *
		FROM stock.view_appointment_stones
		WHERE view_appointment_stones.VISIT_ID=@visit_id
		AND stone_issue_datetime IS NULL
		
END




GO

USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[USP_APPOINTMENT_SAVE]    Script Date: 06/02/2018 2:01:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:  Apexa Patel
-- Create date: 10-01-2018
-- Description: This storage procedure store appoint data
-- =============================================


CREATE PROCEDURE [Stock].[USP_APPOINTMENT_SAVE]
@PARTY_CODE 					INT,
@VISIT_DATE 					DATETIME,
@VISIT_FROM_TIME 				TIME,
@VISIT_TO_TIME 				TIME,
@IS_ACTIVE 					BIT,
@STONEID 						Stock.STONEID READONLY,
@VISIT_CONTACTS_DETAILS 		Stock.VISIT_CONTACTS_DETAILS READONLY,
@SECTION_ID 					SMALLINT,
@REMARK_TEXT 					Stock.REMARK_TEXT READONLY,
@VISIT_CONTACTS_KAM_DETAIL 	Stock.VISIT_CONTACTS_KAM_DETAIL READONLY,
@APPS_CODE 				 	TINYINT,
@USER_CODE 					SMALLINT, -- Code of logged in user who is adding/saving appointment
@CREATED_IPLOCATION_ID 		INT
AS
BEGIN

	DECLARE @IS_AUDIT BIT = 0
	SET @IS_AUDIT = (SELECT Audit.ALLOW_PERF_AUDIT())

	DECLARE @START_TIME DATETIME;
	 

	IF (@IS_AUDIT = 1)
	BEGIN
		SET @START_TIME = Master.Fn_GetISTDATETIME(); 
	END
 	
	DECLARE @VISIT_ID INT, @APPOINTMENT_ID INT = 0
	DECLARE @VISIT_CONTACT_ID INT, @WEEK_START_DATE DATETIME, @WEEK_END_DATE DATETIME
	
	SELECT @WEEK_START_DATE = DATEADD(DAY, 2 - 5, @VISIT_DATE), @WEEK_END_DATE=DATEADD(DAY, 8 - 5, @VISIT_DATE)

	SELECT @APPOINTMENT_ID = ISNULL((SELECT TOP 1 APPOINTMENT_ID FROM Stock.APPOINTMENT WHERE PARTY_CODE = @PARTY_CODE AND CREATED_DATETIME BETWEEN @WEEK_START_DATE AND @WEEK_END_DATE ),0) 

	IF (@APPOINTMENT_ID = 0)
	BEGIN
		SELECT @APPOINTMENT_ID = (ISNULL((SELECT MAX(APPOINTMENT_ID) FROM Stock.APPOINTMENT WHERE PARTY_CODE=@PARTY_CODE),0))+1
		
	INSERT INTO Stock.APPOINTMENT 
	(APPOINTMENT_ID, PARTY_CODE, APPS_CODE, CREATED_BY, CREATED_IPLOCATION_ID, MODIFIED_DATETIME, MODIFIED_BY, MODIFIED_IPLOCATION_ID) 	VALUES 
	(@APPOINTMENT_ID, @PARTY_CODE, @APPS_CODE, @USER_CODE, @CREATED_IPLOCATION_ID, Master.Fn_GetISTDATETIME(), @USER_CODE, @CREATED_IPLOCATION_ID)
	END

	INSERT INTO Stock.VISIT 
	(APPOINTMENT_ID, VISIT_DATE, VISIT_FROM_TIME, VISIT_TO_TIME, IS_ACTIVE, APPS_CODE, CREATED_BY, CREATED_IPLOCATION_ID, MODIFIED_DATETIME, MODIFIED_BY, MODIFIED_IPLOCATION_ID) 
	SELECT @APPOINTMENT_ID, @VISIT_DATE, @VISIT_FROM_TIME, @VISIT_TO_TIME, @IS_ACTIVE, @APPS_CODE, @USER_CODE, @CREATED_IPLOCATION_ID, Master.Fn_GetISTDATETIME(), @USER_CODE, @CREATED_IPLOCATION_ID
	
	SELECT @VISIT_ID = @@IDENTITY 

	INSERT INTO Stock.VISIT_DETAIL 
	(VISIT_ID, STONEID, SECTION_ID, SECTION_SLOT_FROM_TIME, SECTION_SLOT_TO_TIME, APPS_CODE, CREATED_BY, CREATED_IPLOCATION_ID, MODIFIED_DATETIME, MODIFIED_BY, MODIFIED_IPLOCATION_ID) 
	SELECT @VISIT_ID, STONEID, @SECTION_ID, @VISIT_FROM_TIME, @VISIT_TO_TIME, @APPS_CODE, @USER_CODE, @CREATED_IPLOCATION_ID, Master.Fn_GetISTDATETIME(), @USER_CODE, @CREATED_IPLOCATION_ID FROM @STONEID
	
	INSERT INTO Stock.VISIT_CONTACTS 
	(VISIT_ID, PARTY_CONTACTS_CODE, PARTY_ROLE_CODE, CONTACTS_LOCAL_COUNTRY_CODE, CONTACTS_LOCAL_PHONE_NUMBER, APPS_CODE, CREATED_BY, CREATED_IPLOCATION_ID, MODIFIED_DATETIME, MODIFIED_BY, MODIFIED_IPLOCATION_ID) 
	SELECT @VISIT_ID, PARTY_CONTACTS_CODE, PARTY_ROLE_CODE, CONTACTS_LOCAL_COUNTRY_CODE, CONTACTS_LOCAL_PHONE_NUMBER, @APPS_CODE, @USER_CODE, @CREATED_IPLOCATION_ID, Master.Fn_GetISTDATETIME(), @USER_CODE, @CREATED_IPLOCATION_ID FROM @VISIT_CONTACTS_DETAILS


	INSERT INTO Stock.VISIT_CONTACTS_KAM 
	(VISIT_CONTACTS_ID, PARTY_CONTACTS_KAM_CODE, APPS_CODE, CREATED_BY, CREATED_IPLOCATION_ID, MODIFIED_DATETIME, MODIFIED_BY, MODIFIED_IPLOCATION_ID) 
	SELECT vc.VISIT_CONTACTS_ID, vck.PARTY_CONTACTS_KAM_CODE, @APPS_CODE, @USER_CODE, @CREATED_IPLOCATION_ID, Master.Fn_GetISTDATETIME(), @USER_CODE, @CREATED_IPLOCATION_ID FROM @VISIT_CONTACTS_KAM_DETAIL vck LEFT OUTER JOIN Stock.VISIT_CONTACTS vc ON vc.PARTY_CONTACTS_CODE = vck.PARTY_CONTACTS_CODE WHERE vc.VISIT_ID = @VISIT_ID

	INSERT INTO Stock.REMARKS 
	(SOURCE_ID, REMARK_TEXT, REMARK_FROM, REMARK_TYPE_CODE, APPS_CODE, CREATED_BY, CREATED_IPLOCATION_ID, MODIFIED_DATETIME, MODIFIED_BY, MODIFIED_IPLOCATION_ID) 
	SELECT @VISIT_ID, REMARK_TEXT, @USER_CODE, (SELECT REMARK_TYPE_CODE FROM Master.REMARK_TYPE_MASTER WHERE REMARK_TYPE_KEY='appointment_remark'), @APPS_CODE, @USER_CODE, @CREATED_IPLOCATION_ID, Master.Fn_GetISTDATETIME(), @USER_CODE, @CREATED_IPLOCATION_ID FROM @REMARK_TEXT

	IF (@IS_AUDIT = 1)
	BEGIN
		INSERT INTO Audit.SP_PERF_AUDIT ( SP_NAME , START_TIME , END_TIME , EXECUTION_DURATION , APP_CODE )
		SELECT 'Stock.USP_APPOINTMENT_SAVE' , @start_time , Master.Fn_GetISTDATETIME() , Audit.DURATION(@start_time, Master.Fn_GetISTDATETIME()) , '13'; 
	END

END

GO



