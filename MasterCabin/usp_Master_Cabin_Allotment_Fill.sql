
-- =============================================
-- Author:		Satish Kayada
-- Create date: 11/01/2018
-- Description:	This procedure use to fill allocated cabin 
-- =============================================

CREATE proc	usp_master_cabin_allotment_fill
as 
begin
	declare @cabinremark varchar(30) = 'cabin_remark'
	select section_master.cabin_code,
	kam_visit_rules_master.user_code,user_name,
	count(*) as tabcount,
	cabin_master.is_active,
	remark_text
	from MASTER.KAM_VISIT_RULES_MASTER 
		left join MASTER.USER_MASTER  on user_master.user_code = kam_visit_rules_master.user_code
		left join MASTER.SECTION_MASTER on section_master.section_id = kam_visit_rules_master.section_id
		left join MASTER.CABIN_MASTER on cabin_master.cabin_code = section_master.cabin_code
		left join (
						select remark.source_id as cabin_code,
						remark.remark_text
						from STOCK.REMARKS remark
							join (
								select source_id,max(remark_id) as remarkid
								from STOCK.REMARKS
								where remark_type_code=[master].[getremarkcode](@cabinremark)
								group by source_id
							) as maxremark on maxremark.source_id=remark.source_id and remark_id=remarkid
						where remark.remark_type_code=[master].[getremarkcode](@cabinremark)  
				  ) remark on remark.cabin_code = section_master.cabin_code
	group by section_master.cabin_code,kam_visit_rules_master.user_code,user_name,remark_text,cabin_master.is_active
end
