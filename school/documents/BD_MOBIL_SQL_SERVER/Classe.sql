USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Classe]    Script Date: 09/03/2022 15:14:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Classe](
	[CodeClasse] [int] NOT NULL,
	[CodeTypeClasse] [char](2) NULL,
	[LibelleClasse] [char](20) NULL,
	[CodeCycle] [char](2) NULL,
	[CodeSpecialite] [char](10) NULL,
	[codetypeinscrip] [char](10) NULL,
	[CodeEtablissement] [char](10) NULL,
 CONSTRAINT [PK_T_Classe] PRIMARY KEY CLUSTERED 
(
	[CodeClasse] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


