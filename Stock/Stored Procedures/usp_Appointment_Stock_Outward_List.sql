USE [srk_db]
GO
/****** Object:  StoredProcedure [Stock].[usp_Appointment_Stock_Outward_List]    Script Date: 01/02/2018 9:03:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Satish Kayada
-- Create date: 23/01/2018
-- Description:	Inward outWard Summary of Visit List
-- =============================================

ALTER PROC [Stock].[usp_Appointment_Stock_Outward_List]
@visit_id INT
AS 
BEGIN
	DECLARE @msg AS VARCHAR(256)
	IF @visit_id=0 OR @visit_id IS NULL 
	BEGIN
		SET @msg='';
		raiserror('Invalid Visit Id Pass',18,1);
		RETURN;
        
	END
	Declare @guarantor AS VARCHAR(20)= 'guarantor';

	Select
	visit.visit_id,
	visit.party_code,
	sales.party_master.party_name
	,guarantor.party_code guarantorcode
	,guarantor.party_name guarantorname
	,visitcontact.visit_contacts_id
	,party_contacts_kam_code
	,user_master.user_short_name AS kam_short
	,cabinDetail.cabin_name
	,cabinDetail.section_name
	,cabinDetail.visit_date
	,section_slot_from_time 
	,section_slot_to_time
	,stonedetail.total_stones
	,stonedetail.pending_stones
	,allocated_stones
	,stonedetail.waiting_stones
	,stonedetail.rejected_stones
	,visit.is_active
	,CabinDetail.section_id 
	FROM STOCK.VISIT
		LEFT JOIN SALES.PARTY_MASTER ON party_master.party_code = visit.party_code
		CROSS APPLY (
						SELECT TOP 1 visit_contacts.visit_contacts_id
						FROM stock.visit_contacts
						WHERE visit_contacts.visit_id=visit.visit_id 
					) AS visitcontact
		CROSS APPLY (
						SELECT TOP 1 visit_contacts_kam_id,visit_contacts_kam.party_contacts_kam_code
						FROM stock.visit_contacts_kam
						WHERE stock.visit_contacts_kam.visit_contacts_id In (  SELECT visit_contacts_id
																				FROM stock.visit_contacts
																				WHERE visit_contacts.visit_id=visit.visit_id 
																				  )
					) AS visitkam
		OUTER APPLY (
						SELECT TOP 1 party_roles.party_code,party_name 
						FROM sales.party_relations
							LEFT JOIN sales.party_roles ON party_roles.party_role_code = party_relations.party_role_code 
							LEFT JOIN sales.party_master ON party_master.party_code = party_roles.party_code
						WHERE sales.party_relations.party_code=visit.party_code AND sales.party_roles.role_code=master.getrolecode(@guarantor)
					) AS guarantor
		LEFT JOIN master.user_master ON user_master.user_code=visitkam.party_contacts_kam_code
		LEFT JOIN (
						SELECT visit_id,section_id,
						 COUNT(*) total_stones
						,SUM(pending_stone) AS pending_stones
						,SUM(waiting_stone) AS waiting_stones
						,SUM(visit_confirm_stone) AS confirm_stones
						,SUM(on_table_stone) AS allocated_stones
						,SUM(rejected_stone) AS rejected_stones
						,SUM(pending_stone+waiting_stone) AS client_pending_stones
						FROM stock.view_appointment_stone_details
						GROUP BY visit_id,section_id
				  ) AS stonedetail ON stonedetail.visit_id = visit.visit_id
		OUTER APPLY (
						SELECT TOP 1 VISIT_DETAIL.VISIT_ID,Stock.VISIT_DETAIL.SECTION_ID,
						CABIN_MASTER.cabin_name,
						SECTION_NAME section_name,
						VISIT.VISIT_DATE,
						Stock.VISIT_DETAIL.SECTION_SLOT_FROM_TIME , 
						Stock.VISIT_DETAIL.SECTION_SLOT_TO_TIME  
						FROM Stock.VISIT_DETAIL
							LEFT JOIN Stock.VISIT ON VISIT.VISIT_ID = VISIT_DETAIL.VISIT_ID
							LEFT JOIN Master.SECTION_MASTER ON SECTION_MASTER.SECTION_ID = VISIT_DETAIL.SECTION_ID
							LEFT JOIN master.CABIN_MASTER ON CABIN_MASTER.CABIN_CODE = SECTION_MASTER.CABIN_CODE
						WHERE Stock.VISIT_DETAIL.VISIT_ID=visit.VISIT_ID AND stonedetail.section_id=Stock.VISIT_DETAIL.SECTION_ID
				  ) as cabinDetail
		WHERE client_pending_stones>0 AND visit.VISIT_ID=@visit_id

		SELECT *
		FROM stock.view_appointment_stones
		WHERE view_appointment_stones.VISIT_ID=@visit_id
		AND stone_issue_datetime IS NULL
		
END



