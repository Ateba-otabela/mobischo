import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Mobischo'**
  String get appName;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'reset'**
  String get reset;

  /// No description provided for @emptyFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get emptyFields;

  /// No description provided for @incorrectLogin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect login details.'**
  String get incorrectLogin;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please try again.'**
  String get connectionError;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @principal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get principal;

  /// No description provided for @encadreur.
  ///
  /// In en, this message translates to:
  /// **'Encadreur'**
  String get encadreur;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get noData;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get notes;

  /// No description provided for @absences.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get absences;

  /// No description provided for @myChildren.
  ///
  /// In en, this message translates to:
  /// **'My children'**
  String get myChildren;

  /// No description provided for @registerCall.
  ///
  /// In en, this message translates to:
  /// **'Attendance register'**
  String get registerCall;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @classes.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classes;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @convocations.
  ///
  /// In en, this message translates to:
  /// **'Summons'**
  String get convocations;

  /// No description provided for @presence.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get presence;

  /// No description provided for @absentAttendance.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absentAttendance;

  /// No description provided for @lateAttendance.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get lateAttendance;

  /// No description provided for @schoolUniversity.
  ///
  /// In en, this message translates to:
  /// **'School / University'**
  String get schoolUniversity;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Teacher reports'**
  String get reports;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Investigation alerts'**
  String get alerts;

  /// No description provided for @notInterested.
  ///
  /// In en, this message translates to:
  /// **'Not interested?'**
  String get notInterested;

  /// No description provided for @consult.
  ///
  /// In en, this message translates to:
  /// **'Consult'**
  String get consult;

  /// No description provided for @absencesRecordedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Absences recorded successfully'**
  String get absencesRecordedSuccessfully;

  /// No description provided for @convocationRecordedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Convocation issued successfully'**
  String get convocationRecordedSuccessfully;

  /// No description provided for @clickConsultToSeeAbsences.
  ///
  /// In en, this message translates to:
  /// **'Click Consult to see the list of absences'**
  String get clickConsultToSeeAbsences;

  /// No description provided for @clickConsultToSeeConvocations.
  ///
  /// In en, this message translates to:
  /// **'Click Consult to see the list of convocations'**
  String get clickConsultToSeeConvocations;

  /// No description provided for @chooseClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a class'**
  String get chooseClassTitle;

  /// No description provided for @selectClassToContinue.
  ///
  /// In en, this message translates to:
  /// **'Click a class to continue'**
  String get selectClassToContinue;

  /// No description provided for @teacherCalls.
  ///
  /// In en, this message translates to:
  /// **'Teacher calls'**
  String get teacherCalls;

  /// No description provided for @convoke.
  ///
  /// In en, this message translates to:
  /// **'Convene'**
  String get convoke;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @aiGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello 👋 I’m Mobischo AI.\nI can help you find school information and understand attendance, students, classes, and more.'**
  String get aiGreeting;

  /// No description provided for @aiSuggestionAttendance.
  ///
  /// In en, this message translates to:
  /// **'View attendance'**
  String get aiSuggestionAttendance;

  /// No description provided for @aiSuggestionClass.
  ///
  /// In en, this message translates to:
  /// **'Information about my class'**
  String get aiSuggestionClass;

  /// No description provided for @aiSuggestionHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get aiSuggestionHelp;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'School assistant'**
  String get aiAssistant;

  /// No description provided for @conversationHistory.
  ///
  /// In en, this message translates to:
  /// **'Conversation history'**
  String get conversationHistory;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get newConversation;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No saved conversations.'**
  String get noConversations;

  /// No description provided for @loadOlderConversations.
  ///
  /// In en, this message translates to:
  /// **'Load earlier conversations'**
  String get loadOlderConversations;

  /// No description provided for @genericConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get genericConversation;

  /// No description provided for @deleteConversationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get deleteConversationTooltip;

  /// No description provided for @deleteConversationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this conversation?'**
  String get deleteConversationConfirm;

  /// No description provided for @irreversibleAction.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get irreversibleAction;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @aiTyping.
  ///
  /// In en, this message translates to:
  /// **'Mobischo AI is typing…'**
  String get aiTyping;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeMessage;

  /// No description provided for @microphoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Microphone unavailable'**
  String get microphoneUnavailable;

  /// No description provided for @createConversationError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create a conversation.'**
  String get createConversationError;

  /// No description provided for @openConversationError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this conversation.'**
  String get openConversationError;

  /// No description provided for @deleteConversationError.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete this conversation.'**
  String get deleteConversationError;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpired;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Sorry, something went wrong. Please try again.'**
  String get requestFailed;

  /// No description provided for @emptyAiResponse.
  ///
  /// In en, this message translates to:
  /// **'I did not receive a response. Please try again.'**
  String get emptyAiResponse;

  /// No description provided for @responseTimeout.
  ///
  /// In en, this message translates to:
  /// **'The response is taking too long. Check your connection and try again.'**
  String get responseTimeout;

  /// No description provided for @newConversationFallback.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get newConversationFallback;

  /// No description provided for @sendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendTooltip;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingEllipsis;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get className;

  /// No description provided for @classCode.
  ///
  /// In en, this message translates to:
  /// **'Class code: {code}'**
  String classCode(Object code);

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @studentName.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentName;

  /// No description provided for @teacherName.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherName;

  /// No description provided for @firstAndLastNames.
  ///
  /// In en, this message translates to:
  /// **'First and last names'**
  String get firstAndLastNames;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @studentCode.
  ///
  /// In en, this message translates to:
  /// **'Student code'**
  String get studentCode;

  /// No description provided for @teacherCode.
  ///
  /// In en, this message translates to:
  /// **'Teacher code'**
  String get teacherCode;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDate;

  /// No description provided for @birthPlace.
  ///
  /// In en, this message translates to:
  /// **'Place of birth'**
  String get birthPlace;

  /// No description provided for @enrollmentDate.
  ///
  /// In en, this message translates to:
  /// **'Enrollment date'**
  String get enrollmentDate;

  /// No description provided for @courseCode.
  ///
  /// In en, this message translates to:
  /// **'Course code'**
  String get courseCode;

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'Number of hours'**
  String get hoursCount;

  /// No description provided for @coefficient.
  ///
  /// In en, this message translates to:
  /// **'Coefficient'**
  String get coefficient;

  /// No description provided for @institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution;

  /// No description provided for @studentList.
  ///
  /// In en, this message translates to:
  /// **'Student list'**
  String get studentList;

  /// No description provided for @studentListUpper.
  ///
  /// In en, this message translates to:
  /// **'STUDENT LIST'**
  String get studentListUpper;

  /// No description provided for @chooseClass.
  ///
  /// In en, this message translates to:
  /// **'Choose a class'**
  String get chooseClass;

  /// No description provided for @tapClassToContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap a class to continue'**
  String get tapClassToContinue;

  /// No description provided for @retryLoadingStudents.
  ///
  /// In en, this message translates to:
  /// **'Unable to load students.'**
  String get retryLoadingStudents;

  /// No description provided for @noStudentsInClass.
  ///
  /// In en, this message translates to:
  /// **'There are no students in this class.'**
  String get noStudentsInClass;

  /// No description provided for @searchStudents.
  ///
  /// In en, this message translates to:
  /// **'Search by student name or code'**
  String get searchStudents;

  /// No description provided for @filterByGender.
  ///
  /// In en, this message translates to:
  /// **'Filter by gender'**
  String get filterByGender;

  /// No description provided for @allStudents.
  ///
  /// In en, this message translates to:
  /// **'All students'**
  String get allStudents;

  /// No description provided for @studentSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No students match these filters.'**
  String get studentSearchEmpty;

  /// No description provided for @searchColleague.
  ///
  /// In en, this message translates to:
  /// **'Search for a colleague'**
  String get searchColleague;

  /// No description provided for @noColleagueFound.
  ///
  /// In en, this message translates to:
  /// **'No colleagues found'**
  String get noColleagueFound;

  /// No description provided for @noOtherTeacherAvailable.
  ///
  /// In en, this message translates to:
  /// **'No other teacher is currently available at your institution.'**
  String get noOtherTeacherAvailable;

  /// No description provided for @colleagueLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your colleagues.'**
  String get colleagueLoadError;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get invoiceNumber;

  /// No description provided for @registrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Enrollment label'**
  String get registrationLabel;

  /// No description provided for @installment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get installment;

  /// No description provided for @registrationAmount.
  ///
  /// In en, this message translates to:
  /// **'Enrollment amount'**
  String get registrationAmount;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance payment'**
  String get advance;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining balance'**
  String get remaining;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get totalAmount;

  /// No description provided for @schoolYear.
  ///
  /// In en, this message translates to:
  /// **'School year'**
  String get schoolYear;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @invoiceHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'View this invoice\'s history'**
  String get invoiceHistoryDescription;

  /// No description provided for @viewInstitutionWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit website'**
  String get viewInstitutionWebsite;

  /// No description provided for @institutionWebsiteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the institution\'s website.'**
  String get institutionWebsiteError;

  /// No description provided for @homeDashboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to dashboard'**
  String get homeDashboardTooltip;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get oldestFirst;

  /// No description provided for @sortHomework.
  ///
  /// In en, this message translates to:
  /// **'Sort homework'**
  String get sortHomework;

  /// No description provided for @sortMessages.
  ///
  /// In en, this message translates to:
  /// **'Sort messages'**
  String get sortMessages;

  /// No description provided for @allMyChildren.
  ///
  /// In en, this message translates to:
  /// **'All my children'**
  String get allMyChildren;

  /// No description provided for @sortByChildren.
  ///
  /// In en, this message translates to:
  /// **'Sort by children'**
  String get sortByChildren;

  /// No description provided for @noHomeworkAvailable.
  ///
  /// In en, this message translates to:
  /// **'No homework is available yet.'**
  String get noHomeworkAvailable;

  /// No description provided for @homeworkWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your children\'s homework will appear here once it is published.'**
  String get homeworkWillAppear;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date: {date}'**
  String dueDate(Object date);

  /// No description provided for @subjectAndClass.
  ///
  /// In en, this message translates to:
  /// **'Subject: {subject}   Class: {className}'**
  String subjectAndClass(Object className, Object subject);

  /// No description provided for @noMessagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No messages are available yet.'**
  String get noMessagesAvailable;

  /// No description provided for @messagesWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Messages and institution information will appear here when available.'**
  String get messagesWillAppear;

  /// No description provided for @noJustificationYet.
  ///
  /// In en, this message translates to:
  /// **'No absence justification yet'**
  String get noJustificationYet;

  /// No description provided for @noJustificationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'You have not submitted an absence justification yet.'**
  String get noJustificationSubmitted;

  /// No description provided for @justificationHistoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'History is temporarily unavailable.'**
  String get justificationHistoryUnavailable;

  /// No description provided for @justifyAbsence.
  ///
  /// In en, this message translates to:
  /// **'Justify an absence'**
  String get justifyAbsence;

  /// No description provided for @absenceOnDate.
  ///
  /// In en, this message translates to:
  /// **'Absence on {date}'**
  String absenceOnDate(Object date);

  /// No description provided for @submittedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Submitted on {date}'**
  String submittedOnDate(Object date);

  /// No description provided for @addDocumentOrPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a document or photo'**
  String get addDocumentOrPhoto;

  /// No description provided for @optionalSupportingDocument.
  ///
  /// In en, this message translates to:
  /// **'Supporting document (optional)'**
  String get optionalSupportingDocument;

  /// No description provided for @fileSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'PDF, JPG or PNG · 10 MB maximum'**
  String get fileSizeLimit;

  /// No description provided for @selectedDocument.
  ///
  /// In en, this message translates to:
  /// **'Selected document'**
  String get selectedDocument;

  /// No description provided for @deleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get deleteDocument;

  /// No description provided for @sendJustification.
  ///
  /// In en, this message translates to:
  /// **'Submit justification'**
  String get sendJustification;

  /// No description provided for @selectAtLeastOneStudent.
  ///
  /// In en, this message translates to:
  /// **'Select at least one student.'**
  String get selectAtLeastOneStudent;

  /// No description provided for @studentsToConvene.
  ///
  /// In en, this message translates to:
  /// **'Students to convene'**
  String get studentsToConvene;

  /// No description provided for @convenedStudents.
  ///
  /// In en, this message translates to:
  /// **'Convened students'**
  String get convenedStudents;

  /// No description provided for @moreDetailsTap.
  ///
  /// In en, this message translates to:
  /// **'Tap for more details'**
  String get moreDetailsTap;

  /// No description provided for @conveningReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for convening'**
  String get conveningReason;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @noStudentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No students available.'**
  String get noStudentAvailable;

  /// No description provided for @selectClass.
  ///
  /// In en, this message translates to:
  /// **'Select a class'**
  String get selectClass;

  /// No description provided for @selectSubject.
  ///
  /// In en, this message translates to:
  /// **'Select a subject'**
  String get selectSubject;

  /// No description provided for @selectSubjectForHomework.
  ///
  /// In en, this message translates to:
  /// **'Select a subject to view recent homework.'**
  String get selectSubjectForHomework;

  /// No description provided for @noPreviousHomework.
  ///
  /// In en, this message translates to:
  /// **'No previous homework for this class and subject.'**
  String get noPreviousHomework;

  /// No description provided for @homeworkTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'A title is required.'**
  String get homeworkTitleRequired;

  /// No description provided for @homeworkCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'The homework could not be created.'**
  String get homeworkCreationFailed;

  /// No description provided for @homeworkCreated.
  ///
  /// In en, this message translates to:
  /// **'Homework created successfully.'**
  String get homeworkCreated;

  /// No description provided for @noAssignedClasses.
  ///
  /// In en, this message translates to:
  /// **'No classes are currently assigned to you.'**
  String get noAssignedClasses;

  /// No description provided for @noAssignedSubjects.
  ///
  /// In en, this message translates to:
  /// **'No subjects are currently assigned to you.'**
  String get noAssignedSubjects;

  /// No description provided for @noMarksForSubject.
  ///
  /// In en, this message translates to:
  /// **'No grades are available for this subject.'**
  String get noMarksForSubject;

  /// No description provided for @noMarksForNow.
  ///
  /// In en, this message translates to:
  /// **'No grades are available yet.'**
  String get noMarksForNow;

  /// No description provided for @marksNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Your grades have not been published yet. Please send your grades to the administration so they can be entered and published in the app.'**
  String get marksNotPublished;

  /// No description provided for @marksReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Grades are available in read-only mode.'**
  String get marksReadOnly;

  /// No description provided for @marksLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load grades. Please try again.'**
  String get marksLoadError;

  /// No description provided for @subjectMarksLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load grades for this subject.'**
  String get subjectMarksLoadError;

  /// No description provided for @marksSubjectUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to load grades for this subject.'**
  String get marksSubjectUnavailable;

  /// No description provided for @existingMark.
  ///
  /// In en, this message translates to:
  /// **'Existing grade'**
  String get existingMark;

  /// No description provided for @markValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get markValue;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade: {value}'**
  String noteLabel(Object value);

  /// No description provided for @sequencesEvaluations.
  ///
  /// In en, this message translates to:
  /// **'Assessment periods'**
  String get sequencesEvaluations;

  /// No description provided for @schoolYears.
  ///
  /// In en, this message translates to:
  /// **'School years'**
  String get schoolYears;

  /// No description provided for @attendanceNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Unable to load attendance'**
  String get attendanceNotLoaded;

  /// No description provided for @attendanceLoadError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading attendance. Please try again.'**
  String get attendanceLoadError;

  /// No description provided for @noCallRecorded.
  ///
  /// In en, this message translates to:
  /// **'No attendance call recorded'**
  String get noCallRecorded;

  /// No description provided for @noCallForDate.
  ///
  /// In en, this message translates to:
  /// **'No attendance call for this date'**
  String get noCallForDate;

  /// No description provided for @noCallYetForSubject.
  ///
  /// In en, this message translates to:
  /// **'No attendance has been recorded for this subject yet.\nTap + to record the first attendance call.'**
  String get noCallYetForSubject;

  /// No description provided for @noCallForSubjectDate.
  ///
  /// In en, this message translates to:
  /// **'No attendance has been recorded for this subject on the selected date.\nChoose another date or create a new attendance call with +.'**
  String get noCallForSubjectDate;

  /// No description provided for @presentAbsentLateCount.
  ///
  /// In en, this message translates to:
  /// **'Present: {present}   Absent: {absent}   Late: {late}'**
  String presentAbsentLateCount(Object absent, Object late, Object present);

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get selectDate;

  /// No description provided for @saveCallFailed.
  ///
  /// In en, this message translates to:
  /// **'The attendance call could not be saved.'**
  String get saveCallFailed;

  /// No description provided for @saveCallForDate.
  ///
  /// In en, this message translates to:
  /// **'Record attendance for {date}'**
  String saveCallForDate(Object date);

  /// No description provided for @noStudentsForSubject.
  ///
  /// In en, this message translates to:
  /// **'No students found for this subject'**
  String get noStudentsForSubject;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absenceValidated.
  ///
  /// In en, this message translates to:
  /// **'Attendance validated'**
  String get absenceValidated;

  /// No description provided for @dateOfCall.
  ///
  /// In en, this message translates to:
  /// **'Attendance date'**
  String get dateOfCall;

  /// No description provided for @recordedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Recorded on'**
  String get recordedOnDate;

  /// No description provided for @editAbsences.
  ///
  /// In en, this message translates to:
  /// **'Edit absences'**
  String get editAbsences;

  /// No description provided for @callHours.
  ///
  /// In en, this message translates to:
  /// **'Attendance hours'**
  String get callHours;

  /// No description provided for @numberOfHours.
  ///
  /// In en, this message translates to:
  /// **'Number of hours'**
  String get numberOfHours;

  /// No description provided for @attendanceDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String attendanceDate(Object date);

  /// No description provided for @conveningDate.
  ///
  /// In en, this message translates to:
  /// **'Summons date'**
  String get conveningDate;

  /// No description provided for @convokedOn.
  ///
  /// In en, this message translates to:
  /// **'Convened on {date} for {reason}'**
  String convokedOn(Object date, Object reason);

  /// No description provided for @convocationMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get convocationMessage;

  /// No description provided for @noConvocations.
  ///
  /// In en, this message translates to:
  /// **'No summons available.'**
  String get noConvocations;

  /// No description provided for @noAssignedSubjectForConvocation.
  ///
  /// In en, this message translates to:
  /// **'No subjects are currently assigned to you.'**
  String get noAssignedSubjectForConvocation;

  /// No description provided for @grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get grades;

  /// No description provided for @marksByClass.
  ///
  /// In en, this message translates to:
  /// **'Grades — Classes'**
  String get marksByClass;

  /// No description provided for @marksBySubject.
  ///
  /// In en, this message translates to:
  /// **'Grades — Subjects'**
  String get marksBySubject;

  /// No description provided for @studentGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade: {value}'**
  String studentGrade(Object value);

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @connectionIssue.
  ///
  /// In en, this message translates to:
  /// **'Connection problem. Please try again.'**
  String get connectionIssue;

  /// No description provided for @institutionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load institution information.'**
  String get institutionLoadError;

  /// No description provided for @principalDashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the dashboard.'**
  String get principalDashboardLoadError;

  /// No description provided for @principalAttendanceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load attendance.'**
  String get principalAttendanceLoadError;

  /// No description provided for @chooseClassToViewStudents.
  ///
  /// In en, this message translates to:
  /// **'Select a class to view its students'**
  String get chooseClassToViewStudents;

  /// No description provided for @teachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachers;

  /// No description provided for @investigationAlerts.
  ///
  /// In en, this message translates to:
  /// **'Investigation alerts'**
  String get investigationAlerts;

  /// No description provided for @teacherPresence.
  ///
  /// In en, this message translates to:
  /// **'Teacher attendance'**
  String get teacherPresence;

  /// No description provided for @teacherReports.
  ///
  /// In en, this message translates to:
  /// **'Teacher reports'**
  String get teacherReports;

  /// No description provided for @teacherCallHistory.
  ///
  /// In en, this message translates to:
  /// **'Teacher attendance history'**
  String get teacherCallHistory;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @simulatedData.
  ///
  /// In en, this message translates to:
  /// **'The displayed data is simulated.'**
  String get simulatedData;

  /// No description provided for @teacherVerification.
  ///
  /// In en, this message translates to:
  /// **'Teacher verification'**
  String get teacherVerification;

  /// No description provided for @prepareFutureClassCall.
  ///
  /// In en, this message translates to:
  /// **'Prepare a future class attendance call'**
  String get prepareFutureClassCall;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get signOut;

  /// No description provided for @cameraVerification.
  ///
  /// In en, this message translates to:
  /// **'Camera verification'**
  String get cameraVerification;

  /// No description provided for @verificationFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Verification failed / Retry'**
  String get verificationFailedRetry;

  /// No description provided for @attendanceDetail.
  ///
  /// In en, this message translates to:
  /// **'Attendance details'**
  String get attendanceDetail;

  /// No description provided for @attendanceRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get attendanceRate;

  /// No description provided for @studentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String studentCount(Object count);

  /// No description provided for @presentStudents.
  ///
  /// In en, this message translates to:
  /// **'{count} present'**
  String presentStudents(Object count);

  /// No description provided for @absentStudents.
  ///
  /// In en, this message translates to:
  /// **'{count} absent'**
  String absentStudents(Object count);

  /// No description provided for @lateStudents.
  ///
  /// In en, this message translates to:
  /// **'{count} late'**
  String lateStudents(Object count);

  /// No description provided for @welcomeInstitution.
  ///
  /// In en, this message translates to:
  /// **'Your institution at your fingertips'**
  String get welcomeInstitution;

  /// No description provided for @convocationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Summons sent successfully'**
  String get convocationSuccess;

  /// No description provided for @absencesSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Absences saved successfully'**
  String get absencesSavedSuccess;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordUpdatedSuccess;

  /// No description provided for @userDetails.
  ///
  /// In en, this message translates to:
  /// **'User details'**
  String get userDetails;

  /// No description provided for @accountCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get accountCode;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get disconnect;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get myAccount;

  /// No description provided for @colleagues.
  ///
  /// In en, this message translates to:
  /// **'My colleagues'**
  String get colleagues;

  /// No description provided for @allGradesRegistered.
  ///
  /// In en, this message translates to:
  /// **'All your recorded grades'**
  String get allGradesRegistered;

  /// No description provided for @manageAbsencesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add and view absences'**
  String get manageAbsencesDescription;

  /// No description provided for @colleaguesListDescription.
  ///
  /// In en, this message translates to:
  /// **'Your colleagues'**
  String get colleaguesListDescription;

  /// No description provided for @sendAndView.
  ///
  /// In en, this message translates to:
  /// **'Send and view'**
  String get sendAndView;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Your personal information'**
  String get personalInformation;

  /// No description provided for @insubordination.
  ///
  /// In en, this message translates to:
  /// **'Insubordination'**
  String get insubordination;

  /// No description provided for @excessiveLateness.
  ///
  /// In en, this message translates to:
  /// **'Repeated lateness'**
  String get excessiveLateness;

  /// No description provided for @violence.
  ///
  /// In en, this message translates to:
  /// **'Violence'**
  String get violence;

  /// No description provided for @indiscipline.
  ///
  /// In en, this message translates to:
  /// **'Indiscipline'**
  String get indiscipline;

  /// No description provided for @otherReason.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherReason;

  /// No description provided for @loadingWithEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingWithEllipsis;

  /// No description provided for @codeTeaching.
  ///
  /// In en, this message translates to:
  /// **'Course code'**
  String get codeTeaching;

  /// No description provided for @convocationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Summons date'**
  String get convocationDateLabel;

  /// No description provided for @sentDate.
  ///
  /// In en, this message translates to:
  /// **'Date sent'**
  String get sentDate;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get hour;

  /// No description provided for @dateOfRegistration.
  ///
  /// In en, this message translates to:
  /// **'Date recorded'**
  String get dateOfRegistration;

  /// No description provided for @classDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classDateLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateLabel(Object date);

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @calendarSortHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the calendar icon to sort'**
  String get calendarSortHint;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @passwordChangeError.
  ///
  /// In en, this message translates to:
  /// **'Could not change the password.'**
  String get passwordChangeError;

  /// No description provided for @clickToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get clickToEdit;

  /// No description provided for @clickToSignOut.
  ///
  /// In en, this message translates to:
  /// **'Tap to sign out'**
  String get clickToSignOut;

  /// No description provided for @studentListNav.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentListNav;

  /// No description provided for @attendanceNav.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get attendanceNav;

  /// No description provided for @enrollmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Enrollment history'**
  String get enrollmentHistory;

  /// No description provided for @schoolNews.
  ///
  /// In en, this message translates to:
  /// **'Institution news'**
  String get schoolNews;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Your personal information'**
  String get accountInformation;

  /// No description provided for @sendMessages.
  ///
  /// In en, this message translates to:
  /// **'Send messages'**
  String get sendMessages;

  /// No description provided for @viewMessages.
  ///
  /// In en, this message translates to:
  /// **'View messages'**
  String get viewMessages;

  /// No description provided for @sendMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Convene parents'**
  String get sendMessagesDescription;

  /// No description provided for @viewMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'View sent messages'**
  String get viewMessagesDescription;

  /// No description provided for @conveneParents.
  ///
  /// In en, this message translates to:
  /// **'Convene parents'**
  String get conveneParents;

  /// No description provided for @viewStudentLists.
  ///
  /// In en, this message translates to:
  /// **'View student lists'**
  String get viewStudentLists;

  /// No description provided for @pageHome.
  ///
  /// In en, this message translates to:
  /// **'Home page'**
  String get pageHome;

  /// No description provided for @secureAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get secureAccount;

  /// No description provided for @leaveSession.
  ///
  /// In en, this message translates to:
  /// **'End your session'**
  String get leaveSession;

  /// No description provided for @allClasses.
  ///
  /// In en, this message translates to:
  /// **'All classes'**
  String get allClasses;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications at the moment.'**
  String get notificationsEmpty;

  /// No description provided for @markNotificationRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markNotificationRead;

  /// No description provided for @markAllNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllNotificationsRead;

  /// No description provided for @notificationUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationUnread;

  /// No description provided for @notificationRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationRead;

  /// No description provided for @notificationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications.'**
  String get notificationLoadError;

  /// No description provided for @notificationClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get notificationClass;

  /// No description provided for @notificationBellTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationBellTooltip;

  /// No description provided for @messagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get messagesEmpty;

  /// No description provided for @requestFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get requestFailedTryAgain;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @newHomework.
  ///
  /// In en, this message translates to:
  /// **'New homework'**
  String get newHomework;

  /// No description provided for @homeworkDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get homeworkDescription;

  /// No description provided for @homeworkDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get homeworkDueDate;

  /// No description provided for @recordedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get recordedSuccessfully;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @loginName.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginName;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @enrollmentHistoryPayments.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get enrollmentHistoryPayments;

  /// No description provided for @absenceSummaryClear.
  ///
  /// In en, this message translates to:
  /// **'Good news! No late arrivals or absences have been recorded for this student yet.'**
  String get absenceSummaryClear;

  /// No description provided for @noAbsenceOrLate.
  ///
  /// In en, this message translates to:
  /// **'No late arrivals or absences'**
  String get noAbsenceOrLate;

  /// No description provided for @absenceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Absences'**
  String get absenceListTitle;

  /// No description provided for @schoolName.
  ///
  /// In en, this message translates to:
  /// **'School / University'**
  String get schoolName;

  /// No description provided for @moreRecent.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get moreRecent;

  /// No description provided for @moreAncient.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get moreAncient;

  /// No description provided for @absenceDatePicker.
  ///
  /// In en, this message translates to:
  /// **'Select the absence date'**
  String get absenceDatePicker;

  /// No description provided for @documentReadError.
  ///
  /// In en, this message translates to:
  /// **'The selected document could not be read.'**
  String get documentReadError;

  /// No description provided for @documentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The document must not exceed 10 MB.'**
  String get documentTooLarge;

  /// No description provided for @documentSelectError.
  ///
  /// In en, this message translates to:
  /// **'Unable to select this document.'**
  String get documentSelectError;

  /// No description provided for @justificationSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Justification submitted successfully'**
  String get justificationSentSuccess;

  /// No description provided for @awaitingVerification.
  ///
  /// In en, this message translates to:
  /// **'It is awaiting review.'**
  String get awaitingVerification;

  /// No description provided for @backToHistory.
  ///
  /// In en, this message translates to:
  /// **'Back to history'**
  String get backToHistory;

  /// No description provided for @justificationSubmissionError.
  ///
  /// In en, this message translates to:
  /// **'The justification could not be submitted. Check your connection and try again.'**
  String get justificationSubmissionError;

  /// No description provided for @newJustification.
  ///
  /// In en, this message translates to:
  /// **'New justification'**
  String get newJustification;

  /// No description provided for @childStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Select the child concerned'**
  String get childStepTitle;

  /// No description provided for @absenceDate.
  ///
  /// In en, this message translates to:
  /// **'Absence date'**
  String get absenceDate;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @absenceExplanationLabel.
  ///
  /// In en, this message translates to:
  /// **'Briefly explain the reason for the absence *'**
  String get absenceExplanationLabel;

  /// No description provided for @explainChosenReason.
  ///
  /// In en, this message translates to:
  /// **'Explain the selected reason.'**
  String get explainChosenReason;

  /// No description provided for @addExplanation.
  ///
  /// In en, this message translates to:
  /// **'Add an explanation.'**
  String get addExplanation;

  /// No description provided for @addSomeDetails.
  ///
  /// In en, this message translates to:
  /// **'Add a few details (at least 10 characters).'**
  String get addSomeDetails;

  /// No description provided for @reasonIllness.
  ///
  /// In en, this message translates to:
  /// **'Illness'**
  String get reasonIllness;

  /// No description provided for @reasonMedicalAppointment.
  ///
  /// In en, this message translates to:
  /// **'Medical appointment'**
  String get reasonMedicalAppointment;

  /// No description provided for @reasonFamily.
  ///
  /// In en, this message translates to:
  /// **'Family reasons'**
  String get reasonFamily;

  /// No description provided for @reasonFamilyEmergency.
  ///
  /// In en, this message translates to:
  /// **'Family emergency'**
  String get reasonFamilyEmergency;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class {className}'**
  String classLabel(Object className);

  /// No description provided for @classSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a class'**
  String get classSelectionTitle;

  /// No description provided for @homeworkTab.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homeworkTab;

  /// No description provided for @noAbsenceRecorded.
  ///
  /// In en, this message translates to:
  /// **'No late arrivals or absences have been recorded.'**
  String get noAbsenceRecorded;

  /// No description provided for @absenceDetails.
  ///
  /// In en, this message translates to:
  /// **'Absence details'**
  String get absenceDetails;

  /// No description provided for @notice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get notice;

  /// No description provided for @schoolAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Institution announcement'**
  String get schoolAnnouncement;

  /// No description provided for @noSchoolNews.
  ///
  /// In en, this message translates to:
  /// **'No news is available yet.'**
  String get noSchoolNews;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String createdOn(Object date);

  /// No description provided for @studentDetails.
  ///
  /// In en, this message translates to:
  /// **'Student details'**
  String get studentDetails;

  /// No description provided for @enrollmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Enrollment details'**
  String get enrollmentDetails;

  /// No description provided for @courseDetails.
  ///
  /// In en, this message translates to:
  /// **'Course details'**
  String get courseDetails;

  /// No description provided for @courseStudents.
  ///
  /// In en, this message translates to:
  /// **'Student list'**
  String get courseStudents;

  /// No description provided for @subjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjectsLabel;

  /// No description provided for @enrollmentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrollment history'**
  String get enrollmentHistoryTitle;

  /// No description provided for @consultConvocations.
  ///
  /// In en, this message translates to:
  /// **'View summons'**
  String get consultConvocations;

  /// No description provided for @convocationSent.
  ///
  /// In en, this message translates to:
  /// **'Summons sent'**
  String get convocationSent;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @accountLogin.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get accountLogin;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @attendanceReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get attendanceReason;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed successfully.'**
  String get passwordChangeSuccess;

  /// No description provided for @chooseSequence.
  ///
  /// In en, this message translates to:
  /// **'Choose an assessment period'**
  String get chooseSequence;

  /// No description provided for @chooseSchoolYear.
  ///
  /// In en, this message translates to:
  /// **'Choose a school year'**
  String get chooseSchoolYear;

  /// No description provided for @selectYourChild.
  ///
  /// In en, this message translates to:
  /// **'Select your child'**
  String get selectYourChild;

  /// No description provided for @childrenLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your children right now.'**
  String get childrenLoadError;

  /// No description provided for @noChildLinked.
  ///
  /// In en, this message translates to:
  /// **'No child is linked to your account.'**
  String get noChildLinked;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @chooseReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason *'**
  String get chooseReason;

  /// No description provided for @selectReason.
  ///
  /// In en, this message translates to:
  /// **'Select a reason.'**
  String get selectReason;

  /// No description provided for @enrollmentHistoryDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get enrollmentHistoryDetails;

  /// No description provided for @messageFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort messages'**
  String get messageFilter;

  /// No description provided for @courseLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your classes and subjects.'**
  String get courseLoadError;

  /// No description provided for @noMark.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noMark;

  /// No description provided for @sequenceMarksNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Grades for this assessment period have not been recorded yet.\nPlease check back later.'**
  String get sequenceMarksNotRecorded;

  /// No description provided for @returnBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get returnBack;

  /// No description provided for @noMarksRecorded.
  ///
  /// In en, this message translates to:
  /// **'No grades recorded'**
  String get noMarksRecorded;

  /// No description provided for @totalCoefficients.
  ///
  /// In en, this message translates to:
  /// **'Total coefficients: {value}'**
  String totalCoefficients(Object value);

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total points: {value}'**
  String totalPoints(Object value);

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average: {value} / 20'**
  String average(Object value);

  /// No description provided for @noSchoolYearAvailable.
  ///
  /// In en, this message translates to:
  /// **'No school year available'**
  String get noSchoolYearAvailable;

  /// No description provided for @yearsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'School years will appear here when available.'**
  String get yearsWillAppear;

  /// No description provided for @consultYearGrades.
  ///
  /// In en, this message translates to:
  /// **'View this year\'s grades'**
  String get consultYearGrades;

  /// No description provided for @noAbsenceHistory.
  ///
  /// In en, this message translates to:
  /// **'No late arrivals or absences have been recorded for this student yet.'**
  String get noAbsenceHistory;

  /// No description provided for @privateInstitution.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateInstitution;

  /// No description provided for @publicInstitution.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicInstitution;

  /// No description provided for @programs.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programs;

  /// No description provided for @universityCategory.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get universityCategory;

  /// No description provided for @locatedAt.
  ///
  /// In en, this message translates to:
  /// **'Located in'**
  String get locatedAt;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @conveneStudents.
  ///
  /// In en, this message translates to:
  /// **'Convene students'**
  String get conveneStudents;

  /// No description provided for @createConvocation.
  ///
  /// In en, this message translates to:
  /// **'Create a summons'**
  String get createConvocation;

  /// No description provided for @recentConvocations.
  ///
  /// In en, this message translates to:
  /// **'Recent summons'**
  String get recentConvocations;

  /// No description provided for @convocationSentToStudents.
  ///
  /// In en, this message translates to:
  /// **'Track summons sent to students'**
  String get convocationSentToStudents;

  /// No description provided for @convocationsSent.
  ///
  /// In en, this message translates to:
  /// **'Summons sent'**
  String get convocationsSent;

  /// No description provided for @noConvocationSent.
  ///
  /// In en, this message translates to:
  /// **'No summons have been sent.'**
  String get noConvocationSent;

  /// No description provided for @recentCall.
  ///
  /// In en, this message translates to:
  /// **'Recent attendance call'**
  String get recentCall;

  /// No description provided for @alertsAndNotifications.
  ///
  /// In en, this message translates to:
  /// **'Alerts and notifications'**
  String get alertsAndNotifications;

  /// No description provided for @recentJustifications.
  ///
  /// In en, this message translates to:
  /// **'Recent justifications'**
  String get recentJustifications;

  /// No description provided for @callsToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s attendance calls'**
  String get callsToday;

  /// No description provided for @noAttendanceSession.
  ///
  /// In en, this message translates to:
  /// **'No attendance sessions have been recorded.'**
  String get noAttendanceSession;

  /// No description provided for @classOverview.
  ///
  /// In en, this message translates to:
  /// **'Class overview'**
  String get classOverview;

  /// No description provided for @noClassAvailable.
  ///
  /// In en, this message translates to:
  /// **'No classes available.'**
  String get noClassAvailable;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get viewMore;

  /// No description provided for @recentTeacherCalls.
  ///
  /// In en, this message translates to:
  /// **'Recent teacher attendance calls'**
  String get recentTeacherCalls;

  /// No description provided for @classSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No classes match your search.'**
  String get classSearchEmpty;

  /// No description provided for @classesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load classes.'**
  String get classesLoadError;

  /// No description provided for @noTeacherAvailable.
  ///
  /// In en, this message translates to:
  /// **'No teachers available.'**
  String get noTeacherAvailable;

  /// No description provided for @teacherAttendanceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the teacher\'s attendance.'**
  String get teacherAttendanceLoadError;

  /// No description provided for @noSessionMatchesFilters.
  ///
  /// In en, this message translates to:
  /// **'No sessions match the filters.'**
  String get noSessionMatchesFilters;

  /// No description provided for @studentDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Student details'**
  String get studentDetailTitle;

  /// No description provided for @attendanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Attendance history'**
  String get attendanceHistory;

  /// No description provided for @attendanceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance details'**
  String get attendanceDetailTitle;

  /// No description provided for @reportDetail.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportDetail;

  /// No description provided for @rejectTeacherAttendance.
  ///
  /// In en, this message translates to:
  /// **'Reject teacher attendance'**
  String get rejectTeacherAttendance;

  /// No description provided for @noRecentInvestigationAlert.
  ///
  /// In en, this message translates to:
  /// **'No recent investigation alerts.'**
  String get noRecentInvestigationAlert;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noRecentJustification.
  ///
  /// In en, this message translates to:
  /// **'No recent justifications.'**
  String get noRecentJustification;

  /// No description provided for @justificationsForReview.
  ///
  /// In en, this message translates to:
  /// **'Requests submitted for review'**
  String get justificationsForReview;

  /// No description provided for @absenceValidatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Absence validated'**
  String get absenceValidatedMessage;

  /// No description provided for @documentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Document unavailable.'**
  String get documentUnavailable;

  /// No description provided for @documentOpenError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the document.'**
  String get documentOpenError;

  /// No description provided for @justificationDetail.
  ///
  /// In en, this message translates to:
  /// **'Justification details'**
  String get justificationDetail;

  /// No description provided for @parentReportedAbsent.
  ///
  /// In en, this message translates to:
  /// **'Parent report: Absent'**
  String get parentReportedAbsent;

  /// No description provided for @openAttachedDocument.
  ///
  /// In en, this message translates to:
  /// **'Open attached document'**
  String get openAttachedDocument;

  /// No description provided for @noAlertsToProcess.
  ///
  /// In en, this message translates to:
  /// **'No investigation alerts to process.'**
  String get noAlertsToProcess;

  /// No description provided for @teacherCallsTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher attendance calls'**
  String get teacherCallsTitle;

  /// No description provided for @teacherAttendanceTracking.
  ///
  /// In en, this message translates to:
  /// **'Attendance call tracking'**
  String get teacherAttendanceTracking;

  /// No description provided for @temporaryLocalAccess.
  ///
  /// In en, this message translates to:
  /// **'Temporary local access'**
  String get temporaryLocalAccess;

  /// No description provided for @teacherCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Teacher code'**
  String get teacherCodePrompt;

  /// No description provided for @teacherCodeExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. TCH-001'**
  String get teacherCodeExample;

  /// No description provided for @identityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get identityVerified;

  /// No description provided for @simulatedCameraVerification.
  ///
  /// In en, this message translates to:
  /// **'Simulated camera verification'**
  String get simulatedCameraVerification;

  /// No description provided for @startAttendanceCall.
  ///
  /// In en, this message translates to:
  /// **'Start attendance call'**
  String get startAttendanceCall;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get verifyIdentity;

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// No description provided for @teacherPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal teacher'**
  String get teacherPrincipal;

  /// No description provided for @enrollmentCount.
  ///
  /// In en, this message translates to:
  /// **'Enrollment'**
  String get enrollmentCount;

  /// No description provided for @boys.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get boys;

  /// No description provided for @girls.
  ///
  /// In en, this message translates to:
  /// **'Girls'**
  String get girls;

  /// No description provided for @totalSubjects.
  ///
  /// In en, this message translates to:
  /// **'Total subjects'**
  String get totalSubjects;

  /// No description provided for @sessionsToday.
  ///
  /// In en, this message translates to:
  /// **'Sessions today'**
  String get sessionsToday;

  /// No description provided for @noSessionMatches.
  ///
  /// In en, this message translates to:
  /// **'No attendance calls match the filters.'**
  String get noSessionMatches;

  /// No description provided for @schoolAttendance.
  ///
  /// In en, this message translates to:
  /// **'Overall attendance'**
  String get schoolAttendance;

  /// No description provided for @classFilter.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classFilter;

  /// No description provided for @teacherFilter.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherFilter;

  /// No description provided for @reviewAttendanceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Review attendance records that require verification here.'**
  String get reviewAttendanceAlerts;

  /// No description provided for @investigationValidated.
  ///
  /// In en, this message translates to:
  /// **'Investigation validated and attendance confirmed.'**
  String get investigationValidated;

  /// No description provided for @investigationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Investigation updated.'**
  String get investigationUpdated;

  /// No description provided for @teacherCallsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load teacher attendance calls.'**
  String get teacherCallsLoadError;

  /// No description provided for @allTeachers.
  ///
  /// In en, this message translates to:
  /// **'All teachers'**
  String get allTeachers;

  /// No description provided for @dateNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Date not provided'**
  String get dateNotProvided;

  /// No description provided for @classNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Class not provided'**
  String get classNotProvided;

  /// No description provided for @reasonNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Reason not provided'**
  String get reasonNotProvided;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @validatedAbsenceStatus.
  ///
  /// In en, this message translates to:
  /// **'Absence validated'**
  String get validatedAbsenceStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedStatus;

  /// No description provided for @pendingInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get pendingInvestigation;

  /// No description provided for @rejectedInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Investigation rejected'**
  String get rejectedInvestigation;

  /// No description provided for @parentStatus.
  ///
  /// In en, this message translates to:
  /// **'Parent status'**
  String get parentStatus;

  /// No description provided for @teacherStatus.
  ///
  /// In en, this message translates to:
  /// **'Teacher status'**
  String get teacherStatus;

  /// No description provided for @absenceDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Absence date'**
  String get absenceDateLabel;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noNote.
  ///
  /// In en, this message translates to:
  /// **'No grade'**
  String get noNote;

  /// No description provided for @validateTeacherAttendance.
  ///
  /// In en, this message translates to:
  /// **'Validate teacher attendance'**
  String get validateTeacherAttendance;

  /// No description provided for @lateLabel.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get lateLabel;

  /// No description provided for @assignedClasses.
  ///
  /// In en, this message translates to:
  /// **'Assigned classes'**
  String get assignedClasses;

  /// No description provided for @allSchoolClasses.
  ///
  /// In en, this message translates to:
  /// **'All classes at your institution'**
  String get allSchoolClasses;

  /// No description provided for @classesWithSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'{count} with sessions today'**
  String classesWithSessionsToday(Object count);

  /// No description provided for @studentNumbersSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} students\n{boys} boys • {girls} girls'**
  String studentNumbersSummary(Object boys, Object count, Object girls);

  /// No description provided for @teacherCallsRecordedToday.
  ///
  /// In en, this message translates to:
  /// **'{count} attendance calls recorded today'**
  String teacherCallsRecordedToday(Object count);

  /// No description provided for @todayAttendanceSummary.
  ///
  /// In en, this message translates to:
  /// **'{present} present • {absent} absent • {late} late\n{percentage} today'**
  String todayAttendanceSummary(
      Object absent, Object late, Object percentage, Object present);

  /// No description provided for @classAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Access to all classes at the institution'**
  String get classAccessDescription;

  /// No description provided for @teacherNoAttendance.
  ///
  /// In en, this message translates to:
  /// **'No teacher attendance has been recorded for this teacher.'**
  String get teacherNoAttendance;

  /// No description provided for @createConvocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create a summons'**
  String get createConvocationTooltip;

  /// No description provided for @allSubjects.
  ///
  /// In en, this message translates to:
  /// **'All subjects'**
  String get allSubjects;

  /// No description provided for @presentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presentStatusLabel;

  /// No description provided for @absentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absentStatusLabel;

  /// No description provided for @lateStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get lateStatusLabel;

  /// No description provided for @resetDate.
  ///
  /// In en, this message translates to:
  /// **'Reset date'**
  String get resetDate;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @parentReportedButMarkedPresent.
  ///
  /// In en, this message translates to:
  /// **'The parent reported an absence, but the student was marked present.'**
  String get parentReportedButMarkedPresent;

  /// No description provided for @toProcess.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get toProcess;

  /// No description provided for @boysCount.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get boysCount;

  /// No description provided for @teacherPresenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher attendance'**
  String get teacherPresenceLabel;

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total students'**
  String get totalStudents;

  /// No description provided for @studentsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentsCountLabel;

  /// No description provided for @attendanceToday.
  ///
  /// In en, this message translates to:
  /// **'Attendance today'**
  String get attendanceToday;

  /// No description provided for @attendanceRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get attendanceRateLabel;

  /// No description provided for @todaySessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions today'**
  String get todaySessionsLabel;

  /// No description provided for @overallAttendance.
  ///
  /// In en, this message translates to:
  /// **'Overall attendance'**
  String get overallAttendance;

  /// No description provided for @sessionsByStatus.
  ///
  /// In en, this message translates to:
  /// **'{present} present • {absent} absent • {late} late'**
  String sessionsByStatus(Object absent, Object late, Object present);

  /// No description provided for @sessionSummary.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time} • {teacher}\n{present} present • {absent} absent • {late} late'**
  String sessionSummary(Object absent, Object date, Object late, Object present,
      Object teacher, Object time);

  /// No description provided for @subjectsCount.
  ///
  /// In en, this message translates to:
  /// **'Total subjects'**
  String get subjectsCount;

  /// No description provided for @searchClass.
  ///
  /// In en, this message translates to:
  /// **'Search for a class'**
  String get searchClass;

  /// No description provided for @teacherCount.
  ///
  /// In en, this message translates to:
  /// **'{count} teachers'**
  String teacherCount(Object count);

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get allDates;

  /// No description provided for @sessionFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions match the filters.'**
  String get sessionFilterEmpty;

  /// No description provided for @followAllClasses.
  ///
  /// In en, this message translates to:
  /// **'Tracking all classes'**
  String get followAllClasses;

  /// No description provided for @investigationAlert.
  ///
  /// In en, this message translates to:
  /// **'Investigation alert'**
  String get investigationAlert;

  /// No description provided for @classWithColon.
  ///
  /// In en, this message translates to:
  /// **'Class: {className}'**
  String classWithColon(Object className);

  /// No description provided for @dateWithColon.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateWithColon(Object date);

  /// No description provided for @subjectWithCode.
  ///
  /// In en, this message translates to:
  /// **'Subject {code}'**
  String subjectWithCode(Object code);

  /// No description provided for @courseWithCode.
  ///
  /// In en, this message translates to:
  /// **'Course {code}'**
  String courseWithCode(Object code);

  /// No description provided for @approvedStatus.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedStatus;

  /// No description provided for @validationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Validating…'**
  String get validationInProgress;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validate;

  /// No description provided for @submissionDate.
  ///
  /// In en, this message translates to:
  /// **'Submission date'**
  String get submissionDate;

  /// No description provided for @marksBySemesters.
  ///
  /// In en, this message translates to:
  /// **'Grades — Assessment periods'**
  String get marksBySemesters;

  /// No description provided for @marksAvailable.
  ///
  /// In en, this message translates to:
  /// **'Grades available'**
  String get marksAvailable;

  /// No description provided for @noMarksAvailableForSequence.
  ///
  /// In en, this message translates to:
  /// **'No grades available'**
  String get noMarksAvailableForSequence;

  /// No description provided for @mainMenuSubjectCount.
  ///
  /// In en, this message translates to:
  /// **'Number of subjects'**
  String get mainMenuSubjectCount;

  /// No description provided for @mainMenuChildrenCount.
  ///
  /// In en, this message translates to:
  /// **'Number of children'**
  String get mainMenuChildrenCount;

  /// No description provided for @mainMenuAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'ATTENDANCE REGISTER'**
  String get mainMenuAttendanceTitle;

  /// No description provided for @mainMenuAddAndView.
  ///
  /// In en, this message translates to:
  /// **'Add and view'**
  String get mainMenuAddAndView;

  /// No description provided for @mainMenuMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'MESSAGES'**
  String get mainMenuMessagesTitle;

  /// No description provided for @mainMenuMessagesParents.
  ///
  /// In en, this message translates to:
  /// **'Messages to parents'**
  String get mainMenuMessagesParents;

  /// No description provided for @mainMenuGradesTitle.
  ///
  /// In en, this message translates to:
  /// **'GRADES'**
  String get mainMenuGradesTitle;

  /// No description provided for @mainMenuSubjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'SUBJECTS'**
  String get mainMenuSubjectsTitle;

  /// No description provided for @mainMenuView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get mainMenuView;

  /// No description provided for @mainMenuHomeworkTitle.
  ///
  /// In en, this message translates to:
  /// **'HOMEWORK'**
  String get mainMenuHomeworkTitle;

  /// No description provided for @mainMenuHomeworkAndMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'HOMEWORK AND MESSAGES'**
  String get mainMenuHomeworkAndMessagesTitle;

  /// No description provided for @mainMenuLateAndAbsenceTitle.
  ///
  /// In en, this message translates to:
  /// **'LATENESS AND ABSENCE'**
  String get mainMenuLateAndAbsenceTitle;

  /// No description provided for @mainMenuSchoolingTitle.
  ///
  /// In en, this message translates to:
  /// **'SCHOOLING'**
  String get mainMenuSchoolingTitle;

  /// No description provided for @mainMenuJustifyAbsenceTitle.
  ///
  /// In en, this message translates to:
  /// **'JUSTIFY AN ABSENCE'**
  String get mainMenuJustifyAbsenceTitle;

  /// No description provided for @mainMenuSchoolTitle.
  ///
  /// In en, this message translates to:
  /// **'SCHOOL / UNIVERSITY'**
  String get mainMenuSchoolTitle;

  /// No description provided for @mainMenuSchoolDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover schools, universities, and training opportunities.'**
  String get mainMenuSchoolDescription;

  /// No description provided for @mainMenuSendMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'SEND MESSAGES'**
  String get mainMenuSendMessagesTitle;

  /// No description provided for @mainMenuConveneParents.
  ///
  /// In en, this message translates to:
  /// **'Convene parents'**
  String get mainMenuConveneParents;

  /// No description provided for @mainMenuViewMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'VIEW MESSAGES'**
  String get mainMenuViewMessagesTitle;

  /// No description provided for @mainMenuViewMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'View sent messages'**
  String get mainMenuViewMessagesDescription;

  /// No description provided for @mainMenuStudentListTitle.
  ///
  /// In en, this message translates to:
  /// **'STUDENT LIST'**
  String get mainMenuStudentListTitle;

  /// No description provided for @mainMenuAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'MY ACCOUNT'**
  String get mainMenuAccountTitle;

  /// No description provided for @selectStudents.
  ///
  /// In en, this message translates to:
  /// **'Select students'**
  String get selectStudents;

  /// No description provided for @selectedStudentsCount.
  ///
  /// In en, this message translates to:
  /// **'{selected} / {total} students selected'**
  String selectedStudentsCount(Object selected, Object total);

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectStudentAndCompleteFields.
  ///
  /// In en, this message translates to:
  /// **'Select at least one student and complete all fields'**
  String get selectStudentAndCompleteFields;

  /// No description provided for @convocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Summons saved successfully'**
  String get convocationSaved;

  /// No description provided for @convocationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create the convocation. Please try again later.'**
  String get convocationSaveFailed;

  /// No description provided for @convocationNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your internet connection and try again.'**
  String get convocationNetworkError;

  /// No description provided for @noConvocationForClass.
  ///
  /// In en, this message translates to:
  /// **'There are no summons for this class yet.'**
  String get noConvocationForClass;

  /// No description provided for @createConvocationWithButton.
  ///
  /// In en, this message translates to:
  /// **'You can create a new summons with the + button.'**
  String get createConvocationWithButton;

  /// No description provided for @noStudentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No students available.'**
  String get noStudentsAvailable;

  /// No description provided for @convocationDateReason.
  ///
  /// In en, this message translates to:
  /// **'Summoned on {date} for {reason}'**
  String convocationDateReason(Object date, Object reason);

  /// No description provided for @attendanceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the attendance register.'**
  String get attendanceSaveFailed;

  /// No description provided for @institutionType.
  ///
  /// In en, this message translates to:
  /// **'Institution type'**
  String get institutionType;

  /// No description provided for @universityCategoryPlural.
  ///
  /// In en, this message translates to:
  /// **'Universities'**
  String get universityCategoryPlural;

  /// No description provided for @searchInstitutions.
  ///
  /// In en, this message translates to:
  /// **'Search institutions'**
  String get searchInstitutions;

  /// No description provided for @institutionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load institutions right now.'**
  String get institutionsLoadError;

  /// No description provided for @noInstitutionFound.
  ///
  /// In en, this message translates to:
  /// **'No institution found'**
  String get noInstitutionFound;

  /// No description provided for @featuredInstitutions.
  ///
  /// In en, this message translates to:
  /// **'Featured institutions'**
  String get featuredInstitutions;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @selectOnlyStudentsToConvene.
  ///
  /// In en, this message translates to:
  /// **'Select only the students to be summoned'**
  String get selectOnlyStudentsToConvene;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @noSequencesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No assessment periods available'**
  String get noSequencesAvailable;

  /// No description provided for @sequencesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load assessment periods. Please try again.'**
  String get sequencesLoadError;

  /// No description provided for @sequencesWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Assessment periods will appear here when available.'**
  String get sequencesWillAppear;

  /// No description provided for @noSubjectsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No subjects available'**
  String get noSubjectsAvailable;

  /// No description provided for @subjectsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'This student\'s subjects will appear here.'**
  String get subjectsWillAppear;

  /// No description provided for @noEnrollmentYet.
  ///
  /// In en, this message translates to:
  /// **'No enrollment yet'**
  String get noEnrollmentYet;

  /// No description provided for @enrollmentDetailsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Tuition fees for this child have not been recorded yet. Once payment is completed, enrollment information will appear here.'**
  String get enrollmentDetailsWillAppear;

  /// No description provided for @welcomeConsultWithoutStress.
  ///
  /// In en, this message translates to:
  /// **'CHECK WITHOUT STRESS'**
  String get welcomeConsultWithoutStress;

  /// No description provided for @welcomeStayConnected.
  ///
  /// In en, this message translates to:
  /// **'STAY CONNECTED'**
  String get welcomeStayConnected;

  /// No description provided for @welcomeSignIn.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get welcomeSignIn;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Your school within reach'**
  String get welcomeTagline;

  /// No description provided for @convocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Summons'**
  String get convocationTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
