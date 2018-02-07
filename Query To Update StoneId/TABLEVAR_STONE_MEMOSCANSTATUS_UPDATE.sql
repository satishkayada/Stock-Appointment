USE [srk_db]
GO

/****** Object:  UserDefinedTableType [Stock].[TABLEVAR_STONE_MEMOSCANSTATUS_UPDATE]    Script Date: 06/02/2018 1:54:35 PM ******/
CREATE TYPE [Stock].[TABLEVAR_STONE_MEMOSCANSTATUS_UPDATE] AS TABLE(
	[memo_date] [DATE] NULL,
	[memo_number] [INT] NULL,
	[stoneid] bigint NULL,
	[is_barcode_verify] [BIT] NULL,
	[is_rfid_verify] [BIT] NULL
)
GO


