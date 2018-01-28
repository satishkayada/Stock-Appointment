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
@stoneId stock.STONEID READONLY,
@Status_Code TINYINT,
@stone_Id AS VARCHAR(16)='',
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
	--------- Validation for Single Packet
	IF @stone_Id !=''
	BEGIN
		IF EXISTS(
						SELECT 1
						FROM Stock.VISIT_DETAIL
						WHERE VISIT_ID=@visit_id AND STONEID=@stone_Id
						AND STONE_ISSUE_DATETIME IS NOT NULL
				 )
				BEGIN
					SET @msg='Process Issue Done so you can not change status of this Stone.'
					RAISERROR(@msg,18,1);
					RETURN;
				END
	END
	ELSE
    BEGIN
	--------- Validation for Multiple Packet
				SELECT TOP 1 @tmpstone_Id=STONEID
				FROM Stock.VISIT_DETAIL
				WHERE VISIT_ID=@visit_id AND STONEID IN (SELECT StoneId FROM @stoneId)
				AND STONE_ISSUE_DATETIME IS NOT NULL
				IF LEN(@tmpstone_Id)>0
				BEGIN
					SET @msg= 'Process Issue Done for ' +@stone_Id+ ' Stone so you can not change status of this Stone.'
					RAISERROR(@msg,18,1);
					RETURN;
				END
    END
    
    IF @stone_Id !=''
	BEGIN
		UPDATE Stock.VISIT_DETAIL
		SET  
		CHECK_SCAN_STATUS=@Status_Code,
		IS_SCAN_BY_RFID=CASE WHEN(@Status_Code=1) THEN 1 ELSE IS_SCAN_BY_RFID END
		WHERE VISIT_ID=@visit_id AND  STONEID =@stone_Id
	End
	ELSE
	BEGIN
		UPDATE Stock.VISIT_DETAIL
		SET  
		CHECK_SCAN_STATUS=@Status_Code,
		IS_SCAN_BY_RFID=CASE WHEN(@Status_Code=1) THEN 1 ELSE IS_SCAN_BY_RFID END
		WHERE VISIT_ID=@visit_id AND STONEID IN (SELECT STONEID FROM @stoneId)
    End
END