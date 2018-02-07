USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[usp_Issue_Memo_Delete]    Script Date: 06/02/2018 2:23:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [Stock].[usp_Issue_Memo_Delete]
@memo_date DATETIME,
@memo_no SMALLINT,
@department_code TINYINT,
@stoneidlist Stock.STONEID READONLY
AS
BEGIN


		DECLARE @tab TABLE(stoneid VARCHAR(10), prc_no SMALLINT, detid SMALLINT)
		
		INSERT INTO @Tab (STONEID)
		SELECT Prc.stoneid
		FROM Packet.STONE_PROCESSES Prc
		LEFT JOIN @stoneidlist stone ON stone.stoneid = Prc.stoneid
		WHERE Prc.process_issue_date = @memo_date 
			AND Prc.process_issue_memo_no = @memo_no 
			AND Prc.from_department_code =@department_code
			AND stone.stoneid = Prc.stoneid
			--AND (@STONEIDLIST = '' OR stoneid IN (SELECT Value FROM dbo.Split(@stoneidlist,',')))

		DELETE
		FROM STONE_PROCESSES
		WHERE process_issue_date = @memo_date AND process_issue_memo_no = @memo_no AND from_department_code = @department_code
			AND stoneid IN (SELECT stoneid FROM @stoneidlist)
			--AND (@STONEIDLIST = '' OR stoneid IN (SELECT Value FROM dbo.Split(@stoneidlist,',')))
		

		--UPDATE Trn
		--SET NPRC_CODE = 0, 
		--	NPI_THROUGH = '', 
		--	LABCODE = '',
		--	NPI_DATE = NULL,
		--	NPI_TIME = NULL,
		--	NPINO = 0,
		--	NPI_USERID = 0,
		--	NPI_COMPUTERID = 0,
		--	NPI_FORMID = 0,
		--	OUTJAN_SRNO = 0
		--FROM Packet.STONE_PROCESSES Trn
		--INNER JOIN @TAB UMast On Trn.stoneid = UMast.stoneid
		
		UPDATE Packet.STONE_DETAILS
		SET 
			process_code = @department_code,
			--is_process_active = CASE WHEN (@department_code = 1) THEN 0 ELSE 1 END,
			external_process_code = CASE WHEN (process_code = 15) THEN '' ELSE external_process_code END,
			memo_date = CASE WHEN (process_code = 15) THEN NULL ELSE memo_date END,
			memo_no = CASE WHEN(process_code = 15) THEN 0 ELSE memo_no END,
			--PIJ_DATE = NULL,
			--PIJANNO = 0,
			internal_process_code = CASE WHEN(process_code = 6 OR process_code = 4) THEN '' WHEN (process_code = 2 AND internal_process_code = 'GRAREP') THEN '' ELSE internal_process_code END,
			modified_datetime = GETDATE(),
			operation_remark = 'Process Delete'
		WHERE stoneid IN (SELECT stoneid FROM @Tab)
END

GO


