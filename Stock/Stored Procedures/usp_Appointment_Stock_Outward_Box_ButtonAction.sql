﻿USE [srk_db]
GO
/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_Box_ButtonAction]    Script Date: 05/02/2018 12:53:48 PM ******/
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
ALTER PROC [Stock].[usp_Appointment_Stock_Outward_Box_ButtonAction]
@Visit_id_stoneId stock.VISIT_ID_STONEID READONLY,
@action_name AS VARCHAR(30),

@apps_code TINYINT=0,

@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS 
BEGIN
	DECLARE @msg AS VARCHAR(256)
	DECLARE @stone_Id AS VARCHAR(16)

	DECLARE @TMPVISIT_ID AS INT,@TMPSTONEID AS BIGINT
	SELECT 	@TMPVISIT_ID=VISIT_ID_STONEID.VISIT_ID,
			@TMPSTONEID=VISIT_ID_STONEID.stoneid
	FROM @visit_id_stoneId visit_id_stoneId
		LEFT JOIN Stock.VISIT_DETAIL ON VISIT_DETAIL.VISIT_ID = VISIT_ID_STONEID.VISIT_ID AND VISIT_DETAIL.stoneid= VISIT_ID_STONEID.stoneid
	WHERE VISIT_DETAIL.VISIT_ID IS NULL
	IF @TMPVISIT_ID>0 OR @TMPSTONEID>0 
	BEGIN
		SET @msg='Stone Id ' + CAST(@TMPSTONEID AS VARCHAR(30)) +' and Visit Id ' + CAST(@TMPVISIT_ID AS VARCHAR(30)) + ' is invalid'
		RAISERROR(@msg,18,1);
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
