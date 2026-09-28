<?php

namespace App\Http\Controllers;

use App\Models\Classe;
use App\Models\User;
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

        $schoolCode = $context['school_code'];
        $classes = Classe::query()
            ->where('CodeEtablissement', $schoolCode)
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
}
