
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Master].[INCLUSION_MASTER](
	[INCLUSION_CODE] [INT] NOT NULL IDENTITY(1, 1),
	[INCLUSION_TYPE_CODE] [tinyint] NOT NULL,
	[INCLUSION_NAME] [varchar](128) NULL,
	[INCLUSION_SHORT_NAME] [varchar](16) NULL,
	[DISPLAY_ORDER] [tinyint] NULL,
	[IS_ACTIVE] [bit] NULL,
	[IS_RAP_ACTIVE] [bit] NULL,
	[APPS_CODE] [tinyint] NULL,
	[CREATED_DATETIME] [datetime] NULL,
	[CREATED_BY] [smallint] NULL,
	[CREATED_IPLOCATION_ID] [int] NULL,
	[MODIFIED_DATETIME] [datetime] NULL,
	[MODIFIED_BY] [smallint] NULL,
	[MODIFIED_IPLOCATION_ID] [int] NULL,
	[ROW_VERSION] [timestamp] NOT NULL,
	[DATA_VERSION] [bigint] NULL,
 CONSTRAINT [PK_INCLUSION_MASTER] PRIMARY KEY CLUSTERED 
(
	[INCLUSION_CODE] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO

ALTER TABLE [Master].[INCLUSION_MASTER] ADD  CONSTRAINT [DF_INCLUSION_MASTER_IS_ACTIVE]  DEFAULT ((0)) FOR [IS_ACTIVE]
GO

ALTER TABLE [Master].[INCLUSION_MASTER] ADD  CONSTRAINT [DF_INCLUSION_MASTER_CREATED_DATETIME]  DEFAULT ([Master].[Fn_GetISTDATETIME]()) FOR [CREATED_DATETIME]
GO

ALTER TABLE [Master].[INCLUSION_MASTER] ADD  DEFAULT ((0)) FOR [DATA_VERSION]
GO


ALTER TABLE [Master].[INCLUSION_MASTER]  WITH CHECK ADD  CONSTRAINT [FK_INCLUSION_MASTER_INCLUSION_TYPE_MASTER] FOREIGN KEY([INCLUSION_TYPE_CODE])
REFERENCES [Master].[INCLUSION_TYPE_MASTER] ([INCLUSION_TYPE_CODE])
GO

ALTER TABLE [Master].[INCLUSION_MASTER] CHECK CONSTRAINT [FK_INCLUSION_MASTER_INCLUSION_TYPE_MASTER]
GO



EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Inclution Master Feather Major' , @level0type=N'SCHEMA',@level0name=N'Master', @level1type=N'TABLE',@level1name=N'INCLUSION_MASTER'
GO

