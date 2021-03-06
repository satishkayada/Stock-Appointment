USE [srk_db]
GO
/****** Object:  StoredProcedure [Master].[usp_Master_Cabin_Allotment_List]    Script Date: 31/01/2018 1:16:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Satish Kayada
-- Create date: 11/01/2018
-- Description:	This procedure use to fill allocated cabin 
-- =============================================

ALTER PROCEDURE [Master].[usp_Master_Cabin_Allotment_List]
AS 
BEGIN
 

	DECLARE @cabinremark VARCHAR(30) = 'cabin_remark'
	SELECT section_master.cabin_code,
	kam_visit_rules_master.user_code,user_name,
	COUNT(*) AS table_count,
	cabin_master.is_active,
	remark_text
	FROM MASTER.KAM_VISIT_RULES_MASTER 
		LEFT JOIN MASTER.USER_MASTER  ON user_master.user_code = kam_visit_rules_master.user_code
		LEFT JOIN MASTER.SECTION_MASTER ON section_master.section_id = kam_visit_rules_master.section_id
		LEFT JOIN MASTER.CABIN_MASTER ON cabin_master.cabin_code = section_master.cabin_code
		LEFT JOIN (
						SELECT remark.source_id AS cabin_code,
						remark.remark_text
						FROM STOCK.REMARKS remark
							JOIN (
								SELECT source_id,MAX(remark_id) AS remarkid
								FROM STOCK.REMARKS
								WHERE remark_type_code=[master].[getremarkcode](@cabinremark)
								GROUP BY source_id
							) AS maxremark ON maxremark.source_id=remark.source_id AND remark_id=remarkid
						WHERE remark.remark_type_code=[master].[getremarkcode](@cabinremark)  
				  ) remark ON remark.cabin_code = section_master.cabin_code
	GROUP BY section_master.cabin_code,kam_visit_rules_master.user_code,user_name,remark_text,cabin_master.is_active
 
END

