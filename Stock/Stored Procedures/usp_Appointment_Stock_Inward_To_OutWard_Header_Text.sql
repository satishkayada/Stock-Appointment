-- =============================================
-- Author:		Satish Kayada
-- Create date: 01/02/2018
-- Description:	Display Header on Tab of Inward outward Page only
-- =============================================

Create PROC [Stock].[usp_Appointment_Stock_Inward_To_Outward_Header_Text]
AS
BEGIN
        Select Count(*) As totalparty,sum(stonecount) as totalstone 
        From (
		SELECT Distinct Visit.PARTY_CODE,StoneId.stoneid,
        1 As stonecount
		FROM Stock.VISIT_STONES_FOR_NEXTCABIN StoneId
            left join Stock.VISIT on Stock.VISIT.visit_id=StoneId.visit_id
        ) as stone
END;