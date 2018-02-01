USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_Box_UpdateStatus]    Script Date: 30/01/2018 12:44:46 PM ******/
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

Alter PROC [Stock].[usp_Appointment_Stock_Inward_To_outward_Box_UpdateStatus]
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

