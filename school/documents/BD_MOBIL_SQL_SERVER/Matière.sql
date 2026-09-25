USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Matiere]    Script Date: 09/03/2022 15:22:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Matiere](
	[CodeMatiere] [char](10) NOT NULL,
	[LIbelleMatiere] [char](50) NULL,
	[ordre] [char](10) NULL,
	[CodeEtablissement] [char](10) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


