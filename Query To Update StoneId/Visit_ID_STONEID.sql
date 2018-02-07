USE [srk_db]
GO

/****** Object:  UserDefinedTableType [Stock].[VISIT_ID_STONEID]    Script Date: 06/02/2018 1:57:54 PM ******/
DROP TYPE [Stock].[VISIT_ID_STONEID]
GO

/****** Object:  UserDefinedTableType [Stock].[VISIT_ID_STONEID]    Script Date: 06/02/2018 1:57:55 PM ******/
CREATE TYPE [Stock].[VISIT_ID_STONEID] AS TABLE(
	[visit_id] [INT] NULL,
	[stoneid] [VARCHAR](16) NULL
)
GO


