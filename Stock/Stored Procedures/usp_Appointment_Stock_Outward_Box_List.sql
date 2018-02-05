SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

-- =============================================n
-- Author:		Satish Kayada
-- Create date: 25/01/2018
-- Description:	Appointment Stock Outward Box Wise List

--CREATE TYPE [Stock].[RFID_TAG] AS TABLE(
--	[rfid_tag] [varchar](16) NULL
--)

--action List
--all
--buyercabin
--businessprocess
--confirm
--free

-- =============================================

ALTER PROC [Stock].[usp_Appointment_Stock_Outward_Box_List]
@rfid_tag AS Stock.rfid_tag READONLY,
@list_name as varchar(15)
AS
BEGIN

    DECLARE @Today AS DATE= dbo.SOL_GetISTDATETIME();
    DECLARE @msg AS VARCHAR(256);
	DECLARE @tmpStoneId AS stock.STONEID
	INSERT INTO @tmpStoneId
	SELECT STONEID
	FROM Packet.STONE_DETAILS
	WHERE rfid_tag IN (SELECT rfid_tag FROM @rfid_tag)
	
	Select *
	From (
			select 'buyercabin' AS tab_name,
					stoneid.stoneid parastoneid,	stone.rno ,
											stone.visit_id ,
											stone.party_name ,
											stone.party_code ,
											stone.kam_name ,
											stone.party_contacts_kam_code ,
											stone.cabin_name ,
											stone.check_scan_status ,
											stone.is_scan_by_rfid ,
											stone.detail ,
											stone.box_rfid_tag ,
											stone.stoneid ,
											stone.shape_name ,
											stone.clarity_name ,
											stone.color_name ,
											stone.issue_carat ,
											stone.packet_rate ,
											stone.packet_amount
			from @tmpstoneid stoneid
				CROSS apply (
								select 
								row_number() over (order by priority_no desc,visit_start_time)  as rno,
								view_appointment_stones.visit_id,
								party_name,party_code,
								view_appointment_stones.kam_name,
								view_appointment_stones.party_contacts_kam_code,
								cabin_name,
								check_scan_status,
								is_scan_by_rfid,
								'' as detail,
								box_rfid_tag,
								stoneid,
								shape_name,
								clarity_name,
								color_name,
								issue_carat,
								packet_rate,
								packet_rate*issue_carat as packet_amount
								from stock.view_appointment_stones
									left join stock.view_appointment_visitparty_details on view_appointment_visitparty_details.visit_id = view_appointment_stones.visit_id and view_appointment_visitparty_details.party_contacts_code is not null
								where view_appointment_stones.stoneid=stoneid.stoneid
								and view_appointment_stones.visit_date=dbo.sol_getistdate()
								and stone_issue_datetime is null
				) as stone
			where  (@list_name='all' or  @list_name='buyercabin')

			UNION ALL
			select  tab_name,
					stoneid.stoneid parastoneid, stone.rno ,
											stone.visit_id ,
											stone.party_name ,
											stone.party_code ,
											stone.kam_name ,
											stone.party_contacts_kam_code ,
											stone.cabin_name ,
											stone.check_scan_status ,
											stone.is_scan_by_rfid ,
											stone.detail ,
											stone.box_rfid_tag ,
											stone.stoneid ,
											stone.shape_name ,
											stone.clarity_name ,
											stone.color_name ,
											stone.issue_carat ,
											stone.packet_rate ,
											stone.packet_amount
			from @tmpstoneid stoneid
				CROSS apply (
								select 
								CASE WHEN(STONE_DETAILS.memo_date IS NOT NULL AND is_memo_lock=0) THEN 'businessprocess'
									WHEN(STONE_DETAILS.memo_date IS NOT NULL AND is_memo_lock=1) THEN 'confirm'
									WHEN(STONE_DETAILS.memo_date IS NULL AND is_memo_lock=0 AND SECTION_MASTER.section_id IS NULL) THEN 'free'
								ELSE '' END AS tab_name,
								row_number() over (order by Packet.STONE_DETAILS.stoneid)  as rno,
								Packet.STONE_DETAILS.visit_id,
								STONE_DETAILS.party_code,
								PARTY_MASTER.party_name,
								stone_details.user_code party_contacts_kam_code,
								USER_MASTER.user_short_name kam_name,
								cabin_name,
								0 check_scan_status,
								is_scan_by_rfid,
								'' as detail,
								box_rfid_tag,
								stone_details.stoneid,
								shape_name,
								clarity_name,
								color_name,
								issue_carat,
								packet_rate,
								packet_rate*issue_carat as packet_amount
								from packet.STONE_DETAILS	
									LEFT JOIN Sales.PARTY_MASTER ON PARTY_MASTER.PARTY_CODE = STONE_DETAILS.party_code
									LEFT JOIN packet.STONE_LAB_DETAILS ON STONE_LAB_DETAILS.stoneid = STONE_DETAILS.stoneid AND STONE_LAB_DETAILS.certificate_code = STONE_DETAILS.certificate_code
									LEFT JOIN packet.STONE_LAB_DESCRIPTION ON stone_Details.stoneid = packet.stone_lab_description.stoneid 
									AND stone_lab_description.certificate_code = STONE_LAB_DETAILS.certificate_code
									LEFT JOIN Master.USER_MASTER ON USER_MASTER.user_code=stone_details.user_code
									LEFT JOIN Stock.visit_detail ON Stock.VISIT_DETAIL.VISIT_ID=packet.STONE_DETAILS.visit_id
									LEFT JOIN stock.visit ON VISIT.VISIT_ID = STONE_DETAILS.visit_id
									LEFT join stock.view_appointment_visitparty_details on view_appointment_visitparty_details.visit_id = STONE_DETAILS.visit_id AND view_appointment_visitparty_details.party_contacts_code IS NOT NULL
									LEFT JOIN Master.SECTION_MASTER ON SECTION_MASTER.section_id = STONE_DETAILS.section_id
									LEFT JOIN master.CABIN_MASTER ON CABIN_MASTER.cabin_code = SECTION_MASTER.cabin_code
								where packet.STONE_DETAILS.stoneid=stoneid.stoneid
								AND 
								(
									(STONE_DETAILS.memo_date IS NOT NULL AND is_memo_lock=0) OR 
									(STONE_DETAILS.memo_date IS NOT NULL AND is_memo_lock=1) OR 
									(STONE_DETAILS.memo_date IS NULL AND is_memo_lock=0 AND SECTION_MASTER.section_id IS NULL)
								)
				) as stone
			) AS packet
		where (tab_name=@list_name or @list_name='' or @list_name='all')
END;
