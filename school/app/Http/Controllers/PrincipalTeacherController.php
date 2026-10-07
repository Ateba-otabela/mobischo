<?php

namespace App\Http\Controllers;

use App\Models\Classe;
use App\Models\User;
use App\Services\EncadreurClassScope;
use App\Services\PrincipalContextService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PrincipalTeacherController extends Controller
{
    private $principalContext;

    public function __construct(PrincipalContextService $principalContext)
    {
        $this->principalContext = $principalContext;
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $context = $this->principalContext->resolveForAi($user);
        if ($context === null) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }
        if (!$this->isPrincipalRole($context['role'])) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }

        $schoolCode = $context['school_code'];
        $classQuery = Classe::query()->where('CodeEtablissement', $schoolCode);
        if ($context['role'] === 'encadreur') {
            $classCodes = app(EncadreurClassScope::class)
                ->assignedClassCodesForEncadreur($user);
            $classQuery->whereIn('CodeClasse', $classCodes);
        }
        $classes = $classQuery
            ->orderBy('LibelleClasse')
            ->get(['CodeClasse', 'LibelleClasse']);
        $classCodes = $classes->pluck('CodeClasse')->all();

        $assignments = DB::table('enseignements as en')
            ->join('classes as cl', 'cl.CodeClasse', '=', 'en.CodeClasse')
            ->where('cl.CodeEtablissement', $schoolCode)
            ->whereIn('en.CodeClasse', $classCodes)
            ->where(function ($query) use ($schoolCode) {
                $query->where('en.CodeEtablissement', $schoolCode)
                    ->orWhereNull('en.CodeEtablissement')
                    ->orWhere('en.CodeEtablissement', '');
            })
            ->get(['en.CodeClasse', 'en.code', 'en.CodeEnseignant2']);

        $teacherCodesByClass = [];
        $allTeacherCodes = [];
        foreach ($assignments as $assignment) {
            $classCode = (string) $assignment->CodeClasse;
            foreach (['code', 'CodeEnseignant2'] as $field) {
                $teacherCode = trim((string) ($assignment->{$field} ?? ''));
                if ($teacherCode === '') {
                    continue;
                }

                $teacherCodesByClass[$classCode][$teacherCode] = $teacherCode;
                $allTeacherCodes[$teacherCode] = $teacherCode;
            }
        }

        $teachersByCode = User::query()
            ->whereIn('code', array_values($allTeacherCodes))
            ->where('account_type', 'enseignant')
            ->select(['code', 'nom', 'prenom'])
            ->get()
            ->keyBy('code');

        $response = $classes->map(function (Classe $class) use ($teacherCodesByClass, $teachersByCode) {
            $teachers = collect($teacherCodesByClass[$class->CodeClasse] ?? [])
                ->map(function ($teacherCode) use ($teachersByCode) {
                    $teacher = $teachersByCode->get($teacherCode);
                    if (!$teacher) {
                        return null;
                    }

                    return [
                        'code' => (string) $teacher->code,
                        'full_name' => trim((string) $teacher->nom.' '.(string) $teacher->prenom),
                    ];
                })
                ->filter()
                ->sortBy('full_name', SORT_NATURAL | SORT_FLAG_CASE)
                ->values()
                ->all();

            return [
                'CodeClasse' => (string) $class->CodeClasse,
                'LibelleClasse' => (string) $class->LibelleClasse,
                'enseignants' => $teachers,
            ];
        })->values();

        return response()->json($response);
    }

    public function attendance(Request $request, string $teacherCode): JsonResponse
    {
        $user = $request->user();
        if (!$user instanceof User) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $context = $this->principalContext->resolveForAi($user);
        if ($context === null) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }
        if (!$this->isPrincipalRole($context['role'])) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }

        $teacherCode = trim($teacherCode);
        $selectedClassCode = trim((string) $request->query('CodeClasse', ''));
        if ($selectedClassCode === '') {
            return response()->json(['message' => 'CodeClasse is required.'], 422);
        }

        $schoolCode = (string) $context['school_code'];
        $classCodes = $context['role'] === 'encadreur'
            ? app(EncadreurClassScope::class)->assignedClassCodesForEncadreur($user)
            : Classe::query()
                ->where('CodeEtablissement', $schoolCode)
                ->pluck('CodeClasse')
                ->map(fn ($value) => (string) $value)
                ->all();
        if (!in_array($selectedClassCode, $classCodes, true)) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }

        $assignments = DB::table('enseignements as en')
            ->join('classes as cl', 'cl.CodeClasse', '=', 'en.CodeClasse')
            ->where('cl.CodeEtablissement', $schoolCode)
            ->where('en.CodeClasse', $selectedClassCode)
            ->where(function ($query) use ($schoolCode) {
                $query->where('en.CodeEtablissement', $schoolCode)
                    ->orWhereNull('en.CodeEtablissement')
                    ->orWhere('en.CodeEtablissement', '');
            })
            ->where(function ($query) use ($teacherCode) {
                $query->where('en.code', $teacherCode)
                    ->orWhere('en.CodeEnseignant2', $teacherCode);
            })
            ->get([
                'en.CodeEnseignement',
                'en.CodeClasse',
                'en.CodeMatiere',
            ]);

        if ($assignments->isEmpty()) {
            return response()->json(['message' => 'Accès non autorisé.'], 403);
        }

        $attendanceQuery = DB::table('conduites as co')
            ->join('classes as cl', 'cl.CodeClasse', '=', 'co.CodeClasse')
            ->leftJoin('matieres as ma', 'ma.CodeMatiere', '=', 'co.CodeMatiere')
            ->leftJoin('eleves as el', function ($join) {
                $join->on('el.CodeEleve', '=', 'co.CodeEleve')
                    ->on('el.CodeClasse', '=', 'co.CodeClasse');
            })
            ->where('cl.CodeEtablissement', $schoolCode)
            ->where('co.CodeClasse', $selectedClassCode)
            ->whereIn('co.CodeEnseignement', $assignments->pluck('CodeEnseignement'))
            ->where(function ($query) use ($assignments) {
                foreach ($assignments as $assignment) {
                    $query->orWhere(function ($assignmentQuery) use ($assignment) {
                        $assignmentQuery
                            ->where('co.CodeEnseignement', $assignment->CodeEnseignement)
                            ->where('co.CodeClasse', $assignment->CodeClasse);

                        if ($assignment->CodeMatiere === null || $assignment->CodeMatiere === '') {
                            $assignmentQuery->whereNull('co.CodeMatiere');
                        } else {
                            $assignmentQuery->where('co.CodeMatiere', $assignment->CodeMatiere);
                        }
                    });
                }
            })
            ->orderByDesc('co.DateEnreg')
            ->orderBy('co.HeureMatiere')
            ->get([
                'co.CodeEnseignement',
                'co.CodeClasse',
                'co.CodeMatiere',
                'co.CodeAnnee',
                'co.CodeEleve as student_code',
                'el.Nom as student_nom',
                'el.Prenom as student_prenom',
                'co.DateEnreg as attendance_date',
                'co.HeureMatiere as session',
                'co.created_at as recorded_at',
                'co.CodeEtatCond as presence_status',
                'cl.LibelleClasse as class_name',
                'ma.LibelleMatiere as subject_name',
            ])
            ->map(function ($attendance) use ($teacherCode) {
                $attendance->teacher_code = $teacherCode;
                $attendance->student_name = trim(
                    (string) ($attendance->student_nom ?? '').' '.
                    (string) ($attendance->student_prenom ?? '')
                );
                unset($attendance->student_nom, $attendance->student_prenom);

                return $attendance;
            });

        return response()->json($attendanceQuery);
    }

    private function isPrincipalRole(string $role): bool
    {
        return in_array(
            $role,
            ['principal', 'principal_encadreur', 'administrateur', 'admin', 'encadreur'],
            true
        );
    }
}
