USE [srk_db]
GO


/****** Object:  StoredProcedure [Stock].[usp_InwardMfg_Save]    Script Date: 06/02/2018 2:20:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Ritesh Khatri
-- Create date: 01/02/2018
-- Description:	Use to Work on Mfg Inward Details 

-- CREATE TYPE [Stock].[usp_InwardMfg_Save] AS TABLE(
--@STONEID Stock.STONEID READONLY,
--@INWARD_MFG_DATA [Stock].[INWARD_MFG_DATA] READONLY,
--@userid smallint =0 
-- )

-- =============================================
CREATE PROCEDURE [Stock].[usp_InwardMfg_Save]
@STONEID Stock.STONEID READONLY,
@INWARD_MFG_DATA [Stock].[INWARD_MFG_DATA] READONLY,
@userid SMALLINT =0 
AS
BEGIN
			DECLARE @TRNYEAR VARCHAR(10) = ''
			SELECT @TRNYEAR = configuration_value
			FROM Master.CONFIGURATION_MASTER
			WHERE configuration_key = 'SRK_CURRENT_YEAR'

			Declare @department_date DATE = null
			SELECT @department_date = MAX(department_date) 
			FROM Master.STONE_DEPARTMENT_MASTER where size_type_key = 'STKACC'
	
			Merge Into Packet.STONE_DETAILS As Dest
			Using(
				select T.stoneid, T.vendor_lot_code, T.vendor_serial_no,  T.certificate_code, 
					T.clarity_code, T.clarity_sign, T.color_code, T.color_sign, T.cut_code, T.polish_code, T.symmetry_code, T.floro_code, 
					T.packet_base_rate,T.packet_rate, T.packet_percentage, T.rfid_tag, T.is_order_confirm, T.is_order_missed, 
					OrderMaster.order_number order_number, OrderMaster.sub_order_number sub_order_number,
					Master.getinternal_process_code('NEW') process_code, T.lab_control_no,
					T.is_fm_eligible, T.is_cm_eligible, T.clv_tag,
					MinesMaster.mines_code, T.parcel_id, T.invoice_id, rough_carat, T.makable_carat,
					T.rap_year_month , T.rap_number
				From Packet.VENDOR_STONE_DETAILS T
				LEFT JOIN Master.ORDER_MASTER OrderMaster ON T.order_no = OrderMaster.order_number AND T.sub_orderno = OrderMaster.sub_order_number
				LEFT JOIN Master.VENDOR_USER_MASTER VendorUserMast on VendorUserMast.user_code = T.vendor_user_code And T.vendor_code = VendorUserMast.vendor_code
				LEFT JOIN Master.MINES_MASTER MinesMaster on MinesMaster.mines_name = T.mines_name
				LEFT JOIN @STONEID stn ON stn.stoneid = T.stoneid
				Where 1=1 
				--And T.stoneid IN (Select Value From Dbo.Split(@stoneid_list,','))
				AND stn.stoneid = T.stoneid
				And VendorUserMast.is_primary = 1 
				And ISNULL(T.is_stock_final,0) = 0
				)As Sou On Dest.stoneid = Sou.stoneid
			When Matched THEN
			Update
			Set Dest.lot_code = Sou.vendor_lot_code,
				Dest.serial_number = Sou.vendor_serial_no,
				Dest.certificate_code = Sou.certificate_code,
			
				Dest.packet_base_rate = Sou.packet_base_rate,
				Dest.packet_rate = Sou.packet_rate,
				Dest.packet_percentage = Sou.packet_percentage,
				Dest.rfid_tag = Sou.rfid_tag,
				Dest.is_order_confirmed = Sou.is_order_confirm,
				Dest.is_order_missed = Sou.is_order_missed,
				Dest.order_no = Sou.order_number,
				Dest.sub_order_no = Sou.sub_order_number,
				Dest.transaction_year = @TRNYEAR,
				--Dest.internal_process_id = Sou.i,
			
				Dest.modified_datetime=GETDATE(),
				Dest.inwared_dataetime = GETDATE(),
				Dest.user_code = @USERID,
				Dest.operation_remark = 'Stock Inward',

				Dest.control_number = Sou.lab_control_no,
				Dest.is_fm_eligible = Sou.is_fm_eligible,
				
				Dest.parcel_id = Sou.parcel_id, 
				Dest.invoice_id = Sou.invoice_id, 
				Dest.rough_carat = Sou.rough_carat, 
				Dest.mines_code = Sou.mines_code,
				Dest.mfg_rap_year_month = Sou.rap_year_month,
				Dest.mfg_rap_no = Sou.rap_number

			When Not Matched Then
				INSERT (stoneid, lot_code, serial_number, certificate_code, 
					packet_base_rate, packet_rate, packet_percentage, rfid_tag, is_order_confirmed, is_order_missed,
					order_no, sub_order_no, process_code, inwared_dataetime, 
					user_code,operation_remark,transaction_year, --STONEINWYEAR, 
					control_number,is_fm_eligible, --is_cm_certificate,
					 parcel_id, invoice_id, rough_carat, --M_CARAT,
					mines_code,mfg_rap_year_month, mfg_rap_no)
				VALUES (stoneid, Sou.vendor_lot_code, vendor_serial_no, certificate_code, 
					packet_base_rate, packet_rate, packet_percentage, rfid_tag, is_order_confirm, is_order_missed,
					Sou.order_number, Sou.sub_order_number, process_code, GETDATE(), 
					@USERID,'Stock Inward',@TRNYEAR, --STONEINWYEAR, 
					lab_control_no,is_fm_eligible, --is_cm_certificate,
					 parcel_id, invoice_id, rough_carat, --M_CARAT,
					mines_code,rap_year_month, Sou.rap_number );


			MERGE INTO Packet.STONE_ORIGINAL_LAB_DETAILS AS Dest
			Using(								
				select T.stoneid, T.clarity_code, T.clarity_sign, T.color_code, T.color_sign, T.cut_code, T.polish_code, T.symmetry_code, T.floro_code, 
					T.vendor_lot_code mfg_lot_code, T.vendor_serial_no mfg_serial_number, T.clv_lot_code clv_lot_code, T.clv_serial_number clv_serial_number, T.clv_tag clv_tag
				From Packet.VENDOR_STONE_DETAILS T
					LEFT JOIN Master.ORDER_MASTER Old ON T.order_no > 1000 AND T.order_no = Old.old_order_code
					LEFT JOIN Master.ORDER_MASTER New ON T.order_no < 1000 AND T.order_no = New.order_number AND T.sub_orderno = New.sub_order_number
					LEFT JOIN Master.VENDOR_USER_MASTER VendorUserMast on VendorUserMast.user_code = T.vendor_user_code And T.vendor_code = VendorUserMast.vendor_code
					LEFT JOIN @STONEID stn ON stn.stoneid = T.stoneid
				--Where 1=1 AND T.stoneid IN (Select Value From Dbo.Split(@stoneid_list,','))
				WHERE T.stoneid = stn.stoneid
				And VendorUserMast.is_primary = 1 
				AND ISNULL(T.is_stock_final,0) = 0
				)As Sou On Dest.stoneid = Sou.stoneid
			WHEN MATCHED THEN 
			UPDATE SET
				Dest.clarity_code = Sou.clarity_code, 
				Dest.clarity_sign = Sou.clarity_sign, 
				Dest.color_code = Sou.color_code, 
				Dest.color_sign = Sou.color_sign, 
				Dest.cut_code = Sou.cut_code, 
				Dest.polish_code = Sou.polish_code, 
				Dest.symmetry_code = Sou.symmetry_code, 
				Dest.floro_code = Sou.floro_code, 
				Dest.mfg_lot_code = Sou.mfg_lot_code, 
				Dest.mfg_serial_number = Sou.mfg_serial_number, 
				Dest.clv_lot_code = Sou.clv_lot_code, 
				Dest.clv_serial_number = Sou.clv_serial_number, 
				Dest.clv_tag = Sou.clv_tag
			WHEN NOT MATCHED THEN 
			INSERT (stoneid, clarity_code, clarity_sign, color_code, color_sign, cut_code, polish_code, symmetry_code, floro_code, mfg_lot_code, mfg_serial_number, clv_lot_code, clv_serial_number, clv_tag)
			VALUES (stoneid, clarity_code, clarity_sign, color_code, color_sign, cut_code, polish_code, symmetry_code, floro_code, mfg_lot_code, mfg_serial_number, clv_lot_code, clv_serial_number, clv_tag);

			Merge Into Packet.STONE_LAB_DETAILS  As Dest
			Using(
				Select grd.stoneid, 0 certificate_code, shape_code, issue_carat,
					grd.clarity_code, grd.clarity_sign, grd.color_code, grd.color_sign, certificate_no, cut_code, 
					polish_code, symmetry_code, floro_code, table_white_inclusion_code, 
					grd.table_black_inclusion_code,grd.table_open_inclusion_code, grd.table_spot_inclusion_code, 
					grd.table_extrafacet_code,grd.side_white_inclusion_code,grd.side_black_inclusion_code, 
					grd.side_spot_inclusion_code,grd.crown_open_inclusion_code,
					grd.crown_extrafacet_code,grd.pavilion_open_inclusion_code, 
					grd.pavilion_extrafacet_code,grd.girdle_open_inclusion_code,grd.luster_code,
					grd.culet_code,grd.brown_code,grd.heart_arrow_code,grd.girdle_inclusion_code, 
					grd.is_eye_clean, grd.location_code, grd.diameter_ratio,
					grd.diameter_length, grd.total_depth, grd.tabled,
					grd.height, grd.measurement, grd.crown_angle,grd.pavalion_angle,grd.pavalion_height, grd.star_length,
					grd.lower_half,grd.girdle, grd.from_girdle_code, grd.to_girdle_code, lab_control_no,grd.diameter_width,
					1 is_lab_active, remark
				From Packet.VENDOR_STONE_DETAILS grd
					LEFT JOIN Master.VENDOR_USER_MASTER u ON u.user_code = grd.vendor_user_code AND u.vendor_code = grd.vendor_code
					LEFT JOIN @STONEID stn ON stn.stoneid = grd.stoneid
				Where 1=1
					--AND grd.stoneid IN (Select Value From Dbo.Split(@stoneid_list,','))
					AND stn.stoneid = grd.stoneid
					And u.is_primary = 1 And ISNULL(grd.is_stock_final,0) = 0
				)As Sou On Dest.STONEID = Sou.STONEID And Dest.certificate_code = Sou.certificate_code
			When Matched Then
			Update 
			Set Dest.shape_code = Sou.shape_code,
				Dest.issue_carat = Sou.issue_carat,
				Dest.lab_clarity_code = Sou.clarity_code,
				Dest.lab_clarity_sign = Sou.clarity_sign,
				Dest.lab_color_code = Sou.color_code,
				Dest.lab_color_sign = Sou.color_sign,
				Dest.certificate_no = Sou.certificate_no,
				Dest.cut_code = Sou.cut_code,
				Dest.polish_code = Sou.polish_code,
				Dest.symmetry_code = Sou.symmetry_code,
				Dest.fluorescence_code = Sou.floro_code,
				Dest.table_white_inclusion_code = Sou.table_white_inclusion_code,
				Dest.table_black_inclusion_code = Sou.table_black_inclusion_code,
				Dest.table_open_inclusion_code = Sou.table_open_inclusion_code,
				Dest.table_spot_inclusion_code = Sou.table_spot_inclusion_code,
				Dest.table_extrafacet_code = Sou.table_extrafacet_code,
				Dest.side_white_inclusion_code = Sou.side_white_inclusion_code,
				Dest.side_black_inclusion_code = Sou.side_black_inclusion_code,
				Dest.side_spot_inclusion_code = Sou.side_spot_inclusion_code,
				Dest.crown_open_inclusion_code = Sou.crown_open_inclusion_code,
				Dest.crown_extrafacet_code = Sou.crown_extrafacet_code,
				Dest.pavilion_open_inclusion_code = Sou.pavilion_open_inclusion_code,
				Dest.pavilion_extrafacet_code = Sou.pavilion_extrafacet_code,
				Dest.girdle_open_inclusion_code = Sou.girdle_open_inclusion_code,
				Dest.luster_code = Sou.luster_code,
				Dest.culet_code = Sou.culet_code,
				Dest.brown_code = Sou.brown_code,
				Dest.heart_arrow_code = Sou.heart_arrow_code,
				Dest.girdle_inclusion_code= Sou.girdle_inclusion_code,
				Dest.is_eye_clean = Sou.is_eye_clean,
				Dest.location_code = Sou.location_code,
				Dest.diameter_ratio = Sou.diameter_ratio,
				Dest.diameter_length = Sou.diameter_length,
				Dest.diameter_width = Sou.diameter_width,
				Dest.total_depth = Sou.total_depth,
				Dest.tabled = Sou.tabled,
				Dest.height = Sou.height,
				Dest.measurement = Sou.measurement,
				Dest.crown_angle = Sou.crown_angle,

				Dest.pavalion_angle = Sou.pavalion_angle,
				Dest.pavalion_height = Sou.pavalion_height,
				Dest.star_length = Sou.star_length,
				Dest.lower_half = Sou.lower_half,
				Dest.girdle = Sou.girdle,
				Dest.from_girdle_code = Sou.from_girdle_code,
				Dest.to_girdle_code = Sou.to_girdle_code,
				Dest.control_no = Sou.lab_control_no,

				Dest.modified_datetime = GETDATE(),
				Dest.remark = Sou.remark
						When Not Matched Then
				INSERT (stoneid, certificate_code, shape_code, issue_carat, lab_clarity_code, lab_clarity_sign, lab_color_code,lab_color_sign,certificate_no, cut_code, 
					polish_code, symmetry_code, fluorescence_code, table_white_inclusion_code,table_black_inclusion_code,table_open_inclusion_code,table_spot_inclusion_code,
					 table_extrafacet_code,side_white_inclusion_code,side_black_inclusion_code,side_spot_inclusion_code,crown_open_inclusion_code, 
					crown_extrafacet_code,pavilion_open_inclusion_code,pavilion_extrafacet_code,girdle_open_inclusion_code,luster_code,culet_code,
					brown_code, heart_arrow_code,girdle_inclusion_code,is_eye_clean,diameter_ratio,
					diameter_length, diameter_width, total_depth,tabled,height,measurement, crown_angle, 
					pavalion_angle,pavalion_height,star_length, lower_half, girdle, from_girdle_code,to_girdle_code,control_no, remark)
				VALUES (stoneid, certificate_code, shape_code, issue_carat, Sou.clarity_code, Sou.clarity_sign, Sou.color_code,Sou.color_sign,certificate_no, cut_code, 
					polish_code, symmetry_code, Sou.floro_code, table_white_inclusion_code,table_black_inclusion_code,table_open_inclusion_code,table_spot_inclusion_code,
					 table_extrafacet_code,side_white_inclusion_code,side_black_inclusion_code,side_spot_inclusion_code,crown_open_inclusion_code, 
					crown_extrafacet_code,pavilion_open_inclusion_code,pavilion_extrafacet_code,girdle_open_inclusion_code,luster_code,culet_code,
					brown_code, heart_arrow_code,girdle_inclusion_code,is_eye_clean,diameter_ratio,
					diameter_length, diameter_width, total_depth,tabled,height,measurement, crown_angle, 
					pavalion_angle,pavalion_height,star_length, lower_half, girdle, from_girdle_code,to_girdle_code,Sou.lab_control_no,Sou.remark);

			MERGE Into Packet.STONE_PERCENTAGE As Dest
			Using(
			SELECT grd.stoneid ,grd.VENDOR_CODE ,ISSUE_CARAT_PERCENTAGE ,CUT_POLISH_SYMMENTRY_PERCENTAGE ,TABLE_WHITE_INCLUSION_PERCENTAGE ,SUB_TABLE_WHITE_INCLUSION_PERCENTAGE ,
				LOCATION_TABLE_WHITE_INCLUSION_PERCENTAGE ,TABLE_BLACK_INCLUSION_PERCENTAGE ,SUB_TABLE_BLACK_INCLUSION_PERCENTAGE ,LOCATION_TABLE_BLACK_INCLUSION_PERCENTAGE ,
				TABLE_SPOT_INCLUSION_PERCENTAGE ,SUB_TABLE_SPOT_INCLUSION_PERCENTAGE ,LOCATION_TABLE_SPOT_INCLUSION_PERCENTAGE ,SIDE_WHITE_INCLUSION_PERCENTAGE ,
				SUB_SIDE_WHITE_INCLUSION_PERCENTAGE ,LOCATION_SIDE_WHITE_INCLUSION_PERCENTAGE ,SIDE_SPOT_INCLUSION_PERCENTAGE ,SUB_SIDE_SPOT_INCLUSION_PERCENTAGE ,
				LOCATION_SIDE_SPOT_INCLUSION_PERCENTAGE ,SIDE_BLACK_INCLUSION_PERCENTAGE ,SUB_SIDE_BLACK_INCLUSION_PERCENTAGE ,LOCATION_SIDE_BLACK_INCLUSION_PERCENTAGE ,
				TABLE_OPEN_INCLUSION_PERCENTAGE ,SUB_TABLE_OPEN_INCLUSION_PERCENTAGE ,LOCATION_TABLE_OPEN_INCLUSION_PERCENTAGE ,CROWN_OPEN_INCLUSION_PERCENTAGE ,
				SUB_CROWN_OPEN_INCLUSION_PERCENTAGE ,LOCATION_CROWN_OPEN_INCLUSION_PERCENTAGE ,PAVILION_OPEN_INCLUSION_PERCENTAGE ,SUB_PAVILION_OPEN_INCLUSION_PERCENTAGE ,
				LOCATION_PAVILION_OPEN_INCLUSION_PERCENTAGE ,GIRDLE_OPEN_INCLUSION_PERCENTAGE ,SUB_GIRDLE_OPEN_INCLUSION_PERCENTAGE ,LOCATION_GIRDLE_OPEN_INCLUSION_PERCENTAGE ,
				TABLE_EXTRAFACET_PERCENTAGE ,SUB_TABLE_EXTRAFACET_PERCENTAGE ,LOCATION_TABLE_EXTRAFACET_PERCENTAGE ,CROWN_EXTRAFACET_PERCENTAGE ,SUB_CROWN_EXTRAFACET_PERCENTAGE ,
				LOCATION_CROWN_EXTRAFACET_PERCENTAGE ,PAVILION_EXTRAFACET_PERCENTAGE ,SUB_PAVILION_EXTRAFACET_PERCENTAGE ,LOCATION_PAVILION_EXTRAFACET_PERCENTAGE ,
				BROWN_PERCENTAGE ,SUB_BROWN_PERCENTAGE ,LOCATION_BROWN_PERCENTAGE ,GRAINING_INCLUSION_PERCENTAGE ,SUB_GRAINING_INCLUSION_PERCENTAGE ,LOCATION_GRAINING_INCLUSION_PERCENTAGE ,
				LUSTER_PERCENTAGE ,SUB_LUSTER_PERCENTAGE ,LOCATION_LUSTER_PERCENTAGE ,CULET_PERCENTAGE ,SUB_CULET_PERCENTAGE ,LOCATION_CULET_PERCENTAGE ,GIRDLE_INCLUSION_PERCENTAGE ,
				SUB_GIRDLE_INCLUSION_PERCENTAGE ,LOCATION_GIRDLE_INCLUSION_PERCENTAGE ,HEART_ARROW_PERCENTAGE ,TYPE_INCLUSION_PERCENTAGE ,SUB_TYPE_INCLUSION_PERCENTAGE ,
				LOCATION_TYPE_INCLUSION_PERCENTAGE ,REFLECTION_PERCENTAGE ,DIAMETER_RATIO_PERCENTAGE ,DIAMETER_LENGTH_PERCENTAGE ,DIAMETER_WIDTH_PERCENTAGE ,TOTAL_DEPTH_PERCENTAGE ,
				TABLED_PERCENTAGE ,CROWN_ANGLE_PERCENTAGE ,CROWN_HEIGHT_PERCENTAGE ,PAVALION_ANGLE_PERCENTAGE ,GIRDLE_PERCENTAGE,grd.certificate_code
			FROM Packet.VENDOR_STONE_DETAILS grd
					LEFT JOIN Packet.VENDOR_STONE_PERCENTAGE per ON per.STONEID = grd.stoneid AND per.VENDOR_CODE = grd.vendor_code
					LEFT JOIN Master.VENDOR_USER_MASTER u ON u.vendor_code = grd.vendor_code
					LEFT JOIN @STONEID stn ON stn.stoneid = grd.stoneid
				Where 1=1
					--AND grd.stoneid IN (Select Value From Dbo.Split(@stoneid_list,','))
					AND stn.stoneid = grd.stoneid
					And u.is_primary = 1 And ISNULL(grd.is_stock_final,0) = 0
				)As Sou On Dest.STONEID = Sou.STONEID And Dest.certificate_code = Sou.certificate_code
			When Matched Then
			Update 
			Set Dest.issue_carat_percentage = Sou.issue_carat_percentage,
				Dest.cut_polish_symmentry_percentage= Sou.cut_polish_symmentry_percentage,
				Dest.table_white_inclusion_percentage= Sou.table_white_inclusion_percentage,
				Dest.table_black_inclusion_percentage= Sou.table_black_inclusion_percentage,
				Dest.table_open_inclusion_percentage = Sou.table_open_inclusion_percentage,
				Dest.table_spot_inclusion_percentage = Sou.table_spot_inclusion_percentage,
				Dest.table_extrafacet_percentage = Sou.table_extrafacet_percentage,
				Dest.side_white_inclusion_percentage = Sou.side_white_inclusion_percentage,
				Dest.side_black_inclusion_percentage = Sou.side_black_inclusion_percentage,
				Dest.side_spot_inclusion_percentage = Sou.side_spot_inclusion_percentage,
				Dest.crown_open_inclusion_percentage = Sou.crown_open_inclusion_percentage,
				Dest.crown_extrafacet_percentage = Sou.crown_extrafacet_percentage,
				Dest.pavilion_open_inclusion_percentage = Sou.pavilion_open_inclusion_percentage,
				Dest.pavilion_extrafacet_percentage = Sou.pavilion_extrafacet_percentage,
				Dest.girdle_open_inclusion_percentage = Sou.girdle_open_inclusion_percentage,
				Dest.luster_percentage = Sou.luster_percentage,
				Dest.culet_percentage = Sou.culet_percentage,
				Dest.brown_percentage = Sou.brown_percentage,
				Dest.heart_arrow_percentage = Sou.heart_arrow_percentage,
				Dest.girdle_inclusion_percentage = Sou.girdle_inclusion_percentage,
				Dest.diameter_ratio_percentage = Sou.diameter_ratio_percentage,
				Dest.diameter_length_percentage = Sou.diameter_length_percentage,
				Dest.diameter__width_percentage = Sou.DIAMETER_WIDTH_PERCENTAGE,
				Dest.total_depth_percentage = Sou.total_depth_percentage,
				Dest.tabled_percentage = Sou.tabled_percentage,
				Dest.crown_angle_percentage = Sou.crown_angle_percentage,
				Dest.pavalion_angle_percentage = Sou.pavalion_angle_percentage,
				Dest.girdle_percentage = Sou.girdle_percentage
				WHEN NOT MATCHED
				THEN
				INSERT (STONEID ,ISSUE_CARAT_PERCENTAGE ,CUT_POLISH_SYMMENTRY_PERCENTAGE ,TABLE_WHITE_INCLUSION_PERCENTAGE ,SUB_TABLE_WHITE_INCLUSION_PERCENTAGE ,
					LOCATION_TABLE_WHITE_INCLUSION_PERCENTAGE ,TABLE_BLACK_INCLUSION_PERCENTAGE ,SUB_TABLE_BLACK_INCLUSION_PERCENTAGE ,LOCATION_TABLE_BLACK_INCLUSION_PERCENTAGE ,
					TABLE_SPOT_INCLUSION_PERCENTAGE ,SUB_TABLE_SPOT_INCLUSION_PERCENTAGE ,LOCATION_TABLE_SPOT_INCLUSION_PERCENTAGE ,SIDE_WHITE_INCLUSION_PERCENTAGE ,
					SUB_SIDE_WHITE_INCLUSION_PERCENTAGE ,LOCATION_SIDE_WHITE_INCLUSION_PERCENTAGE ,SIDE_SPOT_INCLUSION_PERCENTAGE ,SUB_SIDE_SPOT_INCLUSION_PERCENTAGE ,
					LOCATION_SIDE_SPOT_INCLUSION_PERCENTAGE ,SIDE_BLACK_INCLUSION_PERCENTAGE ,SUB_SIDE_BLACK_INCLUSION_PERCENTAGE ,LOCATION_SIDE_BLACK_INCLUSION_PERCENTAGE ,
					TABLE_OPEN_INCLUSION_PERCENTAGE ,SUB_TABLE_OPEN_INCLUSION_PERCENTAGE ,LOCATION_TABLE_OPEN_INCLUSION_PERCENTAGE ,CROWN_OPEN_INCLUSION_PERCENTAGE ,
					SUB_CROWN_OPEN_INCLUSION_PERCENTAGE ,LOCATION_CROWN_OPEN_INCLUSION_PERCENTAGE ,PAVILION_OPEN_INCLUSION_PERCENTAGE ,SUB_PAVILION_OPEN_INCLUSION_PERCENTAGE ,
					LOCATION_PAVILION_OPEN_INCLUSION_PERCENTAGE ,GIRDLE_OPEN_INCLUSION_PERCENTAGE ,SUB_GIRDLE_OPEN_INCLUSION_PERCENTAGE ,LOCATION_GIRDLE_OPEN_INCLUSION_PERCENTAGE ,
					TABLE_EXTRAFACET_PERCENTAGE ,SUB_TABLE_EXTRAFACET_PERCENTAGE ,LOCATION_TABLE_EXTRAFACET_PERCENTAGE ,CROWN_EXTRAFACET_PERCENTAGE ,SUB_CROWN_EXTRAFACET_PERCENTAGE ,
					LOCATION_CROWN_EXTRAFACET_PERCENTAGE ,PAVILION_EXTRAFACET_PERCENTAGE ,SUB_PAVILION_EXTRAFACET_PERCENTAGE ,LOCATION_PAVILION_EXTRAFACET_PERCENTAGE ,
					BROWN_PERCENTAGE ,SUB_BROWN_PERCENTAGE ,LOCATION_BROWN_PERCENTAGE ,GRAINING_INCLUSION_PERCENTAGE ,SUB_GRAINING_INCLUSION_PERCENTAGE ,LOCATION_GRAINING_INCLUSION_PERCENTAGE ,
					LUSTER_PERCENTAGE ,SUB_LUSTER_PERCENTAGE ,LOCATION_LUSTER_PERCENTAGE ,CULET_PERCENTAGE ,SUB_CULET_PERCENTAGE ,LOCATION_CULET_PERCENTAGE ,GIRDLE_INCLUSION_PERCENTAGE ,
					SUB_GIRDLE_INCLUSION_PERCENTAGE ,LOCATION_GIRDLE_INCLUSION_PERCENTAGE ,HEART_ARROW_PERCENTAGE ,TYPE_INCLUSION_PERCENTAGE ,SUB_TYPE_INCLUSION_PERCENTAGE ,
					LOCATION_TYPE_INCLUSION_PERCENTAGE ,REFLECTION_PERCENTAGE ,DIAMETER_RATIO_PERCENTAGE ,DIAMETER_LENGTH_PERCENTAGE ,diameter__width_percentage ,TOTAL_DEPTH_PERCENTAGE ,
					TABLED_PERCENTAGE ,CROWN_ANGLE_PERCENTAGE ,CROWN_HEIGHT_PERCENTAGE ,PAVALION_ANGLE_PERCENTAGE ,GIRDLE_PERCENTAGE )
				VALUES	(STONEID ,ISSUE_CARAT_PERCENTAGE ,CUT_POLISH_SYMMENTRY_PERCENTAGE ,TABLE_WHITE_INCLUSION_PERCENTAGE ,SUB_TABLE_WHITE_INCLUSION_PERCENTAGE ,
					LOCATION_TABLE_WHITE_INCLUSION_PERCENTAGE ,TABLE_BLACK_INCLUSION_PERCENTAGE ,SUB_TABLE_BLACK_INCLUSION_PERCENTAGE ,LOCATION_TABLE_BLACK_INCLUSION_PERCENTAGE ,
					TABLE_SPOT_INCLUSION_PERCENTAGE ,SUB_TABLE_SPOT_INCLUSION_PERCENTAGE ,LOCATION_TABLE_SPOT_INCLUSION_PERCENTAGE ,SIDE_WHITE_INCLUSION_PERCENTAGE ,
					SUB_SIDE_WHITE_INCLUSION_PERCENTAGE ,LOCATION_SIDE_WHITE_INCLUSION_PERCENTAGE ,SIDE_SPOT_INCLUSION_PERCENTAGE ,SUB_SIDE_SPOT_INCLUSION_PERCENTAGE ,
					LOCATION_SIDE_SPOT_INCLUSION_PERCENTAGE ,SIDE_BLACK_INCLUSION_PERCENTAGE ,SUB_SIDE_BLACK_INCLUSION_PERCENTAGE ,LOCATION_SIDE_BLACK_INCLUSION_PERCENTAGE ,
					TABLE_OPEN_INCLUSION_PERCENTAGE ,SUB_TABLE_OPEN_INCLUSION_PERCENTAGE ,LOCATION_TABLE_OPEN_INCLUSION_PERCENTAGE ,CROWN_OPEN_INCLUSION_PERCENTAGE ,
					SUB_CROWN_OPEN_INCLUSION_PERCENTAGE ,LOCATION_CROWN_OPEN_INCLUSION_PERCENTAGE ,PAVILION_OPEN_INCLUSION_PERCENTAGE ,SUB_PAVILION_OPEN_INCLUSION_PERCENTAGE ,
					LOCATION_PAVILION_OPEN_INCLUSION_PERCENTAGE ,GIRDLE_OPEN_INCLUSION_PERCENTAGE ,SUB_GIRDLE_OPEN_INCLUSION_PERCENTAGE ,LOCATION_GIRDLE_OPEN_INCLUSION_PERCENTAGE ,
					TABLE_EXTRAFACET_PERCENTAGE ,SUB_TABLE_EXTRAFACET_PERCENTAGE ,LOCATION_TABLE_EXTRAFACET_PERCENTAGE ,CROWN_EXTRAFACET_PERCENTAGE ,SUB_CROWN_EXTRAFACET_PERCENTAGE ,
					LOCATION_CROWN_EXTRAFACET_PERCENTAGE ,PAVILION_EXTRAFACET_PERCENTAGE ,SUB_PAVILION_EXTRAFACET_PERCENTAGE ,LOCATION_PAVILION_EXTRAFACET_PERCENTAGE ,
					BROWN_PERCENTAGE ,SUB_BROWN_PERCENTAGE ,LOCATION_BROWN_PERCENTAGE ,GRAINING_INCLUSION_PERCENTAGE ,SUB_GRAINING_INCLUSION_PERCENTAGE ,LOCATION_GRAINING_INCLUSION_PERCENTAGE ,
					LUSTER_PERCENTAGE ,SUB_LUSTER_PERCENTAGE ,LOCATION_LUSTER_PERCENTAGE ,CULET_PERCENTAGE ,SUB_CULET_PERCENTAGE ,LOCATION_CULET_PERCENTAGE ,GIRDLE_INCLUSION_PERCENTAGE ,
					SUB_GIRDLE_INCLUSION_PERCENTAGE ,LOCATION_GIRDLE_INCLUSION_PERCENTAGE ,HEART_ARROW_PERCENTAGE ,TYPE_INCLUSION_PERCENTAGE ,SUB_TYPE_INCLUSION_PERCENTAGE ,
					LOCATION_TYPE_INCLUSION_PERCENTAGE ,REFLECTION_PERCENTAGE ,DIAMETER_RATIO_PERCENTAGE ,DIAMETER_LENGTH_PERCENTAGE ,DIAMETER_WIDTH_PERCENTAGE ,TOTAL_DEPTH_PERCENTAGE ,
					TABLED_PERCENTAGE ,CROWN_ANGLE_PERCENTAGE ,CROWN_HEIGHT_PERCENTAGE ,PAVALION_ANGLE_PERCENTAGE ,GIRDLE_PERCENTAGE );
			




	--		--// Update TRNRATEMAST Table
			MERGE Into Packet.STONE_RATES As Dest
			Using(
				Select grd.stoneid, dollar_rate, dollar_percentage, grd.packet_base_rate, packet_rate, packet_percentage, cost_rate , cost_perercentage, system_rate, 
					system_percentage, order_no,grd.original_rate,grd.original_percentage
				From Packet.VENDOR_STONE_DETAILS grd
				LEFT JOIN Master.VENDOR_USER_MASTER u ON u.user_code = grd.vendor_user_code AND u.vendor_code = grd.vendor_code
				LEFT JOIN @STONEID stn ON stn.stoneid = grd.stoneid
				--Where stoneid IN (Select Value From Dbo.Split(@stoneid_list,','))
					AND u.is_primary = 1 And ISNULL(grd.is_stock_final,0) = 0
					
				)As Sou On Sou.stoneid = Dest.stoneid
			When Matched Then
			Update 
			Set 
				Dest.rap_cost_rate = Sou.dollar_rate,
				Dest.rap_cost_percentage = Sou.dollar_percentage,
				Dest.mfg_rate = Sou.dollar_rate,
				Dest.mfg_percentage = Sou.dollar_percentage,
				Dest.cost_rate= Sou.cost_rate,
				Dest.cost_percentage = Sou.cost_perercentage,
				Dest.packet_rap_rate = Sou.packet_base_rate,
				Dest.new_packet_rap_rate = Sou.packet_base_rate,
				Dest.system_rate = Sou.system_rate,
				Dest.system_percentage = Sou.system_percentage,
				Dest.packet_rate = Sou.packet_rate,
				Dest.packet_percentage= Sou.packet_percentage,
				--Dest.given_original_rate = Sou.given_original_rate,
				--Dest.given_original_percentage = Sou.given_original_percentage,
				Dest.original_rate = Sou.original_rate,
				Dest.original_percentage = Sou.original_percentage,
				Dest.is_packet_rate_lock = (CASE WHEN (ISNULL(Sou.order_no,0) = 0) THEN Dest.is_packet_rate_lock ELSE 1 END),
			
				Dest.operation_remark = 'Stock Inward',
				Dest.modified_datetime=GETDATE()
				
			When Not Matched Then
				INSERT (stoneid, rap_cost_rate, rap_cost_percentage, mfg_rate, mfg_percentage, cost_rate, cost_percentage,
				packet_rap_rate, system_rate,system_percentage,packet_rate, packet_percentage, operation_remark, is_packet_rate_lock)
				VALUES (Sou.stoneid, Sou.dollar_rate, Sou.dollar_percentage, Sou.dollar_rate, Sou.dollar_percentage, Sou.cost_rate, Sou.cost_perercentage, 
					Sou.packet_base_rate, Sou.system_rate, Sou.system_percentage, Sou.packet_rate, Sou.packet_percentage, 'Stock Inward', 
					CASE WHEN (ISNULL(Sou.order_no,0) = 0) THEN 0 ELSE 1 END);
		
	--		--// Update TRNFILEMAST Table
			--MERGE Into Packet.STONE_FILES As Dest
			--Using(
			--	Select STONEID
			--	From Packet.VENDOR_STONE_DETAILS grd
			--	LEFT JOIN Master.VENDOR_USER_MASTER u ON u.user_code = grd.vendor_user_code AND u.vendor_code = grd.vendor_code
			--	Where stoneid IN (Select Value From Dbo.Split(@stoneid_list,','))
			--		AND u.is_primary = 1 And ISNULL(grd.is_stock_final,0) = 0
			--	)As Sou On Sou.STONEID = Dest.STONEID
			--When Not Matched Then
			--	INSERT (STONEID, ISPHOTOAVAIL, ISCERTAVAIL, ISHAFILEAVAIL, ISHDMOVIEAVAIL, ISHDMOVIENAME, ISSARINFILEAVAIL, ISHELIUMFILEAVAIL, ISDNAFILEAVAIL, OPEREMARK, ENTRYDATETIME, USERID, COMPUTERID, FORMID)
			--	VALUES (STONEID, 0, 0, 0, 0, '', 0, 0, 0, 'StockInward', GETDATE(), @UserId,@ComputerId,@FormId);
		

	--		--// Update TRNFILEMAST Table
			--MERGE Into TRNLABRESULT As Dest
			--Using(
			--		Select TGrd.stoneid, 0 certificate_code, 
			--			TGrd.issue_carat,
			--			Shp.shape_short_name, Qua.clarity_short_name, Col.color_short_name,
			--			Cut.cut_short_name,
			--			Sym.symmetry_short_name,
			--			Pol.polish_short_name
			--		From Packet.VENDOR_STONE_DETAILS TGrd
			--		LEFT JOIN Master.SHAPE_MASTER Shp ON TGrd.shape_code = Shp.shape_code
			--		LEFT JOIN Master.CLARITY_MASTER Qua ON TGrd.clarity_code = Qua.clarity_code
			--		LEFT JOIN Master.COLOR_MASTER Col ON TGrd.color_code = COl.color_code
			--		LEFT JOIN Master.CUT_MASTER Cut ON TGrd.cut_code = Cut.cut_code
			--		LEFT JOIN Master.POLISH_MASTER Pol ON TGrd.polish_code = Pol.polish_code
			--		LEFT JOIN Master.SYMMETRY_MASTER Sym ON TGrd.symmetry_code = Sym.symmetry_code
			--		LEFT JOIN Master.VENDOR_USER_MASTER u ON u.user_code = grd.vendor_user_code AND u.vendor_code = grd.vendor_code
			--		Where stoneid IN (Select Value From Dbo.Split(@stoneid_list,','))
			--		AND u.is_primary = 1 And ISNULL(grd.is_stock_final,0) = 0
			--	)As Sou On Sou.STONEID = Dest.STONEID AND Sou.CR_CODE = Dest.CR_CODE
	--		When Not Matched Then
	--			INSERT (STONEID, CR_CODE, WEIGHT, SHAPE, CLARITY, COLOR, FINAL_CUT, SYMMETRY, POLISH, ENTRYUSERID, COMPUTERID)
	--			VALUES (STONEID, CR_CODE, WEIGHT, SHAPE, CLARITY, COLOR, FINAL_CUT, SYMMETRY, POLISH, @USERID, @COMPUTERID);

	--		--// Update LOTMAST Table
			MERGE Into Master.LOT_MASTER As Dest
			Using(
					SELECT DISTINCT grd.vendor_lot_code
					FROM Packet.VENDOR_STONE_DETAILS grd
					LEFT JOIN Master.VENDOR_USER_MASTER u ON u.user_code = grd.vendor_user_code AND u.vendor_code = grd.vendor_code
					LEFT JOIN @STONEID stn ON stn.stoneid = grd.stoneid
					--WHERE stoneid IN (Select Value From Dbo.Split(@stoneid_list,','))
					AND u.is_primary = 1 And ISNULL(grd.is_stock_final,0) = 0
					AND stn.stoneid = grd.stoneid
				)As Sou On Sou.vendor_lot_code = Dest.LOT_CODE
			When Not Matched Then
				INSERT (LOT_CODE, LOT_DATE, IS_REGULAR)
				VALUES (Sou.vendor_lot_code, GETDATE(), (CASE WHEN Sou.vendor_lot_code NOT LIKE 'Z%' THEN 1 ELSE 0 END));

			Update  ven
			Set is_stock_inward = 1, inward_datetime = GETDATE(), is_grading_verify = 1
			FROM Packet.VENDOR_STONE_DETAILS ven
			LEFT JOIN @STONEID stn ON stn.stoneid = ven.stoneid
			--Where STONEID IN (Select Value From Dbo.Split(@stoneid_list,',')) 
				AND  is_stock_inward = 0 
				AND ISNULL(is_stock_final,0) = 0
				AND stn.stoneid = ven.stoneid

	--		-- this update must be after TRNGRDMAST update flag ISSTOCKINWARD
			MERGE INTO Stock.VENDOR_STOCK_SUMMARY AS Dest
			USING(
				SELECT T.vendor_group_number, CONVERT(DATE,GETDATE()) inward_date, T.vendor_lot_code, 
					DENSE_RANK() OVER (ORDER BY T.vendor_exportdatetime) vendor_exportdatetime,
					COUNT(T.stoneid) pcs,
					SUM(T.issue_carat) carat,dept.department_code
				FROM Packet.VENDOR_STONE_DETAILS T
				LEFT JOIN Stock.VENDOR_STOCK_SUMMARY N ON CONVERT(DATE,T.inward_datetime) = N.inward_date AND T.vendor_lot_code = N.lot_code AND T.vendor_group_number = N.vendor_group_number
				LEFT JOIN Master.VENDOR_USER_MASTER u ON u.user_code = T.vendor_user_code AND u.vendor_code = T.vendor_code
				LEFT JOIN Master.STONE_DEPARTMENT_MASTER dept ON size_type_key = 'STKACC' AND dept.department_date = @department_date
				LEFT JOIN @INWARD_MFG_DATA mfg ON  CONVERT(DATE,MFG.export_datetime) = CONVERT(DATE,t.inward_datetime) 
					AND MFG.group_number = T.vendor_group_number
				WHERE 1=1 
				AND u.is_primary = 1
				AND T.vendor_lot_code NOT LIKE 'Z%'
				AND ISNULL(N.is_account_transfer,0) = 0
				AND T.is_stock_inward = 1
				AND T.vendor_exportdatetime = mfg.export_datetime
				AND T.vendor_group_number = mfg.group_number
			GROUP BY T.vendor_group_number, T.vendor_lot_code, vendor_exportdatetime,dept.department_code
			)AS Sou ON Sou.vendor_group_number = Dest.vendor_group_number
				AND Sou.inward_date = Dest.inward_date
				AND Sou.vendor_lot_code = Dest.lot_code
				
			WHEN MATCHED THEN
			UPDATE 
			SET Dest.department_code = Sou.department_code,
				
				Dest.issue_pcs = Sou.pcs,
				Dest.issue_carat = Sou.carat,
				Dest.modified_datetime=GETDATE(),
				Dest.inward_year = @TRNYEAR

	WHEN NOT MATCHED THEN
				INSERT (vendor_group_number, inward_date, lot_code,department_code,issue_pcs, issue_carat, inward_year, inward_time)
				VALUES (vendor_group_number, inward_date, Sou.vendor_lot_code,Sou.department_code, Sou.pcs,Sou.carat, @TRNYEAR, GETDATE());

	
END	

GO

/****** Object:  StoredProcedure [Stock].[usp_InwardMfg_Verify_Update]    Script Date: 06/02/2018 2:20:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Ritesh Khatri
-- Create date: 21/01/2018
-- Description:	Use to Work on Mfg Inward Update Data 
-- =============================================
CREATE PROCEDURE [Stock].[usp_InwardMfg_Verify_Update]
@stoneid AS Stock.STONEID READONLY,
@modified_by SMALLINT,
@modified_iplocation_id INT
AS
BEGIN
	UPDATE VendorStone
	SET VendorStone.is_stock_inward = 1, 
		VendorStone.inward_datetime = Master.Fn_GetISTDATETIME(), 
		VendorStone.is_grading_verify = 1,
		VendorStone.modified_datetime = Master.Fn_GetISTDATETIME(),
		VendorStone.modified_by = @modified_by,
		VendorStone.modified_iplocation_id = @modified_iplocation_id, 
		VendorStone.operemark = 'VERIFY'
	FROM Packet.VENDOR_STONE_DETAILS VendorStone
	LEFT JOIN Master.VENDOR_USER_MASTER VendorUserMast ON VendorUserMast.user_code = VendorStone.vendor_user_code AND VendorStone.vendor_code = VendorUserMast.vendor_code
	LEFT JOIN @stoneid stone ON stone.stoneid = VendorStone.stoneid
	WHERE VendorUserMast.is_primary = 1
		AND stone.stoneid = VendorStone.stoneid
	--And VendorStone.stoneid in (select value from dbo.Split(@stoneid,','))
END

GO


