USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[usp_MfgOutward_StoneDetails_List]    Script Date: 06/02/2018 2:39:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [Stock].[usp_MfgOutward_StoneDetails_List]
--@rfidtag_list varchar(max)='',
--@stoneid_list varchar(max)='',
@stoneid_rfid [Stock].[STONEID_RFID] READONLY,
@to_department_code TINYINT
AS
BEGIN
	SELECT s.shape_short_name, tmast.stoneid, t.issue_carat, q.clarity_short_name, col.color_short_name, c.certificate_short_name, 
		UserMast.user_short_name, tmast.packet_rate, tmast.conversion_rate, (tmast.packet_rate*t.issue_carat) packet_amount, tmast.rfid_tag
	FROM packet.stone_details tmast
	LEFT JOIN packet.stone_processes prc ON tmast.stoneid = prc.stoneid
	LEFT JOIN packet.stone_lab_details t ON tmast.stoneid = t.stoneid --and is_labactive = 1
	LEFT JOIN master.certificate_master c ON c.certificate_code = t.certificate_code
	LEFT JOIN master.shape_master s ON s.shape_code = t.shape_code
	LEFT JOIN master.clarity_master q ON q.clarity_code = t.lab_clarity_code
	LEFT JOIN master.color_master col ON col.color_code = t.lab_color_code
	LEFT JOIN Master.USER_MASTER UserMast ON UserMast.user_code = tmast.user_code
	LEFT JOIN @stoneid_rfid STONE ON 1=1
	WHERE prc.to_department_code = @to_department_code 
		AND prc.is_process_active = 1
		AND (STONE.rfid_tag = '' OR (ISNULL(tmast.rfid_tag,'') <> '' AND tmast.rfid_tag = STONE.rfid_tag))
		AND (
				(STONE.stoneid = '' OR tmast.stoneid = STONE.stoneid)
				OR
				(STONE.stoneid = '' OR tmast.rfid_tag = STONE.stoneid)
			)
		AND (STONE.rfid_tag <> '' OR STONE.stoneid <> '')
		--And (@rfidtag_list = '' or (isnull(rfid_tag,'') <> '' and tmast.rfid_tag in (select value from dbo.split(@rfidtag_list,','))))
		--And (
		--		(@stoneid_list = '' or tmast.stoneid in (select value from d]bo.split(@stoneid_list,',')))
		--		or
		--		(@stoneid_list = '' or tmast.rfid_tag in (select value from dbo.split(@stoneid_list,',')))
		--	)
		--And (@rfidtag_list <> '' or @stoneid_list <> '')
END


GO


