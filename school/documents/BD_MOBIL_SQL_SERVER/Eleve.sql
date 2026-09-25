USE [STUDMANBORROMEE]
GO

/****** Object:  Table [dbo].[T_Eleve]    Script Date: 09/03/2022 15:18:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[T_Eleve](
	[CodeEleve] [char](10) NOT NULL,
	[CodeAnnee] [char](10) NOT NULL,
	[CodeClasse] [char](10) NOT NULL,
	[CodeConduite] [char](10) NULL,
	[Nom] [char](50) NULL,
	[Prenom] [char](50) NULL,
	[DateNaissance] [datetime] NULL,
	[LieuNaissance] [char](20) NULL,
	[Sexe] [char](10) NULL,
	[Nationalite] [char](20) NULL,
	[dateinscription] [datetime] NULL,
	[photo] [char](50) NULL,
	[Excl] [char](1) NULL,
	[ADM] [int] NULL,
	[Nomp] [char](50) NULL,
	[TelP] [char](25) NULL,
	[image] [image] NULL,
	[strimage] [char](16) NULL,
	[Nomm] [char](30) NULL,
	[REGION] [char](50) NULL,
	[DEPART] [char](50) NULL,
	[RELIGION] [char](50) NULL,
	[SITREG] [char](30) NULL,
	[ACTIVEEPS] [int] NULL,
	[PROFP] [char](50) NULL,
	[NOMT] [char](50) NULL,
	[PROFM] [char](50) NULL,
	[PROFT] [char](50) NULL,
	[ADRESSE] [char](50) NULL,
	[RESIDENT] [char](50) NULL,
	[TELM] [char](50) NULL,
	[TELT] [char](50) NULL,
	[PERSOCON] [char](10) NULL,
	[RESERVE1] [char](10) NULL,
	[RESERVE2] [char](10) NULL,
	[RESERVE3] [char](10) NULL,
	[RESERVE4] [char](10) NULL,
 CONSTRAINT [PK_T_Eleve] PRIMARY KEY CLUSTERED 
(
	[CodeEleve] ASC,
	[CodeAnnee] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[T_Eleve] ADD  CONSTRAINT [DF_T_Eleve_Nationalite]  DEFAULT (1) FOR [Nationalite]
GO

ALTER TABLE [dbo].[T_Eleve] ADD  CONSTRAINT [DF_T_Eleve_RELIGION]  DEFAULT ('CATH') FOR [RELIGION]
GO


