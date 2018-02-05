USE [srk_db]
GO

/****** Object:  Table [Packet].[VENDOR_STONE_PERCENTAGE]    Script Date: 15/01/2018 10:19:57 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP TABLE packet.VENDOR_STONE_PERCENTAGE
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [Packet].[VENDOR_STONE_PERCENTAGE](
	[PACKET_ID] [BIGINT] IDENTITY(1,1) NOT NULL,
	[STONEID] [VARCHAR](16) NOT NULL,
	[ISSUE_CARAT_PERCENTAGE] numeric(8,2) null,
	[CUT_POLISH_SYMMENTRY_PERCENTAGE] numeric(8,2) null,

	[INCLUSION_PERCENTAGE1] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE2] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE3] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE4] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE5] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE6] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE7] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE8] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE9] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE10] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE11] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE12] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE13] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE14] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE15] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE16] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE17] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE18] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE19] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE20] NUMERIC(8,2) NULL,

	[INCLUSION_PERCENTAGE_LIST1]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST2]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST3]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST4]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST5]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST6]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST7]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST8]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST9]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST10] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST11] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST12] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST13] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST14] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST15] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST16] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST17] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST18] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST19] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LIST20] Varchar(64) NULL,

	[INCLUSION_PERCENTAGE_SUB1] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB2] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB3] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB4] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB5] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB6] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB7] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB8] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB9] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB10] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB11] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB12] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB13] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB14] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB15] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB16] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB17] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB18] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB19] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_SUB20] NUMERIC(8,2) NULL,

	[INCLUSION_PERCENTAGE_SUB_LIST1]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST2]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST3]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST4]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST5]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST6]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST7]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST8]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST9]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST10] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST11] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST12] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST13] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST14] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST15] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST16] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST17] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST18] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST19] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_SUB_LIST20] Varchar(64) NULL,

	[INCLUSION_PERCENTAGE_LOCATION1] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION2] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION3] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION4] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION5] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION6] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION7] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION8] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION9] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION10] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION11] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION12] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION13] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION14] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION15] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION16] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION17] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION18] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION19] NUMERIC(8,2) NULL,
	[INCLUSION_PERCENTAGE_LOCATION20] NUMERIC(8,2) NULL,

	[INCLUSION_PERCENTAGE_LOCATION_LIST1]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST2]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST3]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST4]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST5]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST6]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST7]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST8]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST9]  Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST10] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST11] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST12] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST13] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST14] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST15] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST16] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST17] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST18] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST19] Varchar(64) NULL,
	[INCLUSION_PERCENTAGE_LOCATION_LIST20] Varchar(64) NULL,

	[CULET_PERCENTAGE]  NUMERIC(8,2) NULL,
	[HEART_ARROW_PERCENTAGE]  NUMERIC(8,2) NULL,
	[DIAMETER_RATIO_PERCENTAGE]  NUMERIC(8,2) NULL,
	[MINIMUM_DIAMETER_LENGTH_PERCENTAGE]  NUMERIC(8,2) NULL,
	[MAXIMUM_DIAMETER_PERCENTAGE]  NUMERIC(8,2) NULL,
	[TOTAL_DEPTH_PERCENTAGE]  NUMERIC(8,2) NULL,
	[TABLED_PERCENTAGE]  NUMERIC(8,2) NULL,
	[CROWN_ANGLE_PERCENTAGE]  NUMERIC(8,2) NULL,
	[CROWN_HEIGHT_PERCENTAGE]  NUMERIC(8,2) NULL,
	[PAVALION_ANGLE_PERCENTAGE]  NUMERIC(8,2) NULL,
	[GIRDLE_PERCENTAGE]  NUMERIC(8,2) NULL,

	[APPS_CODE] [TINYINT] NULL,
	[CREATED_DATETIME] [DATETIME] NULL,
	[CREATED_BY] [SMALLINT] NULL,
	[CREATED_IPLOCATION_ID] [INT] NULL,
	[MODIFIED_DATETIME] [DATETIME] NULL,
	[MODIFIED_BY] [SMALLINT] NULL,
	[MODIFIED_IPLOCATION_ID] [INT] NULL,
	[ROW_VERSION] [TIMESTAMP] NOT NULL,
	[DATA_VERSION] [BIGINT] NULL,
 CONSTRAINT [PK_VENDOR_STONE_PERCENTAGE] PRIMARY KEY CLUSTERED 
(
	[PACKET_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)


GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [Packet].[VENDOR_STONE_PERCENTAGE] ADD  CONSTRAINT [DF_VENDOR_STONE_PERCENTAGE_CREATED_DATETIME]  DEFAULT ([Master].[Fn_GetISTDATETIME]()) FOR [CREATED_DATETIME]
GO

ALTER TABLE [Packet].[VENDOR_STONE_PERCENTAGE] ADD  CONSTRAINT [DF_VENDOR_STONE_PERCENTAGE_DATA_VERSION]  DEFAULT ((0)) FOR [DATA_VERSION]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'This Table use to Store Discount Percentage for Inclusion and paramter' , @level0type=N'SCHEMA',@level0name=N'Packet', @level1type=N'TABLE',@level1name=N'VENDOR_STONE_PERCENTAGE'
GO


