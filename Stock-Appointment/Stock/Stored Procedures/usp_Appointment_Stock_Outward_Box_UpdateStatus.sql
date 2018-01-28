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
@Visit_Id_stoneId stock.VISIT_ID_STONEID READONLY,
@Status_Code TINYINT,
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
				FROM @Visit_Id_stoneId
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
		FROM @Visit_Id_stoneId VISIT_ID_STONEID
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
	FROM @Visit_Id_stoneId VISIT_ID_STONEID
		JOIN Stock.VISIT_DETAIL ON VISIT_DETAIL.STONEID = VISIT_ID_STONEID.STONEID AND VISIT_DETAIL.VISIT_ID = VISIT_ID_STONEID.VISIT_ID
	WHERE VISIT_DETAIL.VISIT_ID IS NOT null
END