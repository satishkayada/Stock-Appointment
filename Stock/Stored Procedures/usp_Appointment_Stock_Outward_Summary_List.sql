USE [srk_db]
GO
/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_Summary_List]    Script Date: 01/02/2018 9:04:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [Stock].[usp_Appointment_Stock_Outward_Summary_List]
AS
BEGIN
	DECLARE @guarantor AS VARCHAR(20)= 'guarantor';
		SELECT  
			ISNULL(COUNT(*),0)							AS total_appointments,
			ISNULL(SUM(stonedetail.total_stones),0)     AS total_stones ,
            IsNull(SUM(stonedetail.pending_stones),0)   AS pending_stones ,
            IsNull(SUM(stonedetail.allocated_stones),0) AS allocated_stones ,
            IsNull(SUM(stonedetail.waiting_stones),0)   AS waiting_stones ,
            IsNull(SUM(stonedetail.rejected_stones),0)  AS rejected_stones
        FROM    Stock.VISIT
                LEFT JOIN ( SELECT  VISIT_ID ,
                                    section_id ,
                                    COUNT(*) total_stones ,
                                    SUM(pending_stone) AS pending_stones ,
                                    SUM(waiting_stone) AS waiting_stones ,
                                    SUM(visit_confirm_stone) AS confirm_stones ,
                                    SUM(on_table_stone) AS allocated_stones ,
                                    SUM(rejected_stone) AS rejected_stones ,
                                    SUM(pending_stone + waiting_stone) AS client_pending_stones
                            FROM    Stock.view_Appointment_Stone_Details
                            GROUP BY VISIT_ID ,
                                    section_id
                          ) AS stonedetail ON stonedetail.VISIT_ID = VISIT.VISIT_ID
        WHERE   client_pending_stones > 0
		AND Visit.VISIT_START_TIME IS NOT null
		AND visit.VISIT_DATE=CAST (dbo.SOL_GetISTDATETIME() AS DATE)
END;
