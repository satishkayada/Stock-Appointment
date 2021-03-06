USE [srk_db]
GO
/****** Object:  StoredProcedure [Master].[usp_Master_KAM_Available_List]    Script Date: 31/01/2018 1:14:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  Satish Kayada
-- Create date: 17-01-2018
-- Description: This Procedure is Use to Fill KAM Available.
-- =============================================


ALTER PROCEDURE [Master].[usp_Master_KAM_Available_List]
AS 
BEGIN
	SELECT 
	kam_visit_rules_master.user_code,
	user_name,
	section_master.cabin_code,
	master.cabin_master.cabin_name,
	section_master.section_id,
	section_code,
	section_name,
	kam_visit_rules_master.simultaneous_visit,
	MAX(CASE WHEN(days_master.day_id=1 AND master.days_master.is_active=1) THEN  days_master.day_id  ELSE 0 END) day1,
	MAX(CASE WHEN(days_master.day_id=2 AND master.days_master.is_active=1) THEN  days_master.day_id  ELSE 0 END) day2,
	MAX(CASE WHEN(days_master.day_id=3 AND master.days_master.is_active=1) THEN  days_master.day_id  ELSE 0 END) day3,
	MAX(CASE WHEN(days_master.day_id=4 AND master.days_master.is_active=1) THEN  days_master.day_id  ELSE 0 END) day4,
	MAX(CASE WHEN(days_master.day_id=5 AND master.days_master.is_active=1) THEN  days_master.day_id  ELSE 0 END) day5,
	MAX(CASE WHEN(days_master.day_id=6 AND master.days_master.is_active=1) THEN  days_master.day_id  ELSE 0 END) day6,
	MAX(CASE WHEN(days_master.day_id=7 AND master.days_master.is_active=1) THEN  days_master.day_id  ELSE 0 END) day7,
	kam_slot_master.is_active
	FROM MASTER.KAM_SLOT_MASTER
		INNER JOIN MASTER.KAM_VISIT_RULES_MASTER ON kam_visit_rules_master.rule_code = kam_slot_master.rule_code AND kam_visit_rules_master.is_active=1
		INNER JOIN MASTER.USER_MASTER ON user_master.user_code = kam_visit_rules_master.user_code AND user_master.is_active=1
		INNER JOIN MASTER.SECTION_MASTER ON section_master.section_id = kam_visit_rules_master.section_id AND section_master.is_active=1
		INNER JOIN MASTER.CABIN_MASTER ON cabin_master.cabin_code = section_master.cabin_code AND cabin_master.is_active=1
		INNER JOIN MASTER.DAYS_MASTER ON days_master.day_id = kam_slot_master.day_id
	GROUP BY 
	kam_visit_rules_master.user_code,
	user_name,
	section_master.cabin_code,
	master.cabin_master.cabin_name,
	kam_visit_rules_master.simultaneous_visit,
	section_master.section_id,
	section_code,
	section_name,
	kam_slot_master.is_active
END	
