USE [srk_db]
GO

/****** Object:  UserDefinedFunction [Packet].[usp_fn_outward_InternalStock_StoneReceive_Check]    Script Date: 06/02/2018 2:14:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create FUNCTION [Packet].[usp_fn_outward_InternalStock_StoneReceive_Check]
(
	@stoneid_list AS Stock.STONEID READONLY,
	@department_code SMALLINT
)
RETURNS VARCHAR(512)
AS
BEGIN 
	
	IF NOT EXISTS (SELECT 1 FROM Packet.STONE_PROCESSES WHERE stoneid IN (SELECT stoneid FROM @stoneid_list))
	BEGIN
		RETURN 'Jangad Not Found'
	END	
	
	IF EXISTS (SELECT 1 FROM Packet.STONE_PROCESSES WHERE stoneid IN (SELECT stoneid FROM @stoneid_list) AND process_issue_date IS NOT NULL AND process_confirm_date IS NOT NULL)
	BEGIN
		RETURN 'Jangad Is Confirm. You Can''t Delete Jangad.'
	END
	
	IF NOT EXISTS (SELECT 1 FROM Packet.STONE_PROCESSES WHERE stoneid IN (SELECT stoneid FROM @stoneid_list) AND from_department_code = @department_code)
	BEGIN
		RETURN 'It Is Not Your Jangad'
	END
	
	RETURN ''
END

GO


