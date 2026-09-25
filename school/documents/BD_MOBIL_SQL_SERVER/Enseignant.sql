USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Enseignant]    Script Date: 09/03/2022 15:10:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Enseignant](
	[CodeEnseignant] [char](10) NOT NULL,
	[NomEns] [char](20) NULL,
	[PrenomEns] [char](20) NULL,
	[DateNaissanceEns] [datetime] NULL,
	[LieuNaissanceEns] [char](10) NULL,
	[NationaliteEns] [char](10) NULL,
	[SexeENS] [char](10) NULL,
	[DatePriseService] [datetime] NULL,
	[Login] [nvarchar](50) NULL,
	[Contacts] [char](50) NULL,
	[CDEGRADE] [char](10) NULL,
	[NBRAN] [int] NULL,
	[Matricule] [char](10) NULL,
	[RESERVE1] [char](10) NULL,
	[RESERVE2] [char](10) NULL,
	[RESERVE3] [char](10) NULL,
	[RESERVE4] [char](10) NULL,
	[RESERVE5] [char](10) NULL,
	[RESERVE6] [char](10) NULL,
	[CAT] [int] NULL,
	[ECHEL] [char](10) NULL,
	[STATUT] [char](100) NULL,
	[RESERVE7] [char](10) NULL,
	[RESERVE8] [char](10) NULL,
	[RESERVE9] [char](10) NULL,
	[CODEBANK] [char](10) NULL,
	[NUMCPT] [char](20) NULL,
	[RIBCPT] [char](2) NULL,
	[TAUXH] [numeric](18, 0) NULL,
	[SYNDICAT] [char](10) NULL,
	[NUMASSURE] [char](15) NULL,
	[CodeEtablissement] [char](10) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


