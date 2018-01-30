USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_Box_Summary_List]    Script Date: 30/01/2018 12:44:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Satish Kayada
-- Create date: 25/01/2018
-- Description:	Appointment Stock Outward Header Count 
-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_Box_Summary_List]
AS
    BEGIN
        DECLARE @Today AS DATE= dbo.SOL_GetISTDATETIME();
        DECLARE @msg AS VARCHAR(256);

        SELECT  COUNT(*) AS allStone ,
                SUM(CASE WHEN ( Packet.STONE_DETAILS.SECTION_ID IS NOT null
                              ) THEN 1
                         ELSE 0
                    END) AS buyercabin ,
                SUM(CASE WHEN ( Packet.STONE_DETAILS.memo_date IS NOT NULL
                                AND is_memo_lock = 0
                              ) THEN 1
                         ELSE 0
                    END) AS totalbusinessprocess ,
                SUM(CASE WHEN ( Packet.STONE_DETAILS.memo_date IS NOT NULL
                                AND is_memo_lock = 0
                              ) THEN 1
                         ELSE 0
                    END) AS totalconfirmstone ,
                SUM(CASE WHEN ( Packet.STONE_DETAILS.SECTION_ID IS NULL
 								AND Packet.STONE_DETAILS.memo_date IS NULL
                                AND is_memo_lock = 0
                              ) THEN 1
                         ELSE 0
                    END)
				AS freestone
        FROM    Stock.VISIT_DETAIL
                LEFT JOIN Stock.VISIT ON VISIT.VISIT_ID = VISIT_DETAIL.VISIT_ID
                LEFT JOIN Packet.STONE_DETAILS ON STONE_DETAILS.stoneid = VISIT_DETAIL.STONEID
        WHERE   VISIT_DATE = @Today;
    END;



GO

