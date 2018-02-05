DROP TABLE [Packet].[INTERNAL_PROCESS_MASTER]
GO

CREATE TABLE [Packet].[INTERNAL_PROCESS_MASTER]
(
	[process_id] [bigint] not null identity(1, 1),
	[memo_date] [date] not null,
	[memo_no] [int] not null,
	[stoneid] varchar(16) not null,
	[from_department_code] tinyint,
	[to_department_code] tinyint,
	[viewrequest_process_code] tinyint,
	[apps_code] [tinyint] null,
	[created_datetime] [datetime] null constraint [df_internal_process_master_created_datetime] default ([master].[fn_getistdatetime]()),
	[created_by] [smallint] null,
	[created_iplocation_id] [int] null,
	[modified_datetime] [datetime] null,
	[modified_by] [smallint] null,
	[modified_iplocation_id] [int] null,
	[row_version] [timestamp] not null,
	[data_version] [bigint] null constraint [df_internal_process_master_data_version] default ((0))
) ON [PRIMARY]
GO
ALTER TABLE [Packet].[INTERNAL_PROCESS_MASTER] ADD CONSTRAINT [FK_INTERNAL_PROCESS_MASTER_VIEWREQUEST_PROCESS_MASTER] FOREIGN KEY ([VIEWREQUEST_PROCESS_CODE]) REFERENCES [Master].[VIEWREQUEST_PROCESS_MASTER] ([PROCESS_CODE])
GO
ALTER TABLE [Packet].[INTERNAL_PROCESS_MASTER] ADD CONSTRAINT [FK_INTERNAL_PROCESS_MASTER_FROMDEPARTMENT_CODE_DEPARTMENT_MASTER] FOREIGN KEY ([FROM_DEPARTMENT_CODE]) REFERENCES [Master].[DEPARTMENT_MASTER] ([DEPARTMENT_CODE])
GO
ALTER TABLE [Packet].[INTERNAL_PROCESS_MASTER] ADD CONSTRAINT [FK_INTERNAL_PROCESS_MASTER_TO_CODE_DEPARTMENT_MASTER] FOREIGN KEY ([TO_DEPARTMENT_CODE]) REFERENCES [Master].[DEPARTMENT_MASTER] ([DEPARTMENT_CODE])
GO
ALTER TABLE [Packet].[INTERNAL_PROCESS_MASTER] ADD CONSTRAINT [FK_INTERNAL_PROCESS_MASTER_VIEWREQUEST_PROCESS_MASTER] FOREIGN KEY ([VIEWREQUEST_PROCESS_CODE]) REFERENCES [Master].[VIEWREQUEST_PROCESS_MASTER] ([PROCESS_CODE])
GO
ALTER TABLE [Packet].[INTERNAL_PROCESS_MASTER] ADD CONSTRAINT [FK_INTERNAL_PROCESS_MASTER_STONE_DETAILS] FOREIGN KEY ([STONEID]) REFERENCES [Packet].[STONE_DETAILS] ([STONEID])
GO

ALTER TABLE [Packet].[INTERNAL_PROCESS_MASTER] ADD CONSTRAINT [PK_INTERNAL_PROCESS_MASTER] PRIMARY KEY CLUSTERED ([PROCESS_ID])
EXEC sp_addextendedproperty N'MS_Description', N'Employee Transfer Entry With in Inner Department', 'SCHEMA', N'Packet', 'TABLE', N'INTERNAL_PROCESS_MASTER', NULL, NULL
GO

