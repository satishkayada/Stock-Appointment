USE [srk_db]
GO
/****** Object:  StoredProcedure [Stock].[usp_ViewRequest_MemoStoneScanStatus_Update]    Script Date: 06/02/2018 1:55:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Rushita 
-- Create date: 27/01/2018
-- Description:	Update rfid scan status or barcode status in internal viewrequest

--CREATE TYPE [Stock].[TABLEVAR_STONE_MEMOSCANSTATUS_UPDATE] AS TABLE(
--	[memo_date] [DATE] NULL,
--	[memo_number] [INT] NULL,
--	[stone_id] [VARCHAR](16) NULL,
--	[is_barcode_verify] [BIT] NULL,
--	[is_rfid_verify] [BIT] NULL
--)
--GO

-- =============================================

 
Alter PROCEDURE [Stock].[usp_ViewRequest_MemoStoneScanStatus_Update]
   @tablevar_stone_memoscanstatus_update Stock.TABLEVAR_STONE_MEMOSCANSTATUS_UPDATE READONLY
AS
    BEGIN
       UPDATE stone_viewrequest_details
			  SET stone_viewrequest_details.is_barcode_veriy=stone_memoscanstatus_update.is_barcode_verify,
				   stone_viewrequest_details.is_rfid_verify=stone_memoscanstatus_update.is_rfid_verify
	   FROM @tablevar_stone_memoscanstatus_update stone_memoscanstatus_update
			LEFT JOIN Packet.STONE_VIEWREQUEST_DETAILS stone_viewrequest_details
									ON stone_viewrequest_details.stoneid = stone_memoscanstatus_update.stoneid
									AND stone_viewrequest_details.memo_date = stone_memoscanstatus_update.memo_date
									AND stone_viewrequest_details.memo_no=stone_memoscanstatus_update.memo_number
    END
        

