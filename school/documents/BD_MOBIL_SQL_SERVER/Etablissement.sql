USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Etablissement]    Script Date: 09/03/2022 15:02:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Etablissement](
	[CodeEtablissement] [char](10) NOT NULL,
	[Pays] [char](20) NULL,
	[Nom] [char](100) NULL,
	[Adresse] [char](100) NULL,
	[Tel] [char](30) NULL,
	[Fax] [char](15) NULL,
	[REPPHOTO] [char](50) NULL,
 CONSTRAINT [PK_T_Etablissement] PRIMARY KEY CLUSTERED 
(
	[CodeEtablissement] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


