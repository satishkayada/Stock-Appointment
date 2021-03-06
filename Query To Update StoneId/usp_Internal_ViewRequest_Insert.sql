USE [srk_db]
GO
/****** Object:  StoredProcedure [Stock].[usp_Internal_ViewRequest_Insert]    Script Date: 06/02/2018 2:18:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [Stock].[usp_Internal_ViewRequest_Insert]
@stoneidlist Stock.STONEID READONLY,
@memo_date DATE,
@memo_no SMALLINT,
@modified_by SMALLINT,
@modified_iplocation_id int
AS
BEGIN
	IF (@memo_date <> '' And  @memo_no <> 0)
	BEGIN
		Insert into Packet.STONE_VIEWREQUEST_DETAILS 
			( stoneid, memo_date, memo_no, memo_week_number, party_code, party_contacts_code, broker_code, internal_process_code, external_process_code, user_code, 
			operation_remark, created_datetime, created_by, created_iplocation_id )
		select s.stoneid, @memo_date, @memo_no, DATENAME(isowk, @memo_date), party_code, party_contacts_code, broker_code, internal_process_code, external_process_code, @modified_by user_code,
			'view requested', Master.Fn_GetISTDATETIME(), @modified_by, @modified_iplocation_id
		From Packet.STONE_DETAILS s
			LEFT JOIN @stoneidlist stone ON stone.stoneid = s.stoneid
		WHERE stone.stoneid = s.stoneid
		--where stoneid in (select value from dbo.Split(@stoneidlist,','))
	END
END
