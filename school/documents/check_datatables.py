import csv
import mysql.connector
import datetime



mydb = mysql.connector.connect(
  host="localhost",
  user="root",
  password="",
  database="STUDMANBORROMEE"
)

mycursor = mydb.cursor()

e = datetime.datetime.now()
today_datetime = str(e.year)+"-"+str(e.month)+"-"+str(e.day)+" "+str(e.hour)+":"+str(e.minute)+":"+str(e.second)
print ("Today's date: ", str(today_datetime))
try:
      file_path = '/home/lmntrix/Desktop/laravel/school/documents/DATA_MOBIL/notes.txt'
      with open(file_path,encoding='utf-8-sig') as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=';')
        line_count = 0
        i=1
        for row in csv_reader:

          #insert enseignants
          sql = "INSERT INTO notes (Codeenseignement,CodeEleve,CodeEvaluation, CodeAppreciation, Valeur, coef,total, Dateeng, codeannee) VALUES (%s, %s,%s,%s, %s, %s,%s, %s,%s)"
          val = (row[0].strip(), row[1].strip(),row[2].strip(),row[3].strip(),row[4].strip(), row[5].strip(),row[6].strip(),row[7].strip(),row[8].strip())
          print(val)
          mycursor.execute(sql, val)
          mydb.commit()

          #insert enseignants
          # sql = "INSERT INTO users (code,nom,prenom, DateDeNaissance, LieuDeNaissance, nationalite,sex, DatePriseService, login, contacts, cdegrade, nbrand, matricule, reserve1, reserve2, reserve3,reserve4,reserve5,reserve6,cat,echel, statut, reserve7,reserve8, reserve9, CodeBank, numcpt, ribcpt, TauhH, syndicat, NumAssure, CodeEtablissement, text_password, password) VALUES (%s, %s,%s,%s, %s, %s,%s, %s,%s,%s, %s, %s,%s, %s,%s,%s, %s, %s,%s,%s, %s,%s,%s, %s, %s,%s, %s,%s,%s,%s,%s, %s,%s,%s)"
          # val = (row[0].strip(), row[1].strip(),row[2].strip(),row[3].strip(),row[4].strip(), row[5].strip(),row[6].strip(),row[7].strip(),row[8].strip(), row[9].strip(),row[10].strip(),row[11].strip(),row[12].strip(), row[13].strip(),row[14].strip(),row[15].strip(),row[16].strip(),row[17].strip(), row[18].strip(),row[19].strip(),row[20].strip(),row[21].strip(), row[22].strip(),row[23].strip(),row[24].strip(),row[25].strip(), row[26].strip(),row[27].strip(),row[28].strip(),row[29].strip(), row[30].strip(),row[31].strip(),'00000000','$2y$10$JuTQ/qgM75boawWtIg4VxOR7Wxlq9pliljVAaLsQlo1n1AuvOXqRW')
          # print(val)
          # mycursor.execute(sql, val)
          # mydb.commit()

          # #insert enseignements
          # sql = "INSERT INTO enseignements (CodeEnseignement,CodeMatiere,code, CodeClasse,CodeEtablissement, Coefficient, CodeSpecialite, CodeCycle, Dateens, CodeEnseignant2, DateModif, NBRHEURE, RESERVE1,RESERVE2,RESERVE3,RESERVE4,RESERVE5, created_at, updated_at) VALUES (%s, %s,%s,%s, %s, %s,%s, %s,%s,%s, %s, %s,%s, %s,%s,%s, %s, %s,%s)"
          # val = (row[0].strip(), row[1].strip(),row[2].strip(),row[3].strip(),row[4].strip(), row[5].strip(),row[6].strip(),row[7].strip(),row[8].strip(), row[9].strip(),row[10].strip(),row[11].strip(),row[12].strip(), row[13].strip(),row[14].strip(),row[15].strip(),row[16].strip(), today_datetime, today_datetime)
          # print(val)
          # mycursor.execute(sql, val)
          # mydb.commit()

          # #insert courses
          # sql = "INSERT INTO matieres (CodeMatiere,LibelleMatiere,ordre, CodeEtablissement, created_at, updated_at) VALUES (%s, %s,%s,%s, %s, %s)"
          # val = (row[0].strip(), row[1].strip(),row[2].strip(),row[3].strip(), today_datetime, today_datetime)
          # print(val)
          # mycursor.execute(sql, val)
          # mydb.commit()


          # #insert sequence evaluation
          # sql = "INSERT INTO sequence_evaluations (CodeEvaluation,LibelleEvaluation, created_at, updated_at) VALUES (%s, %s, %s, %s)"
          # val = (row[0].strip(), row[1].strip(), today_datetime, today_datetime)
          # print(val)
          # mycursor.execute(sql, val)
          # mydb.commit()

          #insert inscriptions
          # sql = "INSERT INTO inscriptions (NUMFAC, CodeInscription, CodeEleve,DateInscription, Tranche, codeannee, Montantins, Avance, Reste, Montantt, libinscrip, heure, caissier, remise, created_at, updated_at) VALUES (%s, %s, %s, %s,%s, %s, %s, %s,%s, %s, %s, %s,%s, %s, %s, %s)"
          # val = (row[0].strip(), row[1].strip(),row[2].strip(), row[3].strip(),row[4].strip(), row[5].strip(),row[6].strip(), row[7].strip(),row[8].strip(), row[9].strip(),row[10].strip(), row[11].strip(),row[12].strip(), row[13].strip(), today_datetime, today_datetime)
          # print(val)
          # mycursor.execute(sql, val)
          # mydb.commit()

          #insert students
          # print('CodeEleve: '+str(row[0]))
          # print('CodeAnnee: '+str(row[1]))
          # print('CodeClasse: '+str(row[2]))
          # print('CodeConduite: '+str(row[3]))
          # print('Nom: '+str(row[4]))
          # print('Prenom: '+str(row[5]))
          # print('Date de Naissance : '+str(row[6]))
          # print('Lieu de Naissance : '+str(row[7]))
          # print('Sex: '+str(row[8]))
          # print('Nationalite: '+str(row[9]))
          # print('Date Inscription : '+str(row[10]))
          # print('Photo : '+str(row[11]))
          # print('Exclu : '+str(row[12]))
          # print('Nomp : '+str(row[13]))

        # insert years
            # print('Code Annee :'+str(row[0]))
            # print('Libelle :'+str(row[1]))
            # sql = "INSERT INTO annees (CodeAnnee, Libelle) VALUES (%s, %s)"
            # val = (int(row[0].strip()), row[1].strip())
            # print(val)
            # mycursor.execute(sql, val)
            # mydb.commit()

          # insert schools
            # print('Code Annee :'+str(row[0]))
            # print('Libelle :'+str(row[1]))
            # sql = "INSERT INTO tranche_scholarites (code, libellet, created_at, updated_at) VALUES (%s, %s, %s, %s)"
            # val = (int(row[0].strip()), row[1].strip(), today_datetime, today_datetime)
            # print(val)
            # mycursor.execute(sql, val)
            # mydb.commit()

          #insert students
          # sql = "INSERT INTO eleves (CodeEleve, CodeAnnee, CodeClasse, CodeConduite, Nom, Prenom, DateNaissance, LieuNaissance, Sex, Nationalite, dateinscription, photo, Excl, Nomp, TelP, Image, strimage, Nomm, REGION,DEPART,RELIGION,SITREG,ACTIVEEPS,PROFP,NOMT,PROFM,ADRESSE,RESIDENT,TELM,TELT,PERSONCON,RESERVE1,RESERVE2,RESERVE3,RESERVE4) VALUES (%s, %s, %s, %s, %s,%s, %s, %s, %s, %s,%s, %s, %s, %s, %s,%s, %s, %s, %s, %s,%s, %s, %s, %s, %s,%s, %s, %s, %s, %s,%s, %s, %s, %s, %s)"
          # val = (row[0].strip(), row[1].strip(), row[2].strip(), row[3].strip(), row[4].strip(), row[5].strip(),row[6].strip(), row[7].strip(), row[8].strip(), row[9].strip(), row[10].strip(), row[11].strip(),row[12].strip(), row[14].strip(), row[15].strip(), '', row[16].strip(), row[18].strip(),row[19].strip(), row[20].strip(), row[21].strip(), row[22].strip(), row[23].strip(), row[24].strip(),row[25].strip(), row[28].strip(), row[29].strip(), '', '', row[30].strip(),row[31].strip(), row[32].strip(), row[33].strip(), row[34].strip(), row[35].strip())
          
          # mycursor.execute(sql, val)
          # mydb.commit()
          # print(i)
          # i+=1

            #insert schools

            # sql = "INSERT INTO etablissements (CodeEtablissement, Pays, Nom, Adresse, Tel, Fax, REPPHOTO) VALUES (%s, %s, %s, %s, %s, %s, %s)"
            # val = (int(row[0].strip()), row[1].strip(), row[2].strip(), 'Yaounde', row[4].strip(), row[3].strip(), 'NULL')
            # print(val)
            # mycursor.execute(sql, val)
            # mydb.commit()

            # insert classes
            # print("CODE CLASSE: " +row[0])
            # print("CODE TYPE CLASSE: "+row[1])
            # print("LIBELLE CLASS: "+row[2])
            # print("CODE CYCLE: " + row[3])
            # print("CODE SPECIALITE: " + row[4])
            # print("CODE TYPE INSCRIPTION: " + row[5])
            # print("CODE ETABLISSEMENT: " + row[6])
            
           

            # sql = "INSERT INTO classes (CodeClasse, CodeTypeClasse, LibelleClasse, CodeCycle, CodeSpecialite, codetypeinscrip, CodeEtablissement) VALUES (%s, %s, %s, %s,%s, %s, %s)"
            # val = (int(row[0].strip()), int(row[1].strip()), row[2].strip(), int(row[3].strip()), int(row[4].strip()), int(row[5].strip()), int(row[6].strip()))
            # print(val)
            # mycursor.execute(sql, val)
            # mydb.commit()
            # i+=1
            

except Exception as e:
    print(e)
        
