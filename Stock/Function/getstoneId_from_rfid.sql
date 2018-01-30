USE [srk_db]
GO

/****** Object:  UserDefinedFunction [Stock].[get_stoneid_from_rfd]    Script Date: 30/01/2018 12:25:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [Stock].[get_stoneid_from_rfd](@stoneId stock.STONEID READONLY)
RETURNS @RtnValue TABLE (
							STONEID VARCHAR(16)
				         )
AS
BEGIN
	INSERT INTO @RtnValue
	        ( STONEID )
	SELECT STONEID
	FROM Packet.STONE_DETAILS
	WHERE rfid_tag IN (SELECT STONEID FROM @StoneId)
	RETURN
END

GO


