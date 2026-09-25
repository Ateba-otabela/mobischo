USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Inscription]    Script Date: 09/03/2022 16:34:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Inscription](
	[NUMFAC] [char](10) NOT NULL,
	[CodeInscription] [char](2) NOT NULL,
	[CodeEleve] [char](10) NOT NULL,
	[DateInscription] [datetime] NULL,
	[Tranche] [char](2) NOT NULL,
	[codeanne] [char](10) NOT NULL,
	[Montantins] [numeric](18, 0) NULL,
	[Avance] [numeric](18, 0) NULL,
	[reste] [numeric](18, 0) NULL,
	[montantt] [numeric](18, 0) NULL,
	[Libinscrip] [char](100) NULL,
	[Heure] [char](10) NULL,
	[caissier] [char](50) NULL,
	[Remise] [numeric](18, 0) NULL,
 CONSTRAINT [PK_T_Inscription_1] PRIMARY KEY CLUSTERED 
(
	[NUMFAC] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


