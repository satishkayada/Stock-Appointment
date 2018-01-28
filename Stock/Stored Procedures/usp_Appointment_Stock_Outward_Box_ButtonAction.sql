﻿-- =============================================
-- Author:		Satish Kayada
-- Create date: 24/01/2018
-- Description:	Use to Work on Button 

--CREATE TYPE [Stock].[STONEID] AS TABLE(
--	[STONEID] [VARCHAR](16) NULL
--)

-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_Box_ButtonAction]
@visit_id INT,
@Visit_Id_stoneId stock.VISIT_ID_STONEID READONLY,
@ButtonName AS VARCHAR(30),

@apps_code TINYINT=0,

@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS 
BEGIN
	DECLARE @msg AS VARCHAR(256)
	DECLARE @stone_Id AS VARCHAR(16)

	IF @ButtonName='removestones'
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
	IF @ButtonName='sendtobuyer'
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
		SET PACKET.STONE_DETAILS.SECTION_ID=Stock.VISIT_DETAIL.SECTION_ID,
		MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
		MODIFIED_BY=@modified_by,
		MODIFIED_IPLOCATION_ID=@modified_iplocation_id
		FROM PACKET.STONE_DETAILS
			JOIN @Visit_Id_stoneId Visit_Id_stoneId ON Visit_Id_stoneId.STONEID = STONE_DETAILS.stoneid 
			JOIN Stock.VISIT_DETAIL ON Visit_Id_stoneId.VISIT_ID=Stock.VISIT_DETAIL.VISIT_ID AND Visit_Id_stoneId.STONEID=Stock.VISIT_DETAIL.STONEID
		WHERE 1=1
    End
End