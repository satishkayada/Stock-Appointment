-- =============================================
-- Author:		Satish Kayada
-- Create date: 01/02/2018
-- Description:	Appointment Stock Outward Box Wise List for Inward outward Page only

--CREATE TYPE [Stock].[STONEID] AS TABLE(
--	[STONEID] [VARCHAR](16) NULL
--)

-- =============================================

Alter PROC [Stock].[usp_Appointment_Stock_Inward_To_Outward_List]
AS
BEGIN
        DECLARE @Today AS DATE= dbo.SOL_GetISTDATETIME();
        DECLARE @msg AS VARCHAR(256);

		SELECT *
		FROM Stock.VISIT_STONES_FOR_NEXTCABIN StoneId
			outer apply (
							SELECT 
							ROW_NUMBER() OVER (ORDER BY priority_no DESC,visit_start_time)  AS rno,
							view_appointment_stones.visit_id,
							party_name,party_code,
							view_appointment_stones.kam_name,
							view_appointment_stones.party_contacts_kam_code,
							cabin_name,
							check_scan_status,
							is_scan_by_rfid,
							'' AS Detail,
							box_rfid_tag,
							STONEID,
							shape_name,
							clarity_name,
							color_name,
							issue_carat,
							packet_rate,
							packet_rate*issue_carat AS packet_amount
							FROM Stock.view_appointment_stones
								LEFT JOIN Stock.view_Appointment_VisitParty_Details ON view_Appointment_VisitParty_Details.visit_id = view_appointment_stones.visit_id
							WHERE view_appointment_stones.stoneid=StoneId.STONEID
							AND stone_issue_datetime IS NULL
			) AS Stone
		ORDER BY party_name
				
END;