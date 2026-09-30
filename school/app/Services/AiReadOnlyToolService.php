<?php

namespace App\Services;

use App\Models\User;
use App\Services\EncadreurClassScope;
use Carbon\Carbon;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;

class AiReadOnlyToolService
{
    private const OUTPUT_FIELD_ALLOWLIST = [
        'eleves' => ['CodeEleve', 'Nom', 'Prenom', 'CodeClasse'],
        'classes' => ['CodeClasse', 'LibelleClasse'],
        'users' => ['code', 'nom', 'prenom'],
        'enseignements' => ['CodeEnseignement', 'CodeClasse', 'CodeMatiere', 'code', 'CodeEnseignant2'],
        'matieres' => ['CodeMatiere', 'LibelleMatiere'],
        'conduites' => ['DateEnreg', 'CodeEleve', 'CodeEtatCond', 'CodeClasse', 'CodeMatiere', 'CodeEnseignement', 'HeureMatiere'],
    ];

    private const PERMANENTLY_RESTRICTED_FIELDS = [
        'users.password',
        'users.text_password',
        'users.remember_token',
        'personal_access_tokens.*',
        'sanctum_tokens.*',
        '.env.*',
        'services.google_ai.api_key',
        'database.*',
        'users.contacts',
        'users.address',
        'users.email',
        'users.login',
        'users.photo_path',
        'users.DateDeNaissance',
        'users.LieuDeNaissance',
        'users.sex',
        'users.matricule',
        'users.numcpt',
        'users.ribcpt',
        'users.CodeBank',
        'users.NumAssure',
        'eleves.code',
        'eleves.CodeAnnee',
        'eleves.CodeConduite',
        'eleves.DateNaissance',
        'eleves.LieuNaissance',
        'eleves.Nationalite',
        'eleves.Sex',
        'eleves.dateinscription',
        'eleves.Excl',
        'eleves.RELIGION',
        'eleves.SITREG',
        'eleves.ACTIVEEPS',
        'eleves.ADRESSE',
        'eleves.RESIDENT',
        'eleves.TelP',
        'eleves.TELM',
        'eleves.TELT',
        'eleves.Nomp',
        'eleves.Nomm',
        'eleves.NOMT',
        'eleves.PROFP',
        'eleves.PROFM',
        'eleves.REGION',
        'eleves.DEPART',
        'eleves.photo',
        'eleves.Image',
        'eleves.strimage',
        'eleves.PERSONCON',
        'eleves.RESERVE1',
        'eleves.RESERVE2',
        'eleves.RESERVE3',
        'eleves.RESERVE4',
        'inscriptions.Montantins',
        'inscriptions.Avance',
        'inscriptions.Reste',
        'inscriptions.Montantt',
        'inscriptions.NUMFAC',
        'inscriptions.CodeInscription',
        'inscriptions.caissier',
        'inscriptions.remise',
        'inscriptions.Tranche',
        'inscriptions.libinscrip',
        'inscriptions.heure',
        'notes.*',
        'convocations.code',
        'convocations.CodeEleve',
        'convocations.CodeEnseignement',
        'convocations.CodeMatiere',
        'convocations.dateConvocation',
        'convocations.motif',
        'convocations.description',
    ];

    private const MAX_STUDENTS = 50;
    private const MAX_ROSTER = 100;
    private const MAX_SESSIONS = 100;
    private const MAX_DATE_RANGE_DAYS = 366;

    private $principalContext;

    public function __construct(PrincipalContextService $principalContext)
    {
        $this->principalContext = $principalContext;
    }

    public function functionDeclarations(User $user): array
    {
        $string = ['type' => 'STRING'];
        $date = ['type' => 'STRING', 'description' => 'ISO date in YYYY-MM-DD format.'];

        $principalTools = [
            $this->declaration('searchStudents', 'Search the authenticated Principal school student directory. Returns only student code, name, class code, and class name.', [
                'classCode' => $string,
                'query' => $string,
                'limit' => ['type' => 'INTEGER', 'minimum' => 1, 'maximum' => self::MAX_STUDENTS],
            ]),
            $this->declaration('getStudentProfile', 'Get a minimal, non-sensitive student identity and class summary by student code.', [
                'studentCode' => $string,
            ], ['studentCode']),
            $this->declaration('getStudentAttendanceSummary', 'Get aggregated attendance counts for one authorized student and bounded date range.', [
                'studentCode' => $string,
                'dateFrom' => $date,
                'dateTo' => $date,
            ], ['studentCode', 'dateFrom', 'dateTo']),
            $this->declaration('getClassSummary', 'Get a school-scoped class summary, approved gender totals, subjects, teachers, attendance, and today sessions.', [
                'classCode' => $string,
            ], ['classCode']),
            $this->declaration('getClassRoster', 'Get a limited roster containing student code, name, and class only.', [
                'classCode' => $string,
            ], ['classCode']),
            $this->declaration('getSchoolClassOverview', 'List classes in the authenticated Principal school. schoolCode must exactly match the authenticated school.', [
                'schoolCode' => $string,
            ], ['schoolCode']),
            $this->declaration('getAttendanceSummary', 'Get approved attendance totals and a bounded session summary for a date.', [
                'date' => $date,
                'classCode' => $string,
                'subjectCode' => $string,
                'teacherCode' => $string,
            ], ['date']),
            $this->declaration('getAttendanceSessionDetail', 'Get one session by the sessionId format date|CodeEnseignement|HeureMatiere.', [
                'sessionId' => $string,
            ], ['sessionId']),
            $this->declaration('getTeacherAttendanceHistory', 'Get aggregated attendance sessions for an authorized school teacher and bounded date range.', [
                'teacherCode' => $string,
                'dateFrom' => $date,
                'dateTo' => $date,
            ], ['teacherCode', 'dateFrom', 'dateTo']),
            $this->declaration('getSchoolDashboardSummary', 'Get high-level totals and attendance session statistics for one date in the authenticated Principal school.', [
                'date' => $date,
            ], ['date']),
        ];

        $parentTools = [
            $this->declaration('get_my_children', 'List only children linked to the authenticated parent account.', []),
            $this->declaration('get_child_notes', 'Get a limited notes summary for one of the authenticated parent’s linked children.', [
                'childCode' => $string,
            ], ['childCode']),
            $this->declaration('get_child_absences', 'Get absence and late counts for one of the authenticated parent’s linked children over a bounded date range.', [
                'childCode' => $string,
                'dateFrom' => $date,
                'dateTo' => $date,
            ], ['childCode', 'dateFrom', 'dateTo']),
            $this->declaration('get_child_attendance', 'Get attendance counts for one of the authenticated parent’s linked children over a bounded date range.', [
                'childCode' => $string,
                'dateFrom' => $date,
                'dateTo' => $date,
            ], ['childCode', 'dateFrom', 'dateTo']),
            $this->declaration('get_child_convocations', 'Get convocations for one of the authenticated parent’s linked children.', [
                'childCode' => $string,
            ], ['childCode']),
            $this->declaration('get_child_messages', 'Read the parent Messages screen, which currently displays that linked child’s convocation records.', [
                'childCode' => $string,
            ], ['childCode']),
            $this->declaration('get_child_homework', 'Get homework for the class of one of the authenticated parent’s linked children.', [
                'childCode' => $string,
            ], ['childCode']),
        ];

        $teacherTools = [
            $this->declaration('get_my_classes', 'List only classes connected to the authenticated teacher through existing Enseignement assignments.', []),
            $this->declaration('get_my_teaching_assignments', 'List the authenticated teacher’s existing teaching assignments and subjects.', []),
            $this->declaration('get_class_students', 'Get a limited roster only for a class where the authenticated teacher has an Enseignement assignment.', [
                'classCode' => $string,
            ], ['classCode']),
            $this->declaration('get_class_attendance', 'Get bounded-date attendance totals and sessions for a class assigned to the authenticated teacher.', [
                'classCode' => $string,
                'dateFrom' => $date,
                'dateTo' => $date,
            ], ['classCode', 'dateFrom', 'dateTo']),
            $this->declaration('get_class_information', 'Get a school-scoped summary only for a class where the authenticated teacher has an Enseignement assignment.', [
                'classCode' => $string,
            ], ['classCode']),
        ];

        $encadreurTools = [
            $this->declaration('get_my_classes', 'List only classes assigned to the authenticated Encadreur by encadreur_classes.', []),
            $this->declaration('get_class_students', 'Get a limited roster only for a class assigned to the authenticated Encadreur.', [
                'classCode' => $string,
            ], ['classCode']),
            $this->declaration('get_class_attendance', 'Get bounded-date attendance only for a class assigned to the authenticated Encadreur.', [
                'classCode' => $string,
                'dateFrom' => $date,
                'dateTo' => $date,
            ], ['classCode', 'dateFrom', 'dateTo']),
            $this->declaration('get_class_information', 'Get a class summary only for a class assigned to the authenticated Encadreur.', [
                'classCode' => $string,
            ], ['classCode']),
        ];

        $context = $this->principalContext->resolveForAi($user);
        if ($context === null) {
            return [];
        }

        if ($context['role'] === 'parent') {
            return $parentTools;
        }

        if ($context['role'] === 'enseignant') {
            return $teacherTools;
        }

        if ($context['role'] === 'encadreur') {
            return $encadreurTools;
        }

        if (in_array($context['role'], ['principal', 'principal_encadreur', 'administrateur', 'admin'], true)) {
            return $principalTools;
        }

        return [];
    }

