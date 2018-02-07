

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Packet].[TRN_PROCESS_MASTER](
	[PROCESS_ID] BIGINT NOT NULL IDENTITY(1, 1),
	[STONEID] VARCHAR(16) NOT NULL,
	[FROM_DEPARTMENT_CODE] TINYINT NOT NULL,
	[TO_DEPARTMENT_CODE] TINYINT NOT NULL,
	[PROCESS_ISSUE_DATE] DATE NOT NULL,
	[PROCESS_ISSUE_TIME] TIME NOT NULL,
	[PROCESS_CONFIRM_DATE] DATE NULL,
	[PROCESS_CONFIRM_TIME] TIME NULL,
	[PROCESS_MEMO_NO] SMALLINT,
	[REMARK] VARCHAR(512),
	[VIEWREQUEST_ID] BIGINT,
	[STONE_PROCESS_CODE] TINYINT NOT NULL,
	[PROCESS_ISSUE_USER_CODE] SMALLINT NOT NULL,
	[PROCESS_CONFIRM_USER_CODE] SMALLINT NOT NULL,
	[PROCESS_ISSUE_IPLOCATION_ID]	INT NOT NULL,
	[PROCESS_CONFIRM_IPLOCATION_ID] INT NOT NULL,
	[APPS_CODE] [tinyint] NULL,
	[CREATED_DATETIME] [datetime] NULL,
	[CREATED_BY] [smallint] NULL,
	[CREATED_IPLOCATION_ID] [int] NULL,
	[MODIFIED_DATETIME] [datetime] NULL,
	[MODIFIED_BY] [smallint] NULL,
	[MODIFIED_IPLOCATION_ID] [int] NULL,
	[ROW_VERSION] [timestamp] NOT NULL,
	[DATA_VERSION] [bigint] NULL,
 CONSTRAINT [PK_TRN_PROCESS_MASTER] PRIMARY KEY CLUSTERED 
(
	[PROCESS_ID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO

ALTER TABLE [Packet].[TRN_PROCESS_MASTER] ADD  CONSTRAINT [DF_TRN_PROCESS_MASTER_CREATED_DATETIME]  DEFAULT ([Master].[Fn_GetISTDATETIME]()) FOR [CREATED_DATETIME]
GO

ALTER TABLE [Packet].[TRN_PROCESS_MASTER] ADD  DEFAULT ((0)) FOR [DATA_VERSION]
GO

ALTER TABLE [Packet].[TRN_PROCESS_MASTER] ADD CONSTRAINT [FK_TRN_PROCESS_MASTER_FROM_DEPARTMENT_MASTER] FOREIGN KEY ([FROM_DEPARTMENT_CODE]) REFERENCES [Master].[DEPARTMENT_MASTER] ([DEPARTMENT_CODE])
GO

ALTER TABLE [Packet].[TRN_PROCESS_MASTER] ADD CONSTRAINT [FK_TRN_PROCESS_MASTER_TO_DEPARTMENT_MASTER] FOREIGN KEY ([TO_DEPARTMENT_CODE]) REFERENCES [Master].[DEPARTMENT_MASTER] ([DEPARTMENT_CODE])
GO

ALTER TABLE [Packet].[TRN_PROCESS_MASTER] ADD CONSTRAINT [FK_TRN_PROCESS_MASTER_ISSUE_USER_MASTER] FOREIGN KEY ([PROCESS_ISSUE_USER_CODE]) REFERENCES [Master].[USER_MASTER] ([USER_CODE])
GO

ALTER TABLE [Packet].[TRN_PROCESS_MASTER] ADD CONSTRAINT [FK_TRN_PROCESS_MASTER_CONFIRM_USER_MASTER] FOREIGN KEY ([PROCESS_CONFIRM_USER_CODE]) REFERENCES [Master].[USER_MASTER] ([USER_CODE])
GO

ALTER TABLE [Packet].[TRN_PROCESS_MASTER] ADD CONSTRAINT [FK_TRN_PROCESS_MASTER_ISSUE_IPLOCATION_MASTER] FOREIGN KEY ([PROCESS_ISSUE_IPLOCATION_ID]) REFERENCES [Master].[IPLOCATION_MASTER] ([IPLOCATION_ID])
GO

ALTER TABLE [Packet].[TRN_PROCESS_MASTER] ADD CONSTRAINT [FK_TRN_PROCESS_MASTER_CONFIRM_IPLOCATION_MASTER] FOREIGN KEY ([PROCESS_CONFIRM_IPLOCATION_ID]) REFERENCES [Master].[IPLOCATION_MASTER] ([IPLOCATION_ID])
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Department to Department Transfer Entry' , @level0type=N'SCHEMA',@level0name=N'Packet', @level1type=N'TABLE',@level1name=N'TRN_PROCESS_MASTER'
GO

