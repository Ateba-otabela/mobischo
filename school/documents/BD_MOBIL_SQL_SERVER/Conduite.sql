USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Conduite]    Script Date: 09/03/2022 15:31:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Conduite](
	[CodeConduite] [char](10) NOT NULL,
	[DateEnreg] [datetime] NOT NULL,
	[codeeleve] [char](10) NOT NULL,
	[Nombre] [numeric](10, 0) NULL,
	[codeetatcond] [char](1) NULL,
	[codeclasse] [char](2) NULL,
	[codeannee] [char](10) NULL,
	[CodeMatiere] [char](10) NULL,
	[HeureMatiere] [char](10) NULL,
 CONSTRAINT [PK_T_Conduite] PRIMARY KEY CLUSTERED 
(
	[CodeConduite] ASC,
	[DateEnreg] ASC,
	[codeeleve] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


