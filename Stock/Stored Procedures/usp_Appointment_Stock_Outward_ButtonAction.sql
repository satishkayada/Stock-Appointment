USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_ButtonAction]    Script Date: 30/01/2018 12:55:11 PM ******/
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

Alter PROC [Stock].[usp_Appointment_Stock_Outward_ButtonAction]
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

