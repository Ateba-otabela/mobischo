USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Enseignement]    Script Date: 09/03/2022 15:12:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Enseignement](
	[CodeEnseignement] [char](10) NOT NULL,
	[CodeMatiere] [char](10) NOT NULL,
	[CodeEnseignant] [char](10) NOT NULL,
	[codeClasse] [char](10) NOT NULL,
	[Coefficient] [char](24) NULL,
	[codeGroupeMat] [char](10) NULL,
	[CodeSpecialite] [char](10) NULL,
	[CodeCycle] [char](10) NULL,
	[Dateens] [datetime] NULL,
	[CodeEnseinant2] [char](10) NULL,
	[DateModif] [char](10) NULL,
	[LibgroupeMat] [char](50) NULL,
	[NBRHEURE] [int] NULL,
	[RESERVE1] [char](10) NULL,
	[RESERVE2] [char](10) NULL,
	[RESERVE3] [char](10) NULL,
	[RESERVE4] [char](10) NULL,
	[RESERVE5] [char](10) NULL,
	[CodeEtablissement] [char](10) NULL,
 CONSTRAINT [PK_T_Enseignement] PRIMARY KEY CLUSTERED 
(
	[CodeEnseignement] ASC,
	[CodeMatiere] ASC,
	[CodeEnseignant] ASC,
	[codeClasse] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