    public function fieldAllowlist(): array
    {
        return self::OUTPUT_FIELD_ALLOWLIST;
    }

    public function permanentlyRestrictedFields(): array
    {
        return self::PERMANENTLY_RESTRICTED_FIELDS;
    }

    public function execute(User $user, string $toolName, array $arguments): array
    {
        try {
            $result = $this->executeAuthorized($user, $toolName, $arguments);
            $this->logToolCall($user, $toolName, true);
            return $result;
        } catch (\Throwable $exception) {
            $this->logToolCall($user, $toolName, false);
            throw $exception;
        }
    }

    private function executeAuthorized(User $user, string $toolName, array $arguments): array
    {
        $context = $this->principalContext->resolveForAi($user);
        if ($context === null) {
            throw new InvalidArgumentException('AI tools are not authorized for this account.');
        }

        $methods = [
            'searchStudents' => 'searchStudents',
            'getStudentProfile' => 'getStudentProfile',
            'getStudentAttendanceSummary' => 'getStudentAttendanceSummary',
            'getClassSummary' => 'getClassSummary',
            'getClassRoster' => 'getClassRoster',
            'getSchoolClassOverview' => 'getSchoolClassOverview',
            'getAttendanceSummary' => 'getAttendanceSummary',
            'getAttendanceSessionDetail' => 'getAttendanceSessionDetail',
            'getTeacherAttendanceHistory' => 'getTeacherAttendanceHistory',
            'getSchoolDashboardSummary' => 'getSchoolDashboardSummary',
        ];
        $parentMethods = [
            'get_my_children' => 'getMyChildren',
            'get_child_notes' => 'getChildNotes',
            'get_child_absences' => 'getChildAbsences',
            'get_child_attendance' => 'getChildAttendance',
            'get_child_convocations' => 'getChildConvocations',
            'get_child_messages' => 'getChildConvocations',
            'get_child_homework' => 'getChildHomework',
        ];
        $teacherMethods = [
            'get_my_classes' => 'getMyClasses',
            'get_my_teaching_assignments' => 'getMyTeachingAssignments',
            'get_class_students' => 'getTeacherClassStudents',
            'get_class_attendance' => 'getTeacherClassAttendance',
            'get_class_information' => 'getTeacherClassInformation',
        ];
        $encadreurMethods = [
            'get_my_classes' => 'getMyClasses',
            'get_class_students' => 'getTeacherClassStudents',
            'get_class_attendance' => 'getTeacherClassAttendance',
            'get_class_information' => 'getTeacherClassInformation',
        ];
        if (isset($parentMethods[$toolName])) {
            if ($context['role'] !== 'parent') {
                throw new InvalidArgumentException('This AI tool is not authorized for this account.');
            }

            return $this->{$parentMethods[$toolName]}($context, $arguments);
        }

        if ($context['role'] === 'encadreur' && isset($encadreurMethods[$toolName])) {
            return $this->{$encadreurMethods[$toolName]}($context, $arguments);
        }

        if (isset($teacherMethods[$toolName])) {
            if ($context['role'] !== 'enseignant') {
                throw new InvalidArgumentException('This AI tool is not authorized for this account.');
            }

            return $this->{$teacherMethods[$toolName]}($context, $arguments);
        }

        if (!isset($methods[$toolName])) {
            throw new InvalidArgumentException('Unsupported AI tool.');
        }

        if (!in_array($context['role'], ['principal', 'principal_encadreur', 'administrateur', 'admin'], true)) {
            throw new InvalidArgumentException('This AI tool is not authorized for this account.');
        }

        return $this->{$methods[$toolName]}($context['school_code'], $arguments);
    }

    private function logToolCall(User $user, string $toolName, bool $success): void
    {
        $context = [
            'user_code' => (string) $user->code,
            'account_type' => (string) ($user->account_type ?? ''),
            'tool_name' => $toolName,
            'timestamp' => now()->toIso8601String(),
            'success' => $success,
        ];

        if ($success) {
            Log::info('Mobischo AI read-only tool completed.', $context);
            return;
        }

        Log::warning('Mobischo AI read-only tool failed.', $context);
    }

    private function declaration(string $name, string $description, array $properties, array $required = []): array
    {
        return [
            'name' => $name,
            'description' => $description,
            'parameters' => [
                'type' => 'OBJECT',
                'properties' => $properties,
                'required' => $required,
            ],
        ];
    }

