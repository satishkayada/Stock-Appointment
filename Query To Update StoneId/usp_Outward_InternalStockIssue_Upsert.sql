USE [srk_db]
GO


/****** Object:  StoredProcedure [Packet].[usp_Outward_InternalStockIssue_Upsert]    Script Date: 06/02/2018 2:27:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Packet].[usp_Outward_InternalStockIssue_Upsert]
@stoneid Stock.STONEID_WITH_ORDER READONLY,
@from_department_code TINYINT,
@to_department_code TINYINT,
@process_issue_date DATE,
@process_issue_memo_no SMALLINT,
@remark VARCHAR(512) = '',
@stone_process_code TINYINT = '',
@updated_by SMALLINT,
@updated_iplocation_id SMALLINT,
@viewrequest_id BIGINT = 0,
@modified_by SMALLINT, 
@modified_iplocation_id INT
AS
BEGIN		
	
	Declare @stock_Department TINYINT = 0
	select @stock_Department = Master.getDepartmentCode('STK')

	BEGIN TRY
		BEGIN TRANSACTION
			--Declare @Tab Table(stoneid Varchar(16), process_id Smallint, outward_serial_id SMALLINT primary key (stoneid))

			--Insert Into @Tab (stoneid, process_id, outward_serial_id)
			--Select Mast.STONEID, ISNULL(MAX(Prc.process_id),0) process_id, outward_serial_id
			--From Packet.STONE_DETAILS Mast
			--Left Join Packet.STONE_PROCESSES Prc On Mast.stoneid = Prc.stoneid
			--LEFT JOIN (Select value stoneid, id outward_serial_id From Dbo.Split(@stoneid_list,',')) T ON T.stoneid = Mast.stoneid
			----Where Mast.STONEID IN (Select Value From Dbo.Split(@stoneid_list,','))
			--WHERE T.stoneid IS NOT NULL
			--Group By Mast.stoneid, T.outward_serial_id

			--Update TMast
			--Set NPRC_CODE = @TPRC_CODE,
			--	NPI_THROUGH = @THROUGH,
			--	NPI_DATE = @J_DATE,
			--	NPI_TIME = GETDATE(),
			--	NPINO = @JANNO,
			--	NPI_USERID = @USERID,
			--	NPI_COMPUTERID = @COMPUTERID,
			--	NPI_FORMID = @FORMID,
			--	OUTJAN_SRNO = OJ_SRNO
			--From TrnProcessMast TMast
			--Inner Join @Tab UMast On TMast.STONEID = UMast.STONEID And TMast.PRC_NO = UMast.PRC_NO And TMast.DETID = UMast.DETID

			--INSERT INTO TrnProcessMast (STONEID,PRC_NO,DETID,FPRC_CODE,PRC_CODE,PI_THROUGH,LABCODE,PI_DATE,PI_TIME,PINO,PI_USERID,PI_COMPUTERID,PI_FORMID, REMARK,GRDPRS_CODE, OUTJAN_SRNO)
			--Select STONEID, PRC_NO + 1 PRC_NO,DETID,@FPRC_CODE FPRC_CODE,@TPRC_CODE PRC_CODE,@THROUGH,@LABCODE,@J_DATE J_DATE,
			--	GETDATE() J_TIME, @JANNO JANNO, @USERID USERID, @COMPUTERID COMPUTERID, @FORMID FORMID, @REMARK REMARK, @GRDPRS_CODE, OJ_SRNO
			--From @Tab
			SELECT stoneid, stoneresult
			From (
				SELECT Stone.stoneid, ISNULL((Select [Packet].[usp_fn_outward_InternalStockConfirm](Stone.stoneid, MAX(StoneProcess.process_id), @from_department_code, @to_department_code)),'') stoneresult
				From @stoneid Stone
				LEFT JOIN Packet.STONE_PROCESSES StoneProcess on StoneProcess.stoneid = Stone.stoneid
				where Stone.stoneid is not null and StoneProcess.stoneid is not null
				Group by Stone.stoneid
			) As outResult
			where stoneresult <> ''

			if @@ROWCOUNT > 0
			BEGIN
			    return;
			END

			insert into Packet.STONE_PROCESSES ( stoneid, from_department_code, to_department_code, process_issue_date, process_issue_time, process_issue_memo_no, 
				remark, viewrequest_id, stone_process_code, process_issue_user_code, process_issue_iplocation_id, created_by, created_iplocation_id, outward_serial_id )
			Select Stone.stoneid, @from_department_code, @to_department_code, @process_issue_date, Master.Fn_GetISTDATETIME(), @process_issue_memo_no,
				@remark, @viewrequest_id, @stone_process_code, @modified_by, @modified_iplocation_id, @modified_by, @modified_iplocation_id, Stone.serial_number outward_serial_id
			From @stoneid Stone
			LEFT JOIN Packet.STONE_DETAILS StoneDet on StoneDet.stoneid = Stone.stoneid
			where Stone.stoneid is not null and StoneDet.stoneid is not null

			Declare @prcDetails table (stoneid VARCHAR(16), internal_process_id bigint)
			SELECT Stone.stoneid, MAX(StoneProcess.process_id) internal_process_id
			From @stoneid Stone
			LEFT JOIN Packet.STONE_PROCESSES StoneProcess on StoneProcess.stoneid = Stone.stoneid
			where Stone.stoneid is not null and StoneProcess.stoneid is not null
			Group by Stone.stoneid

			Update Mast
			Set Mast.internal_process_id = UMast.internal_process_id,
				--ISPROCESSACTIVE = 1,
				Mast.process_code = @to_department_code,
				Mast.box_rfid = null,
				Mast.modified_by = @modified_by,
				Mast.modified_iplocation_id = @modified_iplocation_id,
				Mast.modified_datetime = Master.Fn_GetISTDATETIME(),
				Mast.operation_remark = 'Outward To ' + CONVERT(Varchar(8),@to_department_code)				
			From Packet.STONE_DETAILS Mast
			INNER JOIN @prcDetails UMast On Mast.STONEID = UMast.STONEID

			--Mast.BRS_CODE = 
								
				--					 CASE WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 1 And BRS_CODE = 'RFL' AND @GRDPRS_CODE = '') THEN 
								
				--																					(CASE WHEN (ISNULL(P_CODE,'') = '') THEN 'PRFS' ELSE '' END)
				--						WHEN (@FPRC_CODE = 2 AND @TPRC_CODE = 15) THEN 'PRFS'
				--						WHEN(@FPRC_CODE = 2 And @TPRC_CODE = 1 AND @GRDPRS_CODE <> '' AND ISNULL(P_CODE,'')= '') THEN ''
				--						WHEN(@FPRC_CODE = 2 And @TPRC_CODE = 3 AND @GRDPRS_CODE = 'MATDIS') THEN @GRDPRS_CODE
				--						WHEN(@FPRC_CODE = 2 AND @TPRC_CODE = 4 AND BRS_CODE IN ('RFL','PRFS','RFS','BLS','RMS','PMS')) THEN ''
				--						ELSE Mast.BRS_CODE END,
								
								
				----Mast.PRS_CODE = CASE WHEN (@TPRC_CODE = 4 AND (Mast.PRS_CODE = @LABCODE OR ISNULL(Mast.PRS_CODE,'') = '')) THEN @LABCODE 
				--Mast.PRS_CODE = CASE WHEN (@TPRC_CODE = 4) THEN @LABCODE 
				--					 WHEN (@FPRC_CODE = 4 AND @TPRC_CODE = 2) THEN ''
				--					 WHEN (@TPRC_CODE = 6) THEN @PRS_CODE
				--					 WHEN (@FPRC_CODE = 1 AND @TPRC_CODE = 2 AND PRS_CODE = 'NEW') THEN ''
				--					 WHEN(@FPRC_CODE = 2 AND @TPRC_CODE = 1 AND @GRDPRS_CODE <> ''  AND ISNULL(P_CODE,'')= '') THEN @GRDPRS_CODE
				--					 WHEN(@FPRC_CODE = 2 AND @TPRC_CODE = 3 AND @GRDPRS_CODE = 'MATDIS') THEN ''

				--					 ---------------------- Added by KETAN ----------------------------------
				--					 WHEN(@FPRC_CODE = 1 AND @TPRC_CODE = 2 AND @GRDPRS_CODE <> '') THEN  @GRDPRS_CODE
				--					 WHEN(@FPRC_CODE = 2 AND @TPRC_CODE in (1,15,4) AND PRS_CODE = 'GRAREP') THEN ''


				--					 ELSE Mast.PRS_CODE END,
				
				--Mast.J_DATE = CASE WHEN (@TPRC_CODE = 15) THEN (Case WHEN(@J_DATE IS NULL) THen Mast.J_DATE Else @J_DATE END)
				--				   --WHEN (@TPRC_CODE = 4 AND J_DATE IS NULL AND ISNULL(JANNO,0) = 0) THEN @J_DATE
				--				   WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 1 And BRS_CODE = 'RFL' AND ISNULL(P_CODE,'') = '' AND @GRDPRS_CODE = '') THEN @J_DATE
				--				   WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 1 And BRS_CODE = 'RFL' AND ISNULL(P_CODE,'') = '' AND @GRDPRS_CODE <> '') THEN NULL
				--				   -- condtion added of P_Code after discusison . if jangad is in party than dont' release
				--				    WHEN(@FPRC_CODE = 2 AND @TPRC_CODE = 1 AND @GRDPRS_CODE <> '' AND ISNULL(P_CODE,'')= '') THEN NULL
				--				   WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 3 And @GRDPRS_CODE = 'MATDIS') THEN @J_DATE
				--			  ELSE Mast.J_DATE END,
				--Mast.JANNO = CASE WHEN (@TPRC_CODE = 15) THEN (Case WHEN (@JANNO = 0) Then Mast.JANNO Else @JANNO END)
				--				   --WHEN (@TPRC_CODE = 4 AND J_DATE IS NULL AND ISNULL(JANNO,0) = 0) THEN @JANNO
				--				   WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 1 And BRS_CODE = 'RFL' AND ISNULL(P_CODE,'') = '' AND @GRDPRS_CODE = '') THEN @JANNO
				--				   WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 1 And BRS_CODE = 'RFL' AND ISNULL(P_CODE,'') = '' AND @GRDPRS_CODE <> '') THEN 0
				--				    WHEN(@FPRC_CODE = 2 AND @TPRC_CODE = 1 AND @GRDPRS_CODE <> '' AND ISNULL(P_CODE,'')= '') THEN 0
				--				    WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 3 And @GRDPRS_CODE = 'MATDIS') THEN @JANNO
				--			  ELSE Mast.JANNO END,
				

				--Mast.JANENTRYDATETIME = CASE WHEN (@TPRC_CODE = 15) THEN (Case WHEN(@J_DATE IS NULL) THen Mast.JANENTRYDATETIME ELSE GETDATE() END)
								  
				--				   WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 1 And BRS_CODE = 'RFL' AND ISNULL(P_CODE,'') = '' AND @GRDPRS_CODE = '') THEN GETDATE()
				--				   WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 1 And BRS_CODE = 'RFL' AND ISNULL(P_CODE,'') = '' AND @GRDPRS_CODE <> '') THEN NULL
				--				   -- condtion added of P_Code after discusison . if jangad is in party than dont' release
				--				    WHEN(@FPRC_CODE = 2 AND @TPRC_CODE = 1 AND @GRDPRS_CODE <> '' AND ISNULL(P_CODE,'')= '') THEN NULL
				--				   WHEN (@FPRC_CODE = 2 And @TPRC_CODE = 3 And @GRDPRS_CODE = 'MATDIS') THEN GETDATE()
				--			  ELSE Mast.JANENTRYDATETIME END,

				--PIJ_DATE = CASE WHEN (@TPRC_CODE = 4) THEN @J_DATE ELSE PIJ_DATE END,
				--PIJANNO = CASE WHEN (@TPRC_CODE = 4) THEN @JANNO ELSE PIJANNO END,


				--ISEXPORTPACKED =  CASE when(brs_Code IN('SHOW','SHOWAY','SHOWDDC')) then ISEXPORTPACKED ELSE  0 end,
				--ISEXPORTCOMPLETE =CASE when(brs_Code IN('SHOW','SHOWAY','SHOWDDC')) then  ISEXPORTCOMPLETE else 0 end,
				--ISSTONEIDVERIFY = CASE when(brs_Code IN('SHOW','SHOWAY','SHOWDDC')) then ISSTONEIDVERIFY else 0 end,

			IF (@from_department_code = @stock_Department AND @to_department_code <> @stock_Department)
			BEGIN
				if Exists (Select 1 From Packet.VENDOR_STONE_DETAILS Where stoneid IN (Select stoneid From @prcDetails) And ISNULL(is_stock_final,0) = 0)
				Begin
					Update Packet.VENDOR_STONE_DETAILS Set is_stock_final = 1 Where stoneid IN (Select stoneid From @prcDetails) And ISNULL(is_stock_final,0) = 0
				END
				--IF (@to_department_code = 2)
				--BEGIN
				--	IF EXISTS (SELECT 1 FROM Packet.STONE_DETAILS WHERE stoneid IN (SELECT stoneid FROM @prcDetails) AND BC_CODE = 'IVR')
				--	BEGIN
				--		UPDATE TRNMAST
				--		SET BC_CODE = '',
				--			USERID = @USERID,
				--			COMPUTERID = @COMPUTERID,
				--			FORMID = @FORMID,
				--			OPEREMARK = 'Del IVR - Outward To Grading'
				--		WHERE STONEID IN (SELECT STONEID FROM @Tab) AND BC_CODE = 'IVR'
				--		AND STONEID IN (SELECT STONEID FROM View_SalesProcDailyMast WHERE GRPTYPE IN ('1PP1','1PP2'))

				--		--Delete Internal View Request From Process Memo And Main Memo.
				--		UPDATE TRNPROCESSDAILY
				--		SET USERID = @USERID,
				--			COMPUTERID = @COMPUTERID,
				--			FORMID = @FORMID,
				--			OPEREMARK = 'Del IVR - Outward To Grading'
				--		WHERE STONEID IN (SELECT STONEID FROM @Tab) AND BC_CODE = 'IVR'
				--		AND STONEID IN (SELECT STONEID FROM View_SalesProcDailyMast WHERE GRPTYPE IN ('1PP1','1PP2'))

				--		DELETE FROM TRNPROCESSDAILY
				--		WHERE STONEID IN (SELECT STONEID FROM @Tab) AND BC_CODE = 'IVR'
				--		AND STONEID IN (SELECT STONEID FROM View_SalesProcDailyMast WHERE GRPTYPE IN ('1PP1','1PP2'))						
				--	END
				--END
			END

			----- to delete view request like Mat team request for GIAI and stone is goes Stock To grading and grading make outward for lab than process delete of mat team
			--DELETE FROM TMast
			--FROM TRNPROCESSDAILY TMast
			--Inner Join @Tab UMast On TMast.STONEID = UMast.STONEID
			--WHERE ISNULL(PDEPT_CODE,0) <> 0 AND ISNULL(PDEPT_CODE,0) = @TPRC_CODE

			--------For View Request to Stock Department ask ketan/riki for this
			--IF(@FPRC_CODE in (2,3) And @TPRC_CODE IN(1,3) AND @GRDPRS_CODE <> '')
			--BEGIN
			--		DECLARE @PR_CODE VARCHAR(16) = '';
			--		SET @PR_CODE = (SELECT USERNAME FROM USERMAST WHERE USERID = @USERID)

			--		DECLARE @PDEPT_CODE TINYINT =0;
			--		SET @PDEPT_CODE = (SELECT ISNULL(PDEPT_CODE,0) FROM BROKMASTSRK WHERE BRS_CODE = @GRDPRS_CODE)
			--		INSERT INTO TRNPROCESSDAILY
			--		(
			--			STONEID,J_DATE, JANNO, PI_TIME,J_WEEK,P_CODE, BR_CODE,BUY_CODE, PR_CODE,BRS_CODE, 
			--			PRS_CODE,T_CODE,JRATE, JPER, FRATE, FPER, THROUGH, JANSTATUS, 
			--			JANREMARK,JANNOTE,JANSTYPE,
			--			USERID,FORMID,COMPUTERID,ENTRYDATETIME,OPEREMARK,PDEPT_CODE
			--		)
			--		SELECT     
			--			T.STONEID,GETDATE(),@PRCJANNO,CONVERT(TIME,GETDATE()),J_WEEK,P_CODE,BR_CODE,BUY_CODE,@PR_CODE,BRS_CODE,
			--			@GRDPRS_CODE,T_CODE,JRATE,JPER,FRATE,FPER,THROUGH,JANSTATUS,
			--			JANREMARK,JANNOTE,JANSTYPE,
			--			@USERID,@FORMID,@COMPUTERID,GETDATE(),'GrdViewRequest',@PDEPT_CODE
			--		FROM    TRNMAST T
			--		WHERE 1=1
			--			AND STONEID IN(SELECT Value FROM Split(@stoneid_list,','))
			--END
            
		COMMIT TRANSACTION
	
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		EXECUTE [dbo].[uspLogError];
		
		DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT 
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY()    
		RAISERROR ( @ErrorMessage, @ErrorSeverity, 1 ) 
		
	END CATCH
END



GO


