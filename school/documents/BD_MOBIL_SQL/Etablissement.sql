USE `STUDMANBORROMEE`;

/****** Object:  Table `T_Etablissement`    Script Date: 09/03/2022 15:02:57 ******/


CREATE TABLE `etablissements`(
	`CodeEtablissement` varchar(10) NOT NULL,
	`Pays` varchar(20) NULL,
	`Nom` varchar(100) NULL,
	`Adresse` varchar(100) NULL,
	`Tel` varchar(30) NULL,
	`Fax` varchar(15) NULL,
	`REPPHOTO` varchar(50) NULL,
	`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  	`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT `PK_etablissements` PRIMARY KEY 
(
	`CodeEtablissement` ASC
)
);