    private function searchStudents(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'classCode' => 'sometimes|nullable|string|max:80',
            'query' => 'sometimes|nullable|string|max:100',
            'limit' => 'sometimes|integer|min:1|max:'.self::MAX_STUDENTS,
        ]);
        if (!empty($args['classCode'])) {
            $this->requireClass($schoolCode, $args['classCode']);
        }

        $query = $this->studentQuery($schoolCode);
        if (!empty($args['classCode'])) {
            $query->where('e.CodeClasse', $args['classCode']);
        }
        if (!empty($args['query'])) {
            $search = '%'.$args['query'].'%';
            $query->where(function ($builder) use ($search) {
                $builder->where('e.CodeEleve', 'like', $search)
                    ->orWhere('e.Nom', 'like', $search)
                    ->orWhere('e.Prenom', 'like', $search);
            });
        }

        $limit = isset($args['limit']) ? (int) $args['limit'] : 20;
        $rows = $query->orderBy('e.Nom')->orderBy('e.Prenom')->limit($limit + 1)->get();

        return [
            'students' => $rows->take($limit)->map(function ($row) {
                return $this->studentProjection($row);
            })->values()->all(),
            'returned' => min($rows->count(), $limit),
            'truncated' => $rows->count() > $limit,
        ];
    }

    private function getStudentProfile(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'studentCode' => 'required|string|max:80',
        ]);
        $student = $this->studentQuery($schoolCode)
            ->where('e.CodeEleve', $args['studentCode'])
            ->first();

        if (!$student) {
            return ['found' => false];
        }

        return [
            'found' => true,
            'student' => $this->studentProjection($student),
        ];
    }

    private function getStudentAttendanceSummary(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'studentCode' => 'required|string|max:80',
            'dateFrom' => 'required|date_format:Y-m-d',
            'dateTo' => 'required|date_format:Y-m-d|after_or_equal:dateFrom',
        ]);
        $this->validateDateRange($args['dateFrom'], $args['dateTo']);
        $student = $this->studentQuery($schoolCode)
            ->where('e.CodeEleve', $args['studentCode'])
            ->first();
        if (!$student) {
            return ['found' => false];
        }

        $latestIds = $this->latestAttendanceIds($schoolCode, $args['dateFrom'], $args['dateTo'], [
            'studentCode' => $args['studentCode'],
            'classCode' => $student->CodeClasse,
        ]);
        $dailyRows = DB::table('conduites as c')
            ->whereIn('c.id', $latestIds)
            ->whereIn(DB::raw("UPPER(COALESCE(c.CodeEtatCond, ''))"), ['P', 'A', 'R'])
            ->selectRaw("c.DateEnreg as date, UPPER(c.CodeEtatCond) as status, COUNT(*) as total")
            ->groupBy('c.DateEnreg', 'c.CodeEtatCond')
            ->orderBy('c.DateEnreg')
            ->get();

        $byDate = [];
        foreach ($dailyRows as $row) {
            if (!isset($byDate[$row->date])) {
                $byDate[$row->date] = ['date' => $row->date, 'present' => 0, 'absent' => 0, 'late' => 0];
            }
            $key = $this->statusKey($row->status);
            if ($key !== null) {
                $byDate[$row->date][$key] += (int) $row->total;
            }
        }

        $daily = array_values($byDate);
        foreach ($daily as &$day) {
            $day['total'] = $day['present'] + $day['absent'] + $day['late'];
            $day['attendance_percentage'] = $day['total'] > 0
                ? (int) round(($day['present'] / $day['total']) * 100)
                : null;
        }
        unset($day);

        $totals = ['present' => 0, 'absent' => 0, 'late' => 0];
        foreach ($daily as $day) {
            $totals['present'] += $day['present'];
            $totals['absent'] += $day['absent'];
            $totals['late'] += $day['late'];
        }

        return [
            'found' => true,
            'student' => $this->studentProjection($student),
            'date_from' => $args['dateFrom'],
            'date_to' => $args['dateTo'],
            'attendance' => $this->finishTotals($totals),
            'by_date' => $daily,
        ];
    }

    private function getClassSummary(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'classCode' => 'required|string|max:80',
        ]);
        $class = $this->requireClass($schoolCode, $args['classCode']);
        $studentBase = DB::table('eleves')->where('CodeClasse', $class->CodeClasse);
        $studentCount = (clone $studentBase)->count();
        $boys = (clone $studentBase)->whereIn(DB::raw('LOWER(TRIM(Sex))'), ['1', 'm', 'masculin', 'male', 'garcon', 'g'])->count();
        $girls = (clone $studentBase)->whereIn(DB::raw('LOWER(TRIM(Sex))'), ['0', 'f', 'feminin', 'female', 'fille', 'fe'])->count();

        $subjectRows = DB::table('enseignements as en')
            ->join('matieres as m', function ($join) use ($schoolCode) {
                $join->on('m.CodeMatiere', '=', 'en.CodeMatiere')
                    ->where('m.CodeEtablissement', '=', $schoolCode);
            })
            ->where('en.CodeClasse', $class->CodeClasse)
            ->where('en.CodeEtablissement', $schoolCode)
            ->select('m.CodeMatiere', 'm.LibelleMatiere')
            ->distinct()
            ->orderBy('m.LibelleMatiere')
            ->limit(100)
            ->get()
            ->map(function ($row) {
                return ['CodeMatiere' => $row->CodeMatiere, 'LibelleMatiere' => $row->LibelleMatiere];
            })->all();

        $teachingRows = DB::table('enseignements')
            ->where('CodeClasse', $class->CodeClasse)
            ->where('CodeEtablissement', $schoolCode)
            ->select('code', 'CodeEnseignant2')
            ->limit(201)
            ->get();
        $teacherCodes = $teachingRows->flatMap(function ($row) {
            return [$row->code, $row->CodeEnseignant2];
        })->filter()->unique()->values()->all();
        $teachers = $this->teacherNames($schoolCode, $teacherCodes);

        $today = now()->toDateString();
        $filters = ['classCode' => $class->CodeClasse];
        $todaySessions = $this->attendanceSessionRows(
            $schoolCode,
            $today,
            $today,
            $filters,
            self::MAX_SESSIONS + 1
        );

        return [
            'class' => ['CodeClasse' => $class->CodeClasse, 'LibelleClasse' => $class->LibelleClasse],
            'student_count' => $studentCount,
            'gender_totals' => ['boys' => $boys, 'girls' => $girls, 'unspecified' => max(0, $studentCount - $boys - $girls)],
            'attendance' => $this->attendanceTotals(
                $this->latestAttendanceIds($schoolCode, $today, $today, $filters)
            ),
            'subjects' => $subjectRows,
            'teachers' => $teachers,
            'today_sessions' => array_slice($todaySessions, 0, self::MAX_SESSIONS),
            'today_sessions_truncated' => count($todaySessions) > self::MAX_SESSIONS,
        ];
    }

    private function getClassRoster(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'classCode' => 'required|string|max:80',
        ]);
        $class = $this->requireClass($schoolCode, $args['classCode']);
        $rows = $this->studentQuery($schoolCode)
            ->where('e.CodeClasse', $class->CodeClasse)
            ->orderBy('e.Nom')->orderBy('e.Prenom')
            ->limit(self::MAX_ROSTER + 1)
            ->get();

        return [
            'class' => ['CodeClasse' => $class->CodeClasse, 'LibelleClasse' => $class->LibelleClasse],
            'students' => $rows->take(self::MAX_ROSTER)->map(function ($row) {
                return $this->studentProjection($row);
            })->values()->all(),
            'returned' => min($rows->count(), self::MAX_ROSTER),
            'truncated' => $rows->count() > self::MAX_ROSTER,
        ];
    }

    private function getSchoolClassOverview(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'schoolCode' => 'required|string|max:80',
        ]);
        if (!hash_equals($schoolCode, trim($args['schoolCode']))) {
            throw ValidationException::withMessages([
                'schoolCode' => 'School code must match the authenticated Principal school.',
            ]);
        }

        $rows = DB::table('classes as cl')
            ->leftJoin('eleves as e', 'e.CodeClasse', '=', 'cl.CodeClasse')
            ->where('cl.CodeEtablissement', $schoolCode)
            ->select(
                'cl.CodeClasse',
                'cl.LibelleClasse',
                DB::raw('COUNT(e.CodeEleve) as student_count')
            )
            ->groupBy('cl.CodeClasse', 'cl.LibelleClasse')
            ->orderBy('cl.LibelleClasse')
            ->limit(101)
            ->get();

        return [
            'classes' => $rows->take(100)->map(function ($row) {
                return [
                    'CodeClasse' => $row->CodeClasse,
                    'LibelleClasse' => $row->LibelleClasse,
                    'student_count' => (int) $row->student_count,
                ];
            })->values()->all(),
            'returned' => min($rows->count(), 100),
            'truncated' => $rows->count() > 100,
        ];
    }

    private function getAttendanceSummary(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'date' => 'required|date_format:Y-m-d',
            'classCode' => 'sometimes|nullable|string|max:80',
            'subjectCode' => 'sometimes|nullable|string|max:80',
            'teacherCode' => 'sometimes|nullable|string|max:80',
        ]);
        $filters = [];
        if (!empty($args['classCode'])) {
            $this->requireClass($schoolCode, $args['classCode']);
            $filters['classCode'] = $args['classCode'];
        }
        if (!empty($args['subjectCode'])) {
            $subjectExists = DB::table('matieres')
                ->where('CodeMatiere', $args['subjectCode'])
                ->where('CodeEtablissement', $schoolCode)
                ->exists();
            if (!$subjectExists) {
                throw ValidationException::withMessages(['subjectCode' => 'Subject is outside the authenticated school.']);
            }
            $filters['subjectCode'] = $args['subjectCode'];
        }
        if (!empty($args['teacherCode'])) {
            $this->requireTeacher($schoolCode, $args['teacherCode']);
            $filters['teacherCode'] = $args['teacherCode'];
        }

        $from = $args['date'];
        $latestIds = $this->latestAttendanceIds($schoolCode, $from, $from, $filters);
        $sessions = $this->attendanceSessionRows(
            $schoolCode,
            $from,
            $from,
            $filters,
            self::MAX_SESSIONS + 1
        );

        return [
            'date' => $from,
            'filters' => [
                'classCode' => $filters['classCode'] ?? null,
                'subjectCode' => $filters['subjectCode'] ?? null,
                'teacherCode' => $filters['teacherCode'] ?? null,
            ],
            'attendance' => $this->attendanceTotals($latestIds),
            'sessions' => array_slice($sessions, 0, self::MAX_SESSIONS),
            'sessions_truncated' => count($sessions) > self::MAX_SESSIONS,
        ];
    }

    private function getAttendanceSessionDetail(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'sessionId' => 'required|string|max:240',
        ]);
        $parts = explode('|', $args['sessionId']);
        if (count($parts) !== 3) {
            throw ValidationException::withMessages(['sessionId' => 'Invalid attendance session identifier.']);
        }
        list($date, $teachingCode, $time) = $parts;
        $this->validateArguments(['date' => $date], ['date' => 'required|date_format:Y-m-d']);

        $teaching = DB::table('enseignements')
            ->where('CodeEnseignement', $teachingCode)
            ->where('CodeEtablissement', $schoolCode)
            ->first(['CodeEnseignement', 'CodeClasse', 'CodeMatiere', 'code', 'CodeEnseignant2']);
        if (!$teaching || !$this->classExists($schoolCode, $teaching->CodeClasse)) {
            return ['found' => false];
        }
        $class = $this->requireClass($schoolCode, $teaching->CodeClasse);
        $subject = DB::table('matieres')
            ->where('CodeMatiere', $teaching->CodeMatiere)
            ->where('CodeEtablissement', $schoolCode)
            ->value('LibelleMatiere');
        $teachers = $this->teacherNames($schoolCode, [$teaching->code, $teaching->CodeEnseignant2], 2);

        $filters = [
            'classCode' => $teaching->CodeClasse,
            'teachingCode' => $teachingCode,
            'time' => $time,
        ];
        $latestIds = $this->latestAttendanceIds($schoolCode, $date, $date, $filters);
        $records = DB::table('conduites as c')
            ->join('eleves as e', function ($join) {
                $join->on('e.CodeEleve', '=', 'c.CodeEleve')
                    ->on('e.CodeClasse', '=', 'c.CodeClasse');
            })
            ->whereIn('c.id', $latestIds)
            ->whereIn(DB::raw("UPPER(COALESCE(c.CodeEtatCond, ''))"), ['P', 'A', 'R'])
            ->select('e.CodeEleve', 'e.Nom', 'e.Prenom', 'e.CodeClasse', 'c.CodeEtatCond')
            ->orderBy('e.Nom')->orderBy('e.Prenom')
            ->limit(self::MAX_ROSTER + 1)
            ->get();
        $totals = $this->attendanceTotals($latestIds);

        return [
            'found' => $records->isNotEmpty(),
            'session' => [
                'sessionId' => $args['sessionId'],
                'date' => $date,
                'time' => $time,
                'classCode' => $teaching->CodeClasse,
                'className' => $class->LibelleClasse,
                'subjectCode' => $teaching->CodeMatiere,
                'subject' => (string) ($subject ?? ''),
                'teacher' => implode(', ', array_column($teachers, 'name')),
                'attendance' => $totals,
                'students' => $records->take(self::MAX_ROSTER)->map(function ($row) {
                    return [
                        'CodeEleve' => $row->CodeEleve,
                        'Nom' => $row->Nom,
                        'Prenom' => $row->Prenom,
                        'CodeClasse' => $row->CodeClasse,
                        'status' => strtoupper((string) $row->CodeEtatCond),
                    ];
                })->values()->all(),
                'truncated' => $records->count() > self::MAX_ROSTER,
            ],
        ];
    }

    private function getTeacherAttendanceHistory(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'teacherCode' => 'required|string|max:80',
            'dateFrom' => 'required|date_format:Y-m-d',
            'dateTo' => 'required|date_format:Y-m-d|after_or_equal:dateFrom',
        ]);
        $this->validateDateRange($args['dateFrom'], $args['dateTo']);
        $this->requireTeacher($schoolCode, $args['teacherCode']);
        $filters = ['teacherCode' => $args['teacherCode']];
        $sessions = $this->attendanceSessionRows(
            $schoolCode,
            $args['dateFrom'],
            $args['dateTo'],
            $filters,
            self::MAX_SESSIONS + 1
        );

        return [
            'teacherCode' => $args['teacherCode'],
            'date_from' => $args['dateFrom'],
            'date_to' => $args['dateTo'],
            'sessions' => array_slice($sessions, 0, self::MAX_SESSIONS),
            'returned' => min(count($sessions), self::MAX_SESSIONS),
            'truncated' => count($sessions) > self::MAX_SESSIONS,
        ];
    }

    private function getSchoolDashboardSummary(string $schoolCode, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'date' => 'required|date_format:Y-m-d',
        ]);
        $classCodes = DB::table('classes')
            ->where('CodeEtablissement', $schoolCode)
            ->select('CodeClasse');
        $classCount = DB::table('classes')->where('CodeEtablissement', $schoolCode)->count();
        $studentCount = DB::table('eleves')->whereIn('CodeClasse', $classCodes)->count();
        $teacherCount = User::where('CodeEtablissement', $schoolCode)
            ->where('account_type', 'enseignant')
            ->count();
        $latestIds = $this->latestAttendanceIds($schoolCode, $args['date'], $args['date']);
        $dailySessions = $this->attendanceSessionRows(
            $schoolCode,
            $args['date'],
            $args['date'],
            [],
            self::MAX_SESSIONS + 1
        );

        return [
            'date' => $args['date'],
            'total_classes' => $classCount,
            'total_students' => $studentCount,
            'total_teachers' => $teacherCount,
            'attendance' => $this->attendanceTotals($latestIds),
            'daily_sessions' => array_slice($dailySessions, 0, self::MAX_SESSIONS),
            'daily_sessions_truncated' => count($dailySessions) > self::MAX_SESSIONS,
        ];
    }

    private function getMyChildren(array $context, array $arguments): array
    {
        $this->validateArguments($arguments, []);
        $rows = DB::table('eleves as e')
            ->leftJoin('classes as cl', 'cl.CodeClasse', '=', 'e.CodeClasse')
            ->where('e.code', $context['parent_code'])
            ->select('e.CodeEleve', 'e.Nom', 'e.Prenom', 'e.CodeClasse', 'cl.LibelleClasse')
            ->orderBy('e.Nom')
            ->orderBy('e.Prenom')
            ->limit(self::MAX_STUDENTS + 1)
            ->get();

        return [
            'children' => $rows->take(self::MAX_STUDENTS)->map(fn ($row) => [
                'CodeEleve' => (string) $row->CodeEleve,
                'name' => trim((string) ($row->Nom ?? '').' '.(string) ($row->Prenom ?? '')),
                'CodeClasse' => (string) ($row->CodeClasse ?? ''),
                'className' => (string) ($row->LibelleClasse ?? ''),
            ])->values()->all(),
            'returned' => min($rows->count(), self::MAX_STUDENTS),
            'truncated' => $rows->count() > self::MAX_STUDENTS,
        ];
    }

    private function getChildNotes(array $context, array $arguments): array
    {
        $args = $this->validateArguments($arguments, ['childCode' => 'required|string|max:80']);
        $child = $this->parentOwnedChild($context['parent_code'], $args['childCode']);
        if (!$child) {
            return ['found' => false];
        }

        $rows = DB::table('notes as n')
            ->join('enseignements as en', function ($join) use ($child) {
                $join->on('en.CodeEnseignement', '=', 'n.CodeEnseignement')
                    ->where('en.CodeClasse', '=', $child->CodeClasse)
                    ->where('en.CodeEtablissement', '=', $child->schoolCode);
            })
            ->leftJoin('matieres as m', function ($join) use ($child) {
                $join->on('m.CodeMatiere', '=', 'en.CodeMatiere')
                    ->where('m.CodeEtablissement', '=', $child->schoolCode);
            })
            ->where('n.CodeEleve', $child->CodeEleve)
            ->select('n.CodeEvaluation', 'n.valeur', 'n.coef', 'n.Total', 'n.Dateeng', 'n.CodeAnnee', 'en.CodeMatiere', 'm.LibelleMatiere')
            ->orderByDesc('n.Dateeng')
            ->limit(101)
            ->get();

        return [
            'found' => true,
            'child' => $this->parentChildProjection($child),
            'notes' => $rows->take(100)->map(fn ($row) => [
                'evaluation_code' => (string) $row->CodeEvaluation,
                'subject' => (string) ($row->LibelleMatiere ?? $row->CodeMatiere ?? ''),
                'value' => $row->valeur,
                'coefficient' => $row->coef,
                'total' => $row->Total,
                'date' => $row->Dateeng,
                'school_year' => $row->CodeAnnee,
            ])->values()->all(),
            'returned' => min($rows->count(), 100),
            'truncated' => $rows->count() > 100,
        ];
    }

    private function getChildAttendance(array $context, array $arguments): array
    {
        $args = $this->parentAttendanceArguments($arguments);
        $child = $this->parentOwnedChild($context['parent_code'], $args['childCode']);
        if (!$child) {
            return ['found' => false];
        }

        return $this->getStudentAttendanceSummary($child->schoolCode, [
            'studentCode' => (string) $child->CodeEleve,
            'dateFrom' => $args['dateFrom'],
            'dateTo' => $args['dateTo'],
        ]);
    }

    private function getChildAbsences(array $context, array $arguments): array
    {
        $attendance = $this->getChildAttendance($context, $arguments);
        if (!($attendance['found'] ?? false)) {
            return ['found' => false];
        }

        $absenceDays = array_values(array_filter($attendance['by_date'], function ($day) {
            return $day['absent'] > 0 || $day['late'] > 0;
        }));

        return [
            'found' => true,
            'student' => $attendance['student'],
            'date_from' => $attendance['date_from'],
            'date_to' => $attendance['date_to'],
            'totals' => [
                'absent' => $attendance['attendance']['absent'],
                'late' => $attendance['attendance']['late'],
            ],
            'by_date' => $absenceDays,
        ];
    }

    private function getChildConvocations(array $context, array $arguments): array
    {
        $args = $this->validateArguments($arguments, ['childCode' => 'required|string|max:80']);
        $child = $this->parentOwnedChild($context['parent_code'], $args['childCode']);
        if (!$child) {
            return ['found' => false];
        }

        $rows = DB::table('convocations as cv')
            ->leftJoin('enseignements as en', function ($join) use ($child) {
                $join->on('en.CodeEnseignement', '=', 'cv.CodeEnseignement')
                    ->where('en.CodeClasse', '=', $child->CodeClasse)
                    ->where('en.CodeEtablissement', '=', $child->schoolCode);
            })
            ->leftJoin('matieres as m', function ($join) use ($child) {
                $join->on('m.CodeMatiere', '=', 'en.CodeMatiere')
                    ->where('m.CodeEtablissement', '=', $child->schoolCode);
            })
            ->where('cv.CodeEleve', $child->CodeEleve)
            ->select('cv.motif', 'cv.description', 'cv.dateConvocation', 'en.CodeMatiere', 'm.LibelleMatiere')
            ->orderByDesc('cv.dateConvocation')
            ->limit(101)
            ->get();

        return [
            'found' => true,
            'child' => $this->parentChildProjection($child),
            'convocations' => $rows->take(100)->map(fn ($row) => [
                'reason' => $row->motif,
                'description' => $row->description,
                'date' => $row->dateConvocation,
                'subject' => (string) ($row->LibelleMatiere ?? $row->CodeMatiere ?? ''),
            ])->values()->all(),
            'returned' => min($rows->count(), 100),
            'truncated' => $rows->count() > 100,
        ];
    }

    private function getChildHomework(array $context, array $arguments): array
    {
        $args = $this->validateArguments($arguments, ['childCode' => 'required|string|max:80']);
        $child = $this->parentOwnedChild($context['parent_code'], $args['childCode']);
        if (!$child) {
            return ['found' => false];
        }

        $rows = DB::table('devoirs as d')
            ->leftJoin('matieres as m', function ($join) use ($child) {
                $join->on('m.CodeMatiere', '=', 'd.CodeMatiere')
                    ->where('m.CodeEtablissement', '=', $child->schoolCode);
            })
            ->where('d.CodeClasse', $child->CodeClasse)
            ->where(function ($query) use ($child) {
                $query->where('d.CodeEtablissement', $child->schoolCode)
                    ->orWhereNull('d.CodeEtablissement')
                    ->orWhere('d.CodeEtablissement', '');
            })
            ->select('d.titre', 'd.description', 'd.dateDuDevoir', 'd.CodeMatiere', 'm.LibelleMatiere')
            ->orderByDesc('d.dateDuDevoir')
            ->limit(101)
            ->get();

        return [
            'found' => true,
            'child' => $this->parentChildProjection($child),
            'homework' => $rows->take(100)->map(fn ($row) => [
                'title' => $row->titre,
                'description' => $row->description,
                'date' => $row->dateDuDevoir,
                'subject' => (string) ($row->LibelleMatiere ?? $row->CodeMatiere ?? ''),
            ])->values()->all(),
            'returned' => min($rows->count(), 100),
            'truncated' => $rows->count() > 100,
        ];
    }

    private function parentAttendanceArguments(array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'childCode' => 'required|string|max:80',
            'dateFrom' => 'required|date_format:Y-m-d',
            'dateTo' => 'required|date_format:Y-m-d|after_or_equal:dateFrom',
        ]);
        $this->validateDateRange($args['dateFrom'], $args['dateTo']);

        return $args;
    }

    private function parentOwnedChild(string $parentCode, string $childCode)
    {
        return DB::table('eleves as e')
            ->join('classes as cl', 'cl.CodeClasse', '=', 'e.CodeClasse')
            ->where('e.code', $parentCode)
            ->where('e.CodeEleve', $childCode)
            ->select('e.CodeEleve', 'e.Nom', 'e.Prenom', 'e.CodeClasse', 'cl.LibelleClasse', 'cl.CodeEtablissement as schoolCode')
            ->first();
    }

    private function parentChildProjection($child): array
    {
        return [
            'CodeEleve' => (string) $child->CodeEleve,
            'name' => trim((string) ($child->Nom ?? '').' '.(string) ($child->Prenom ?? '')),
            'CodeClasse' => (string) $child->CodeClasse,
            'className' => (string) ($child->LibelleClasse ?? ''),
        ];
    }

    private function getMyClasses(array $context, array $arguments): array
    {
        $this->validateArguments($arguments, []);
        if ($context['role'] === 'encadreur') {
            $classCodes = app(EncadreurClassScope::class)
                ->assignedClassCodesForEncadreur($context['user']);
            $rows = empty($classCodes)
                ? collect()
                : DB::table('classes')
                    ->where('CodeEtablissement', $context['school_code'])
                    ->whereIn('CodeClasse', $classCodes)
                    ->select('CodeClasse', 'LibelleClasse')
                    ->orderBy('LibelleClasse')
                    ->limit(101)
                    ->get();

            return [
                'classes' => $rows->take(100)->map(fn ($row) => [
                    'CodeClasse' => (string) $row->CodeClasse,
                    'LibelleClasse' => (string) $row->LibelleClasse,
                ])->values()->all(),
                'returned' => min($rows->count(), 100),
                'truncated' => $rows->count() > 100,
            ];
        }

        $rows = DB::table('enseignements as en')
            ->join('classes as cl', function ($join) {
                $join->on('cl.CodeClasse', '=', 'en.CodeClasse')
                    ->on('cl.CodeEtablissement', '=', 'en.CodeEtablissement');
            })
            ->where('en.CodeEtablissement', $context['school_code'])
            ->where(function ($query) use ($context) {
                $query->where('en.code', $context['teacher_code'])
                    ->orWhere('en.CodeEnseignant2', $context['teacher_code']);
            })
            ->select('cl.CodeClasse', 'cl.LibelleClasse')
            ->distinct()
            ->orderBy('cl.LibelleClasse')
            ->limit(101)
            ->get();

        return [
            'classes' => $rows->take(100)->map(fn ($row) => [
                'CodeClasse' => (string) $row->CodeClasse,
                'LibelleClasse' => (string) $row->LibelleClasse,
            ])->values()->all(),
            'returned' => min($rows->count(), 100),
            'truncated' => $rows->count() > 100,
        ];
    }

    private function getMyTeachingAssignments(array $context, array $arguments): array
    {
        $this->validateArguments($arguments, []);
        $rows = DB::table('enseignements as en')
            ->join('classes as cl', function ($join) {
                $join->on('cl.CodeClasse', '=', 'en.CodeClasse')
                    ->on('cl.CodeEtablissement', '=', 'en.CodeEtablissement');
            })
            ->leftJoin('matieres as m', function ($join) {
                $join->on('m.CodeMatiere', '=', 'en.CodeMatiere')
                    ->on('m.CodeEtablissement', '=', 'en.CodeEtablissement');
            })
            ->where('en.CodeEtablissement', $context['school_code'])
            ->where(function ($query) use ($context) {
                $query->where('en.code', $context['teacher_code'])
                    ->orWhere('en.CodeEnseignant2', $context['teacher_code']);
            })
            ->select('en.CodeEnseignement', 'en.CodeClasse', 'cl.LibelleClasse', 'en.CodeMatiere', 'm.LibelleMatiere')
            ->orderBy('cl.LibelleClasse')
            ->orderBy('m.LibelleMatiere')
            ->limit(101)
            ->get();

        return [
            'assignments' => $rows->take(100)->map(fn ($row) => [
                'CodeEnseignement' => (string) $row->CodeEnseignement,
                'CodeClasse' => (string) $row->CodeClasse,
                'className' => (string) $row->LibelleClasse,
                'CodeMatiere' => (string) $row->CodeMatiere,
                'subject' => (string) ($row->LibelleMatiere ?? ''),
            ])->values()->all(),
            'returned' => min($rows->count(), 100),
            'truncated' => $rows->count() > 100,
        ];
    }

    private function getTeacherClassStudents(array $context, array $arguments): array
    {
        $args = $this->validateArguments($arguments, ['classCode' => 'required|string|max:80']);
        $class = $this->requireAssignedClass($context, $args['classCode']);
        $rows = $this->studentQuery($context['school_code'])
            ->where('e.CodeClasse', $class->CodeClasse)
            ->orderBy('e.Nom')
            ->orderBy('e.Prenom')
            ->limit(self::MAX_ROSTER + 1)
            ->get();

        return [
            'class' => ['CodeClasse' => $class->CodeClasse, 'LibelleClasse' => $class->LibelleClasse],
            'students' => $rows->take(self::MAX_ROSTER)->map(fn ($row) => $this->studentProjection($row))->values()->all(),
            'returned' => min($rows->count(), self::MAX_ROSTER),
            'truncated' => $rows->count() > self::MAX_ROSTER,
        ];
    }

    private function getTeacherClassAttendance(array $context, array $arguments): array
    {
        $args = $this->validateArguments($arguments, [
            'classCode' => 'required|string|max:80',
            'dateFrom' => 'required|date_format:Y-m-d',
            'dateTo' => 'required|date_format:Y-m-d|after_or_equal:dateFrom',
        ]);
        $this->validateDateRange($args['dateFrom'], $args['dateTo']);
        $class = $this->requireAssignedClass($context, $args['classCode']);
        $filters = ['classCode' => $class->CodeClasse];
        if ($context['role'] === 'enseignant') {
            $filters['teacherCode'] = $context['teacher_code'];
        }
        $latestIds = $this->latestAttendanceIds(
            $context['school_code'],
            $args['dateFrom'],
            $args['dateTo'],
            $filters
        );
        $sessions = $this->attendanceSessionRows(
            $context['school_code'],
            $args['dateFrom'],
            $args['dateTo'],
            $filters,
            self::MAX_SESSIONS + 1
        );

        return [
            'class' => ['CodeClasse' => $class->CodeClasse, 'LibelleClasse' => $class->LibelleClasse],
            'date_from' => $args['dateFrom'],
            'date_to' => $args['dateTo'],
            'attendance' => $this->attendanceTotals($latestIds),
            'sessions' => array_slice($sessions, 0, self::MAX_SESSIONS),
            'sessions_truncated' => count($sessions) > self::MAX_SESSIONS,
        ];
    }

    private function getTeacherClassInformation(array $context, array $arguments): array
    {
        $args = $this->validateArguments($arguments, ['classCode' => 'required|string|max:80']);
        $class = $this->requireAssignedClass($context, $args['classCode']);

        return $this->getClassSummary($context['school_code'], ['classCode' => $class->CodeClasse]);
    }

    private function requireAssignedClass(array $context, string $classCode)
    {
        if ($context['role'] === 'encadreur') {
            $assigned = app(EncadreurClassScope::class)
                ->ensureClassAccessForEncadreur($context['user'], $classCode);
        } else {
            $assigned = DB::table('enseignements')
                ->where('CodeClasse', $classCode)
                ->where('CodeEtablissement', $context['school_code'])
                ->where(function ($query) use ($context) {
                    $query->where('code', $context['teacher_code'])
                        ->orWhere('CodeEnseignant2', $context['teacher_code']);
                })
                ->exists();
        }

        if (!$assigned) {
            throw ValidationException::withMessages([
                'classCode' => 'Class is outside the authenticated teacher assignments.',
            ]);
        }

        return $this->requireClass($context['school_code'], $classCode);
    }

    private function studentQuery(string $schoolCode): Builder
    {
        return DB::table('eleves as e')
            ->join('classes as cl', function ($join) use ($schoolCode) {
                $join->on('cl.CodeClasse', '=', 'e.CodeClasse')
                    ->where('cl.CodeEtablissement', '=', $schoolCode);
            })
            ->select('e.CodeEleve', 'e.Nom', 'e.Prenom', 'e.CodeClasse', 'cl.LibelleClasse as className');
    }

    private function studentProjection($student): array
    {
        return [
            'CodeEleve' => (string) $student->CodeEleve,
            'Nom' => (string) ($student->Nom ?? ''),
            'Prenom' => (string) ($student->Prenom ?? ''),
            'CodeClasse' => (string) $student->CodeClasse,
            'className' => (string) ($student->className ?? ''),
        ];
    }

    private function requireClass(string $schoolCode, string $classCode)
    {
        $class = DB::table('classes')
            ->where('CodeClasse', $classCode)
            ->where('CodeEtablissement', $schoolCode)
            ->first(['CodeClasse', 'LibelleClasse']);
        if (!$class) {
            throw ValidationException::withMessages(['classCode' => 'Class is outside the authenticated school.']);
        }

        return $class;
    }

    private function classExists(string $schoolCode, string $classCode): bool
    {
        return DB::table('classes')
            ->where('CodeClasse', $classCode)
            ->where('CodeEtablissement', $schoolCode)
            ->exists();
    }

    private function requireTeacher(string $schoolCode, string $teacherCode): void
    {
        $teacherExists = User::where('code', $teacherCode)
            ->where('account_type', 'enseignant')
            ->where('CodeEtablissement', $schoolCode)
            ->exists();
        $assigned = DB::table('enseignements')
            ->where('CodeEtablissement', $schoolCode)
            ->where(function ($query) use ($teacherCode) {
                $query->where('code', $teacherCode)
                    ->orWhere('CodeEnseignant2', $teacherCode);
            })
            ->exists();

        if (!$teacherExists || !$assigned) {
            throw ValidationException::withMessages(['teacherCode' => 'Teacher is outside the authenticated school.']);
        }
    }

    private function teacherNames(string $schoolCode, array $codes, int $limit = 100): array
    {
        $codes = array_slice(array_values(array_unique(array_filter($codes))), 0, $limit);
        if (empty($codes)) {
            return [];
        }

        return User::whereIn('code', $codes)
            ->where('account_type', 'enseignant')
            ->where('CodeEtablissement', $schoolCode)
            ->select('code', 'nom', 'prenom')
            ->orderBy('nom')->orderBy('prenom')
            ->limit($limit)
            ->get()
            ->map(function ($teacher) {
                return [
                    'code' => (string) $teacher->code,
                    'name' => trim((string) $teacher->nom.' '.(string) $teacher->prenom),
                ];
            })->all();
    }

    private function latestAttendanceIds(string $schoolCode, string $dateFrom, string $dateTo, array $filters = []): Builder
    {
        $query = DB::table('conduites as c')
            ->join('classes as cl', function ($join) use ($schoolCode) {
                $join->on('cl.CodeClasse', '=', 'c.CodeClasse')
                    ->where('cl.CodeEtablissement', '=', $schoolCode);
            })
            ->join('enseignements as en', function ($join) use ($schoolCode) {
                $join->on('en.CodeEnseignement', '=', 'c.CodeEnseignement')
                    ->on('en.CodeClasse', '=', 'c.CodeClasse')
                    ->where('en.CodeEtablissement', '=', $schoolCode);
            })
            ->whereBetween('c.DateEnreg', [$dateFrom, $dateTo]);

        if (!empty($filters['classCode'])) {
            $query->where('c.CodeClasse', $filters['classCode']);
        }
        if (!empty($filters['studentCode'])) {
            $query->where('c.CodeEleve', $filters['studentCode']);
        }
        if (!empty($filters['subjectCode'])) {
            $query->where('en.CodeMatiere', $filters['subjectCode']);
        }
        if (!empty($filters['teachingCode'])) {
            $query->where('en.CodeEnseignement', $filters['teachingCode']);
        }
        if (array_key_exists('time', $filters)) {
            $query->where('c.HeureMatiere', $filters['time']);
        }
        if (!empty($filters['teacherCode'])) {
            $query->where(function ($builder) use ($filters) {
                $builder->where('en.code', $filters['teacherCode'])
                    ->orWhere('en.CodeEnseignant2', $filters['teacherCode']);
            });
        }

        return $query->selectRaw('MAX(c.id) as id')
            ->groupBy(
                'c.DateEnreg',
                'c.CodeEleve',
                'c.CodeClasse',
                'c.CodeEnseignement',
                'c.CodeMatiere',
                'c.HeureMatiere'
            );
    }

    private function attendanceTotals(Builder $latestIds): array
    {
        $row = DB::table('conduites as c')
            ->whereIn('c.id', $latestIds)
            ->selectRaw("SUM(CASE WHEN UPPER(COALESCE(c.CodeEtatCond, '')) = 'P' THEN 1 ELSE 0 END) as present")
            ->selectRaw("SUM(CASE WHEN UPPER(COALESCE(c.CodeEtatCond, '')) = 'A' THEN 1 ELSE 0 END) as absent")
            ->selectRaw("SUM(CASE WHEN UPPER(COALESCE(c.CodeEtatCond, '')) = 'R' THEN 1 ELSE 0 END) as late")
            ->selectRaw("SUM(CASE WHEN UPPER(COALESCE(c.CodeEtatCond, '')) IN ('P', 'A', 'R') THEN 1 ELSE 0 END) as total")
            ->first();

        return $this->finishTotals([
            'present' => (int) ($row->present ?? 0),
            'absent' => (int) ($row->absent ?? 0),
            'late' => (int) ($row->late ?? 0),
            'total' => (int) ($row->total ?? 0),
        ]);
    }

    private function finishTotals(array $totals): array
    {
        $total = isset($totals['total'])
            ? (int) $totals['total']
            : (int) $totals['present'] + (int) $totals['absent'] + (int) $totals['late'];

        return [
            'total' => $total,
            'present' => (int) $totals['present'],
            'absent' => (int) $totals['absent'],
            'late' => (int) $totals['late'],
            'attendance_percentage' => $total > 0
                ? (int) round(((int) $totals['present'] / $total) * 100)
                : null,
        ];
    }

    private function attendanceSessionRows(
        string $schoolCode,
        string $dateFrom,
        string $dateTo,
        array $filters = [],
        int $limit = self::MAX_SESSIONS
    ): array {
        $latestIds = $this->latestAttendanceIds($schoolCode, $dateFrom, $dateTo, $filters);
        $rows = DB::table('conduites as c')
            ->join('classes as cl', function ($join) use ($schoolCode) {
                $join->on('cl.CodeClasse', '=', 'c.CodeClasse')
                    ->where('cl.CodeEtablissement', '=', $schoolCode);
            })
            ->join('enseignements as en', function ($join) use ($schoolCode) {
                $join->on('en.CodeEnseignement', '=', 'c.CodeEnseignement')
                    ->on('en.CodeClasse', '=', 'c.CodeClasse')
                    ->where('en.CodeEtablissement', '=', $schoolCode);
            })
            ->leftJoin('matieres as m', function ($join) use ($schoolCode) {
                $join->on('m.CodeMatiere', '=', 'en.CodeMatiere')
                    ->where('m.CodeEtablissement', '=', $schoolCode);
            })
            ->whereIn('c.id', $latestIds)
            ->whereIn(DB::raw("UPPER(COALESCE(c.CodeEtatCond, ''))"), ['P', 'A', 'R'])
            ->select(
                'c.DateEnreg as date',
                'c.HeureMatiere as time',
                'c.CodeClasse as classCode',
                'cl.LibelleClasse as className',
                'en.CodeEnseignement as teachingCode',
                'en.CodeMatiere as subjectCode',
                'm.LibelleMatiere as subject',
                'en.code as teacherCode',
                'en.CodeEnseignant2 as secondaryTeacherCode'
            )
            ->selectRaw("SUM(CASE WHEN UPPER(COALESCE(c.CodeEtatCond, '')) = 'P' THEN 1 ELSE 0 END) as present")
            ->selectRaw("SUM(CASE WHEN UPPER(COALESCE(c.CodeEtatCond, '')) = 'A' THEN 1 ELSE 0 END) as absent")
            ->selectRaw("SUM(CASE WHEN UPPER(COALESCE(c.CodeEtatCond, '')) = 'R' THEN 1 ELSE 0 END) as late")
            ->selectRaw("COUNT(CASE WHEN UPPER(COALESCE(c.CodeEtatCond, '')) IN ('P', 'A', 'R') THEN 1 END) as total")
            ->groupBy(
                'c.DateEnreg',
                'c.HeureMatiere',
                'c.CodeClasse',
                'cl.LibelleClasse',
                'en.CodeEnseignement',
                'en.CodeMatiere',
                'm.LibelleMatiere',
                'en.code',
                'en.CodeEnseignant2'
            )
            ->orderBy('c.DateEnreg')
            ->orderBy('c.HeureMatiere')
            ->limit($limit)
            ->get();

        $teacherCodes = $rows->flatMap(function ($row) {
            return [$row->teacherCode, $row->secondaryTeacherCode];
        })->filter()->unique()->values()->all();
        $teachers = collect($this->teacherNames($schoolCode, $teacherCodes, 202))->keyBy('code');

        return $rows->map(function ($row) use ($teachers) {
            $teacherNames = collect([$row->teacherCode, $row->secondaryTeacherCode])
                ->filter()
                ->unique()
                ->map(function ($code) use ($teachers) {
                    return $teachers->get($code)['name'] ?? null;
                })
                ->filter()
                ->values()
                ->all();
            $totals = $this->finishTotals([
                'present' => (int) $row->present,
                'absent' => (int) $row->absent,
                'late' => (int) $row->late,
                'total' => (int) $row->total,
            ]);

            return [
                'sessionId' => (string) $row->date.'|'.(string) $row->teachingCode.'|'.(string) $row->time,
                'date' => (string) $row->date,
                'time' => (string) $row->time,
                'classCode' => (string) $row->classCode,
                'className' => (string) $row->className,
                'subjectCode' => (string) $row->subjectCode,
                'subject' => (string) ($row->subject ?? ''),
                'teacher' => implode(', ', $teacherNames),
                'attendance' => $totals,
            ];
        })->all();
    }

    private function statusKey(string $status): ?string
    {
        switch (strtoupper($status)) {
            case 'P':
                return 'present';
            case 'A':
                return 'absent';
            case 'R':
                return 'late';
            default:
                return null;
        }
    }

    private function validateArguments(array $arguments, array $rules): array
    {
        $unexpected = array_diff(array_keys($arguments), array_keys($rules));
        if (!empty($unexpected)) {
            throw ValidationException::withMessages([
                'arguments' => 'Unsupported tool argument.',
            ]);
        }

        return Validator::make($arguments, $rules)->validate();
    }

    private function validateDateRange(string $dateFrom, string $dateTo): void
    {
        $from = Carbon::createFromFormat('Y-m-d', $dateFrom);
        $to = Carbon::createFromFormat('Y-m-d', $dateTo);
        if (!$from || !$to || $from->diffInDays($to) > self::MAX_DATE_RANGE_DAYS) {
            throw ValidationException::withMessages([
                'dateTo' => 'Date range must not exceed one year.',
            ]);
        }
    }
}