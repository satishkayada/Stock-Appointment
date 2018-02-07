USE [srk_db]
GO


/****** Object:  StoredProcedure [dbo].[usp_Outward_InternalStockReceiveDelete_Upsert]    Script Date: 06/02/2018 2:22:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Outward_InternalStockReceiveDelete_Upsert]
@process_issue_date DATETIME,
@process_issue_memo_no SMALLINT,
@department_code SMALLINT,
@stoneid_list AS Stock.STONEID READONLY,

@modified_by SMALLINT,
@modified_iplocation_id int
AS
BEGIN
	BEGIN TRY
	
		--Declare @Tab Table(STONEID Varchar(10), PRC_NO Smallint, DETID Smallint)
		
		--Insert Into @Tab (STONEID, PRC_NO, DETID)
		--Select STONEID, PRC_NO, DETID
		--From Packet.STONE_PROCESSES Prc
		--Where PI_DATE = @process_issue_date AND PINO = @process_issue_memo_no AND FPRC_CODE = @department_code
		--	AND (@stoneid_list = '' OR STONEID IN (SELECT Value FROM dbo.Split(@stoneid_list,',')))

		DELETE
		FROM Packet.STONE_PROCESSES
		WHERE process_issue_date = @process_issue_date AND process_issue_memo_no = @process_issue_memo_no AND from_department_code = @department_code
			--AND (STONEID IN (SELECT Value FROM dbo.Split(@stoneid_list,',')))
			AND stoneid IN(SELECT stoneid FROM @stoneid_list)


		--UPDATE Trn
		--SET 
			--NPRC_CODE = 0, 
			--NPI_THROUGH = '', 
			--LABCODE = '',
			--NPI_DATE = NULL,
			--NPI_TIME = NULL,
			--NPINO = 0,
			--NPI_USERID = 0,
			--NPI_COMPUTERID = 0,
			--NPI_FORMID = 0,
			--OUTJAN_SRNO = 0
		--FROM TRNPROCESSMAST Trn
		--INNER JOIN @TAB UMast On Trn.STONEID = UMast.STONEID AND Trn.PRC_NO = UMast.PRC_NO - 1 AND Trn.DETID = UMast.DETID
		
		Declare @Tab Table(stoneid Varchar(16), process_id BIGINT)
		
		Insert Into @Tab (stoneid, process_id)
		Select Prc.stoneid, MAX(Prc.process_id) process_id
		From Packet.STONE_PROCESSES Prc
		LEFT JOIN @stoneid_list stone ON stone.stoneid = Prc.stoneid
		Where Prc.process_issue_date = @process_issue_date AND Prc.process_issue_memo_no = @process_issue_memo_no AND Prc.from_department_code = @department_code
			--AND (STONEID IN (SELECT Value FROM dbo.Split(@stoneid_list,',')))
			AND stone.stoneid = Prc.stoneid
		Group by Prc.stoneid

		UPDATE Trn
		SET Trn.internal_process_id = UMast.process_id,
			Trn.department_code = @department_code,
			--Trn.ISPROCESSACTIVE = CASE WHEN (@department_code = 1) THEN 0 ELSE 1 END,
			--Trn.external_process_code = CASE WHEN (department_code = 15) THEN '' ELSE BRS_CODE END,
			--Trn.J_DATE = CASE WHEN (PRC_CODE = 15) THEN NULL ELSE J_DATE END,
			--Trn.JANNO = CASE WHEN(PRC_CODE = 15) THEN 0 ELSE JANNO END,
			--Trn.PIJ_DATE = NULL,
			--Trn.PIJANNO = 0,
			--Trn.PRS_CODE = CASE WHEN(PRC_CODE = 6 OR PRC_CODE = 4) THEN '' WHEN (PRC_CODE = 2 AND PRS_CODE = 'GRAREP') THEN '' ELSE PRS_CODE END,
			Trn.modified_by = @modified_by,
			Trn.modified_datetime = Master.Fn_GetISTDATETIME(),
			Trn.modified_iplocation_id = @modified_iplocation_id,
			Trn.operation_remark = 'PrcDelete'
		FROM Packet.STONE_DETAILS Trn
		LEFT JOIN @Tab UMast on UMast.stoneid = Trn.stoneid
		where UMast.stoneid IS NOT NULL


		--UPDATE Packet.STONE_DETAILS
		--SET process_code = PRC_NO - 1,
		--	PRC_CODE = @department_code,
		--	ISPROCESSACTIVE = CASE WHEN (@department_code = 1) THEN 0 ELSE 1 END,
		--	BRS_CODE = CASE WHEN (PRC_CODE = 15) THEN '' ELSE BRS_CODE END,
		--	J_DATE = CASE WHEN (PRC_CODE = 15) THEN NULL ELSE J_DATE END,
		--	JANNO = CASE WHEN(PRC_CODE = 15) THEN 0 ELSE JANNO END,
		--	PIJ_DATE = NULL,
		--	PIJANNO = 0,
		--	PRS_CODE = CASE WHEN(PRC_CODE = 6 OR PRC_CODE = 4) THEN '' WHEN (PRC_CODE = 2 AND PRS_CODE = 'GRAREP') THEN '' ELSE PRS_CODE END,
		--	MODIFYDATETIME = GETDATE(),
		--	USERID = @USERID,
		--	COMPUTERID = @COMPUTERID,
		--	FORMID = @FORMID,
		--	OPEREMARK = 'PrcDelete'
		--WHERE STONEID IN (SELECT STONEID FROM @Tab)
	End Try
	Begin Catch
	
		Execute [dbo].[uspLogError];
		
		Declare @ErrorMessage nvarchar(4000), @ErrorSeverity int 
		Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()    
		Raiserror ( @ErrorMessage, @ErrorSeverity, 1 ) 
		
	End Catch
END

GO

/****** Object:  StoredProcedure [Stock].[usp_Outward_StoneDetails_List]    Script Date: 06/02/2018 2:22:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [Stock].[usp_Outward_StoneDetails_List]
@rfid_tag Stock.RFID_TAG READONLY,
@stoneid Stock.STONEID READONLY,
@department_code TINYINT
AS
BEGIN
	IF EXISTS(SELECT 1 FROM @rfid_tag)
	BEGIN
		SELECT tmast.stoneid, UserMast.user_short_name, tmast.rfid_tag, t.issue_carat, c.certificate_short_name, s.shape_short_name,
			1 is_select, '' errordet,q.clarity_short_name, col.color_short_name
		FROM Packet.STONE_DETAILS TMast
			LEFT JOIN Packet.STONE_LAB_DETAILS T ON TMast.STONEID = T.STONEID AND TMast.CERTIFICATE_CODE = T.CERTIFICATE_CODE
			LEFT JOIN Master.CERTIFICATE_MASTER C ON C.CERTIFICATE_CODE = T.CERTIFICATE_CODE
			LEFT JOIN Master.SHAPE_MASTER S ON S.shape_code = T.SHAPE_CODE
			LEFT JOIN Master.CLARITY_MASTER Q ON Q.clarity_code = T.LAB_CLARITY_CODE
			LEFT JOIN Master.COLOR_MASTER Col ON Col.color_code = T.LAB_COLOR_CODE
			LEFT JOIN Master.ORIGINAL_SIZE_MASTER Size ON T.ISSUE_CARAT BETWEEN Size.from_size AND Size.to_size
			LEFT JOIN Master.USER_MASTER UserMast ON UserMast.user_code = TMast.user_code
			LEFT JOIN @rfid_tag r ON r.rfid_tag = TMast.rfid_tag
		WHERE TMast.process_code = @department_code
			--AND TMast.RFID_TAG IN (Select Value From Dbo.Split_XML(@rfid_tag,','))
			AND TMast.rfid_tag = r.rfid_tag
		ORDER BY S.display_order, Size.size_code DESC, Q.display_order, Col.display_order, T.ISSUE_CARAT,T.STONEID
	END
	ELSE
	BEGIN
		SELECT tmast.stoneid, UserMast.user_short_name, tmast.rfid_tag, t.issue_carat, c.certificate_short_name, s.shape_short_name, 
			1 is_select, '' errordet, q.clarity_short_name, col.color_short_name
		FROM Packet.STONE_DETAILS TMast
			LEFT JOIN Packet.STONE_LAB_DETAILS T ON TMast.STONEID = T.STONEID AND TMast.CERTIFICATE_CODE = T.CERTIFICATE_CODE
			LEFT JOIN Master.CERTIFICATE_MASTER C ON C.CERTIFICATE_CODE = T.CERTIFICATE_CODE
			LEFT JOIN Master.SHAPE_MASTER S ON S.shape_code = T.SHAPE_CODE
			LEFT JOIN Master.CLARITY_MASTER Q ON Q.clarity_code = T.LAB_CLARITY_CODE
			LEFT JOIN Master.COLOR_MASTER Col ON Col.color_code = T.LAB_COLOR_CODE
			LEFT JOIN Master.ORIGINAL_SIZE_MASTER Size ON T.ISSUE_CARAT BETWEEN from_size AND to_size
			LEFT JOIN Master.USER_MASTER UserMast ON UserMast.user_code = TMast.user_code
			LEFT JOIN @stoneid stone ON stone.stoneid = TMast.stoneid
		WHERE TMast.process_code = @department_code 
			--AND (
			--		(TMast.STONEID IN (SELECT Value FROM Dbo.Split_XML(@stoneid,',')))
			--		OR
			--		(TMast.RFID_TAG IN (SELECT Value FROM Dbo.Split_XML(@stoneid,',')))
			--	)
			AND stone.stoneid = TMast.stoneid
		ORDER BY S.display_order, Size.size_code DESC, Q.display_order, Col.display_order, ISSUE_CARAT,T.STONEID
	END
END

GO


