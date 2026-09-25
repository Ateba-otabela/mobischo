USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Note]    Script Date: 09/03/2022 15:32:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Note](
	[Codeenseignement] [char](10) NOT NULL,
	[CodeEleve] [char](10) NOT NULL,
	[CodeEvaluation] [char](10) NOT NULL,
	[CodeAppreciation] [char](10) NULL,
	[Valeur] [char](6) NULL,
	[coef] [char](10) NULL,
	[Total] [char](6) NULL,
	[Dateeng] [datetime] NOT NULL,
	[codeannee] [char](10) NOT NULL,
 CONSTRAINT [PK_T_Note] PRIMARY KEY CLUSTERED 
(
	[Codeenseignement] ASC,
	[CodeEleve] ASC,
	[CodeEvaluation] ASC,
	[codeannee] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


