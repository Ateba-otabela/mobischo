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
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class API extends Controller
{

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

        $userPayload = [
            'nom' => (string) ($user->nom ?? ''),
            'prenom' => (string) ($user->prenom ?? ''),
            'contacts' => (string) ($user->contacts ?? ''),
            'sex' => (string) ($user->sex ?? ''),
            'email' => (string) ($user->email ?? ''),
            'login' => (string) ($user->login ?? ''),
            'code' => (string) ($user->code ?? ''),
            'account_type' => (string) ($user->account_type ?? ''),
            'text_password' => (string) ($user->text_password ?? ''),
            'address' => (string) ($user->address ?? ''),
            'admin' => (string) ($user->admin ?? '0'),
            'CodeEtablissement' => (string) ($user->CodeEtablissement ?? ''),
        ];

        return response()->json([$userPayload]);
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

            return response()->json(['status' => 'success', 'id' => $justification->id]);
        }

        if ($action == 'GET_PARENT_ABSENCE_JUSTIFICATIONS') {
            $parentCode = trim((string) $request->input('code', ''));
            $studentCodes = Eleve::where('code', $parentCode)->pluck('CodeEleve');
            return AbsenceJustification::whereIn('CodeEleve', $studentCodes)
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
            $principalContext = $this->resolvePrincipalContext($request);
            if (!$principalContext['allowed']) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = (string) $principalContext['school_code'];
            $classes = Classe::where('CodeEtablissement', '=', $schoolCode)
                ->orderBy('LibelleClasse')
                ->get();
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
            $principalContext = $this->resolvePrincipalContext($request);
            if (!$principalContext['allowed']) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = (string) $principalContext['school_code'];
            $today = date('Y-m-d');
            $classes = Classe::where('CodeEtablissement', '=', $schoolCode)
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
            $principalContext = $this->resolvePrincipalContext($request);
            if (!$principalContext['allowed']) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = (string) $principalContext['school_code'];
            $classCodes = Classe::where('CodeEtablissement', '=', $schoolCode)
                ->pluck('CodeClasse')
                ->all();

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
            $principalContext = $this->resolvePrincipalContext($request);
            if (!$principalContext['allowed']) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = (string) $principalContext['school_code'];
            $classCode = trim((string) $request->input('CodeClasse', ''));
            if ($classCode === '') {
                return response()->json(['error' => 'Missing CodeClasse'], 422);
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

            $teacher = User::where('code', '=', $code)
                ->where('account_type', '=', 'enseignant')
                ->first();
            if (!$teacher) {
                return response()->json(['error' => 'Enseignant non autorisé.'], 403);
            }

            $enseignement = Enseignement::where('CodeEnseignement', '=', $codeEnseignement)
                ->where(function ($query) use ($code) {
                    $query->where('code', '=', $code)
                        ->orWhere('CodeEnseignant2', '=', $code);
                })
                ->first();
            if (!$enseignement) {
                return response()->json(['error' => 'Cette matière ne fait pas partie de vos classes.'], 403);
            }

            if ($codeClasse === '') {
                $codeClasse = (string) $enseignement->CodeClasse;
            }
            if ((string) $enseignement->CodeClasse !== $codeClasse) {
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
            $CodeClasse = $request->codeClasse;
            $students = Eleve::where('CodeClasse','=',$CodeClasse)->orderBy('Nom', 'ASC')->get();
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

            $statuses = json_decode($request->input('statuses', '[]'), true);
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

            $records = json_decode($request->input('records', '[]'), true);
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
}

