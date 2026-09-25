USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Inscriptionhisto]    Script Date: 09/03/2022 15:59:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Inscriptionhisto](
	[NUMFAC] [numeric](18, 0) NOT NULL,
	[CodeInscription] [char](2) NOT NULL,
	[CodeEleve] [char](10) NOT NULL,
	[DateInscription] [datetime] NULL,
	[tranche] [char](2) NOT NULL,
	[codeanne] [char](10) NOT NULL,
	[Montantins] [numeric](18, 0) NULL,
	[Avance] [numeric](18, 0) NULL,
	[reste] [numeric](18, 0) NULL,
	[Montantt] [numeric](18, 0) NULL,
	[Libinscrip] [char](100) NULL,
	[Heure] [char](10) NULL,
	[caissier] [char](50) NULL,
	[Remise] [numeric](18, 0) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


