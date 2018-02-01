USE [srk_db]
GO

/****** Object:  StoredProcedure [Stock].[usp_Appointment_OverView_list]    Script Date: 31/01/2018 1:18:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- author:		satish kayada
-- create date: 21/01/2018
-- description:	fill appointment overview
-- =============================================
Alter procedure [Stock].[usp_Appointment_OverView_list]
@view_date as date=null
as 
		declare @todaydate as date;
		declare @cabinpercentage as numeric(4,2)
		declare @averageavailable as numeric(8,2)
		set @todaydate=case when(@view_date is null) then dbo.sol_getistdatetime() else @view_date end

		select @averageavailable=[stock].getaverageavailabilityofcabin(@todaydate,0)

		select 
		@averageavailable			As availablepercentage,
		sum(totalappointment   )	As totalappointment   ,
		sum(totalappointmentcarat ) As totalappointmentcarat ,

		--sum(totalissuepcs      ) as totalissuepcs      ,
		--sum(totalreceivepcs    ) as totalreceivepcs    ,
		--sum(totalrequestpcs    ) as totalrequestpcs    ,

		sum(ongoing            ) as ongoing            ,
		sum(ongoingcarat       ) as ongoingcarat       ,
		sum(upcomming          ) as upcomming          ,
		sum(upcomingcarat      ) as upcomingcarat      ,
		sum(completed          ) as completed          ,
		sum(completedcarat     ) as completedcarat     ,
		sum(cancel             ) as cancel             ,
		sum(cancelcarat        ) as cancelcarat        ,
		sum(notseen            ) as notseen            ,
		sum(notseencarat       ) as notseencarat       ,
		
		SUM(totalontablepcs    ) as totalontablepcs    ,
		sum(totalpendingpcs    ) as totalpendingpcs    ,
		sum(totalwaitingpcs    ) as totalwaitingpcs    ,
		sum(totalrejectedpcs   ) as totalrejectedpcs   ,
		sum(totalholdpcs       ) as totalholdpcs       ,
		sum(totalconfirmpcs    ) as totalconfirmpcs    ,
		sum(totalontablecarat  ) as totalontablecarat  ,
		sum(totalpendingcarat  ) as totalpendingcarat  ,
		sum(totalwaitingcarat  ) as totalwaitingcarat  ,
		sum(totalrejectedcarat ) as totalrejectedcarat ,
		sum(totalholdcarat     ) as totalholdcarat     ,
		sum(totalconfirmcarat  ) as totalconfirmcarat  
		from (
				select totcarat.visit_id,
				count(*) as totalappointment,
				sum(totcarat.issuecarat) as totalappointmentcarat,
				sum(totcarat.totalissuepcs) as totalissuepcs, 
				sum(totcarat.totalreceivepcs) as totalreceivepcs,
				sum(totcarat.totalrequestpcs) as totalrequestpcs,
				-- ongoing
				case when(		
							stock.visit.visit_start_time is not null
							and is_active=1
						 )
						 then 1
						 else 0 
				end ongoing,
				case when(
							stock.visit.visit_start_time is not null
							and is_active=1
						 )
						 then sum(totcarat.issuecarat)
						 else 0 
				end ongoingcarat,
				-- upcoming
				case when(
								Master.fn_getistdatetime()<cast(visit_date as datetime)+cast(visit_from_time as datetime)  -- on going visit
								AND visit_start_time is null
								AND is_active=1
						 )
						 then 1
						 else 0 
				end upcomming,
				case when(
								Master.fn_getistdatetime()<cast(visit_date as datetime)+cast(visit_from_time as datetime)  -- on going visit
								AND visit_start_time is null
								AND is_active=1
						 )
						 then sum(totcarat.issuecarat)
						 else 0 
				end upcomingcarat,
				case when(
								visit_start_time IS NOT NULL
								AND 
								visit_completed_time IS NOT NULL
								and is_active=1
						 )
						 then 1
						 else 0 
				end completed,
				case when(
								visit_start_time IS NOT NULL
								AND 
								visit_completed_time IS NOT NULL
								and is_active=1
						 )
						 then sum(totcarat.issuecarat)
						 else 0 
				end completedcarat,
				-- cancel 
				case when(visit.is_active=0)
						 then 1
						 else 0 
				end cancel,
				case when(visit.is_active=0)
						 then sum(totcarat.issuecarat)
						 else 0 
				end cancelcarat,
				-- not seeen
				case when(
								Master.Fn_GetISTDATETIME()>cast(visit_date as datetime)+cast(visit_to_time as datetime)  -- on going visit
								AND 
								VISIT_START_TIME IS null
								AND 
								IS_ACTIVE=1
						 )
						 then 1
						 else 0 
				end notseen,
				case when(
								Master.Fn_GetISTDATETIME()>cast(visit_date as datetime)+cast(visit_to_time as datetime)  -- on going visit
								AND 
								VISIT_START_TIME IS null
								AND 
								IS_ACTIVE=1
						 )
						 then sum(totcarat.issuecarat)
						 else 0 
				end notseencarat,
				sum(totcarat.totalontablepcs)			 totalontablepcs,
				sum(isnull(pending.totalpendingpcs,0))   totalpendingpcs,
				sum(isnull(pending.totalpendingpcs,0))	 totalwaitingpcs,
				sum(totcarat.totalrejectedpcs)			 totalrejectedpcs,
				sum(totcarat.totalholdpcs)				 totalholdpcs,
				sum(totcarat.totalconfirmpcs)			 totalconfirmpcs,
				sum(totcarat.totalontablecarat)			 totalontablecarat,
				sum(isnull(pending.totalpendingcarat,0)) totalpendingcarat,
				sum(isnull(pending.totalpendingcarat,0)) totalwaitingcarat,
				sum(totcarat.totalrejectedcarat)		 totalrejectedcarat,
				sum(totcarat.totalholdcarat)			 totalholdcarat,
				sum(totcarat.totalconfirmcarat)			 totalconfirmcarat
				from stock.visit
					left join
						(
							select visit_detail.visit_id,
							sum(1) totalrequestpcs,
							sum(case when (visit_detail.stone_issue_datetime is not null) then 1 else 0 end) totalissuepcs,
							sum(case when (visit_detail.stone_received_datetime is not null) then 1 else 0 end) totalreceivepcs,
							sum(case when (visit_detail.stone_issue_datetime is not null and stock.visit_detail.stone_received_datetime is null)  
									then 1 else 0 end) 
							as totalontablepcs,
							sum(case when (
												visit_detail.stone_issue_datetime is not null 
											and stock.visit_detail.stone_received_datetime is not null 
											and (packet.stone_details.is_memo_lock=0 OR packet.STONE_DETAILS.party_code!=visit.PARTY_CODE)
										  ) then 1 else 0 end) 
								as totalrejectedpcs,
							sum(case when (visit_detail.stone_issue_datetime is not null and packet.stone_details.memo_date IS NOT NULL AND packet.STONE_DETAILS.party_code=visit.PARTY_CODE) then 1 else 0 end) 
							as totalholdpcs,
							sum(case when (visit_detail.stone_issue_datetime is not null and packet.stone_details.is_memo_lock=1 AND packet.STONE_DETAILS.party_code=visit.PARTY_CODE) then 1 else 0 end) 
							as totalconfirmpcs,
						
							sum(stone_lab_details.issue_carat) as issuecarat,
							sum(case when (visit_detail.stone_received_datetime is not null) then stone_lab_details.issue_carat else 0 end) totalreceiveCarat,
						
							sum(case when (visit_detail.stone_issue_datetime is not null and stock.visit_detail.stone_received_datetime is null)  
									then stone_lab_details.issue_carat else 0 end) 
							as totalontablecarat,

							sum(case when (
												visit_detail.stone_issue_datetime is not null 
											and stock.visit_detail.stone_received_datetime is not null 
											and (packet.stone_details.is_memo_lock=0 OR packet.STONE_DETAILS.party_code!=visit.PARTY_CODE)
										  ) then stone_lab_details.issue_carat else 0 end) 
								as  totalrejectedcarat,

							sum(case when (visit_detail.stone_issue_datetime is not null and packet.stone_details.memo_date IS NOT NULL AND packet.STONE_DETAILS.party_code=visit.PARTY_CODE) 
								then stone_lab_details.issue_carat else 0 end) 
							as totalholdcarat,
							sum(case when (visit_detail.stone_issue_datetime is not null and packet.stone_details.is_memo_lock=1 AND packet.STONE_DETAILS.party_code=visit.PARTY_CODE) 
								then stone_lab_details.issue_carat else 0 end) 
							as totalconfirmcarat
							from stock.visit_detail	
								left join stock.visit on visit.visit_id=visit_detail.visit_id
								left join packet.stone_details on stone_details.stoneid = visit_detail.stoneid
								left join packet.stone_lab_details on stone_lab_details.stoneid = visit_detail.stoneid and stone_lab_details.certificate_code= stone_details.certificate_code
							where visit_date=@todaydate
							group by visit_detail.visit_id
					) as totcarat  on totcarat.visit_id = visit.visit_id
					left join (
								select visit_id,
									count(*) as totalpendingpcs,
									sum(pending.issue_carat) as totalpendingcarat
								from (
										select a.visit_id,a.stoneid,max(packet.stone_lab_details.issue_carat) as issue_carat
										from stock.visit_detail	a 
											left join packet.stone_details on stone_details.stoneid = a.stoneid
											left join packet.stone_lab_details on stone_lab_details.stoneid = a.stoneid and stone_lab_details.certificate_code= stone_details.certificate_code
											left join stock.visit on visit.visit_id=a.visit_id
											left join stock.visit_detail as b	on a.stoneid=b.stoneid and a.visit_id!=b.visit_id and cast(dbo.sol_getistdatetime() as time) >= a.section_slot_from_time 
											left join stock.visit v on b.visit_id=v.visit_id
										where 1=1
										and visit.visit_date=@todaydate
										and v.is_active=1
										and b.stoneid is not null
										and a.stone_issue_datetime is not null and a.stone_received_datetime is null
										group by a.visit_id,a.stoneid
									) as pending
								group by pending.visit_id
								) as pending on pending.visit_id = visit.visit_id
				where visit_date=@todaydate
				group by totcarat.visit_id
				,visit_date
				,visit_from_time
				,is_active
				,visit_start_time
				,visit_to_time
				,visit_completed_time
			) as visit

GO

