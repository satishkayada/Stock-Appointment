-- =============================================
-- Author:		Satish Kayada
-- Create date: 25/01/2018
-- Description:	Appointment Stock Inward List

--CREATE TYPE [Stock].[STONEID] AS TABLE(
--	[STONEID] [VARCHAR](16) NULL
--)

-- =============================================

CREATE PROCEDURE [Stock].[usp_Appointment_Stock_Inward_List]
@stoneid AS stock.STONEID READONLY,
@is_rfid AS BIT=0
AS 
BEGIN

	DECLARE @tmpstoneId AS stock.STONEID
	IF @is_rfid=1
	BEGIN
		INSERT INTO @tmpstoneId
		        ( STONEID )
		SELECT STONEID
		FROM stock.get_stoneid_from_rfd(@stoneid)
    END
    ELSE
    BEGIN
		INSERT INTO @tmpstoneId
		        ( STONEID )
		SELECT STONEID
		FROM @stoneid
    End

	declare @msg AS VARCHAR(256)
	Declare @guarantor AS VARCHAR(20)= 'guarantor';

	SELECT 
	'' details,
	stoneId.stoneid,
	view_appointment_stones.shape_name,
	view_appointment_stones.clarity_name,
	view_appointment_stones.color_name,
	view_appointment_stones.issue_carat,
	view_appointment_stones.packet_rate,
	view_appointment_stones.visit_id,
    CABIN_NAME + ' ' + SECTION_NAME AS cabin_section_name,
	kam_short,
	next_cabin_section_name,
	packet_rate*issue_carat AS packet_amount
	FROM @tmpstoneid AS StoneId
		LEFT JOIN stock.view_appointment_stones on view_appointment_stones.stoneid = StoneId.STONEID AND view_appointment_stones.stone_issue_datetime IS NOT NULL AND view_appointment_stones.stone_received_datetime IS NULL
		LEFT JOIN stock.view_Appointment_Stone_Details ON view_Appointment_Stone_Details.VISIT_ID = view_appointment_stones.visit_id
		AND view_Appointment_Stone_Details.stoneid = view_appointment_stones.stoneid
		OUTER APPLY (
					SELECT TOP 1 CABIN_NAME + ' ' + SECTION_NAME AS next_cabin_section_name
					FROM Stock.VISIT_DETAIL
						LEFT JOIN Stock.VISIT on VISIT.VISIT_ID=Stock.VISIT_DETAIL.VISIT_ID
						LEFT JOIN Stock.VISIT_STONE_PRIORITY ON VISIT_STONE_PRIORITY.VISIT_ID=Stock.VISIT_DETAIL.VISIT_ID
						LEFT JOIN Master.SECTION_MASTER ON SECTION_MASTER.SECTION_ID = VISIT_DETAIL.SECTION_ID
						LEFT JOIN Master.CABIN_MASTER ON CABIN_MASTER.CABIN_CODE = SECTION_MASTER.CABIN_CODE
					WHERE VISIT_DETAIL.STONEID=StoneId.STONEID
					AND Visit.VISIT_START_TIME IS NOT NULL
					AND view_Appointment_Stone_Details.VISIT_ID != VISIT.VISIT_ID
                    AND vISIT.VISIT_DATE=CAST(DBO.SOL_GetISTDATETIME() AS DATE)
					ORDER BY VISIT_STONE_PRIORITY.PRIORITY_NO DESC,VISIT_START_TIME
				  ) AS nextcabinname
	WHERE view_appointment_stones.stone_issue_datetime IS NOT NULL AND view_appointment_stones.stone_received_datetime IS NULL
END