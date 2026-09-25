USE `STUDMANBORROMEE`
;

/****** Object:  Table `T_Classe`    Script Date: 09/03/2022 15:14:48 ******/






CREATE TABLE `classes`(
	`id` bigint(20) UNSIGNED NULL,
	`CodeClasse` int NOT NULL,
	`CodeTypeClasse` varchar(2) NULL,
	`LibelleClasse` varchar(20) NULL,
	`CodeCycle` varchar(2) NULL,
	`CodeSpecialite` varchar(10) NULL,
	`codetypeinscrip` varchar(10) NULL,
	`CodeEtablissement` bigint(20) UNSIGNED NULL,
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  	`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

 CONSTRAINT `PK_classes` PRIMARY KEY 
(
	`CodeEtablissement` ASC
)
);

