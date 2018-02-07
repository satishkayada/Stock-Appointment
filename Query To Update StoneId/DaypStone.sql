--Done

USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[usp_DaypStone_TakeOut_AddStone_Insert]    Script Date: 06/02/2018 2:07:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON

GO

ALTER PROCEDURE [Stock].[usp_DaypStone_TakeOut_AddStone_Insert]
@stoneid Stock.STONEID READONLY,

@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS
BEGIN

	DECLARE @today DATETIME = Master.Fn_GetISTDATETIME();
	
	MERGE INTO Stock.STONE_DAYP_CONFIRM_TAKEOUT AS Dest
	USING(
		SELECT trn.stoneid
		FROM Packet.STONE_DETAILS trn
		LEFT JOIN @stoneid STN ON STN.stoneid = trn.stoneid
		WHERE trn.stoneid = STN.stoneid
	)AS sou ON Dest.stoneid = sou.stoneid
	WHEN NOT MATCHED THEN 
		INSERT (stoneid,modified_datetime,modified_by,modified_iplocation_id)
		VALUES (sou.stoneid,@today,@modified_by,@modified_iplocation_id);

END

GO

/****** Object:  StoredProcedure [Stock].[usp_DaypStone_TakeOut_Stone_Upsert]    Script Date: 06/02/2018 2:07:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [Stock].[usp_DaypStone_TakeOut_Stone_Upsert]
@stoneid Stock.STONEID READONLY,
@is_rfid BIT = 0,
@is_barcode BIT = 0,
@is_certi BIT = 0,

@modified_by SMALLINT=0,
@modified_iplocation_id INT=0
AS
BEGIN	

	DECLARE @today DATETIME = Master.Fn_GetISTDATETIME();
	
    MERGE INTO Stock.STONE_DAYP_CONFIRM_TAKEOUT AS Dest
	USING(
		SELECT trn.stoneid
		FROM Packet.STONE_DETAILS trn
		LEFT JOIN @stoneid STN ON STN.stoneid = trn.stoneid
		WHERE trn.stoneid = STN.stoneid
	)AS sou ON Dest.stoneid = sou.stoneid
	WHEN MATCHED THEN
    UPDATE SET
		Dest.barcode_datetime = CASE WHEN @is_barcode = 1 THEN @today ELSE NULL END ,
		Dest.rfid_datetime = CASE WHEN @is_rfid = 1 THEN @today ELSE NULL END ,
		Dest.certificate_datetime = CASE WHEN @is_certi = 1 THEN @today ELSE NULL END ,

		MODIFIED_DATETIME=Master.Fn_GetISTDATETIME(),
		MODIFIED_BY=@modified_by,
		MODIFIED_IPLOCATION_ID=@modified_iplocation_id

	WHEN NOT MATCHED THEN 
		INSERT (stoneid,barcode_datetime,rfid_datetime,certificate_datetime,modified_datetime,modified_by,modified_iplocation_id)
		VALUES (sou.stoneid,CASE WHEN @is_barcode = 1 THEN @today ELSE NULL END,CASE WHEN @is_rfid = 1 THEN @today ELSE NULL END,
				CASE WHEN @is_certi = 1 THEN @today ELSE NULL END,@today,@modified_by,@modified_iplocation_id);

END	

GO

/****** Object:  StoredProcedure [Stock].[usp_DaypStone_TakeOutDetails_Delete]    Script Date: 06/02/2018 2:07:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [Stock].[usp_DaypStone_TakeOutDetails_Delete]
@STONEID Stock.STONEID READONLY
AS
BEGIN
	DELETE FROM Stock.STONE_DAYP_CONFIRM_TAKEOUT
	WHERE stoneid IN (SELECT stoneid FROM @STONEID)
END

GO

/****** Object:  StoredProcedure [Stock].[usp_DaypStone_TakeOutDetails_List]    Script Date: 06/02/2018 2:07:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [Stock].[usp_DaypStone_TakeOutDetails_List]
AS	
BEGIN
	SELECT 'STOCK' party_name,
		trn.box_rfid, 
		cnfrm.stoneid,shape_name, clarity_name, color_name, 
		lab.issue_carat, certificate_name, 
		'' cabin_name, DeptMast.department_name
	FROM Stock.STONE_DAYP_CONFIRM_TAKEOUT AS cnfrm
	LEFT JOIN Packet.STONE_DETAILS trn ON trn.stoneid = cnfrm.stoneid
	LEFT JOIN Packet.STONE_LAB_DETAILS lab ON lab.certificate_code = trn.certificate_code AND lab.stoneid = trn.stoneid
	LEFT JOIN Packet.STONE_LAB_DESCRIPTION LDes ON LDes.stoneid = cnfrm.stoneid AND LDes.certificate_code = trn.certificate_code
	--LEFT JOIN Master.SHAPE_MASTER Shp on Shp.shape_code = lab.shape_code
	--LEFT JOIN Master.CLARITY_MASTER Cla on Cla.clarity_code = lab.lab_clarity_code
	--LEFT JOIN Master.COLOR_MASTER Col on Col.color_code = lab.lab_color_code
	--LEFT JOIN Master.CERTIFICATE_MASTER CertMast on CertMast.certificate_code = lab.certificate_code
	LEFT JOIN Master.DEPARTMENT_MASTER DeptMast ON DeptMast.department_code = trn.department_code
	WHERE trn.is_dayp_stone_takeout = 1
		AND trn.stoneid = cnfrm.stoneid
		AND dayp_stone_takeout_datetime IS NOT NULL
		AND trn.internal_process_code = Master.getinternal_process_code('DAYP')
END

GO


