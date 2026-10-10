// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Mobischo';

  @override
  String get loginTitle => 'Connectez-vous à votre compte';

  @override
  String get login => 'Connexion';

  @override
  String get username => 'Nom d’utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get reset => 'réinitialiser';

  @override
  String get emptyFields => 'Veuillez remplir tous les champs.';

  @override
  String get incorrectLogin => 'Identifiants incorrects.';

  @override
  String get connectionError => 'Erreur de connexion. Veuillez réessayer.';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get parent => 'Parent';

  @override
  String get student => 'Élève';

  @override
  String get teacher => 'Enseignant';

  @override
  String get principal => 'Principal';

  @override
  String get encadreur => 'Encadreur';

  @override
  String get notifications => 'Notifications';

  @override
  String get messages => 'Messages';

  @override
  String get settings => 'Paramètres';

  @override
  String get profile => 'Profil';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get noData => 'Aucune donnée disponible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get send => 'Envoyer';

  @override
  String get close => 'Fermer';

  @override
  String get continueButton => 'Continuer';

  @override
  String get users => 'Utilisateurs';

  @override
  String get notes => 'Notes';

  @override
  String get absences => 'Absences';

  @override
  String get myChildren => 'Mes enfants';

  @override
  String get registerCall => 'Registre d’appel';

  @override
  String get subjects => 'Matières';

  @override
  String get classes => 'Classes';

  @override
  String get students => 'Élèves';

  @override
  String get convocations => 'Convocations';

  @override
  String get presence => 'Présence';

  @override
  String get absentAttendance => 'Absent';

  @override
  String get lateAttendance => 'En retard';

  @override
  String get schoolUniversity => 'École / Université';

  @override
  String get home => 'Accueil';

  @override
  String get reports => 'Rapports des professeurs';

  @override
  String get alerts => 'Alertes d’investigation';

  @override
  String get notInterested => 'Ça ne vous intéresse pas ?';

  @override
  String get consult => 'Consulter';

  @override
  String get absencesRecordedSuccessfully =>
      'Absences enregistrées avec succès';

  @override
  String get convocationRecordedSuccessfully =>
      'Convocation coupée avec succès';

  @override
  String get clickConsultToSeeAbsences =>
      'Cliquez sur Consulter pour voir la liste des absents';

  @override
  String get clickConsultToSeeConvocations =>
      'Cliquez sur Consulter pour voir la liste des convocations';

  @override
  String get chooseClassTitle => 'Choisissez une classe';

  @override
  String get selectClassToContinue => 'Cliquez sur la classe pour continuer';

  @override
  String get teacherCalls => 'Appels des professeurs';

  @override
  String get convoke => 'Convoquer';

  @override
  String get ai => 'IA';

  @override
  String get aiGreeting =>
      'Bonjour 👋 Je suis Mobischo AI.\nJe peux vous aider à consulter les informations scolaires, comprendre les présences, les élèves, les classes et bien plus encore.';

  @override
  String get aiSuggestionAttendance => 'Voir les présences';

  @override
  String get aiSuggestionClass => 'Informations sur ma classe';

  @override
  String get aiSuggestionHelp => 'Aide';

  @override
  String get aiAssistant => 'Assistant scolaire';

  @override
  String get conversationHistory => 'Historique des conversations';

  @override
  String get newConversation => 'Nouvelle conversation';

  @override
  String get conversations => 'Conversations';

  @override
  String get noConversations => 'Aucune conversation enregistrée.';

  @override
  String get loadOlderConversations => 'Charger les conversations précédentes';

  @override
  String get genericConversation => 'Conversation';

  @override
  String get deleteConversationTooltip => 'Supprimer la conversation';

  @override
  String get deleteConversationConfirm => 'Supprimer cette conversation ?';

  @override
  String get irreversibleAction => 'Cette action est définitive.';

  @override
  String get copied => 'Copié';

  @override
  String get copy => 'Copier';

  @override
  String get aiTyping => 'Mobischo AI écrit…';

  @override
  String get writeMessage => 'Écrire un message...';

  @override
  String get microphoneUnavailable => 'Microphone indisponible';

  @override
  String get createConversationError => 'Impossible de créer une conversation.';

  @override
  String get openConversationError => 'Impossible d’ouvrir cette conversation.';

  @override
  String get deleteConversationError =>
      'Impossible de supprimer cette conversation.';

  @override
  String get sessionExpired =>
      'Votre session doit être renouvelée. Veuillez vous reconnecter.';

  @override
  String get requestFailed =>
      'Désolé, je rencontre actuellement un problème de connexion. Veuillez réessayer.';

  @override
  String get emptyAiResponse =>
      'Je n’ai pas reçu de réponse. Veuillez réessayer.';

  @override
  String get responseTimeout =>
      'La réponse prend trop de temps. Vérifiez votre connexion et réessayez.';

  @override
  String get newConversationFallback => 'Nouvelle conversation';

  @override
  String get sendTooltip => 'Envoyer';

  @override
  String get loadingEllipsis => 'Chargement...';

  @override
  String get details => 'Détails';

  @override
  String get className => 'Classe';

  @override
  String classCode(Object code) {
    return 'Code de la classe : $code';
  }

  @override
  String get subject => 'Matière';

  @override
  String get studentName => 'Élève';

  @override
  String get teacherName => 'Enseignant';

  @override
  String get firstAndLastNames => 'Noms et prénoms';

  @override
  String get gender => 'Genre';

  @override
  String get studentCode => 'Code élève';

  @override
  String get teacherCode => 'Code enseignant';

  @override
  String get birthDate => 'Date de naissance';

  @override
  String get birthPlace => 'Lieu de naissance';

  @override
  String get enrollmentDate => 'Date d\'inscription';

  @override
  String get courseCode => 'Code enseignement';

  @override
  String get hoursCount => 'Nombre d\'heures';

  @override
  String get coefficient => 'Coefficient';

  @override
  String get institution => 'Établissement';

  @override
  String get studentList => 'Liste des élèves';

  @override
  String get studentListUpper => 'LISTE DES ÉLÈVES';

  @override
  String get chooseClass => 'Choisissez une classe';

  @override
  String get tapClassToContinue => 'Cliquez sur la classe pour continuer';

  @override
  String get retryLoadingStudents => 'Impossible de charger les élèves.';

  @override
  String get noStudentsInClass => 'Aucun élève dans cette classe.';

  @override
  String get searchStudents => 'Rechercher par nom ou code d’élève';

  @override
  String get filterByGender => 'Filtrer par sexe';

  @override
  String get allStudents => 'Tous les élèves';

  @override
  String get studentSearchEmpty => 'Aucun élève ne correspond à ces filtres.';

  @override
  String get searchColleague => 'Rechercher un collègue';

  @override
  String get noColleagueFound => 'Aucun collègue trouvé';

  @override
  String get noOtherTeacherAvailable =>
      'Aucun autre enseignant n\'est actuellement disponible dans votre établissement.';

  @override
  String get colleagueLoadError => 'Impossible de charger vos collègues.';

  @override
  String get invoiceNumber => 'Numéro de facture';

  @override
  String get registrationLabel => 'Libellé d\'inscription';

  @override
  String get installment => 'Tranche';

  @override
  String get registrationAmount => 'Montant d\'inscription';

  @override
  String get advance => 'Avance';

  @override
  String get remaining => 'Reste';

  @override
  String get totalAmount => 'Montant total';

  @override
  String get schoolYear => 'Année scolaire';

  @override
  String get time => 'Heure';

  @override
  String get paymentHistory => 'Historique des paiements';

  @override
  String get invoiceHistoryDescription =>
      'Consultez l\'historique de cette facture';

  @override
  String get viewInstitutionWebsite => 'Visiter le site';

  @override
  String get institutionWebsiteError =>
      'Impossible d’ouvrir le site web de l’établissement.';

  @override
  String get homeDashboardTooltip => 'Retour au tableau de bord';

  @override
  String get newestFirst => 'Plus récent';

  @override
  String get oldestFirst => 'Plus ancien';

  @override
  String get sortHomework => 'Trier les devoirs';

  @override
  String get sortMessages => 'Trier les messages';

  @override
  String get allMyChildren => 'Tous mes enfants';

  @override
  String get sortByChildren => 'Trier en fonction des enfants';

  @override
  String get noHomeworkAvailable => 'Aucun devoir disponible pour le moment.';

  @override
  String get homeworkWillAppear =>
      'Les devoirs de vos enfants apparaîtront ici dès qu\'ils seront publiés.';

  @override
  String dueDate(Object date) {
    return 'Date limite de remise : $date';
  }

  @override
  String subjectAndClass(Object className, Object subject) {
    return 'Matière : $subject   Classe : $className';
  }

  @override
  String get noMessagesAvailable => 'Aucun message disponible pour le moment.';

  @override
  String get messagesWillAppear =>
      'Les messages et informations de l\'établissement apparaîtront ici lorsqu\'ils seront disponibles.';

  @override
  String get noJustificationYet => 'Aucune justification pour le moment';

  @override
  String get noJustificationSubmitted =>
      'Vous n’avez pas encore soumis de justification d’absence.';

  @override
  String get justificationHistoryUnavailable =>
      'L’historique est momentanément indisponible.';

  @override
  String get justifyAbsence => 'Justifier une absence';

  @override
  String absenceOnDate(Object date) {
    return 'Absence du $date';
  }

  @override
  String submittedOnDate(Object date) {
    return 'Soumise le $date';
  }

  @override
  String get addDocumentOrPhoto => 'Ajouter un document ou une photo';

  @override
  String get optionalSupportingDocument => 'Document justificatif (facultatif)';

  @override
  String get fileSizeLimit => 'PDF, JPG ou PNG · 10 Mo maximum';

  @override
  String get selectedDocument => 'Document sélectionné';

  @override
  String get deleteDocument => 'Supprimer le document';

  @override
  String get sendJustification => 'Envoyer la justification';

  @override
  String get selectAtLeastOneStudent => 'Sélectionnez au moins un élève.';

  @override
  String get studentsToConvene => 'Élèves à convoquer';

  @override
  String get convenedStudents => 'Élèves convoqués';

  @override
  String get moreDetailsTap => 'Cliquez pour plus de détails';

  @override
  String get conveningReason => 'Motif de convocation';

  @override
  String get description => 'Description';

  @override
  String get noStudentAvailable => 'Aucun élève disponible.';

  @override
  String get selectClass => 'Sélectionnez une classe';

  @override
  String get selectSubject => 'Sélectionnez une matière';

  @override
  String get selectSubjectForHomework =>
      'Sélectionnez une matière pour afficher les devoirs récents.';

  @override
  String get noPreviousHomework =>
      'Aucun devoir précédent pour cette classe et cette matière.';

  @override
  String get homeworkTitleRequired => 'Le titre est obligatoire.';

  @override
  String get homeworkCreationFailed => 'Le devoir n\'a pas pu être créé.';

  @override
  String get homeworkCreated => 'Devoir créé avec succès.';

  @override
  String get noAssignedClasses =>
      'Aucune classe ne vous est actuellement attribuée.';

  @override
  String get noAssignedSubjects =>
      'Aucune matière ne vous est actuellement attribuée.';

  @override
  String get noMarksForSubject => 'Aucune note disponible pour cette matière.';

  @override
  String get noMarksForNow => 'Aucune note disponible pour le moment.';

  @override
  String get marksNotPublished =>
      'Vos notes n\'ont pas encore été publiées. Veuillez transmettre vos notes à l\'administration afin qu\'elles puissent être saisies et publiées dans l\'application.';

  @override
  String get marksReadOnly =>
      'Les notes sont consultables uniquement en lecture.';

  @override
  String get marksLoadError =>
      'Impossible de charger les notes. Veuillez réessayer.';

  @override
  String get subjectMarksLoadError =>
      'Impossible de charger les notes de cette matière.';

  @override
  String get marksSubjectUnavailable =>
      'Impossible de charger les notes de cette matière.';

  @override
  String get existingMark => 'Note existante';

  @override
  String get markValue => 'Valeur';

  @override
  String get total => 'Total';

  @override
  String noteLabel(Object value) {
    return 'Note : $value';
  }

  @override
  String get sequencesEvaluations => 'Séquences d\'évaluation';

  @override
  String get schoolYears => 'Années scolaires';

  @override
  String get attendanceNotLoaded => 'Impossible de charger les présences';

  @override
  String get attendanceLoadError =>
      'Une erreur est survenue lors du chargement des présences. Veuillez réessayer.';

  @override
  String get noCallRecorded => 'Aucun appel enregistré';

  @override
  String get noCallForDate => 'Aucun appel pour cette date';

  @override
  String get noCallYetForSubject =>
      'Aucun appel n\'a encore été enregistré pour cette matière.\nCliquez sur + pour enregistrer le premier appel.';

  @override
  String get noCallForSubjectDate =>
      'Aucun appel n\'a été enregistré pour cette matière à la date sélectionnée.\nVous pouvez sélectionner une autre date ou créer un nouvel appel avec +.';

  @override
  String presentAbsentLateCount(Object absent, Object late, Object present) {
    return 'Présents : $present   Absents : $absent   Retards : $late';
  }

  @override
  String get selectDate => 'Sélectionnez une date';

  @override
  String get saveCallFailed => 'L\'appel n\'a pas pu être enregistré.';

  @override
  String saveCallForDate(Object date) {
    return 'Enregistrer l\'appel pour $date';
  }

  @override
  String get noStudentsForSubject => 'Aucun élève trouvé pour cette matière';

  @override
  String get present => 'Présent';

  @override
  String get absenceValidated => 'Présence validée';

  @override
  String get dateOfCall => 'Date d\'appel';

  @override
  String get recordedOnDate => 'Date d\'enregistrement';

  @override
  String get editAbsences => 'Modifier les absences';

  @override
  String get callHours => 'Heures d\'appel';

  @override
  String get numberOfHours => 'Nombre d\'heures';

  @override
  String attendanceDate(Object date) {
    return 'Date : $date';
  }

  @override
  String get conveningDate => 'Date de convocation';

  @override
  String convokedOn(Object date, Object reason) {
    return 'Convoqué le $date pour $reason';
  }

  @override
  String get convocationMessage => 'Message';

  @override
  String get noConvocations => 'Aucune convocation disponible.';

  @override
  String get noAssignedSubjectForConvocation =>
      'Aucune matière ne vous est actuellement attribuée.';

  @override
  String get grades => 'Notes';

  @override
  String get marksByClass => 'Notes — Classes';

  @override
  String get marksBySubject => 'Notes — Matières';

  @override
  String studentGrade(Object value) {
    return 'Note : $value';
  }

  @override
  String get female => 'Féminin';

  @override
  String get male => 'Masculin';

  @override
  String get notProvided => 'Non renseigné';

  @override
  String get connectionIssue => 'Problème de connexion. Veuillez réessayer.';

  @override
  String get institutionLoadError =>
      'Impossible de charger les informations de l’établissement.';

  @override
  String get principalDashboardLoadError =>
      'Impossible de charger le tableau de bord.';

  @override
  String get principalAttendanceLoadError =>
      'Impossible de charger les présences.';

  @override
  String get chooseClassToViewStudents =>
      'Sélectionnez une classe pour consulter ses élèves';

  @override
  String get teachers => 'Professeurs';

  @override
  String get investigationAlerts => 'Alertes d’investigation';

  @override
  String get teacherPresence => 'Présence des enseignants';

  @override
  String get teacherReports => 'Rapports des professeurs';

  @override
  String get teacherCallHistory => 'Historique des appels des professeurs';

  @override
  String get noDataAvailable => 'Aucune donnée';

  @override
  String get simulatedData => 'Les données affichées sont simulées.';

  @override
  String get teacherVerification => 'Vérification enseignant';

  @override
  String get prepareFutureClassCall => 'Préparer un futur appel en classe';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get cameraVerification => 'Vérification caméra';

  @override
  String get verificationFailedRetry => 'Échec de la vérification / Réessayer';

  @override
  String get attendanceDetail => 'Détail de la présence';

  @override
  String get attendanceRate => 'Taux de présence';

  @override
  String studentCount(Object count) {
    return '$count élèves';
  }

  @override
  String presentStudents(Object count) {
    return '$count présents';
  }

  @override
  String absentStudents(Object count) {
    return '$count absents';
  }

  @override
  String lateStudents(Object count) {
    return '$count retards';
  }

  @override
  String get welcomeInstitution => 'Votre établissement au bout des doigts';

  @override
  String get convocationSuccess => 'Convocation envoyée avec succès';

  @override
  String get absencesSavedSuccess => 'Absences enregistrées avec succès';

  @override
  String get passwordUpdatedSuccess => 'Mot de passe modifié avec succès';

  @override
  String get userDetails => 'Détails utilisateur';

  @override
  String get accountCode => 'Code';

  @override
  String get disconnect => 'Se déconnecter';

  @override
  String get myAccount => 'Mon compte';

  @override
  String get colleagues => 'Mes collègues';

  @override
  String get allGradesRegistered => 'Toutes vos notes enregistrées';

  @override
  String get manageAbsencesDescription => 'Ajoutez et consultez les absences';

  @override
  String get colleaguesListDescription => 'Liste de vos collègues';

  @override
  String get sendAndView => 'Envoyer et consulter';

  @override
  String get personalInformation => 'Vos informations personnelles';

  @override
  String get insubordination => 'Insubordination';

  @override
  String get excessiveLateness => 'Retards abusifs';

  @override
  String get violence => 'Violence';

  @override
  String get indiscipline => 'Indiscipline';

  @override
  String get otherReason => 'Autre';

  @override
  String get loadingWithEllipsis => 'Chargement...';

  @override
  String get codeTeaching => 'Code enseignement';

  @override
  String get convocationDateLabel => 'Date de convocation';

  @override
  String get sentDate => 'Date d\'envoi';

  @override
  String get hour => 'Heure';

  @override
  String get dateOfRegistration => 'Date d\'enregistrement';

  @override
  String get classDateLabel => 'Classe';

  @override
  String dateLabel(Object date) {
    return 'Date : $date';
  }

  @override
  String get messageLabel => 'Message';

  @override
  String get searchByName => 'Rechercher par nom';

  @override
  String get sort => 'Trier';

  @override
  String get calendarSortHint =>
      'Cliquez sur l\'icône du calendrier pour trier';

  @override
  String get passwordMismatch => 'Le nouveau mot de passe ne correspond pas.';

  @override
  String get passwordChangeError =>
      'Erreur lors de la modification du mot de passe.';

  @override
  String get clickToEdit => 'Cliquez pour modifier';

  @override
  String get clickToSignOut => 'Cliquez pour vous déconnecter';

  @override
  String get studentListNav => 'Élèves';

  @override
  String get attendanceNav => 'Absences';

  @override
  String get enrollmentHistory => 'Historique des inscriptions';

  @override
  String get schoolNews => 'Actualités de l\'établissement';

  @override
  String get accountInformation => 'Vos informations personnelles';

  @override
  String get sendMessages => 'Envoyer des messages';

  @override
  String get viewMessages => 'Consulter les messages';

  @override
  String get sendMessagesDescription => 'Convoquez des parents';

  @override
  String get viewMessagesDescription => 'Consultez les messages envoyés';

  @override
  String get conveneParents => 'Convoquer des parents';

  @override
  String get viewStudentLists => 'Consultez les listes';

  @override
  String get pageHome => 'Page d\'accueil';

  @override
  String get secureAccount => 'Sécurisez votre compte';

  @override
  String get leaveSession => 'Quitter votre session';

  @override
  String get allClasses => 'Toutes les classes';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String get notificationsEmpty =>
      'Vous n’avez aucune notification pour le moment.';

  @override
  String get markNotificationRead => 'Marquer comme lu';

  @override
  String get markAllNotificationsRead => 'Tout marquer comme lu';

  @override
  String get notificationUnread => 'Non lue';

  @override
  String get notificationRead => 'Lue';

  @override
  String get notificationLoadError =>
      'Impossible de charger les notifications.';

  @override
  String get notificationClass => 'Classe';

  @override
  String get notificationBellTooltip => 'Notifications';

  @override
  String get messagesEmpty => 'Aucun message pour le moment.';

  @override
  String get requestFailedTryAgain =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get confirm => 'Confirmer';

  @override
  String get save => 'Enregistrer';

  @override
  String get title => 'Titre';

  @override
  String get newHomework => 'Nouveau devoir';

  @override
  String get homeworkDescription => 'Description';

  @override
  String get homeworkDueDate => 'Date limite de remise';

  @override
  String get recordedSuccessfully => 'Enregistré avec succès';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmez le mot de passe';

  @override
  String get loginName => 'Identifiant';

  @override
  String get detailsLabel => 'Détails';

  @override
  String get enrollmentHistoryPayments => 'Historique des paiements';

  @override
  String get absenceSummaryClear =>
      'Bonne nouvelle ! Aucun retard ou absence n\'a été enregistré pour cet élève pour le moment.';

  @override
  String get noAbsenceOrLate => 'Aucun retard ou absence';

  @override
  String get absenceListTitle => 'Absences';

  @override
  String get schoolName => 'École / Université';

  @override
  String get moreRecent => 'Plus récent';

  @override
  String get moreAncient => 'Plus ancien';

  @override
  String get absenceDatePicker => 'Sélectionnez la date de l’absence';

  @override
  String get documentReadError => 'Le document sélectionné n’a pas pu être lu.';

  @override
  String get documentTooLarge => 'Le document ne doit pas dépasser 10 Mo.';

  @override
  String get documentSelectError => 'Impossible de sélectionner ce document.';

  @override
  String get justificationSentSuccess => 'Justification envoyée avec succès';

  @override
  String get awaitingVerification => 'Elle est en attente de vérification.';

  @override
  String get backToHistory => 'Retour à l’historique';

  @override
  String get justificationSubmissionError =>
      'La justification n’a pas pu être envoyée. Vérifiez votre connexion et réessayez.';

  @override
  String get newJustification => 'Nouvelle justification';

  @override
  String get childStepTitle => 'Sélectionnez l’enfant concerné';

  @override
  String get absenceDate => 'Date de l’absence';

  @override
  String get reason => 'Motif';

  @override
  String get explanation => 'Explication';

  @override
  String get absenceExplanationLabel =>
      'Expliquez brièvement la raison de l’absence *';

  @override
  String get explainChosenReason => 'Expliquez le motif choisi.';

  @override
  String get addExplanation => 'Ajoutez une explication.';

  @override
  String get addSomeDetails =>
      'Ajoutez quelques détails (10 caractères minimum).';

  @override
  String get reasonIllness => 'Maladie';

  @override
  String get reasonMedicalAppointment => 'Rendez-vous médical';

  @override
  String get reasonFamily => 'Raisons familiales';

  @override
  String get reasonFamilyEmergency => 'Urgence familiale';

  @override
  String get reasonOther => 'Autre';

  @override
  String classLabel(Object className) {
    return 'Classe $className';
  }

  @override
  String get classSelectionTitle => 'Sélectionnez une classe';

  @override
  String get homeworkTab => 'Devoirs';

  @override
  String get noAbsenceRecorded =>
      'Aucun retard ou absence n\'a été enregistré.';

  @override
  String get absenceDetails => 'Détails de l\'absence';

  @override
  String get notice => 'Avis';

  @override
  String get schoolAnnouncement => 'Annonce de l\'établissement';

  @override
  String get noSchoolNews => 'Aucune actualité disponible pour le moment.';

  @override
  String get readMore => 'Lire la suite';

  @override
  String createdOn(Object date) {
    return 'Créé le $date';
  }

  @override
  String get studentDetails => 'Détails de l\'élève';

  @override
  String get enrollmentDetails => 'Détails de l\'inscription';

  @override
  String get courseDetails => 'Détails du cours';

  @override
  String get courseStudents => 'Liste d\'élèves';

  @override
  String get subjectsLabel => 'Matières';

  @override
  String get enrollmentHistoryTitle => 'Historique des inscriptions';

  @override
  String get consultConvocations => 'Consulter les convocations';

  @override
  String get convocationSent => 'Convocation envoyée';

  @override
  String get hours => 'Heures';

  @override
  String get accountLogin => 'Identifiant';

  @override
  String get genderFemale => 'Féminin';

  @override
  String get genderMale => 'Masculin';

  @override
  String get attendanceReason => 'Motif';

  @override
  String get status => 'Statut';

  @override
  String get date => 'Date';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get confirmNewPassword => 'Confirmez le nouveau mot de passe';

  @override
  String get passwordChangeSuccess =>
      'Votre mot de passe a été modifié avec succès.';

  @override
  String get chooseSequence => 'Choisissez une séquence';

  @override
  String get chooseSchoolYear => 'Choisissez une année scolaire';

  @override
  String get selectYourChild => 'Sélectionnez votre enfant';

  @override
  String get childrenLoadError =>
      'Impossible de charger vos enfants pour le moment.';

  @override
  String get noChildLinked => 'Aucun enfant n’est associé à votre compte.';

  @override
  String get change => 'Changer';

  @override
  String get chooseReason => 'Choisissez un motif *';

  @override
  String get selectReason => 'Sélectionnez un motif.';

  @override
  String get enrollmentHistoryDetails => 'Détails';

  @override
  String get messageFilter => 'Trier les messages';

  @override
  String get courseLoadError =>
      'Impossible de charger vos classes et matières.';

  @override
  String get noMark => 'Aucune';

  @override
  String get sequenceMarksNotRecorded =>
      'Les notes de cette séquence n\'ont pas encore été enregistrées.\nVeuillez revenir plus tard.';

  @override
  String get returnBack => 'Retour';

  @override
  String get noMarksRecorded => 'Aucune note enregistrée';

  @override
  String totalCoefficients(Object value) {
    return 'Total coefficients : $value';
  }

  @override
  String totalPoints(Object value) {
    return 'Total points : $value';
  }

  @override
  String average(Object value) {
    return 'Moyenne : $value / 20';
  }

  @override
  String get noSchoolYearAvailable => 'Aucune année scolaire disponible';

  @override
  String get yearsWillAppear =>
      'Les années scolaires apparaîtront ici lorsqu’elles seront disponibles.';

  @override
  String get consultYearGrades => 'Consulter les notes de cette année';

  @override
  String get noAbsenceHistory =>
      'Aucun retard ou absence n\'a été enregistré pour cet élève pour le moment.';

  @override
  String get privateInstitution => 'Privée';

  @override
  String get publicInstitution => 'Publique';

  @override
  String get programs => 'Filières';

  @override
  String get universityCategory => 'Universitaire';

  @override
  String get locatedAt => 'Situé à';

  @override
  String get languages => 'Langues';

  @override
  String get conveneStudents => 'Convoquer des élèves';

  @override
  String get createConvocation => 'Créer une convocation';

  @override
  String get recentConvocations => 'Convocations récentes';

  @override
  String get convocationSentToStudents =>
      'Suivi des convocations envoyées aux élèves';

  @override
  String get convocationsSent => 'Convocations envoyées';

  @override
  String get noConvocationSent => 'Aucune convocation envoyée.';

  @override
  String get recentCall => 'Appel récent';

  @override
  String get alertsAndNotifications => 'Alertes et notifications';

  @override
  String get recentJustifications => 'Justifications récentes';

  @override
  String get callsToday => 'Appels du jour';

  @override
  String get noAttendanceSession => 'Aucune session de présence enregistrée.';

  @override
  String get classOverview => 'Vue d’ensemble des classes';

  @override
  String get noClassAvailable => 'Aucune classe disponible.';

  @override
  String get viewMore => 'Voir plus';

  @override
  String get recentTeacherCalls => 'Appels récents des professeurs';

  @override
  String get classSearchEmpty => 'Aucune classe ne correspond à la recherche.';

  @override
  String get classesLoadError => 'Impossible de charger les classes.';

  @override
  String get noTeacherAvailable => 'Aucun professeur disponible.';

  @override
  String get teacherAttendanceLoadError =>
      'Impossible de charger les présences du professeur.';

  @override
  String get noSessionMatchesFilters =>
      'Aucune session ne correspond aux filtres.';

  @override
  String get studentDetailTitle => 'Détail de l’élève';

  @override
  String get attendanceHistory => 'Historique de présence';

  @override
  String get attendanceDetailTitle => 'Détail de la présence';

  @override
  String get reportDetail => 'Détail du signalement';

  @override
  String get rejectTeacherAttendance => 'Rejeter la présence du professeur';

  @override
  String get noRecentInvestigationAlert =>
      'Aucune alerte d’investigation récente.';

  @override
  String get refresh => 'Actualiser';

  @override
  String get noRecentJustification => 'Aucune justification récente.';

  @override
  String get justificationsForReview => 'Demandes transmises pour vérification';

  @override
  String get absenceValidatedMessage => 'Absence validée';

  @override
  String get documentUnavailable => 'Document indisponible.';

  @override
  String get documentOpenError => 'Impossible d’ouvrir le document.';

  @override
  String get justificationDetail => 'Détail de la justification';

  @override
  String get parentReportedAbsent => 'Déclaration du parent : Absent';

  @override
  String get openAttachedDocument => 'Ouvrir le document joint';

  @override
  String get noAlertsToProcess => 'Aucune alerte d’investigation à traiter.';

  @override
  String get teacherCallsTitle => 'Appels des professeurs';

  @override
  String get teacherAttendanceTracking => 'Suivi des appels de présence';

  @override
  String get temporaryLocalAccess => 'Accès local temporaire';

  @override
  String get teacherCodePrompt => 'Code enseignant';

  @override
  String get teacherCodeExample => 'Ex. ENS-001';

  @override
  String get identityVerified => 'Identité vérifiée';

  @override
  String get simulatedCameraVerification => 'Vérification caméra simulée';

  @override
  String get startAttendanceCall => 'Commencer l’appel';

  @override
  String get verifyIdentity => 'Vérifier l’identité';

  @override
  String get identity => 'Identité';

  @override
  String get teacherPrincipal => 'Enseignant principal';

  @override
  String get enrollmentCount => 'Effectif';

  @override
  String get boys => 'Garçons';

  @override
  String get girls => 'Filles';

  @override
  String get totalSubjects => 'Total matières';

  @override
  String get sessionsToday => 'Séances du jour';

  @override
  String get noSessionMatches => 'Aucun appel ne correspond aux filtres.';

  @override
  String get schoolAttendance => 'Présence globale';

  @override
  String get classFilter => 'Classe';

  @override
  String get teacherFilter => 'Enseignant';

  @override
  String get reviewAttendanceAlerts =>
      'Consultez ici les présences nécessitant une vérification.';

  @override
  String get investigationValidated =>
      'Investigation validée et présence confirmée.';

  @override
  String get investigationUpdated => 'Investigation mise à jour.';

  @override
  String get teacherCallsLoadError =>
      'Impossible de charger les appels des professeurs.';

  @override
  String get allTeachers => 'Tous les enseignants';

  @override
  String get dateNotProvided => 'Date non renseignée';

  @override
  String get classNotProvided => 'Classe non renseignée';

  @override
  String get reasonNotProvided => 'Motif non renseigné';

  @override
  String get pendingStatus => 'En attente';

  @override
  String get validatedAbsenceStatus => 'Absence validée';

  @override
  String get rejectedStatus => 'Rejetée';

  @override
  String get pendingInvestigation => 'En attente de vérification';

  @override
  String get rejectedInvestigation => 'Investigation rejetée';

  @override
  String get parentStatus => 'Statut du parent';

  @override
  String get teacherStatus => 'Statut du professeur';

  @override
  String get absenceDateLabel => 'Date d’absence';

  @override
  String get note => 'Note';

  @override
  String get noNote => 'Aucune note';

  @override
  String get validateTeacherAttendance => 'Valider la présence du professeur';

  @override
  String get lateLabel => 'Retards';

  @override
  String get assignedClasses => 'Classes attribuées';

  @override
  String get allSchoolClasses => 'Toutes les classes de votre établissement';

  @override
  String classesWithSessionsToday(Object count) {
    return '$count avec des séances aujourd’hui';
  }

  @override
  String studentNumbersSummary(Object boys, Object count, Object girls) {
    return '$count élèves\n$boys garçons • $girls filles';
  }

  @override
  String teacherCallsRecordedToday(Object count) {
    return '$count appels enregistrés aujourd’hui';
  }

  @override
  String todayAttendanceSummary(
      Object absent, Object late, Object percentage, Object present) {
    return '$present présents • $absent absents • $late retards\n$percentage aujourd’hui';
  }

  @override
  String get classAccessDescription =>
      'Accès à toutes les classes de l’établissement';

  @override
  String get teacherNoAttendance =>
      'Aucune présence enseignant enregistrée pour ce professeur.';

  @override
  String get createConvocationTooltip => 'Créer une convocation';

  @override
  String get allSubjects => 'Toutes les matières';

  @override
  String get presentStatusLabel => 'Présent';

  @override
  String get absentStatusLabel => 'Absent';

  @override
  String get lateStatusLabel => 'Retard';

  @override
  String get resetDate => 'Réinitialiser la date';

  @override
  String get allStatuses => 'Tous les statuts';

  @override
  String get parentReportedButMarkedPresent =>
      'Le parent a signalé une absence, mais l’élève a été marqué présent.';

  @override
  String get toProcess => 'À traiter';

  @override
  String get boysCount => 'Garçons';

  @override
  String get teacherPresenceLabel => 'Présence enseignant';

  @override
  String get totalStudents => 'Total élèves';

  @override
  String get studentsCountLabel => 'Élèves';

  @override
  String get attendanceToday => 'Présence aujourd\'hui';

  @override
  String get attendanceRateLabel => 'Taux de présence';

  @override
  String get todaySessionsLabel => 'Séances du jour';

  @override
  String get overallAttendance => 'Présence globale';

  @override
  String sessionsByStatus(Object absent, Object late, Object present) {
    return '$present présents • $absent absents • $late retards';
  }

  @override
  String sessionSummary(Object absent, Object date, Object late, Object present,
      Object teacher, Object time) {
    return '$date à $time • $teacher\n$present présents • $absent absents • $late retards';
  }

  @override
  String get subjectsCount => 'Total matières';

  @override
  String get searchClass => 'Rechercher une classe';

  @override
  String teacherCount(Object count) {
    return '$count professeurs';
  }

  @override
  String get allDates => 'Toutes les dates';

  @override
  String get sessionFilterEmpty => 'Aucune session ne correspond aux filtres.';

  @override
  String get followAllClasses => 'Suivi de toutes les classes';

  @override
  String get investigationAlert => 'Alerte d’investigation';

  @override
  String classWithColon(Object className) {
    return 'Classe : $className';
  }

  @override
  String dateWithColon(Object date) {
    return 'Date : $date';
  }

  @override
  String subjectWithCode(Object code) {
    return 'Matière $code';
  }

  @override
  String courseWithCode(Object code) {
    return 'Enseignement $code';
  }

  @override
  String get approvedStatus => 'Approuvée';

  @override
  String get validationInProgress => 'Validation…';

  @override
  String get validate => 'Valider';

  @override
  String get submissionDate => 'Date de soumission';

  @override
  String get marksBySemesters => 'Notes — Séquences';

  @override
  String get marksAvailable => 'Notes disponibles';

  @override
  String get noMarksAvailableForSequence => 'Aucune note disponible';

  @override
  String get mainMenuSubjectCount => 'Nombre de matières';

  @override
  String get mainMenuChildrenCount => 'Nombre d\'enfants';

  @override
  String get mainMenuAttendanceTitle => 'REGISTRE D\'APPEL';

  @override
  String get mainMenuAddAndView => 'Ajoutez et consultez';

  @override
  String get mainMenuMessagesTitle => 'MESSAGES';

  @override
  String get mainMenuMessagesParents => 'Messages aux parents';

  @override
  String get mainMenuGradesTitle => 'NOTES';

  @override
  String get mainMenuSubjectsTitle => 'MATIÈRES';

  @override
  String get mainMenuView => 'Consultez';

  @override
  String get mainMenuHomeworkTitle => 'DEVOIRS';

  @override
  String get mainMenuHomeworkAndMessagesTitle => 'DEVOIR ET MESSAGE';

  @override
  String get mainMenuLateAndAbsenceTitle => 'RETARD ET ABSENCE';

  @override
  String get mainMenuSchoolingTitle => 'SCOLARITÉ';

  @override
  String get mainMenuJustifyAbsenceTitle => 'JUSTIFIER UNE ABSENCE';

  @override
  String get mainMenuSchoolTitle => 'ÉCOLE / UNIVERSITÉ';

  @override
  String get mainMenuSchoolDescription =>
      'Découvrez les écoles, universités et opportunités de formation.';

  @override
  String get mainMenuSendMessagesTitle => 'ENVOYER DES MESSAGES';

  @override
  String get mainMenuConveneParents => 'Convoquez des parents';

  @override
  String get mainMenuViewMessagesTitle => 'CONSULTEZ DES MESSAGES';

  @override
  String get mainMenuViewMessagesDescription =>
      'Consultez les messages envoyés';

  @override
  String get mainMenuStudentListTitle => 'LISTE D\'ÉLÈVES';

  @override
  String get mainMenuAccountTitle => 'MON COMPTE';

  @override
  String get selectStudents => 'Sélectionner les élèves';

  @override
  String selectedStudentsCount(Object selected, Object total) {
    return '$selected / $total élèves sélectionnés';
  }

  @override
  String get deselectAll => 'Tout désélectionner';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get selectStudentAndCompleteFields =>
      'Sélectionnez au moins un élève et remplissez tous les champs';

  @override
  String get convocationSaved => 'Convocation enregistrée avec succès';

  @override
  String get convocationSaveFailed =>
      'Impossible de créer la convocation. Veuillez réessayer plus tard.';

  @override
  String get convocationNetworkError =>
      'Connexion impossible. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get noConvocationForClass =>
      'Aucune convocation pour cette classe pour le moment.';

  @override
  String get createConvocationWithButton =>
      'Vous pouvez créer une nouvelle convocation avec le bouton +.';

  @override
  String get noStudentsAvailable => 'Aucun élève disponible.';

  @override
  String convocationDateReason(Object date, Object reason) {
    return 'Convoqué le $date pour $reason';
  }

  @override
  String get attendanceSaveFailed => 'L\'appel n\'a pas pu être enregistré.';

  @override
  String get institutionType => 'Type d’établissement';

  @override
  String get universityCategoryPlural => 'Universités';

  @override
  String get searchInstitutions => 'Rechercher des institutions';

  @override
  String get institutionsLoadError =>
      'Impossible de charger les institutions pour le moment.';

  @override
  String get noInstitutionFound => 'Aucune institution trouvée';

  @override
  String get featuredInstitutions => 'Institutions à la une';

  @override
  String get all => 'Tout';

  @override
  String get selectOnlyStudentsToConvene =>
      'Ne cochez que les élèves à convoquer';

  @override
  String get continueAction => 'Continuer';

  @override
  String get noSequencesAvailable => 'Aucune séquence disponible';

  @override
  String get sequencesLoadError =>
      'Impossible de charger les séquences. Veuillez réessayer.';

  @override
  String get sequencesWillAppear =>
      'Les séquences apparaîtront ici lorsqu’elles seront disponibles.';

  @override
  String get noSubjectsAvailable => 'Aucune matière disponible';

  @override
  String get subjectsWillAppear =>
      'Les matières de cet élève apparaîtront ici.';

  @override
  String get noEnrollmentYet => 'Aucune inscription pour le moment';

  @override
  String get enrollmentDetailsWillAppear =>
      'Les frais de scolarité de cet enfant n\'ont pas encore été enregistrés. Une fois le paiement effectué, les informations d\'inscription apparaîtront ici.';

  @override
  String get welcomeConsultWithoutStress => 'CONSULTEZ SANS STRESS';

  @override
  String get welcomeStayConnected => 'RESTEZ CONNECTÉ';

  @override
  String get welcomeSignIn => 'CONNECTEZ-VOUS';

  @override
  String get welcomeTagline => 'Votre établissement à portée de main';

  @override
  String get convocationTitle => 'Convocation';
}
