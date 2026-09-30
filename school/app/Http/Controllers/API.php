<?php

namespace App\Http\Controllers;

use App\Models\Note;
use App\Models\User;
use App\Models\Annee;
use App\Models\Eleve;
use App\Models\Classe;
use App\Models\Matiere;
use App\Models\Conduite;
use App\Models\Convocation;
use App\Models\Devoir;
use App\Models\Inscription;
use App\Models\Enseignement;
use App\Models\Advert;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use App\Models\SequenceEvaluation;
use Illuminate\Support\Facades\DB;
use App\Models\HistoriqueInscription;
use App\Models\AbsenceJustification;
use App\Models\InvestigationAlert;
use App\Services\EncadreurClassScope;
use App\Services\NotificationDispatchService;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class API extends Controller
{
    private function isMobileEligibleUser(User $user): bool
    {
        $accountType = strtolower(trim((string) ($user->account_type ?? '')));

        return (bool) $user->admin || in_array($accountType, [
            'parent',
            'enseignant',
            'principal',
            'encadreur',
            'principal_encadreur',
            'administrateur',
        ], true);
    }

    public function mobileLogin(Request $request)
    {
        $action = strtoupper((string) $request->input('action', ''));

        if ($action !== 'LOGIN') {
            return response()->json('Error');
        }

        $login = trim((string) $request->input('login', ''));
        $textPassword = trim((string) $request->input('text_password', ''));

        if ($login === '' || $textPassword === '') {
            return response()->json('Error');
        }

        $user = User::where('login', $login)->first();

        if (!$user) {
            return response()->json('Error');
        }

        $storedTextPassword = (string) ($user->text_password ?? '');
        $storedPasswordHash = (string) ($user->password ?? '');

        $matchesLegacyPassword = $storedTextPassword !== ''
            && (hash_equals($storedTextPassword, $textPassword) || strcasecmp($storedTextPassword, $textPassword) === 0);

        $matchesHash = $storedPasswordHash !== '' && Hash::check($textPassword, $storedPasswordHash);

        if (!$matchesLegacyPassword && !$matchesHash) {
            return response()->json('Error');
        }

        if (!$this->isMobileEligibleUser($user)) {
            return response()->json('Error');
        }

        $mobileToken = $user->createToken('mobischo-mobile', ['mobischo:mobile'])
            ->plainTextToken;

        $aiToken = null;
        if ((new \App\Services\PrincipalContextService())->canUseAi($user)) {
            $aiToken = $user->createToken('mobischo-principal-ai', ['ai:chat'])
                ->plainTextToken;
        }

        $userPayload = [
            'nom' => (string) ($user->nom ?? ''),
            'prenom' => (string) ($user->prenom ?? ''),
            'contacts' => (string) ($user->contacts ?? ''),
            'sex' => (string) ($user->sex ?? ''),
            'email' => (string) ($user->email ?? ''),
            'login' => (string) ($user->login ?? ''),
            'code' => (string) ($user->code ?? ''),
            'account_type' => (string) ($user->account_type ?? ''),
            'address' => (string) ($user->address ?? ''),
            'admin' => (string) ($user->admin ?? '0'),
            'CodeEtablissement' => (string) ($user->CodeEtablissement ?? ''),
            'token' => $mobileToken,
            'ai_token' => $aiToken,
        ];

        return response()->json([$userPayload]);
    }

    public function mobileLogout(Request $request)
    {
        $token = $request->user()?->currentAccessToken();

        if ($token) {
            $token->delete();
        }

        return response()->json(['success' => true]);
    }

    public function school_manager(Request $request)
    {
        $action = $request->action;

        if ($action == 'SUBMIT_ABSENCE_JUSTIFICATION') {
            $parentCode = trim((string) $request->input('code', ''));
            $studentCode = trim((string) $request->input('CodeEleve', ''));
            $absenceDate = trim((string) $request->input('date_absence', ''));
            $reason = trim((string) $request->input('motif', ''));
            $description = trim((string) $request->input('justification', ''));

            if ($parentCode === '' || $studentCode === '' || $absenceDate === '' ||
                $reason === '' || $description === '') {
                return response()->json(['error' => 'Les champs de justification sont obligatoires.'], 422);
            }

            $studentBelongsToParent = Eleve::where('CodeEleve', $studentCode)
                ->where('code', $parentCode)
                ->exists();
            if (!$studentBelongsToParent) {
                return response()->json(['error' => 'Élève non autorisé.'], 403);
            }

            $parsedDate = \DateTime::createFromFormat('Y-m-d', $absenceDate);
            $dateErrors = \DateTime::getLastErrors();
            if (!$parsedDate || ($dateErrors !== false && ($dateErrors['warning_count'] > 0 || $dateErrors['error_count'] > 0)) ||
                $parsedDate->format('Y-m-d') !== $absenceDate) {
                return response()->json(['error' => 'La date d’absence est invalide.'], 422);
            }

            $justification = AbsenceJustification::create([
                'parent_code' => $parentCode,
                'CodeEleve' => $studentCode,
                'date_absence' => $absenceDate,
                'motif' => $reason,
                'justification' => $description,
                'piece_jointe' => trim((string) $request->input('piece_jointe', '')) ?: null,
                'statut' => 'En attente',
            ]);

            $student = Eleve::query()->where('CodeEleve', $studentCode)->first();
            if ($student) {
                $schoolCode = trim((string) ((User::where('code', '=', $parentCode)->value('CodeEtablissement')) ?? ''));
                $dispatcher = new NotificationDispatchService();
                $dispatcher->dispatchAbsenceJustificationNotification($studentCode, $parentCode, ['school_code' => $schoolCode]);
            }

            return response()->json(['status' => 'success', 'id' => $justification->id]);
        }

        if ($action == 'GET_PARENT_ABSENCE_JUSTIFICATIONS') {
            $parentCode = trim((string) $request->input('code', ''));
            $studentCodes = Eleve::where('code', $parentCode)->pluck('CodeEleve');
            return AbsenceJustification::where('parent_code', '=', $parentCode)
                ->whereIn('CodeEleve', $studentCodes)
                ->orderBy('date_absence', 'DESC')
                ->orderBy('created_at', 'DESC')
                ->get();
        }

        #users
        if($action == 'GET_ALL'){
            $users = User::where('account_type','=','enseignant')->get();
            return $users;
        }

        if($action == 'GET_MAIN_USER'){
            $code = $request->code;
            $user = User::where('code','=',$code)->get();
            return $user;
        }

        if ($action == 'GET_TEACHER_COLLEAGUES') {
            $teacherCode = trim((string) $request->input('teacher_code', ''));
            $schoolCode = trim((string) $request->input('CodeEtablissement', ''));

            if ($teacherCode === '' || $schoolCode === '') {
                return response()->json([], 200);
            }

            $teacher = User::where('code', '=', $teacherCode)
                ->where('account_type', '=', 'enseignant')
                ->first();

            if (!$teacher || (string) ($teacher->CodeEtablissement ?? '') !== $schoolCode) {
                return response()->json([], 200);
            }

            return User::where('account_type', '=', 'enseignant')
                ->where('CodeEtablissement', '=', $schoolCode)
                ->where('code', '!=', $teacherCode)
                ->orderBy('nom')
                ->orderBy('prenom')
                ->get();
        }

        #marks
        if($action == 'GET_COURSE_MARKS'){
            $CodeEnseignement = $request->CodeEnseignement;
            $marks = Note::where('CodeEnseignement','=',$CodeEnseignement)->get();
            return $marks;
        }

        if($action == 'GET_SORTED_COURSE_MARKS'){
            $codeEnseignement = $request->codeEnseignement;
            $codeAnnee = $request->codeAnnee;
            $codeEvaluation = $request->codeEvaluation;
            
            $marks = Note::where('CodeEnseignement','=',$codeEnseignement)->where('CodeAnnee','=',$codeAnnee)->where('CodeEvaluation','=',$codeEvaluation)->get();
            return $marks;
        }

        if($action == 'GET_STUDENT_MARKS'){
            $CodeEnseignement = $request->CodeEnseignement;
            $CodeEleve = $request->CodeEleve;
            
            $marks = Note::where('CodeEnseignement','=',$CodeEnseignement)->where('CodeEleve','=',$CodeEleve)->get();
            return $marks;
        }
        if($action == 'GET_SORTED_STUDENT_MARKS'){

            $codeEleve = $request->codeEleve;
            $codeEnseignement = $request->codeEnseignement;
            $codeAnnee = $request->codeAnnee;
            $codeEvaluation = $request->codeEvaluation;
            // return $codeEvaluation;
            $marks = Note::where('CodeEleve','=',$codeEleve)->where('CodeEnseignement','=',$codeEnseignement)->where('CodeAnnee','=',$codeAnnee)->where('CodeEvaluation','=',$codeEvaluation)->get();

            // $marks = Note::where('CodeEleve','=',$codeEleve)->where('CodeEnseignement','=',$codeEnseignement)->where('CodeAnnee','=',$codeAnnee)->where('CodeEvaluation','=',$codeEvaluation)->get();
            return $marks;
        }

        #courses
        if($action == 'GET_ALL_COURSES'){
            $courses = Enseignement::all();
            return $courses;
        }

        if($action == 'GET_TEACHER_COURSES'){
            $teacher_code = $request->teacher_code;
            $courses = Enseignement::where(function ($query) use ($teacher_code) {
                $query->where('code', '=', $teacher_code)
                    ->orWhere('CodeEnseignant2', '=', $teacher_code);
            })->get();
            return $courses;
        }
        
        if($action == 'GET_CLASS_COURSES'){
            $CodeClasse = $request->CodeClasse;
            $courses = Enseignement::where('CodeClasse','=',$CodeClasse)->get();
            return $courses;
        }


        #academic
        if($action == 'GET_MAIN_CLASS'){
            $code_classe = $request->code_classe;
            $class = Classe::where('CodeClasse','=',$code_classe)->get();
            return $class;
        }

        if($action == 'GET_MAIN_COURSE'){
            $code_matiere = $request->code_matiere;
            $matiere = Matiere::where('CodeMatiere','=',$code_matiere)->get();
            // return "here";
            return $matiere;
        }

        if($action == 'GET_ALL_YEARS'){
            $years= Annee::all();
            return $years;
        }

        if($action == 'GET_ALL_SEQUENCES'){
            $sequences = SequenceEvaluation::all();
            return $sequences;
        }
        if($action == 'GET_MAIN_YEAR'){
            $CodeAnnee = $request->codeAnnee;
            return Annee::where('CodeAnnee','=',$CodeAnnee)->get();
        }
        if($action == 'GET_MAIN_SEQUENCE'){
            $CodeEvaluation = $request->codeEvaluation;
            return SequenceEvaluation::where('CodeEvaluation','=',$CodeEvaluation)->get();
        }
        if($action == 'GET_ALL_CLASSES'){
            return Classe::all();    
        }

        if ($action == 'GET_PRINCIPAL_DASHBOARD') {
            $principalContext = $this->resolveDashboardScope($request);
            if (!$principalContext['allowed']) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = (string) $principalContext['school_code'];
            $classCodes = $principalContext['class_codes'];
            $classes = Classe::where('CodeEtablissement', '=', $schoolCode)
                ->whereIn('CodeClasse', $classCodes)
                ->orderBy('LibelleClasse')
                ->get();

            if ($classes->isEmpty()) {
                return response()->json([
                    'classes' => 0,
                    'teachers' => 0,
                    'students' => 0,
                    'today_attendance_percentage' => null,
                    'class_overview' => [],
                    'today_sessions' => [],
                ]);
            }

            $classCodes = $classes->pluck('CodeClasse')->all();

            $today = date('Y-m-d');
            $todayAttendance = Conduite::whereIn('CodeClasse', $classCodes)
                ->where('DateEnreg', '=', $today)
                ->get();

            $todayClassOverview = $classes->map(function ($class) use ($today, $schoolCode) {
                $classStudentCounts = Eleve::where('CodeClasse', '=', $class->CodeClasse)
                    ->selectRaw(
                        'COUNT(*) as effectif, SUM(CASE WHEN Sex = ? THEN 1 ELSE 0 END) as garcons, SUM(CASE WHEN Sex = ? THEN 1 ELSE 0 END) as filles',
                        ['1', '0']
                    )
                    ->first();
                $classAttendance = Conduite::where('CodeClasse', '=', $class->CodeClasse)
                    ->where('DateEnreg', '=', $today)
                    ->get();

                $presentToday = $classAttendance->filter(function ($record) {
                    return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'P';
                })->count();

                $totalToday = $classAttendance->filter(function ($record) {
                    $status = strtoupper((string) ($record->CodeEtatCond ?? ''));
                    return in_array($status, ['P', 'A', 'R'], true);
                })->count();

                $latestAttendanceIds = DB::table('conduites')
                    ->where('CodeClasse', '=', $class->CodeClasse)
                    ->selectRaw('MAX(id) as id')
                    ->groupBy('DateEnreg', 'CodeEleve', 'CodeEnseignement', 'CodeMatiere', 'HeureMatiere');
                $attendanceTotals = DB::table('conduites')
                    ->whereIn('id', $latestAttendanceIds)
                    ->whereIn(DB::raw('UPPER(CodeEtatCond)'), ['P', 'A', 'R'])
                    ->selectRaw("COUNT(*) as total, SUM(CASE WHEN UPPER(CodeEtatCond) = 'P' THEN 1 ELSE 0 END) as present")
                    ->first();

                $totalAttendance = (int) ($attendanceTotals->total ?? 0);
                $presentAttendance = (int) ($attendanceTotals->present ?? 0);
                $tauxPresence = $totalAttendance > 0
                    ? round(($presentAttendance / $totalAttendance) * 100)
                    : null;

                return [
                    'CodeClasse' => (string) ($class->CodeClasse ?? ''),
                    'LibelleClasse' => (string) ($class->LibelleClasse ?? ''),
                    'effectif' => (int) ($classStudentCounts->effectif ?? 0),
                    'garcons' => (int) ($classStudentCounts->garcons ?? 0),
                    'filles' => (int) ($classStudentCounts->filles ?? 0),
                    'total_matieres' => DB::table('enseignements')
                        ->join('matieres', 'enseignements.CodeMatiere', '=', 'matieres.CodeMatiere')
                        ->where('enseignements.CodeClasse', '=', $class->CodeClasse)
                        ->distinct()
                        ->count('enseignements.CodeMatiere'),
                    'seances_du_jour' => $classAttendance
                        ->pluck('CodeEnseignement')
                        ->filter()
                        ->unique()
                        ->count(),
                    'taux_presence' => $tauxPresence,
                    'present' => $presentToday,
                    'total_students' => $totalToday,
                ];
            })->values();

            $totalPresentToday = $todayAttendance->filter(function ($record) {
                return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'P';
            })->count();

            $totalTrackedToday = $todayAttendance->filter(function ($record) {
                $status = strtoupper((string) ($record->CodeEtatCond ?? ''));
                return in_array($status, ['P', 'A', 'R'], true);
            })->count();

            $dashboardAttendance = $totalTrackedToday > 0
                ? round(($totalPresentToday / $totalTrackedToday) * 100)
                : null;

            $todaySessions = $todayAttendance
                ->groupBy(function ($record) {
                    return $record->DateEnreg . '|' . $record->CodeEnseignement . '|' . $record->HeureMatiere;
                })
                ->map(function ($sessionRecords, $key) use ($schoolCode) {
                    $codeEnseignement = (string) ($sessionRecords->first()->CodeEnseignement ?? '');
                    $course = $codeEnseignement !== ''
                        ? Enseignement::where('CodeEnseignement', '=', $codeEnseignement)
                            ->where('CodeEtablissement', '=', $schoolCode)
                            ->first()
                        : null;

                    $present = $sessionRecords->filter(function ($record) {
                        return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'P';
                    })->count();

                    $absent = $sessionRecords->filter(function ($record) {
                        return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'A';
                    })->count();

                    $late = $sessionRecords->filter(function ($record) {
                        return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'R';
                    })->count();

                    $totalStudents = $sessionRecords->filter(function ($record) {
                        $status = strtoupper((string) ($record->CodeEtatCond ?? ''));
                        return in_array($status, ['P', 'A', 'R'], true);
                    })->count();

                    $teacherSummary = $this->resolveTeacherSummaryForCourse($course);

                    return [
                        'date' => (string) ($sessionRecords->first()->DateEnreg ?? $today),
                        'time' => (string) ($sessionRecords->first()->HeureMatiere ?? ''),
                        'CodeEnseignement' => $codeEnseignement,
                        'class' => (string) ($course ? ($course->classe->LibelleClasse ?? '') : ''),
                        'subject' => (string) ($course && $course->matiere ? ($course->matiere->LibelleMatiere ?? '') : ''),
                        'teacher' => $teacherSummary['full_name'] ?? '',
                        'present' => $present,
                        'absent' => $absent,
                        'late' => $late,
                        'student_count' => $totalStudents,
                        'attendance_percentage' => $totalStudents > 0 ? round(($present / $totalStudents) * 100) : null,
                    ];
                })->values();

            return response()->json([
                'classes' => $classes->count(),
                'teachers' => User::where('account_type', '=', 'enseignant')
                    ->where('CodeEtablissement', '=', $schoolCode)
                    ->count(),
                'students' => Eleve::whereIn('CodeClasse', $classCodes)->count(),
                'today_attendance_percentage' => $dashboardAttendance,
                'class_overview' => $todayClassOverview,
                'today_sessions' => $todaySessions,
            ]);
        }

        if ($action == 'GET_PRINCIPAL_CLASSES') {
            $principalContext = $this->resolveDashboardScope($request);
            if (!$principalContext['allowed']) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = (string) $principalContext['school_code'];
            $classCodes = $principalContext['class_codes'];
            $today = date('Y-m-d');
            $classes = Classe::where('CodeEtablissement', '=', $schoolCode)
                ->whereIn('CodeClasse', $classCodes)
                ->orderBy('LibelleClasse')
                ->get();

            $classPayload = $classes->map(function ($class) use ($today, $schoolCode) {
                $students = Eleve::where('CodeClasse', '=', $class->CodeClasse)->get();
                $attendanceToday = Conduite::where('CodeClasse', '=', $class->CodeClasse)
                    ->where('DateEnreg', '=', $today)
                    ->get();

                $present = $attendanceToday->filter(function ($record) {
                    return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'P';
                })->count();

                $totalTracked = $attendanceToday->filter(function ($record) {
                    $status = strtoupper((string) ($record->CodeEtatCond ?? ''));
                    return in_array($status, ['P', 'A', 'R'], true);
                })->count();

                $teachers = Enseignement::where('CodeClasse', '=', $class->CodeClasse)
                    ->where('CodeEtablissement', '=', $schoolCode)
                    ->with(['enseignant'])
                    ->get()
                    ->flatMap(function ($enseignement) {
                        $entries = [];
                        $teacherCodes = array_filter([
                            trim((string) ($enseignement->code ?? '')),
                            trim((string) ($enseignement->CodeEnseignant2 ?? '')),
                        ]);
                        foreach ($teacherCodes as $teacherCode) {
                            if ($teacherCode === '') {
                                continue;
                            }
                            $teacher = User::where('code', '=', $teacherCode)
                                ->where('account_type', '=', 'enseignant')
                                ->first();
                            if ($teacher) {
                                $entries[] = [
                                    'code' => (string) ($teacher->code ?? ''),
                                    'nom' => (string) ($teacher->nom ?? ''),
                                    'prenom' => (string) ($teacher->prenom ?? ''),
                                    'full_name' => trim((string) (($teacher->nom ?? '') . ' ' . ($teacher->prenom ?? ''))),
                                ];
                            }
                        }
                        return $entries;
                    })
                    ->values()
                    ->unique('code')
                    ->values();

                $subjects = Enseignement::where('CodeClasse', '=', $class->CodeClasse)
                    ->where('CodeEtablissement', '=', $schoolCode)
                    ->with(['matiere'])
                    ->get()
                    ->map(function ($enseignement) {
                        $subject = $enseignement->matiere;
                        return [
                            'CodeMatiere' => (string) ($enseignement->CodeMatiere ?? ''),
                            'LibelleMatiere' => (string) ($subject ? ($subject->LibelleMatiere ?? '') : ''),
                        ];
                    })
                    ->values()
                    ->unique('CodeMatiere')
                    ->values();

                $tauxPresence = $totalTracked > 0 ? round(($present / $totalTracked) * 100) : null;

                return [
                    'CodeClasse' => (string) ($class->CodeClasse ?? ''),
                    'LibelleClasse' => (string) ($class->LibelleClasse ?? ''),
                    'effectif' => $students->count(),
                    'garcons' => $students->filter(function ($student) {
                        $sex = strtolower(trim((string) ($student->Sex ?? '')));
                        return in_array($sex, ['m', 'masculin', 'male', 'garcon', 'g'], true);
                    })->count(),
                    'filles' => $students->filter(function ($student) {
                        $sex = strtolower(trim((string) ($student->Sex ?? '')));
                        return in_array($sex, ['f', 'feminin', 'female', 'fille', 'fe'], true);
                    })->count(),
                    'enseignants' => $teachers,
                    'matieres' => $subjects,
                    'seances_du_jour' => $attendanceToday
                        ->pluck('CodeEnseignement')
                        ->filter()
                        ->unique()
                        ->count(),
                    'taux_presence' => $tauxPresence,
                ];
            })->values();

            return response()->json($classPayload);
        }

        if ($action == 'GET_PRINCIPAL_ATTENDANCE') {
            $principalContext = $this->resolveDashboardScope($request);
            if (!$principalContext['allowed']) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = (string) $principalContext['school_code'];
            $classCodes = $principalContext['class_codes'];

            $attendanceQuery = Conduite::whereIn('CodeClasse', $classCodes);
            if ($request->filled('DateEnreg')) {
                $attendanceQuery->where('DateEnreg', '=', trim((string) $request->input('DateEnreg')));
            }

            $attendanceRecords = $attendanceQuery
                ->orderBy('DateEnreg')
                ->orderBy('HeureMatiere')
                ->get();

            $sessions = $attendanceRecords
                ->groupBy(function ($record) {
                    return $record->DateEnreg . '|' . $record->CodeEnseignement . '|' . $record->HeureMatiere;
                })
                ->map(function ($sessionRecords) use ($schoolCode) {
                    $first = $sessionRecords->first();
                    $course = Enseignement::where('CodeEnseignement', '=', $first->CodeEnseignement)
                        ->where('CodeClasse', '=', $first->CodeClasse)
                        ->where(function ($query) use ($schoolCode) {
                            $query->where('CodeEtablissement', '=', $schoolCode)
                                ->orWhereNull('CodeEtablissement')
                                ->orWhere('CodeEtablissement', '=', '');
                        })
                        ->first();
                    $class = Classe::where('CodeClasse', '=', $first->CodeClasse)
                        ->where('CodeEtablissement', '=', $schoolCode)
                        ->first();
                    $subject = $course
                        ? Matiere::where('CodeMatiere', '=', $course->CodeMatiere)->first()
                        : null;
                    $teacherSummary = $this->resolveTeacherSummaryForCourse($course);
                    $students = Eleve::whereIn('CodeEleve', $sessionRecords->pluck('CodeEleve')->unique())
                        ->where('CodeClasse', '=', $first->CodeClasse)
                        ->get()
                        ->keyBy('CodeEleve');

                    $present = $sessionRecords->filter(function ($record) {
                        return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'P';
                    })->count();
                    $absent = $sessionRecords->filter(function ($record) {
                        return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'A';
                    })->count();
                    $late = $sessionRecords->filter(function ($record) {
                        return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'R';
                    })->count();
                    $total = $sessionRecords->filter(function ($record) {
                        return in_array(strtoupper((string) ($record->CodeEtatCond ?? '')), ['P', 'A', 'R'], true);
                    })->count();

                    return [
                        'date' => (string) ($first->DateEnreg ?? ''),
                        'time' => $this->formatAttendanceTime($first->HeureMatiere),
                        'CodeClasse' => (string) ($first->CodeClasse ?? ''),
                        'CodeMatiere' => (string) ($first->CodeMatiere ?? ($course->CodeMatiere ?? '')),
                        'CodeEnseignement' => (string) ($first->CodeEnseignement ?? ''),
                        'class' => (string) ($class->LibelleClasse ?? ''),
                        'subject' => (string) ($subject->LibelleMatiere ?? ''),
                        'teacher' => $teacherSummary['full_name'] ?? '',
                        'present' => $present,
                        'absent' => $absent,
                        'late' => $late,
                        'student_count' => $total,
                        'attendance_percentage' => $total > 0 ? round(($present / $total) * 100) : null,
                        'records' => $sessionRecords->map(function ($record) use ($students) {
                            $student = $students->get($record->CodeEleve);
                            return [
                                'CodeEleve' => (string) ($record->CodeEleve ?? ''),
                                'student_name' => trim((string) (($student->Nom ?? '') . ' ' . ($student->Prenom ?? ''))),
                                'status' => strtoupper((string) ($record->CodeEtatCond ?? '')),
                            ];
                        })->values(),
                    ];
                })->values();

            return response()->json($sessions);
        }

        if ($action == 'GET_PRINCIPAL_CLASS_DETAILS') {
            $principalContext = $this->resolveDashboardScope($request);
            if (!$principalContext['allowed']) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = (string) $principalContext['school_code'];
            $classCode = trim((string) $request->input('CodeClasse', ''));
            if ($classCode === '') {
                return response()->json(['error' => 'Missing CodeClasse'], 422);
            }

            if (($principalContext['user']->account_type ?? '') === 'encadreur') {
                $encadreurScope = new EncadreurClassScope();
                if (!$encadreurScope->ensureClassAccessForEncadreur($principalContext['user'], $classCode)) {
                    return response()->json(['error' => 'Unauthorized'], 403);
                }
            }

            $class = Classe::where('CodeClasse', '=', $classCode)
                ->where('CodeEtablissement', '=', $schoolCode)
                ->first();

            if (!$class) {
                return response()->json(['error' => 'Class not found'], 404);
            }

            $students = Eleve::where('CodeClasse', '=', $classCode)->get();
            $teachingRows = Enseignement::where('CodeClasse', '=', $classCode)
                ->where('CodeEtablissement', '=', $schoolCode)
                ->with(['matiere', 'enseignant'])
                ->orderBy('CodeMatiere')
                ->get();

            $subjectDetails = $teachingRows
                ->groupBy('CodeMatiere')
                ->map(function ($rows, $codeMatiere) {
                    $subject = $rows->first()->matiere;
                    $teacherSet = [];
                    foreach ($rows as $row) {
                        $teacherCodes = array_filter([
                            trim((string) ($row->code ?? '')),
                            trim((string) ($row->CodeEnseignant2 ?? '')),
                        ]);
                        foreach ($teacherCodes as $teacherCode) {
                            if ($teacherCode === '') {
                                continue;
                            }
                            $teacher = User::where('code', '=', $teacherCode)
                                ->where('account_type', '=', 'enseignant')
                                ->first();
                            if ($teacher) {
                                $teacherSet[] = [
                                    'code' => (string) ($teacher->code ?? ''),
                                    'nom' => (string) ($teacher->nom ?? ''),
                                    'prenom' => (string) ($teacher->prenom ?? ''),
                                    'full_name' => trim((string) (($teacher->nom ?? '') . ' ' . ($teacher->prenom ?? ''))),
                                ];
                            }
                        }
                    }

                    return [
                        'CodeMatiere' => (string) $codeMatiere,
                        'LibelleMatiere' => (string) ($subject ? ($subject->LibelleMatiere ?? '') : ''),
                        'teachers' => array_values(
                            collect($teacherSet)->unique('code')->values()->all()
                        ),
                    ];
                })->values();

            $teachers = $teachingRows->flatMap(function ($row) {
                $teacherCodes = array_filter([
                    trim((string) ($row->code ?? '')),
                    trim((string) ($row->CodeEnseignant2 ?? '')),
                ]);

                $teachers = [];
                foreach ($teacherCodes as $teacherCode) {
                    if ($teacherCode === '') {
                        continue;
                    }
                    $teacher = User::where('code', '=', $teacherCode)
                        ->where('account_type', '=', 'enseignant')
                        ->first();
                    if ($teacher) {
                        $teachers[] = [
                            'code' => (string) ($teacher->code ?? ''),
                            'nom' => (string) ($teacher->nom ?? ''),
                            'prenom' => (string) ($teacher->prenom ?? ''),
                            'full_name' => trim((string) (($teacher->nom ?? '') . ' ' . ($teacher->prenom ?? ''))),
                        ];
                    }
                }
                return $teachers;
            })->unique('code')->values();

            $today = date('Y-m-d');
            $todayRecords = Conduite::where('CodeClasse', '=', $classCode)
                ->where('DateEnreg', '=', $today)
                ->get();

            $todaySessions = $todayRecords
                ->groupBy(function ($record) {
                    return $record->DateEnreg . '|' . $record->CodeEnseignement . '|' . $record->HeureMatiere;
                })
                ->map(function ($sessionRecords, $groupKey) use ($class, $schoolCode) {
                    $first = $sessionRecords->first();
                    $course = $first && !empty($first->CodeEnseignement)
                        ? Enseignement::where('CodeEnseignement', '=', $first->CodeEnseignement)
                            ->where('CodeEtablissement', '=', $schoolCode)
                            ->first()
                        : null;

                    $present = $sessionRecords->filter(function ($record) {
                        return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'P';
                    })->count();

                    $absent = $sessionRecords->filter(function ($record) {
                        return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'A';
                    })->count();

                    $late = $sessionRecords->filter(function ($record) {
                        return strtoupper((string) ($record->CodeEtatCond ?? '')) === 'R';
                    })->count();

                    $totalStudents = $sessionRecords->filter(function ($record) {
                        $status = strtoupper((string) ($record->CodeEtatCond ?? ''));
                        return in_array($status, ['P', 'A', 'R'], true);
                    })->count();

                    $teacherSummary = $this->resolveTeacherSummaryForCourse($course);

                    return [
                        'date' => (string) ($first->DateEnreg ?? $today),
                        'time' => (string) ($first->HeureMatiere ?? ''),
                        'CodeEnseignement' => (string) ($first->CodeEnseignement ?? ''),
                        'class' => (string) ($class->LibelleClasse ?? ''),
                        'subject' => (string) ($course && $course->matiere ? ($course->matiere->LibelleMatiere ?? '') : ''),
                        'teacher' => $teacherSummary['full_name'] ?? '',
                        'student_count' => $totalStudents,
                        'present' => $present,
                        'absent' => $absent,
                        'late' => $late,
                        'attendance_percentage' => $totalStudents > 0 ? round(($present / $totalStudents) * 100) : null,
                    ];
                })->values();

            return response()->json([
                'CodeClasse' => (string) ($class->CodeClasse ?? ''),
                'LibelleClasse' => (string) ($class->LibelleClasse ?? ''),
                'effectif' => $students->count(),
                'garcons' => $students->filter(function ($student) {
                    $sex = strtolower(trim((string) ($student->Sex ?? '')));
                    return in_array($sex, ['m', 'masculin', 'male', 'garcon', 'g'], true);
                })->count(),
                'filles' => $students->filter(function ($student) {
                    $sex = strtolower(trim((string) ($student->Sex ?? '')));
                    return in_array($sex, ['f', 'feminin', 'female', 'fille', 'fe'], true);
                })->count(),
                'subjects' => $subjectDetails,
                'teachers' => $teachers,
                'today_sessions' => $todaySessions,
            ]);
        }

        if($action == 'INSERT_CONVOCATION'){
            $code = trim((string) $request->input('code', ''));
            $codeClasse = trim((string) $request->input('CodeClasse', ''));
            $codeEnseignement = trim((string) $request->input('CodeEnseignement', ''));
            $motif = trim((string) $request->input('motif', ''));
            $description = trim((string) $request->input('description', ''));
            $dateConvocation = trim((string) $request->input('dateConvocation', ''));

            $studentCodes = $request->input('CodeEleves');
            if (is_string($studentCodes)) {
                $decodedStudentCodes = json_decode($studentCodes, true);
                $studentCodes = is_array($decodedStudentCodes) ? $decodedStudentCodes : [];
            }
            if (!is_array($studentCodes) || count($studentCodes) === 0) {
                $legacyStudentCode = trim((string) $request->input('CodeEleve', ''));
                $studentCodes = $legacyStudentCode === '' ? [] : [$legacyStudentCode];
            }
            $studentCodes = array_values(array_unique(array_filter(array_map('trim', $studentCodes))));

            if ($code === '' || $codeEnseignement === '' || $motif === '' ||
                $description === '' || $dateConvocation === '' || count($studentCodes) === 0) {
                return response()->json(['error' => 'Les champs de convocation sont obligatoires.'], 422);
            }

            $parsedDate = \DateTime::createFromFormat('Y-m-d', $dateConvocation);
            $dateErrors = \DateTime::getLastErrors();
            if (!$parsedDate || ($dateErrors !== false && ($dateErrors['warning_count'] > 0 || $dateErrors['error_count'] > 0)) ||
                $parsedDate->format('Y-m-d') !== $dateConvocation) {
                return response()->json(['error' => 'La date de convocation est invalide.'], 422);
            }

            $creator = User::where('code', '=', $code)->first();
            $accountType = strtolower(trim((string) ($creator->account_type ?? '')));
            $isTeacher = $creator && $accountType === 'enseignant';
            $hasSchoolWideConvocationAccess = $creator && (
                (bool) $creator->admin
                || in_array($accountType, ['principal', 'principal_encadreur', 'administrateur'], true)
            );

            if (!$isTeacher && !$hasSchoolWideConvocationAccess) {
                return response()->json(['error' => 'Enseignant non autorisé.'], 403);
            }

            $schoolCode = trim((string) ($creator->CodeEtablissement ?? ''));
            $enseignementQuery = Enseignement::where('CodeEnseignement', '=', $codeEnseignement);
            if ($isTeacher) {
                $enseignementQuery->where(function ($query) use ($code) {
                    $query->where('code', '=', $code)
                        ->orWhere('CodeEnseignant2', '=', $code);
                });
            } else {
                if ($schoolCode === '') {
                    return response()->json(['error' => 'Établissement non autorisé.'], 403);
                }

                $enseignementQuery->where('CodeEtablissement', '=', $schoolCode);
                if ($codeClasse !== '') {
                    $enseignementQuery->where('CodeClasse', '=', $codeClasse);
                }
            }
            $enseignement = $enseignementQuery->first();
            if (!$enseignement) {
                return response()->json([
                    'error' => $isTeacher
                        ? 'Cette matière ne fait pas partie de vos classes.'
                        : 'Cette matière n’appartient pas à votre établissement.',
                ], 403);
            }

            if ($codeClasse === '') {
                $codeClasse = (string) $enseignement->CodeClasse;
            }
            if ((string) $enseignement->CodeClasse !== $codeClasse) {
                return response()->json(['error' => 'La classe sélectionnée n’est pas autorisée.'], 403);
            }

            if (!$isTeacher && !Classe::where('CodeClasse', '=', $codeClasse)
                ->where('CodeEtablissement', '=', $schoolCode)
                ->exists()) {
                return response()->json(['error' => 'La classe sélectionnée n’est pas autorisée.'], 403);
            }

            $students = Eleve::whereIn('CodeEleve', $studentCodes)
                ->where('CodeClasse', '=', $codeClasse)
                ->get();
            if ($students->count() !== count($studentCodes)) {
                return response()->json(['error' => 'Un ou plusieurs élèves ne correspondent pas à la classe.'], 422);
            }

            $createdConvocations = DB::transaction(function () use (
                $code,
                $codeEnseignement,
                $enseignement,
                $motif,
                $description,
                $dateConvocation,
                $students
            ) {
                $created = [];
                foreach ($students as $student) {
                    $created[] = Convocation::create([
                        'code' => $code,
                        'CodeEleve' => $student->CodeEleve,
                        'motif' => $motif,
                        'description' => $description,
                        'CodeEnseignement' => $codeEnseignement,
                        'CodeMatiere' => $enseignement->CodeMatiere,
                        'dateConvocation' => $dateConvocation,
                    ]);
                }
                return $created;
            });

            $schoolCode = trim((string) (($creator->CodeEtablissement ?? '') ?: ($enseignement->CodeEtablissement ?? '')));
            $dispatcher = new NotificationDispatchService();
            $dispatcher->dispatchConvocationNotification(
                array_map(fn ($student) => (string) $student->CodeEleve, $students->all()),
                $code,
                ['school_code' => $schoolCode, 'class_code' => $codeClasse]
            );

            return response()->json(['status' => 'success']);
        }
        if($action == 'GET_TEACHER_CONVOCATIONS'){
            $code = trim((string) $request->input('code', ''));
            $query = Convocation::where('code', '=', $code);
            if ($request->filled('CodeClasse')) {
                $studentCodes = Eleve::where('CodeClasse', '=', $request->CodeClasse)
                    ->pluck('CodeEleve');
                $query->whereIn('CodeEleve', $studentCodes);
            }
            $convocations = $query->orderBy('created_at', 'DESC')->get();
            return $convocations->map(function ($convocation) {
                $teacherCode = null;
                $teacherName = null;

                if (!empty($convocation->CodeEnseignement)) {
                    $enseignement = Enseignement::where(
                        'CodeEnseignement',
                        '=',
                        $convocation->CodeEnseignement
                    )->first();
                    if ($enseignement) {
                        $teacherCode = $enseignement->code;
                        $teacher = User::where('code', '=', $enseignement->code)->first();
                        if ($teacher) {
                            $teacherName = trim(
                                ($teacher->nom ?? '') . ' ' . ($teacher->prenom ?? '')
                            );
                        }
                    }
                }

                $payload = $convocation->toArray();
                $payload['teacher_code'] = $teacherCode;
                $payload['teacher_name'] = $teacherName;

                return $payload;
            })->values();
        }

        if($action == 'GET_PARENT_CONVOCATIONS'){
            $code = $request->code;

            if (!$code) {
                return response()->json([], 200);
            }

            $students = Eleve::where('code', '=', $code)->orderBy('Nom', 'ASC')->pluck('CodeEleve');

            if ($students->isEmpty()) {
                return response()->json([], 200);
            }

            $query = Convocation::whereIn('CodeEleve', $students);

            if ($request->filled('CodeEleve')) {
                $query->where('CodeEleve', '=', $request->CodeEleve);
            }

            $convocations = $query
                ->orderBy('dateConvocation', 'DESC')
                ->get();

            return $convocations->map(function ($convocation) {
                $teacherCode = null;
                $teacherName = null;

                if (!empty($convocation->CodeEnseignement)) {
                    $enseignement = Enseignement::where('CodeEnseignement', '=', $convocation->CodeEnseignement)->first();
                    if ($enseignement) {
                        $teacherCode = $enseignement->code;

                        $teacher = User::where('code', '=', $enseignement->code)->first();
                        if ($teacher) {
                            $teacherName = trim(($teacher->nom ?? '') . ' ' . ($teacher->prenom ?? ''));
                        }
                    }
                }

                $payload = $convocation->toArray();
                $payload['teacher_code'] = $teacherCode;
                $payload['teacher_name'] = $teacherName;

                return $payload;
            })->values();
        }

        if($action == 'GET_PARENT_DEVOIRS'){
            $code = $request->code;
            $studentsQuery = Eleve::where('code', '=', $code);

            if($request->filled('CodeEleve')){
                $studentsQuery->where('CodeEleve', '=', $request->CodeEleve);
            }

            $classCodes = $studentsQuery->pluck('CodeClasse')->filter()->unique()->values();
            if($classCodes->isEmpty()){
                return [];
            }

            return Devoir::whereIn('CodeClasse', $classCodes)
                ->orderBy('dateDuDevoir', 'DESC')
                ->get();
        }

        if ($action == 'GET_INVESTIGATIONS') {
            $code = trim((string) $request->input('code', ''));
            if ($code === '') {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $user = User::where('code', '=', $code)->first();
            if (!$user) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
            if ($schoolCode === '') {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $query = InvestigationAlert::query()->where('CodeEtablissement', '=', $schoolCode);

            if (strtolower((string) ($user->account_type ?? '')) === 'encadreur') {
                $encadreurScope = new EncadreurClassScope();
                $assignedClassCodes = $encadreurScope->assignedClassCodesForEncadreur($user);
                if ($assignedClassCodes === []) {
                    return response()->json([]);
                }
                $query->whereIn('CodeClasse', $assignedClassCodes);
            }

            if ($request->filled('CodeClasse')) {
                $requestedClass = trim((string) $request->input('CodeClasse', ''));
                if ($requestedClass !== '') {
                    if (strtolower((string) ($user->account_type ?? '')) === 'encadreur') {
                        $encadreurScope = new EncadreurClassScope();
                        if (!$encadreurScope->ensureClassAccessForEncadreur($user, $requestedClass)) {
                            return response()->json(['error' => 'Unauthorized'], 403);
                        }
                    }
                    $query->where('CodeClasse', '=', $requestedClass);
                }
            }

            $alerts = $query->orderByDesc('date_absence')->orderByDesc('created_at')->get();

            return response()->json($alerts->map(function ($alert) {
                $student = Eleve::where('CodeEleve', '=', $alert->CodeEleve)->first();
                $payload = $alert->toArray();
                $payload['student_name'] = $student ? trim((string) (($student->Nom ?? '') . ' ' . ($student->Prenom ?? ''))) : '';
                $payload['student_code'] = (string) ($student->CodeEleve ?? '');
                return $payload;
            })->values());
        }

        if ($action == 'UPDATE_INVESTIGATION_ALERT') {
            $code = trim((string) $request->input('code', ''));
            $alertId = $request->input('id');
            $status = trim((string) $request->input('status', ''));
            $notes = trim((string) $request->input('notes', ''));

            if ($code === '' || $alertId === '' || $status === '') {
                return response()->json(['error' => 'Missing investigation fields'], 422);
            }

            $user = User::where('code', '=', $code)->first();
            if (!$user) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $alert = InvestigationAlert::find($alertId);
            if (!$alert) {
                return response()->json(['error' => 'Investigation not found'], 404);
            }

            $allowedStates = ['pending', 'validated', 'rejected'];
            if (!in_array($status, $allowedStates, true)) {
                return response()->json(['error' => 'Invalid investigation status'], 422);
            }

            if (strtolower((string) ($user->account_type ?? '')) === 'encadreur') {
                $encadreurScope = new EncadreurClassScope();
                if (!$encadreurScope->ensureClassAccessForEncadreur($user, (string) $alert->CodeClasse)) {
                    return response()->json(['error' => 'Unauthorized'], 403);
                }
            }

            $alert->status = $status;
            $alert->notes = $notes !== '' ? $notes : ($alert->notes ?? '');
            $alert->resolved_by = (string) ($user->code ?? '');
            $alert->resolved_at = now();
            $alert->save();

            return response()->json(['status' => 'success', 'alert' => $alert]);
        }

        if ($action == 'GET_TEACHER_DEVOIRS') {
            $teacherCode = trim((string) $request->input('teacher_code', ''));
            $codeEnseignement = trim((string) $request->input('CodeEnseignement', ''));
            $codeClasse = trim((string) $request->input('CodeClasse', ''));
            $codeMatiere = trim((string) $request->input('CodeMatiere', ''));

            if ($teacherCode === '') {
                return response()->json(['message' => 'Missing teacher code'], 422);
            }

            $courseQuery = Enseignement::query()
                ->where(function ($query) use ($teacherCode) {
                    $query->where('code', '=', $teacherCode)
                        ->orWhere('CodeEnseignant2', '=', $teacherCode);
                });

            if ($codeEnseignement !== '') {
                $courseQuery->where('CodeEnseignement', '=', $codeEnseignement);
            }
            if ($codeClasse !== '') {
                $courseQuery->where('CodeClasse', '=', $codeClasse);
            }
            if ($codeMatiere !== '') {
                $courseQuery->where('CodeMatiere', '=', $codeMatiere);
            }

            if ($codeEnseignement === '' && $codeClasse === '' && $codeMatiere === '') {
                return response()->json(['message' => 'Missing filter parameters'], 422);
            }

            if (!$courseQuery->exists()) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            $devoirQuery = Devoir::where('code', '=', $teacherCode);

            if ($codeClasse !== '') {
                $devoirQuery->where('CodeClasse', '=', $codeClasse);
            }
            if ($codeMatiere !== '') {
                $devoirQuery->where('CodeMatiere', '=', $codeMatiere);
            }
            if ($codeEnseignement !== '') {
                $devoirQuery->where('CodeEnseignement', '=', $codeEnseignement);
            }

            return $devoirQuery
                ->orderByDesc('dateDuDevoir')
                ->orderByDesc('id')
                ->get();
        }

        if ($action == 'CREATE_TEACHER_DEVOIR') {
            $teacherCode = trim((string) $request->input('teacher_code', ''));
            $codeEnseignement = trim((string) $request->input('CodeEnseignement', ''));
            $titre = trim((string) $request->input('titre', ''));
            $description = trim((string) $request->input('description', ''));
            $dateDuDevoir = trim((string) $request->input('dateDuDevoir', ''));

            if ($teacherCode === '' || $codeEnseignement === '' || $titre === ''
                || $dateDuDevoir === '') {
                return response()->json(['message' => 'Missing devoir fields'], 422);
            }

            $course = Enseignement::where('CodeEnseignement', '=', $codeEnseignement)
                ->where(function ($query) use ($teacherCode) {
                    $query->where('code', '=', $teacherCode)
                        ->orWhere('CodeEnseignant2', '=', $teacherCode);
                })
                ->first();

            if (!$course) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            $devoir = Devoir::create([
                'titre' => $titre,
                'description' => $description,
                'dateDuDevoir' => $dateDuDevoir,
                'code' => $teacherCode,
                'CodeClasse' => $course->CodeClasse,
                'CodeMatiere' => $course->CodeMatiere,
                'CodeEnseignement' => $course->CodeEnseignement,
                'CodeEtablissement' => $course->CodeEtablissement,
            ]);

            $subjectLabel = trim((string) (($course->matiere?->LibelleMatiere ?? $course->CodeMatiere ?? '')));
            $dispatcher = new NotificationDispatchService();
            $dispatcher->dispatchHomeworkNotification(
                (string) $course->CodeClasse,
                $subjectLabel,
                $teacherCode,
                (string) ($course->CodeEtablissement ?? ''),
                (string) $devoir->id,
                $titre
            );

            return response()->json($devoir, 201);
        }

        if ($action == 'GET_ADVERTS') {
            $adverts = Advert::query()
                ->where('group', 'ECOLE_UNIVERSITE')
                ->where('isDeleted', 0)
                ->orderByDesc('isPopular')
                ->orderByDesc('id')
                ->get();

            return response()->json($adverts->values()->all());
        }

        #students
        if($action == 'GET_COURSE_STUDENTS'){
            $CodeClasse = trim((string) $request->input('codeClasse', ''));
            $userCode = trim((string) $request->input('code', ''));
            $schoolCode = trim((string) $request->input('CodeEtablissement', ''));
            $user = $userCode !== '' ? User::where('code', '=', $userCode)->first() : null;

            if ($schoolCode === '' && $user) {
                $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
            }

            if ($CodeClasse === '') {
                return response()->json([], 200);
            }

            $classMatch = Classe::query()->where('CodeClasse', '=', $CodeClasse);
            if ($schoolCode !== '') {
                $classMatch->where('CodeEtablissement', '=', $schoolCode);
            }

            $classForSchool = $classMatch->first();
            if (!$classForSchool) {
                return response()->json([], 200);
            }

            if ($user && strtolower(trim((string) ($user->account_type ?? ''))) === 'encadreur') {
                $encadreurScope = new EncadreurClassScope();
                if (!$encadreurScope->ensureClassAccessForEncadreur($user, $CodeClasse)) {
                    return response()->json(['error' => 'Unauthorized'], 403);
                }
            }

            $studentsQuery = Eleve::query()->where('CodeClasse', '=', $CodeClasse);
            $students = $studentsQuery->orderBy('Nom', 'ASC')->get();

            if ($user && strtolower(trim((string) ($user->account_type ?? ''))) === 'encadreur') {
                $students = $encadreurScope->listStudentsForEncadreur($user, $CodeClasse)->get();
            }

            return $students;
        }
        if($action == 'GET_MAIN_STUDENT'){
            $CodeEleve = $request->codeEleve;
            $student = Eleve::where('CodeEleve','=',$CodeEleve)->orderBy('Nom', 'ASC')->get();
            return $student;
        }
        if($action == 'GET_PARENT_STUDENTS'){
            $code = $request->code;
            $students = Eleve::where('code','=',$code)->orderBy('Nom', 'ASC')->get();
            return $students;
        }

        #inscriptions
        if($action == 'GET_STUDENT_INSCRIPTIONS'){
            $CodeEleve = $request->CodeEleve;
            $inscriptions = Inscription::where('CodeEleve','=', $CodeEleve)->orderBy('NUMFAC', 'ASC')->get();
            return $inscriptions;
        }
        if($action == 'GET_ALL_STUDENTS'){
            // $CodeEtablissement = $request->CodeEtablissement;
            // $classes = Classe::where('CodeEtablissement','=','11201')->get();
            // $students = array();
            // foreach($classes as $classe){
            //     return $classe->students;
            //     array_combine($students, $classe->students);
            // }
            return DB::select('select * from eleves');
        }

        if($action == 'GET_SUM_INSCRIPTIONS'){
            $NUMFAC = $request->NUMFAC;
            $CodeEleve = $request->CodeEleve;
            $inscriptions = HistoriqueInscription::where('CodeEleve','=', $CodeEleve)->where('NUMFAC','=',$NUMFAC)->orderBy('NUMFAC', 'ASC')->get();
            // return $inscriptions;
            $sum = 0;
            foreach($inscriptions as $inscription){
                $sum +=(float)$inscription->Avance;
            }
            return $sum;
            $sum = 0;
        }

        if($action == 'GET_STUDENT_HISTORIQUE_INSCRIPTIONS'){
            $CodeEleve = $request->CodeEleve;
            $NUMFAC = $request->NUMFAC;
            $inscriptions = HistoriqueInscription::where('NUMFAC','=',$NUMFAC)->get();
            return $inscriptions;
        }

        if($action == 'GET_COURSE_ABSENCES'){
            $CodeEnseignement = $request->CodeEnseignement;
            $absences = Conduite::where('CodeEnseignement','=',$CodeEnseignement)->get();
            return $absences;
        }

        if($action == 'GET_TEACHER_ATTENDANCE'){
            $CodeEnseignement = $request->CodeEnseignement;
            $teacherCode = $request->teacher_code;
            $course = Enseignement::where('CodeEnseignement', $CodeEnseignement)
                ->where(function ($query) use ($teacherCode) {
                    $query->where('code', $teacherCode)
                        ->orWhere('CodeEnseignant2', $teacherCode);
                })
                ->first();

            if (!$course) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            $attendanceQuery = Conduite::where('CodeEnseignement', $CodeEnseignement);
            if ($request->filled('DateEnreg')) {
                $attendanceQuery->where('DateEnreg', $request->DateEnreg);
            }

            return response()->json(
                $attendanceQuery->orderByDesc('DateEnreg')->get(),
                200,
                ['Content-Type' => 'application/json']
            );
        }

        if($action == 'SAVE_TEACHER_ATTENDANCE'){
            $CodeEnseignement = $request->CodeEnseignement;
            $teacherCode = $request->teacher_code;
            $course = Enseignement::where('CodeEnseignement', $CodeEnseignement)
                ->where(function ($query) use ($teacherCode) {
                    $query->where('code', $teacherCode)
                        ->orWhere('CodeEnseignant2', $teacherCode);
                })
                ->first();

            if (!$course) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            $statuses = $this->decodeJsonArrayInput($request->input('statuses', '[]'));
            if (!is_array($statuses) || empty($statuses)) {
                return response()->json(['message' => 'Invalid attendance'], 422);
            }

            $students = Eleve::where('CodeClasse', $course->CodeClasse)
                ->pluck('CodeEleve')->all();
            $studentCodes = array_flip($students);
            $allowedStatuses = ['P', 'A', 'R'];

            foreach ($statuses as $status) {
                if (!isset($status['CodeEleve'], $status['status'])
                    || !isset($studentCodes[$status['CodeEleve']])
                    || !in_array($status['status'], $allowedStatuses, true)) {
                    return response()->json(['message' => 'Invalid attendance student or status'], 422);
                }
            }

            DB::transaction(function () use ($request, $course, $CodeEnseignement, $statuses) {
                Conduite::where('CodeEnseignement', $CodeEnseignement)
                    ->where('DateEnreg', $request->DateEnreg)
                    ->delete();

                foreach ($statuses as $status) {
                    Conduite::create([
                        'DateEnreg' => $request->DateEnreg,
                        'CodeEleve' => $status['CodeEleve'],
                        'Nombre' => '1',
                        'CodeEtatCond' => $status['status'],
                        'CodeClasse' => $course->CodeClasse,
                        'CodeAnnee' => $request->CodeAnnee,
                        'CodeMatiere' => $course->CodeMatiere,
                        'CodeEnseignement' => $CodeEnseignement,
                        'HeureMatiere' => $course->NBRHEURE ?: '1',
                    ]);
                }
            });

            $this->createAttendanceMessages(
                $course,
                array_column($statuses, 'CodeEleve'),
                (string) $request->DateEnreg
            );

            $dispatcher = new NotificationDispatchService();
            foreach ($statuses as $statusEntry) {
                $studentCode = (string) ($statusEntry['CodeEleve'] ?? '');
                $status = (string) ($statusEntry['status'] ?? '');
                if ($studentCode === '' || $status === '') {
                    continue;
                }
                $dispatcher->dispatchAttendanceNotification(
                    $studentCode,
                    (string) $request->DateEnreg,
                    $status,
                    (string) $teacherCode,
                    ['school_code' => (string) ($course->CodeEtablissement ?? ''), 'class_code' => (string) $course->CodeClasse]
                );
            }

            $this->createInvestigationAlertsForAttendance(
                $course,
                $request->DateEnreg,
                $statuses,
                $students
            );

            return response()->json(['status' => 'success']);
        }

        if($action == 'UPDATE_TEACHER_ATTENDANCE'){
            $CodeEnseignement = trim((string) $request->input('CodeEnseignement', ''));
            $teacherCode = trim((string) $request->input('teacher_code', ''));
            $date = trim((string) $request->input('DateEnreg', ''));
            $course = Enseignement::where('CodeEnseignement', $CodeEnseignement)
                ->where(function ($query) use ($teacherCode) {
                    $query->where('code', $teacherCode)
                        ->orWhere('CodeEnseignant2', $teacherCode);
                })
                ->first();

            if (!$course) {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            $records = $this->decodeJsonArrayInput($request->input('records', '[]'));
            if (!is_array($records) || empty($records) || $date === '') {
                return response()->json(['message' => 'Invalid attendance'], 422);
            }

            $allowedStatuses = ['P', 'A', 'R'];
            $recordIds = [];
            foreach ($records as $record) {
                $id = filter_var($record['id'] ?? null, FILTER_VALIDATE_INT);
                $status = $record['status'] ?? null;
                if (!$id || !in_array($status, $allowedStatuses, true)) {
                    return response()->json(['message' => 'Invalid attendance record or status'], 422);
                }
                $recordIds[] = $id;
            }

            $attendanceRecords = Conduite::whereIn('id', $recordIds)
                ->where('CodeEnseignement', $CodeEnseignement)
                ->where('DateEnreg', $date)
                ->where('CodeClasse', $course->CodeClasse)
                ->get();
            if ($attendanceRecords->count() !== count(array_unique($recordIds))) {
                return response()->json(['message' => 'Attendance record not found'], 422);
            }

            DB::transaction(function () use ($records) {
                foreach ($records as $record) {
                    Conduite::where('id', (int) $record['id'])
                        ->update(['CodeEtatCond' => $record['status']]);
                }
            });

            $this->createAttendanceMessages(
                $course,
                $attendanceRecords->pluck('CodeEleve')->all(),
                $date
            );

            $dispatcher = new NotificationDispatchService();
            foreach ($records as $record) {
                $studentCode = (string) ($attendanceRecords->firstWhere('id', (int) ($record['id'] ?? 0))?->CodeEleve ?? '');
                $status = (string) ($record['status'] ?? '');
                if ($studentCode === '' || $status === '') {
                    continue;
                }
                $dispatcher->dispatchAttendanceNotification(
                    $studentCode,
                    $date,
                    $status,
                    (string) $teacherCode,
                    ['school_code' => (string) ($course->CodeEtablissement ?? ''), 'class_code' => (string) $course->CodeClasse]
                );
            }

            return response()->json(['status' => 'success']);
        }

        #conduite

        if($action == 'ADD_CONDUITE'){
            $DateEnreg = $request->DateEnreg;
            $CodeEleve = $request->CodeEleve;
            $Nombre = $request->Nombre;
            $CodeEtatCond = '';
            $CodeClasse = $request->CodeClasse;
            $CodeAnnee = $request->CodeAnnee;
            $CodeMatiere = $request->CodeMatiere;
            $CodeEnseignement = $request->CodeEnseignement;
            $HeureMatiere = '1';

            $conduite = Conduite::create([
                'DateEnreg'=>$DateEnreg,
                'CodeEleve'=>$CodeEleve,
                'Nombre'=>$Nombre,
                'CodeEtatCond'=>$CodeEtatCond,
                'CodeClasse'=>$CodeClasse,
                'CodeAnnee'=>$CodeAnnee,
                'CodeMatiere'=>$CodeMatiere,
                'CodeEnseignement'=>$CodeEnseignement,
                'HeureMatiere'=>$HeureMatiere
            ]);
            $conduite->save();
            return "success";
        }

        if($action == 'GET_SORTED_STUDENT_ABSENCES'){
            $CodeEnseignement = $request->CodeEnseignement;
            // $CodeEleve = $request->CodeEleve;
            $sortedDate = $request->sortedDate;
            $absences = Conduite::where('CodeEnseignement','=',$CodeEnseignement)->where('DateEnreg','=',$sortedDate)->get();
            return $absences;
        }

        if($action == 'GET_SORTED_ALL_STUDENT_ABSENCES'){
            // $CodeEnseignement = $request->CodeEnseignement;
            $CodeEleve = $request->CodeEleve;
            $sortedDate = $request->sortedDate;
            $absences = Conduite::where('CodeEleve','=',$CodeEleve)->where('DateEnreg','=',$sortedDate)->get();
            return $absences;
        }

        if($action == 'GET_SORTED_COURSE_ABSENT_STUDENTS'){
            $CodeEnseignement = $request->CodeEnseignement;
            $sortedDate = $request->sortedDate;
            $students = array();
            $absences = Conduite::where('CodeEnseignement','=',$CodeEnseignement)->where('DateEnreg','=',$sortedDate)->get();
            
            foreach($absences as $absence){
                $student = Eleve::find($absence->CodeEleve);
                $students[] = $student;
            }
            return $students;
        }
        if($action == 'GET_COURSE_STUDENT_ABSENCES'){
            $CodeEnseignement = $request->CodeEnseignement;
            $CodeEleve = $request->CodeEleve;

            $absences = Conduite::where('CodeEnseignement','=',$CodeEnseignement)->where('CodeEleve','=',$CodeEleve)->get();
            return $absences;
        }

        if($action == 'GET_SORTED_COURSE_ABSENCES'){
            $CodeEnseignement = $request->CodeEnseignement;
            // $CodeEleve = $request->CodeEleve;
            $sortedDate = $request->sortedDate;
            $absences = Conduite::where('CodeEnseignement','=',$CodeEnseignement)->where('DateEnreg','=',$sortedDate)->get();
            return $absences;
        }
        
        if($action == 'GET_ALL_STUDENT_ABSENCES'){
            $CodeEleve = $request->CodeEleve;

            $absences = Conduite::where('CodeEleve','=',$CodeEleve)->get();
            return $absences;
        }

        if($action == 'CLEAR'){
            $CodeEnseignement = $request->CodeEnseignement;
            // $CodeEleve = $request->CodeEleve;
            $sortedDate = $request->sortedDate;
            $absences = Conduite::where('CodeEnseignement','=',$CodeEnseignement)->where('DateEnreg','=',$sortedDate)->get();
            $absences->delete();
            return "success";
        }

        if($action == 'GET_MAIN_SCHOOL'){
            $codeEtablissement = $request->codeEtablissement;
            $school = Etablissement::where('CodeEtablissement','=',$codeEtablissement)->get();
            return $school;
        }
    }

    private function resolvePrincipalContext(Request $request): array
    {
        $code = trim((string) $request->input('code', ''));

        if ($code !== '') {
            $user = User::where('code', '=', $code)->first();
            if (!$user || !$this->isPrincipalUser($user)) {
                return ['allowed' => false];
            }

            $resolvedSchoolCode = trim((string) ($user->CodeEtablissement ?? ''));
            if ($resolvedSchoolCode === '') {
                return ['allowed' => false];
            }

            return ['allowed' => true, 'school_code' => $resolvedSchoolCode, 'user' => $user];
        }

        return ['allowed' => false];
    }

    private function resolveDashboardScope(Request $request): array
    {
        $code = trim((string) $request->input('code', ''));
        if ($code === '') {
            return ['allowed' => false];
        }

        $user = User::where('code', '=', $code)->first();
        if (!$user) {
            return ['allowed' => false];
        }

        $resolvedSchoolCode = trim((string) ($user->CodeEtablissement ?? ''));
        if ($resolvedSchoolCode === '') {
            return ['allowed' => false];
        }

        $accountType = strtolower(trim((string) ($user->account_type ?? '')));
        $adminFlag = (bool) $user->admin;

        if ($adminFlag || in_array($accountType, ['principal', 'principal_encadreur', 'administrateur'], true)) {
            $classCodes = Classe::where('CodeEtablissement', '=', $resolvedSchoolCode)
                ->pluck('CodeClasse')
                ->map(fn ($value) => (string) $value)
                ->values()
                ->all();

            return ['allowed' => true, 'school_code' => $resolvedSchoolCode, 'user' => $user, 'class_codes' => $classCodes];
        }

        if ($accountType === 'encadreur') {
            $encadreurScope = new EncadreurClassScope();
            $classCodes = $encadreurScope->assignedClassCodesForEncadreur($user);

            return ['allowed' => true, 'school_code' => $resolvedSchoolCode, 'user' => $user, 'class_codes' => $classCodes];
        }

        return ['allowed' => false];
    }

    private function isPrincipalUser(User $user): bool
    {
        $accountType = strtolower(trim((string) ($user->account_type ?? '')));
        $adminFlag = (bool) $user->admin;

        return $adminFlag || in_array($accountType, ['encadreur', 'principal', 'principal_encadreur', 'administrateur'], true);
    }

    private function resolveTeacherSummaryForCourse($course): array
    {
        if (!$course) {
            return ['code' => null, 'nom' => '', 'prenom' => '', 'full_name' => ''];
        }

        $teacherCode = trim((string) ($course->code ?? ''));
        $secondaryTeacherCode = trim((string) ($course->CodeEnseignant2 ?? ''));

        $teacher = $teacherCode !== ''
            ? User::where('code', '=', $teacherCode)
                ->where('account_type', '=', 'enseignant')
                ->first()
            : null;

        if (!$teacher && $secondaryTeacherCode !== '') {
            $teacher = User::where('code', '=', $secondaryTeacherCode)
                ->where('account_type', '=', 'enseignant')
                ->first();
        }

        if (!$teacher) {
            return ['code' => $teacherCode !== '' ? $teacherCode : $secondaryTeacherCode, 'nom' => '', 'prenom' => '', 'full_name' => ''];
        }

        return [
            'code' => (string) ($teacher->code ?? ''),
            'nom' => (string) ($teacher->nom ?? ''),
            'prenom' => (string) ($teacher->prenom ?? ''),
            'full_name' => trim((string) (($teacher->nom ?? '') . ' ' . ($teacher->prenom ?? ''))),
        ];
    }

    private function formatAttendanceTime($value): string
    {
        $duration = trim((string) ($value ?? ''));
        if ($duration === '') {
            return '';
        }

        return $duration . ((float) $duration === 1.0 ? ' heure' : ' heures');
    }

    private function decodeJsonArrayInput(mixed $value): array
    {
        if (is_array($value)) {
            return $value;
        }

        if (!is_string($value) || trim($value) === '') {
            return [];
        }

        $decoded = json_decode($value, true);

        return is_array($decoded) ? $decoded : [];
    }

    private function createAttendanceMessages($course, array $studentCodes, string $attendanceDate): void
    {
        $class = Classe::where('CodeClasse', $course->CodeClasse)->first();
        $subject = Matiere::where('CodeMatiere', $course->CodeMatiere)->first();
        $className = trim((string) ($class->LibelleClasse ?? ''));
        $subjectName = trim((string) ($subject->LibelleMatiere ?? ''));
        $attendanceTime = now()->format('H:i');

        $students = Eleve::whereIn('CodeEleve', array_unique($studentCodes))->get();
        foreach ($students as $student) {
            $studentName = trim(($student->Nom ?? '') . ' ' . ($student->Prenom ?? ''));
            $description = implode("\n", [
                'Présence validée',
                'Élève : ' . $studentName,
                'Classe : ' . $className,
                'Matière : ' . $subjectName,
                'Heure : ' . $attendanceTime,
            ]);

            Convocation::firstOrCreate(
                [
                    'code' => $student->code,
                    'CodeEleve' => $student->CodeEleve,
                    'motif' => 'Présence validée',
                    'CodeEnseignement' => $course->CodeEnseignement,
                    'CodeMatiere' => $course->CodeMatiere,
                    'dateConvocation' => $attendanceDate,
                ],
                ['description' => $description]
            );
        }
    }

    private function createInvestigationAlertsForAttendance($course, string $attendanceDate, array $statuses, $students): void
    {
        if (!$course) {
            return;
        }

        $schoolCode = trim((string) ($course->CodeEtablissement ?? ''));
        if ($schoolCode === '') {
            return;
        }

        $statusMap = [];
        foreach ($statuses as $entry) {
            if (!isset($entry['CodeEleve']) || !isset($entry['status'])) {
                continue;
            }
            $statusMap[(string) $entry['CodeEleve']] = strtoupper((string) $entry['status']);
        }

        $studentCodes = [];
        foreach ($students as $student) {
            $studentCode = is_object($student)
                ? (string) ($student->CodeEleve ?? '')
                : (string) $student;
            if ($studentCode !== '') {
                $studentCodes[] = $studentCode;
            }
        }

        foreach (array_values(array_unique($studentCodes)) as $studentCode) {
            $teacherStatus = strtoupper((string) ($statusMap[$studentCode] ?? ''));
            if ($teacherStatus !== 'P') {
                continue;
            }

            $absenceJustification = AbsenceJustification::query()
                ->where('CodeEleve', '=', $studentCode)
                ->where('date_absence', '=', $attendanceDate)
                ->whereIn('statut', ['En attente', 'validée', 'Validee', 'Validée'])
                ->orderByDesc('id')
                ->first();

            if (!$absenceJustification) {
                continue;
            }

            InvestigationAlert::firstOrCreate([
                'CodeEtablissement' => $schoolCode,
                'CodeEleve' => $studentCode,
                'CodeClasse' => (string) ($course->CodeClasse ?? ''),
                'CodeEnseignement' => (string) ($course->CodeEnseignement ?? ''),
                'CodeMatiere' => (string) ($course->CodeMatiere ?? ''),
                'date_absence' => $attendanceDate,
            ], [
                'parent_status' => 'A',
                'teacher_status' => 'P',
                'status' => 'pending',
                'notes' => 'Parent absent / professeur présent',
            ]);
        }
    }
}

