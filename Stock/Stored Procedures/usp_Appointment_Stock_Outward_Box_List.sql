-- =============================================
-- Author:		Satish Kayada
-- Create date: 25/01/2018
-- Description:	Appointment Stock Outward Box Wise List

--CREATE TYPE [Stock].[STONEID] AS TABLE(
--	[STONEID] [VARCHAR](16) NULL
--)

--is_rfId Parameter Speicfy that stoneId Table Variable Pass rfid List
-- =============================================

CREATE PROC [Stock].[usp_Appointment_Stock_Outward_Box_List]
@StoneId AS Stock.STONEID READONLY,
@is_rfid BIT=0
AS
BEGIN
        DECLARE @Today AS DATE= dbo.SOL_GetISTDATETIME();
        DECLARE @msg AS VARCHAR(256);
		DECLARE @tmpStoneId AS stock.STONEID
		IF @is_rfid=1 
		BEGIN
			INSERT INTO @tmpStoneId 
			SELECT STONEID 
			FROM @StoneId
		END
		ELSE
		BEGIN
			INSERT INTO @tmpStoneId
			SELECT *
			FROM stock.get_stoneid_from_rfd(@StoneId)
		End
		SELECT StoneId.stoneid parastoneid,Stone.*
		FROM @tmpStoneId StoneId
			OUTER APPLY (
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
							stoneid,
							shape_name,
							clarity_name,
							color_name,
							issue_carat,
							packet_rate,
							packet_rate*issue_carat AS packet_amount
							FROM Stock.view_appointment_stones
								LEFT JOIN Stock.view_Appointment_VisitParty_Details ON view_Appointment_VisitParty_Details.visit_id = view_appointment_stones.visit_id AND view_Appointment_VisitParty_Details.party_contacts_code IS NOT null
							WHERE view_appointment_stones.stoneid=StoneId.stoneid
							AND view_appointment_stones.visit_date=DBO.SOL_GetISTDATE()
							AND stone_issue_datetime IS NULL
			) AS Stone
		ORDER BY party_name
				
END;