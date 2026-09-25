USE `STUDMANBORROMEE`
;

/****** Object:  Table `T_Eleve`    Script Date: 09/03/2022 15:18:08 ******/

CREATE TABLE `eleves`(
	`CodeEleve` varchar(10) NOT NULL,
	`CodeAnnee` varchar(10) NOT NULL,
	`CodeClasse` varchar(10) NOT NULL,
	`CodeConduite` varchar(10) NULL,
	`Nom` varchar(50) NULL,
	`Prenom` varchar(50) NULL,
	`DateNaissance` datetime NULL,
	`LieuNaissance` varchar(20) NULL,
	`Sexe` varchar(10) NULL,
	`Nationalite` varchar(20) NULL,
	`dateinscription` datetime NULL,
	`photo` varchar(50) NULL,
	`Excl` varchar(1) NULL,
	`ADM` int NULL,
	`Nomp` varchar(50) NULL,
	`TelP` varchar(25) NULL,
	`Image` varchar(300) NULL,
	`strimage` varchar(16) NULL,
	`Nomm` varchar(30) NULL,
	`REGION` varchar(50) NULL,
	`DEPART` varchar(50) NULL,
	`RELIGION` varchar(50) NULL,
	`SITREG` varchar(30) NULL,
	`ACTIVEEPS` int NULL,
	`PROFP` varchar(50) NULL,
	`NOMT` varchar(50) NULL,
	`PROFM` varchar(50) NULL,
	`PROFT` varchar(50) NULL,
	`ADRESSE` varchar(50) NULL,
	`RESIDENT` varchar(50) NULL,
	`TELM` varchar(50) NULL,
	`TELT` varchar(50) NULL,
	`PERSOCON` varchar(10) NULL,
	`RESERVE1` varchar(10) NULL,
	`RESERVE2` varchar(10) NULL,
	`RESERVE3` varchar(10) NULL,
	`RESERVE4` varchar(10) NULL,
 CONSTRAINT `PK_eleves` PRIMARY KEY 
(
	`CodeEleve` ASC,
	`CodeAnnee` ASC
)
);
