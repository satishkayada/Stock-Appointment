USE [srk_db]
GO
/****** Object:  StoredProcedure [Packet].[usp_Inward_InternalStockConfirm_Upsert]    Script Date: 06/02/2018 2:19:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--CREATE TYPE [Stock].[STONEID] AS TABLE(
--	[STONEID] [VARCHAR](16) NULL
--)

Create PROCEDURE [Packet].[usp_Inward_InternalStockConfirm_Upsert]
@stoneid Stock.STONEID readonly,
@process_issue_date DATETIME,
@process_issue_memo_no SMALLINT,
@to_department_code TINYINT,
--@THROUGH VARCHAR(64) = '',
@modified_by SMALLINT,
@modified_iplocation_id INT
AS
BEGIN
	DECLARE @todaydate DATETIME
	SET @todaydate = Master.Fn_GetISTDATETIME()

	Declare @stock_Department TINYINT = 0
	select @stock_Department = Master.getDepartmentCode('STK')

	
	BEGIN TRY
		BEGIN TRANSACTION
		
			Update Mast
			Set Mast.is_process_active = 0
			From Packet.STONE_PROCESSES Mast
			LEFT JOIN @stoneid Stone on Stone.stoneid = Mast.stoneid
			Where Mast.is_process_active = 1 And Stone.stoneid is not null
			And process_issue_date = CONVERT(DATE,@process_issue_date)
			And process_issue_memo_no = @process_issue_memo_no

			Update Process
			Set process_confirm_date = @todaydate, 
				process_confirm_time = CONVERT(DATETIME,CONVERT(VARCHAR,@todaydate,108)),
				is_process_active = (Case When (@to_department_code = @stock_Department /*OR @to_department_code = 15*/) Then 0 Else 1 End),
				--PIC_THROUGH = @THROUGH,
				modified_by = @modified_by,
				modified_iplocation_id = @modified_iplocation_id
			From Packet.STONE_PROCESSES Process
			LEFT JOIN @stoneid Stone on Stone.stoneid = Process.stoneid
			Where Stone.stoneid is not null
			And process_issue_date = CONVERT(DATE,@process_issue_date)
			And process_issue_memo_no = @process_issue_memo_no

			--Update Mast
			--Set Mast.is_process_active = 0	
			--From Packet.STONE_PROCESSES Mast
			--Inner Join (
			--	Select Mast.stoneid, PRC_NO - 1 PRC_NO
			--	From TrnProcessMast WITH(NOLOCK)
			--	Where STONEID In (Select Value From Dbo.Split(@stoneid_list,','))
			--		And PI_DATE = @JAN_DATE
			--		And PINO = @JANNO
			--) As Trn On Mast.STONEID = Trn.STONEID And Mast.PRC_NO = Trn.PRC_NO
			
			-- added by riki for lab turn arround time.
			--if (@PRC_CODE = 4)
			--BEGIN
			--	UPDATE T
			--	Set T.lab_turn_around_datetime = GETDATE(),
			--		T.lab_turn_around_days = TOTDAYS,
			--		USERID = @USERID,
			--		COMPUTERID = @COMPUTERID,
			--		FORMID = @FORMID,
			--		OPEREMARK = 'Lab TAT Update'
			--	FROM Packet.STONE_DETAILS T
			--	LEFT JOIN dbo.TRNLABMAST L ON L.STONEID = T.STONEID AND L.CR_CODE = T.CR_CODE
			--	LEFT JOIN dbo.SIZEMAST S ON L.I_CARAT BETWEEN S.F_SIZE AND S.T_SIZE
			--	LEFT JOIN dbo.LABTATMAST LT ON T.PRS_CODE = LT.BRS_CODE AND S.SZ_CODE = LT.SZ_CODE
			--	Where T.STONEID In (Select Value From Dbo.Split(@stoneid_list,',')) And T.PRS_CODE <> ''
			--	And ISNULL(LT.TOTDAYS,0) <> 0

			--	if EXISTS (SELECT 1 FROM STONEREMINDER WHERE STONEID IN (SELECT Value From Dbo.Split(@stoneid_list,',')))
			--	BEGIN
			--		DELETE FROM STONEREMINDER WHERE STONEID IN (SELECT Value From Dbo.Split(@stoneid_list,','))
			--	END
			--END

			--if (@to_department_code = @stock_Department /*OR @PRC_CODE = 15*/)
			--BEGIN
			--	DECLARE @ISMFG BIT = 0
			--	IF EXISTS (SELECT 1 FROM dbo.TRNPROCESSMAST WHERE STONEID In (Select Value From Dbo.Split(@stoneid_list,',')) AND FPRC_CODE = 6)
			--	BEGIN
			--		SET @ISMFG = 1
			--	END

			--	Update TrnMast
			--	Set PRC_NO = 0, 
			--		PRS_CODE = (CASE WHEN (@ISMFG = 1 AND PRS_CODE <> '' And PRS_CODE NOT IN('DAYP','B2B')) THEN '' ELSE PRS_CODE END),
			--		ISPROCESSACTIVE = 0, 
			--		PRC_CODE = 1,
			--		USERID = @USERID,
			--		COMPUTERID = @COMPUTERID,
			--		FORMID = @FORMID,
			--		OPEREMARK = 'Inw/Conf From' + CONVERT(Varchar(8),@PRC_CODE)
			--	Where STONEID In (Select Value From Dbo.Split(@stoneid_list,','))

			--END
			
			--DECLARE @DEPT_CODE SMALLINT = 0

			--SELECT @DEPT_CODE = DEPT_CODE FROM USERMAST WHERE USERID = @USERID
			
			--IF (@DEPT_CODE <> 0)
			--Begin

			--	UPDATE T
			--	SET PRS_CODE = '', ISPRSREQUESTED = 0,
			--		USERID = @USERID,
			--		COMPUTERID = @COMPUTERID,
			--		FORMID = @FORMID,
			--		OPEREMARK = 'Outward-Process Deleted-AllDel'
			--	FROM TRNMAST T
			--	WHERE STONEID In (Select Value From Dbo.Split(@stoneid_list,',') WHERE Value <> '')
			--	AND EXISTS (SELECT 1 FROM TRNPROCESSDAILY P
			--		WHERE PR_CODE IN (SELECT USERNAME FROM USERMAST WHERE DEPT_CODE = @DEPT_CODE AND @DEPT_CODE <> 0)
			--			AND T.STONEID = P.STONEID
			--			AND (PRS_CODE IN ('GIA','GIAI','IGI','HRD','EGL','AGS','NGTC','FM','RCUT','STD','MATVR','MT','STDVR','MATDIS','DIS','PHTVR','GRAVR'))
			--		)
			--	AND PRC_CODE <> 4
			--	And T.PRS_CODE NOT IN ('DAYP','B2B')

			--	DELETE FROM TDaily
			--	FROM TRNPROCESSDAILY TDaily
			--	LEFT JOIN TRNMAST TMast On TDaily.STONEID = TMast.STONEID
			--	WHERE TDaily.PR_CODE IN (SELECT USERNAME FROM USERMAST WHERE DEPT_CODE = @DEPT_CODE AND @DEPT_CODE <> 0)
			--	AND TMast.STONEID In (Select Value From Dbo.Split(@stoneid_list,',') WHERE Value <> '')
			--	AND (TDaily.PRS_CODE IN ('GIA','GIAI','IGI','HRD','EGL','AGS','NGTC','FM','RCUT','STD','MATVR','MT','STDVR','MATDIS','DIS','PHTVR','GRAVR'))
			--	And TMast.PRS_CODE  NOT IN ('DAYP','B2B')
			--End
			
			--IF EXISTS (SELECT 1 FROM TRNPROCESSDAILY WHERE STONEID In (Select Value From Dbo.Split(@stoneid_list,',') WHERE Value <> '') AND ISNULL(PDEPT_CODE,0) <> 0)
			--Begin
			--	UPDATE T
			--	SET PRS_CODE = '', ISPRSREQUESTED = 0,
			--		USERID = @USERID,
			--		COMPUTERID = @COMPUTERID,
			--		FORMID = @FORMID,
			--		OPEREMARK = 'Outward-Process Deleted-DeptDel'
			--	FROM TRNMAST T
			--	WHERE STONEID In (Select Value From Dbo.Split(@stoneid_list,',') WHERE Value <> '')
			--	AND EXISTS (SELECT 1 FROM TRNPROCESSDAILY D WHERE D.STONEID = T.STONEID AND PDEPT_CODE <> 0 AND PRS_CODE IN ('STDVR','PHTVR','MATVR','GRAVR'))
			--	AND PRC_CODE <> 4
			--	And T.PRS_CODE  NOT IN ('DAYP','B2B')
			--	--AND EXISTS (SELECT 1 FROM TRNPROCESSDAILY D WHERE D.STONEID = T.STONEID AND PDEPT_CODE <> 0)
			--	--AND PRS_CODE IN ('STDVR','PHTVR','MATVR')

			--	DELETE FROM TDaily
			--	FROM TRNPROCESSDAILY TDaily
			--	LEFT JOIN TRNMAST TMast On TDaily.STONEID = TMast.STONEID
			--	WHERE ISNULL(PDEPT_CODE,0) <> 0 AND ISNULL(PDEPT_CODE,0) = @PRC_CODE
			--	AND TMast.STONEID In (Select Value From Dbo.Split(@stoneid_list,',') WHERE Value <> '')
			--	And TMast.PRS_CODE NOT IN ('DAYP','B2B')
			--END

		COMMIT TRANSACTION
	End Try
	Begin Catch
		ROLLBACK TRANSACTION
		Execute [dbo].[uspLogError];
		
		Declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT 
		Select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()    
		Raiserror ( @ErrorMessage, @ErrorSeverity, 1 ) 
		
	End Catch
END