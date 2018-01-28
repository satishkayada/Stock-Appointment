CREATE PROC [Stock].[usp_Appointment_Stock_Outward_Summary_List]
AS
    BEGIN

        DECLARE @guarantor AS VARCHAR(20)= 'guarantor';

        SELECT  
				visit.visit_id ,
                visit.party_code ,
                sales.party_master.party_name ,
                guarantor.party_code guarantor_code ,
                guarantor.party_name guarantor_name ,
                visitcontact.visit_contacts_id ,
                party_contacts_kam_code ,
                user_master.user_name AS kam ,
            
			    cabinDetail.cabin_name,
				cabinDetail.section_name ,
			
			    cabindetail.visit_date ,
                section_slot_from_time ,
                stonedetail.total_stones ,
                stonedetail.pending_stones ,
                stonedetail.allocated_stones ,
                stonedetail.waiting_stones ,
                stonedetail.rejected_stones ,
                visit.is_active ,
                cabindetail.section_id
        INTO    #tempvisitdata
        FROM    Stock.VISIT
                LEFT JOIN Sales.PARTY_MASTER ON PARTY_MASTER.PARTY_CODE = VISIT.PARTY_CODE
                CROSS APPLY ( SELECT TOP 1
                                        VISIT_CONTACTS.VISIT_CONTACTS_ID
                              FROM      Stock.VISIT_CONTACTS
                              WHERE     VISIT_CONTACTS.VISIT_ID = VISIT.VISIT_ID
                            ) AS visitcontact
                CROSS APPLY ( SELECT TOP 1
                                        VISIT_CONTACTS_KAM_ID ,
                                        VISIT_CONTACTS_KAM.PARTY_CONTACTS_KAM_CODE
                              FROM      Stock.VISIT_CONTACTS_KAM
							  WHERE stock.visit_contacts_kam.visit_contacts_id IN (  SELECT visit_contacts_id
																				FROM stock.visit_contacts
																				WHERE visit_contacts.visit_id=visit.visit_id 
																				  )
									  
                            ) AS visitkam
                OUTER APPLY ( SELECT TOP 1
                                        PARTY_ROLES.PARTY_CODE ,
                                        PARTY_NAME
                              FROM      Sales.PARTY_RELATIONS
                                        LEFT JOIN Sales.PARTY_ROLES ON PARTY_ROLES.PARTY_ROLE_CODE = PARTY_RELATIONS.PARTY_ROLE_CODE
                                        LEFT JOIN Sales.PARTY_MASTER ON PARTY_MASTER.PARTY_CODE = PARTY_ROLES.PARTY_CODE
                              WHERE     Sales.PARTY_RELATIONS.PARTY_CODE = VISIT.PARTY_CODE
                                        AND Sales.PARTY_ROLES.ROLE_CODE = Master.getRoleCode(@guarantor)
                            ) AS guarantor
                LEFT JOIN Master.USER_MASTER ON USER_MASTER.user_code = visitkam.PARTY_CONTACTS_KAM_CODE
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
                OUTER APPLY ( SELECT TOP 1
                                        VISIT_DETAIL.VISIT_ID ,
                                        Stock.VISIT_DETAIL.SECTION_ID ,
										CABIN_MASTER.cabin_name,
										section_name,
                                        VISIT.VISIT_DATE ,
                                        Stock.VISIT_DETAIL.SECTION_SLOT_FROM_TIME
                              FROM      Stock.VISIT_DETAIL
                                        LEFT JOIN Stock.VISIT ON VISIT.VISIT_ID = VISIT_DETAIL.VISIT_ID
                                        LEFT JOIN Master.SECTION_MASTER ON SECTION_MASTER.SECTION_ID = VISIT_DETAIL.SECTION_ID
                                        LEFT JOIN Master.CABIN_MASTER ON CABIN_MASTER.CABIN_CODE = SECTION_MASTER.CABIN_CODE
                              WHERE     Stock.VISIT_DETAIL.VISIT_ID = VISIT.VISIT_ID
                                        AND stonedetail.SECTION_ID = Stock.VISIT_DETAIL.SECTION_ID
                            ) AS cabinDetail
        WHERE   client_pending_stones > 0
		AND Visit.VISIT_START_TIME IS NOT null
		AND visit.VISIT_DATE=CAST (dbo.SOL_GetISTDATETIME() AS DATE)
        ORDER BY cabinDetail.VISIT_DATE,SECTION_SLOT_FROM_TIME;  

        SELECT  ISNULL(COUNT(*),0) AS total_appointments,
				ISNULL(SUM(total_stones)		,0) total_stones ,
                IsNull(SUM(pending_stones)	,0) pending_stones ,
                IsNull(SUM(allocated_stones)	,0) allocated_stones ,
                IsNull(SUM(waiting_stones)	,0) waiting_stones ,
                IsNull(SUM(rejected_stones)	,0) rejected_stones
        FROM    #tempvisitdata;


        SELECT  *
        FROM    #tempvisitdata;


        DROP TABLE #tempvisitdata;
    END;