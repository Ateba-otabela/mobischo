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
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use App\Models\HistoriqueInscription;
use App\Models\AbsenceJustification;
use App\Models\InvestigationAlert;
use App\Models\TeacherAttendance;
use App\Services\EncadreurClassScope;
use App\Services\PrincipalContextService;
use App\Services\NotificationDispatchService;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class API extends Controller
{
    private function authorizeStudentNotesRequest(Request $request, string $codeEleve)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['error' => 'Authentication is required.'], 401);
        }
        if (!$user->tokenCan('mobischo:mobile')) {
            return response()->json(['error' => 'This token cannot access student notes.'], 403);
        }

        $student = Eleve::where('CodeEleve', $codeEleve)->first();
        if (!$student) {
            return response()->json(['error' => 'Student not found.'], 404);
        }

        $accountType = strtolower(trim((string) ($user->account_type ?? '')));
        if ($accountType === 'parent') {
            if ((string) $student->code !== (string) $user->code) {
                return response()->json(['error' => 'Student is not linked to this parent.'], 403);
            }
        } else {
            $principalRole = in_array($accountType, [
                'principal',
                'principal_encadreur',
                'administrateur',
            ], true) || (bool) $user->admin;
            $principalScope = (new PrincipalContextService())->resolve($user);
            $schoolCode = trim((string) ($principalScope['school_code'] ?? ''));

            if (!$principalRole || $schoolCode === '') {
                return response()->json(['error' => 'This account cannot access student notes.'], 403);
            }

            $studentBelongsToSchool = Classe::where('CodeClasse', $student->CodeClasse)
                ->where('CodeEtablissement', $schoolCode)
                ->exists();
            if (!$studentBelongsToSchool) {
                return response()->json(['error' => 'Student is outside this school.'], 403);
            }
        }

        return $student;
    }

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

    private function normalizeInstitutionFilterValue(string $value): string
    {
        $lower = strtolower($value);
        $lower = str_replace(['é', 'è', 'ê', 'à', 'ç', 'ô', 'î', 'ï', 'ù'], ['e', 'e', 'e', 'a', 'c', 'o', 'i', 'i', 'u'], $lower);

        $aliases = [
            'private' => 'private',
            'prive' => 'private',
            'privé' => 'private',
            'public' => 'public',
            'universitaire' => 'universitaire',
            'universitaires' => 'universitaire',
            'secondaire' => 'secondaire',
            'secondaires' => 'secondaire',
        ];

        return $aliases[$lower] ?? $lower;
    }

    private function getInstitutionDiscoveryCatalog(): array
    {
        return [
            [
                'id' => 'universite-de-douala',
                'name' => 'Université de Douala',
                'type' => 'public',
                'category' => 'universitaire',
                'location' => 'Douala, Littoral',
                'city' => 'Douala',
                'region' => 'Littoral',
                'description' => 'Université publique de référence au Cameroun, reconnue pour ses filières scientifiques, économiques et technologiques.',
                'programs' => ['Informatique', 'Droit', 'Commerce', 'Génie civil'],
                'languages' => ['Français', 'Anglais'],
                'logo_url' => 'https://www.univ-douala.cm/images/logo_udo.jpg',
                'image_url' => 'https://www.univ-douala.cm/images/logo_udo.jpg',
                'website_url' => 'https://www.univ-douala.cm/',
                'featured' => true,
            ],
            [
                'id' => 'universite-de-yaounde-i',
                'name' => 'Université de Yaoundé I',
                'type' => 'public',
                'category' => 'universitaire',
                'location' => 'Yaoundé, Centre',
                'city' => 'Yaoundé',
                'region' => 'Centre',
                'description' => 'Grande université publique de référence dans la capitale camerounaise, avec un large éventail de formations et de laboratoires.',
                'programs' => ['Sciences', 'Médecine', 'Droit', 'Lettres'],
                'languages' => ['Français', 'Anglais'],
                'logo_url' => 'https://uy1.uninet.cm/wp-content/uploads/2025/03/Logo-Universite-de-Yaounde-1-251px-.png',
                'image_url' => 'https://uy1.uninet.cm/wp-content/uploads/2025/03/Logo-Universite-de-Yaounde-1-251px-.png',
                'website_url' => 'https://uy1.uninet.cm/',
                'featured' => true,
            ],
            [
                'id' => 'institut-universitaire-siantou',
                'name' => 'Institut Universitaire SIANTOU',
                'type' => 'privé',
                'category' => 'universitaire',
                'location' => 'Yaoundé, Centre',
                'city' => 'Yaoundé',
                'region' => 'Centre',
                'description' => 'Institut privé axé sur l’innovation pédagogique et les formations professionnelles de qualité.',
                'programs' => ['Digital', 'Gestion', 'Marketing', 'Administration'],
                'languages' => ['Français', 'Anglais'],
                'logo_url' => 'https://siantou-univ.com/wp-content/uploads/2025/06/logo-IUS-etoile-Copie-Photoroo666m.png',
                'image_url' => 'https://siantou-univ.com/wp-content/uploads/2025/07/WhatsApp-Image-2025-07-17-at-05.32.39.jpeg',
                'website_url' => 'https://siantou-univ.com/',
                'featured' => true,
            ],
            [
                'id' => 'campus-centre-dexcellence-paul-biya',
                'name' => 'Campus du Centre d’Excellence Technologique Paul Biya',
                'type' => 'public',
                'category' => 'universitaire',
                'location' => 'Yaoundé, Centre',
                'city' => 'Yaoundé',
                'region' => 'Centre',
                'description' => 'Campus technologique orienté formation, innovation et mise en œuvre de projets de recherche appliquée.',
                'programs' => ['Technologie', 'Innovation', 'IA', 'Numérique'],
                'languages' => ['Français', 'Anglais'],
                'logo_url' => '',
                'image_url' => '',
                'website_url' => 'https://www.paulbiya-center.cm/',
                'featured' => false,
            ],
            [
                'id' => 'institut-saint-jean',
                'name' => 'Institut Saint Jean',
                'type' => 'privé',
                'category' => 'secondaire',
                'location' => 'Yaoundé, Centre',
                'city' => 'Yaoundé',
                'region' => 'Centre',
                'description' => 'Établissement secondaire privé orienté excellence académique, leadership et développement personnel.',
                'programs' => ['Sciences', 'Lettres', 'Commercial', 'TIC'],
                'languages' => ['Français', 'Anglais'],
                'logo_url' => '',
                'image_url' => '',
                'website_url' => 'https://www.institutsaintjean.cm/',
                'featured' => false,
            ],
            [
                'id' => 'college-bilingue-de-bafoussam',
                'name' => 'Collège Bilingue de Bafoussam',
                'type' => 'privé',
                'category' => 'secondaire',
                'location' => 'Bafoussam, Ouest',
                'city' => 'Bafoussam',
                'region' => 'Ouest',
                'description' => 'Structure secondaire bilingue avec forte vocation d’accompagnement à la réussite scolaire et à l’orientation.',
                'programs' => ['Sciences', 'Lettres', 'Commercial', 'Mécanique'],
                'languages' => ['Français', 'Anglais'],
                'logo_url' => '',
                'image_url' => '',
                'website_url' => 'https://www.bafoussamcollege.cm/',
                'featured' => false,
            ],
        ];
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
            'must_change_password' => $storedTextPassword === '00000000',
        ];

        return response()->json([$userPayload]);
    }

    public function mobileLoginDiagnostic(Request $request)
    {
        $diagnosticKey = (string) config('services.mobile_login_diagnostic_key', '');
        $providedKey = (string) $request->header('X-Mobile-Login-Diagnostic-Key', '');

        if ($diagnosticKey === '' || $providedKey === '' || !hash_equals($diagnosticKey, $providedKey)) {
            return response()->json(['message' => 'Not found.'], 404);
        }

        $actionValid = strtoupper((string) $request->input('action', '')) === 'LOGIN';
        $login = trim((string) $request->input('login', ''));
        $textPassword = trim((string) $request->input('text_password', ''));
        $credentialsPresent = $login !== '' && $textPassword !== '';
        $user = $actionValid && $credentialsPresent
            ? User::where('login', $login)->first()
            : null;

        $storedTextPassword = (string) ($user->text_password ?? '');
        $storedPasswordHash = (string) ($user->password ?? '');
        $legacyPasswordMatch = $user !== null && $storedTextPassword !== ''
            && (hash_equals($storedTextPassword, $textPassword) || strcasecmp($storedTextPassword, $textPassword) === 0);
        $hashPasswordMatch = $user !== null && $storedPasswordHash !== ''
            && Hash::check($textPassword, $storedPasswordHash);

        return response()->json([
            'action_valid' => $actionValid,
            'credentials_present' => $credentialsPresent,
            'user_found' => $user !== null,
            'legacy_password_match' => $legacyPasswordMatch,
            'hash_password_match' => $hashPasswordMatch,
            'mobile_eligible' => $user !== null && $this->isMobileEligibleUser($user),
            'ai_eligible' => $user !== null && (new \App\Services\PrincipalContextService())->canUseAi($user),
        ]);
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
            $parent = $request->user();
            if (!$parent instanceof User || strtolower(trim((string) $parent->account_type)) !== 'parent') {
                return response()->json(['error' => 'Parent non autorisé.'], 403);
            }

            $parentCode = trim((string) $parent->code);
            $schoolCode = trim((string) ($parent->CodeEtablissement ?? ''));
            $request->validate([
                'CodeEleve' => 'required|string|max:255',
                'date_absence' => 'required|date_format:Y-m-d',
                'reason' => 'required|in:Maladie,Rendez-vous médical,Raisons familiales,Urgence familiale,Autre',
                'justification' => 'required|string|min:10|max:500',
                'document' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240',
            ]);
            $studentCode = trim((string) $request->input('CodeEleve', ''));
            $reason = trim((string) $request->input('reason'));
            $absenceDate = trim((string) $request->input('date_absence'));
            $justificationText = trim((string) $request->input('justification', ''));

            $student = Eleve::query()
                ->where('CodeEleve', $studentCode)
                ->where('code', $parentCode)
                ->first();
            if (!$student) {
                return response()->json(['error' => 'Élève non autorisé.'], 403);
            }

            $classCode = trim((string) $student->CodeClasse);
            $class = Classe::query()
                ->where('CodeClasse', $classCode)
                ->when($schoolCode !== '', fn ($query) => $query->where('CodeEtablissement', $schoolCode))
                ->first();
            if (!$class) {
                return response()->json(['error' => 'La classe de l’élève ne correspond pas à votre établissement.'], 403);
            }
            $schoolCode = trim((string) $class->CodeEtablissement);

            $documentPath = null;
            try {
                $submission = DB::transaction(function () use (
                    $request,
                    $parent,
                    $parentCode,
                    $schoolCode,
                    $studentCode,
                    $absenceDate,
                    $reason,
                    $justificationText,
                    $class,
                    &$documentPath
                ) {
                    $lockedStudent = Eleve::query()
                        ->where('CodeEleve', $studentCode)
                        ->where('code', $parentCode)
                        ->lockForUpdate()
                        ->first();
                    if (!$lockedStudent) {
                        return ['unauthorized_student' => true];
                    }

                    $existing = AbsenceJustification::query()
                        ->where('CodeEleve', $studentCode)
                        ->where(function ($query) use ($absenceDate) {
                            $query->where('absence_date', $absenceDate)
                                ->orWhere('date_absence', $absenceDate);
                        })
                        ->where(function ($query) {
                            $query->where('status', 'pending')
                                ->orWhere('statut', 'En attente');
                        })
                        ->lockForUpdate()
                        ->first();
                    if ($existing) {
                        return ['duplicate' => $existing];
                    }

                    if ($request->hasFile('document')) {
                        $storedDocumentPath = $request->file('document')->store('absence-justifications', 'public');
                        if ($storedDocumentPath === false) {
                            throw new \RuntimeException('Document storage failed.');
                        }
                        $documentPath = $storedDocumentPath;
                    }

                    $parentName = trim((string) ($parent->nom ?? '').' '.(string) ($parent->prenom ?? ''));
                    $record = AbsenceJustification::create([
                        'CodeEleve' => $studentCode,
                        'CodeEtablissement' => $schoolCode !== '' ? $schoolCode : null,
                        'absence_date' => $absenceDate,
                        'date_absence' => $absenceDate,
                        'reason' => $reason,
                        'motif' => $reason,
                        'justification' => $justificationText,
                        'status' => 'pending',
                        'statut' => 'En attente',
                        'parent_code' => $parentCode,
                        'parent_name' => $parentName,
                        'document_path' => $documentPath,
                    ]);

                    return ['record' => $record];
                });
            } catch (\Throwable $exception) {
                if (is_string($documentPath) && $documentPath !== '') {
                    Storage::disk('public')->delete($documentPath);
                }
                Log::warning('Parent absence justification could not be stored.', [
                    'parent_code' => $parentCode,
                    'student_code' => $studentCode,
                    'exception_type' => get_class($exception),
                ]);

                return response()->json(['error' => 'La justification n’a pas pu être enregistrée.'], 500);
            }

            if (isset($submission['unauthorized_student'])) {
                return response()->json(['error' => 'Élève non autorisé.'], 403);
            }

            if (isset($submission['duplicate'])) {
                return response()->json([
                    'error' => 'Une justification est déjà en attente pour cet élève à cette date.',
                    'id' => $submission['duplicate']->id,
                ], 409);
            }

            $justification = $submission['record'];
            $studentName = trim((string) ($student->Nom ?? '').' '.(string) ($student->Prenom ?? ''));
            $dispatcher = app(NotificationDispatchService::class);
            try {
                $dispatcher->dispatchAbsenceJustificationNotification(
                    $studentCode,
                    $parentCode,
                    ['school_code' => $schoolCode]
                );
            } catch (\Throwable $exception) {
                Log::warning('Teacher notification for parent absence justification failed.', [
                    'justification_id' => $justification->id,
                    'student_code' => $studentCode,
                    'exception_type' => get_class($exception),
                ]);
            }

            try {
                $dispatcher->dispatchAbsenceJustificationToEncadreurs(
                    (int) $justification->id,
                    $studentCode,
                    $studentName,
                    (string) $class->CodeClasse,
                    $absenceDate,
                    $schoolCode
                );
            } catch (\Throwable $exception) {
                Log::warning('Encadreur notification for parent absence justification failed.', [
                    'justification_id' => $justification->id,
                    'student_code' => $studentCode,
                    'class_code' => $class->CodeClasse,
                    'exception_type' => get_class($exception),
                ]);
            }

            return response()->json([
                'status' => 'success',
                'id' => $justification->id,
                'statut' => 'En attente',
            ], 200);
        }

        if ($action == 'GET_INSTITUTIONS') {
            $search = trim((string) strtolower((string) $request->input('search', '')));
            $type = $this->normalizeInstitutionFilterValue((string) $request->input('type', ''));
            $category = $this->normalizeInstitutionFilterValue((string) $request->input('category', ''));
            $location = trim((string) strtolower((string) $request->input('location', '')));
            $page = max(1, (int) $request->input('page', 1));
            $perPage = max(1, min(50, (int) $request->input('per_page', 12)));

            $institutions = $this->getInstitutionDiscoveryCatalog();

            $filtered = array_values(array_filter($institutions, function ($institution) use ($search, $type, $category, $location) {
                $name = strtolower((string) ($institution['name'] ?? ''));
                $description = strtolower((string) ($institution['description'] ?? ''));
                $city = strtolower((string) ($institution['city'] ?? ''));
                $region = strtolower((string) ($institution['region'] ?? ''));
                $locationText = strtolower((string) ($institution['location'] ?? ''));
                $institutionType = $this->normalizeInstitutionFilterValue((string) ($institution['type'] ?? ''));
                $institutionCategory = $this->normalizeInstitutionFilterValue((string) ($institution['category'] ?? ''));

                if ($search !== '' && strpos($name, $search) === false && strpos($description, $search) === false && strpos($city, $search) === false && strpos($region, $search) === false) {
                    return false;
                }

                if ($type !== '' && $institutionType !== $type) {
                    return false;
                }

                if ($category !== '' && $institutionCategory !== $category) {
                    return false;
                }

                if ($location !== '' && strpos($locationText, $location) === false && strpos($city, $location) === false && strpos($region, $location) === false) {
                    return false;
                }

                return true;
            }));

            $total = count($filtered);
            $totalPages = $total > 0 ? (int) ceil($total / $perPage) : 1;
            $offset = ($page - 1) * $perPage;
            $paginated = array_slice($filtered, $offset, $perPage);

            return response()->json([
                'data' => $paginated,
                'total' => $total,
                'page' => $page,
                'per_page' => $perPage,
                'total_pages' => $totalPages,
            ]);
        }

        if ($action == 'GET_PARENT_ABSENCE_JUSTIFICATIONS') {
            try {
                $parent = $request->user();
                if (!$parent instanceof User || strtolower(trim((string) $parent->account_type)) !== 'parent') {
                    return response()->json(['error' => 'Parent non autorisé.'], 403);
                }

                $parentCode = (string) $parent->code;
                $schoolCode = trim((string) ($parent->CodeEtablissement ?? ''));
                $studentCodes = DB::table('eleves as e')
                    ->join('classes as cl', 'cl.CodeClasse', '=', 'e.CodeClasse')
                    ->where('e.code', $parentCode)
                    ->when($schoolCode !== '', fn ($query) => $query->where('cl.CodeEtablissement', $schoolCode))
                    ->pluck('e.CodeEleve');

                $query = AbsenceJustification::query()
                    ->where('parent_code', $parentCode)
                    ->where(function ($builder) use ($schoolCode) {
                        if ($schoolCode !== '') {
                            $builder->where('CodeEtablissement', $schoolCode)
                                ->orWhereNull('CodeEtablissement');
                        }
                    })
                    ->whereIn('CodeEleve', $studentCodes)
                    ->orderByRaw('COALESCE(date_absence, absence_date) DESC')
                    ->orderBy('created_at', 'DESC');

                return response()->json($query->get());
            } catch (\Throwable $exception) {
                // TEMPORARY DIAGNOSTIC CODE: remove after identifying the production failure.
                $safeMessage = $exception->getMessage();
                $sql = null;
                $queryException = $exception;
                while ($queryException !== null) {
                    if ($queryException instanceof \Illuminate\Database\QueryException) {
                        $sql = $queryException->getSql();
                        foreach ($queryException->getBindings() as $binding) {
                            if (is_scalar($binding) && (string) $binding !== '') {
                                $safeMessage = str_replace((string) $binding, '[REDACTED]', $safeMessage);
                            }
                        }
                        break;
                    }
                    $queryException = $queryException->getPrevious();
                }

                $safeMessage = preg_replace('/Bearer\s+\S+/i', 'Bearer [REDACTED]', $safeMessage) ?? $safeMessage;
                $safeMessage = preg_replace('/-----BEGIN [^-]+-----.*?-----END [^-]+-----/s', '[REDACTED]', $safeMessage) ?? $safeMessage;
                $httpMessage = preg_replace('/\s*\(SQL:.*$/s', '', $safeMessage) ?? $safeMessage;
                $httpMessage = preg_replace('/\b(password|token|api[_-]?key|authorization)\b\s*[=:]\s*[^\s,;]+/i', '$1=[REDACTED]', $httpMessage) ?? $httpMessage;

                Log::error('Temporary parent absence history diagnostic.', [
                    'exception_class' => get_class($exception),
                    'exception_message' => $safeMessage,
                    'file' => $exception->getFile(),
                    'line' => $exception->getLine(),
                    'sql' => $sql,
                    'trace' => $exception->getTraceAsString(),
                ]);

                return response()->json([
                    'status' => 'error',
                    'error_type' => get_class($exception),
                    'message' => $httpMessage,
                    'file' => $exception->getFile(),
                    'line' => $exception->getLine(),
                ], 500);
            }
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

        if ($action == 'GET_STUDENT_YEAR_MARKS') {
            $codeEleve = trim((string) $request->input('codeEleve', ''));
            $codeAnnee = trim((string) $request->input('codeAnnee', ''));
            if ($codeEleve === '' || $codeAnnee === '') {
                return response()->json(['error' => 'Student and school year are required.'], 422);
            }

            return Note::where('CodeEleve', '=', $codeEleve)
                ->where('CodeAnnee', '=', $codeAnnee)
                ->get();
        }

        if ($action === 'GET_STUDENT_SEQUENCE_AVAILABILITY') {
            $codeEleve = trim((string) $request->input('codeEleve', ''));
            if ($codeEleve === '') {
                return response()->json(['error' => 'Student is required.'], 422);
            }

            $student = $this->authorizeStudentNotesRequest($request, $codeEleve);
            if (!$student instanceof Eleve) {
                return $student;
            }

            $availableSequenceCodes = DB::table('notes')
                ->where('CodeEleve', $codeEleve)
                ->whereNotNull('valeur')
                ->where('valeur', '<>', '')
                ->distinct()
                ->pluck('CodeEvaluation')
                ->map(function ($code) {
                    return (string) $code;
                })
                ->flip();

            return SequenceEvaluation::query()
                ->get()
                ->map(function (SequenceEvaluation $sequence) use ($availableSequenceCodes) {
                    $sequence->setAttribute(
                        'hasMarks',
                        $availableSequenceCodes->has((string) $sequence->CodeEvaluation)
                    );

                    return $sequence;
                })
                ->values();
        }

        if ($action === 'GET_STUDENT_SEQUENCE_MARKS') {
            $codeEleve = trim((string) $request->input('codeEleve', ''));
            $codeEvaluation = trim((string) $request->input('codeEvaluation', ''));
            if ($codeEleve === '' || $codeEvaluation === '') {
                return response()->json(['error' => 'Student and sequence are required.'], 422);
            }

            $student = $this->authorizeStudentNotesRequest($request, $codeEleve);
            if (!$student instanceof Eleve) {
                return $student;
            }

            if (!SequenceEvaluation::where('CodeEvaluation', $codeEvaluation)->exists()) {
                return response()->json(['error' => 'Sequence not found.'], 404);
            }

            return DB::table('notes as n')
                ->leftJoin('enseignements as e', 'e.CodeEnseignement', '=', 'n.CodeEnseignement')
                ->leftJoin('matieres as m', 'm.CodeMatiere', '=', 'e.CodeMatiere')
                ->where('n.CodeEleve', $codeEleve)
                ->where('n.CodeEvaluation', $codeEvaluation)
                ->orderBy('m.LibelleMatiere')
                ->orderBy('n.CodeEnseignement')
                ->orderBy('n.id')
                ->get([
                    'n.id',
                    'n.CodeEleve',
                    'n.CodeEnseignement',
                    'n.CodeEvaluation',
                    'e.CodeMatiere',
                    'm.LibelleMatiere',
                    'n.CodeAppreciation',
                    'n.valeur',
                    'n.coef',
                    'n.Total',
                    'n.Dateeng',
                ]);
        }

        if ($action == 'GET_COURSE_YEAR_MARKS') {
            $codeEnseignement = trim((string) $request->input('codeEnseignement', ''));
            $codeAnnee = trim((string) $request->input('codeAnnee', ''));
            if ($codeEnseignement === '' || $codeAnnee === '') {
                return response()->json(['error' => 'Course and school year are required.'], 422);
            }

            return Note::where('CodeEnseignement', '=', $codeEnseignement)
                ->where('CodeAnnee', '=', $codeAnnee)
                ->get();
        }

        #courses
        if($action == 'GET_ALL_COURSES'){
            $courses = Enseignement::all();
            return $courses;
        }

        if($action == 'GET_TEACHER_COURSES'){
            $teacher_code = trim((string) $request->input('teacher_code', ''));
            $teacher = User::where('code', '=', $teacher_code)
                ->where('account_type', '=', 'enseignant')
                ->first();
            $courses = Enseignement::where(function ($query) use ($teacher_code, $teacher) {
                $query->where('code', '=', $teacher_code)
                    ->orWhere('CodeEnseignant2', '=', $teacher_code);

                if ($teacher && $teacher->CodeEtablissement) {
                    $schoolCode = (string) $teacher->CodeEtablissement;
                    $query->orWhere(function ($assignedClassCourses) use ($teacher_code, $schoolCode) {
                        $assignedClassCourses
                            ->where('CodeEtablissement', '=', $schoolCode)
                            ->whereIn('CodeClasse', function ($assignedClasses) use ($teacher_code, $schoolCode) {
                                $assignedClasses
                                    ->select('ec.CodeClasse')
                                    ->from('encadreur_classes as ec')
                                    ->join('classes as c', 'c.CodeClasse', '=', 'ec.CodeClasse')
                                    ->where('ec.code', '=', $teacher_code)
                                    ->where('ec.CodeEtablissement', '=', $schoolCode)
                                    ->where('c.CodeEtablissement', '=', $schoolCode);
                            });
                    });
                }
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
            $teacherAttendanceBySession = collect();
            if ($this->teacherAttendanceStorageIsReady()) {
                $teacherAttendanceBySession = TeacherAttendance::query()
                    ->where('CodeEtablissement', $schoolCode)
                    ->whereIn('CodeClasse', $classCodes)
                    ->get()
                    ->keyBy('session_key');
            } else {
                Log::warning(
                    'Teacher attendance storage is unavailable; principal attendance report will omit teacher presence.'
                );
            }

            $sessions = $attendanceRecords
                ->groupBy(function ($record) {
                    return $record->DateEnreg . '|' . $record->CodeEnseignement . '|' . $record->HeureMatiere;
                })
                ->map(function ($sessionRecords) use (
                    $schoolCode,
                    $teacherAttendanceBySession
                ) {
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
                    $teacherCode = (string) ($teacherSummary['code'] ?? '');
                    $codeMatiere = (string) ($first->CodeMatiere ?? ($course->CodeMatiere ?? ''));
                    $sessionKey = TeacherAttendance::makeSessionKey(
                        $schoolCode,
                        $teacherCode,
                        (string) ($first->CodeEnseignement ?? ''),
                        (string) ($first->CodeClasse ?? ''),
                        $codeMatiere,
                        (string) ($first->DateEnreg ?? ''),
                        $first->HeureMatiere
                    );
                    $teacherAttendance = $teacherAttendanceBySession->get($sessionKey);
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
                        'CodeMatiere' => $codeMatiere,
                        'CodeEnseignement' => (string) ($first->CodeEnseignement ?? ''),
                        'class' => (string) ($class->LibelleClasse ?? ''),
                        'subject' => (string) ($subject->LibelleMatiere ?? ''),
                        'teacher' => $teacherSummary['full_name'] ?? '',
                        'teacher_code' => $teacherCode,
                        'teacher_presence_status' => $teacherAttendance?->presence_status,
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
            $request->validate([
                'document' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240',
            ]);

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

            $documentPath = null;
            if ($request->hasFile('document')) {
                $documentPath = $request->file('document')->store('convocations', 'public');
                if ($documentPath === false) {
                    return response()->json(['error' => 'Le document n’a pas pu être enregistré.'], 500);
                }
            }

            try {
                DB::transaction(function () use (
                    $code,
                    $codeEnseignement,
                    $enseignement,
                    $motif,
                    $description,
                    $dateConvocation,
                    $students,
                    $documentPath
                ) {
                    foreach ($students as $student) {
                        Convocation::create([
                            'code' => $code,
                            'CodeEleve' => $student->CodeEleve,
                            'motif' => $motif,
                            'description' => $description,
                            'CodeEnseignement' => $codeEnseignement,
                            'CodeMatiere' => $enseignement->CodeMatiere,
                            'dateConvocation' => $dateConvocation,
                            'document_path' => $documentPath,
                        ]);
                    }
                });
            } catch (\Throwable $exception) {
                if ($documentPath !== null) {
                    Storage::disk('public')->delete($documentPath);
                }

                throw $exception;
            }

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
                $payload['document_url'] = $convocation->document_path
                    ? url(Storage::disk('public')->url($convocation->document_path))
                    : null;

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
                $payload['document_url'] = $convocation->document_path
                    ? url(Storage::disk('public')->url($convocation->document_path))
                    : null;

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

        if ($action == 'GET_DASHBOARD_JUSTIFICATIONS') {
            $user = $request->user();
            if (!$user instanceof User) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $accountType = strtolower(trim((string) ($user->account_type ?? '')));
            if (!in_array($accountType, ['principal', 'principal_encadreur', 'encadreur'], true)) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
            if ($schoolCode === '') {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $request->validate([
                'page' => 'sometimes|integer|min:1',
                'per_page' => 'sometimes|integer|min:1|max:50',
            ]);
            $assignedClassCodes = null;
            if ($accountType === 'encadreur') {
                $assignedClassCodes = (new EncadreurClassScope())
                    ->assignedClassCodesForEncadreur($user);
                if ($assignedClassCodes === []) {
                    return response()->json([
                        'data' => [],
                        'current_page' => 1,
                        'last_page' => 1,
                        'per_page' => (int) $request->input('per_page', 3),
                        'total' => 0,
                    ]);
                }
            }

            $justifications = AbsenceJustification::query()
                ->join('eleves as justification_student', 'justification_student.CodeEleve', '=', 'absence_justifications.CodeEleve')
                ->join('classes as justification_class', function ($join) {
                    $join->on('justification_class.CodeClasse', '=', 'justification_student.CodeClasse')
                        ->on('justification_class.CodeEtablissement', '=', 'absence_justifications.CodeEtablissement');
                })
                ->where('absence_justifications.CodeEtablissement', $schoolCode)
                ->when(
                    $assignedClassCodes !== null,
                    fn ($query) => $query->whereIn('justification_student.CodeClasse', $assignedClassCodes)
                )
                ->select([
                    'absence_justifications.id',
                    'absence_justifications.CodeEleve',
                    'absence_justifications.CodeEtablissement',
                    'justification_student.CodeClasse',
                    'justification_student.Nom as student_last_name',
                    'justification_student.Prenom as student_first_name',
                    'justification_class.LibelleClasse as class_name',
                    'absence_justifications.justification',
                    'absence_justifications.created_at',
                    DB::raw("COALESCE(NULLIF(absence_justifications.motif, ''), NULLIF(absence_justifications.reason, ''), '') as reason"),
                    DB::raw('COALESCE(absence_justifications.date_absence, absence_justifications.absence_date) as absence_date'),
                    DB::raw("COALESCE(NULLIF(absence_justifications.statut, ''), NULLIF(absence_justifications.status, ''), '') as status"),
                ])
                ->orderByDesc('absence_justifications.created_at')
                ->orderByDesc('absence_justifications.id')
                ->paginate((int) $request->input('per_page', 3));

            $justifications->getCollection()->transform(function ($justification) {
                $justification->student_name = trim(
                    (string) ($justification->student_last_name ?? '').' '.
                    (string) ($justification->student_first_name ?? '')
                );
                unset($justification->student_last_name, $justification->student_first_name);

                return $justification;
            });

            return response()->json($justifications);
        }

        if ($action == 'GET_DASHBOARD_JUSTIFICATION_DETAIL') {
            $user = $request->user();
            if (!$user instanceof User) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $accountType = strtolower(trim((string) ($user->account_type ?? '')));
            if (!in_array($accountType, ['principal', 'principal_encadreur', 'encadreur'], true)) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $request->validate(['id' => 'required|integer|min:1']);
            $justification = $this->dashboardJustificationDetailForUser(
                $user,
                (int) $request->input('id')
            );
            if ($justification === null) {
                return response()->json(['error' => 'Justification not found'], 404);
            }

            return response()->json(['justification' => $justification]);
        }

        if ($action == 'VALIDATE_DASHBOARD_JUSTIFICATION') {
            $user = $request->user();
            if (!$user instanceof User) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $accountType = strtolower(trim((string) ($user->account_type ?? '')));
            if (!in_array($accountType, ['principal', 'principal_encadreur', 'encadreur'], true)) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $request->validate(['id' => 'required|integer|min:1']);
            $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
            if ($schoolCode === '') {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $result = DB::transaction(function () use ($user, $accountType, $schoolCode, $request) {
                $justification = AbsenceJustification::query()
                    ->whereKey((int) $request->input('id'))
                    ->where('CodeEtablissement', $schoolCode)
                    ->lockForUpdate()
                    ->first();
                if (!$justification) {
                    return ['not_found' => true];
                }

                $classCode = DB::table('eleves as justification_student')
                    ->join('classes as justification_class', function ($join) {
                        $join->on(
                            'justification_class.CodeClasse',
                            '=',
                            'justification_student.CodeClasse'
                        );
                    })
                    ->where('justification_student.CodeEleve', $justification->CodeEleve)
                    ->where('justification_class.CodeEtablissement', $schoolCode)
                    ->value('justification_student.CodeClasse');
                if ($classCode === null) {
                    return ['not_found' => true];
                }

                if ($accountType === 'encadreur'
                    && !(new EncadreurClassScope())->ensureClassAccessForEncadreur(
                        $user,
                        (string) $classCode
                    )) {
                    return ['forbidden' => true];
                }

                $workflowStatus = strtolower(trim((string) ($justification->status ?? '')));
                $legacyStatus = strtolower(trim((string) ($justification->statut ?? '')));
                $pendingStatuses = ['pending', 'en attente'];
                $isPending = in_array($workflowStatus, $pendingStatuses, true)
                    || in_array($legacyStatus, $pendingStatuses, true);
                $hasUnsupportedWorkflowStatus = !in_array(
                    $workflowStatus,
                    array_merge([''], $pendingStatuses),
                    true
                ) || !in_array(
                    $legacyStatus,
                    array_merge([''], $pendingStatuses),
                    true
                );
                if (!$isPending || $hasUnsupportedWorkflowStatus) {
                    return ['already_processed' => true];
                }

                DB::table('absence_justifications')
                    ->where('id', $justification->id)
                    ->update([
                        'status' => 'approved',
                        'statut' => 'validée',
                        'reviewed_by' => (string) $user->code,
                        'reviewed_at' => now(),
                        'updated_at' => now(),
                    ]);

                return ['id' => (int) $justification->id];
            });

            if (isset($result['not_found'])) {
                return response()->json(['error' => 'Justification not found'], 404);
            }
            if (isset($result['forbidden'])) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }
            if (isset($result['already_processed'])) {
                return response()->json([
                    'error' => 'Cette justification a déjà été traitée.',
                ], 409);
            }

            $justification = $this->dashboardJustificationDetailForUser(
                $user,
                $result['id']
            );
            if ($justification === null) {
                return response()->json(['error' => 'Justification not found'], 404);
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Absence validée.',
                'justification' => $justification,
            ]);
        }

        if ($action == 'GET_DASHBOARD_ALERTS') {
            $user = $request->user();
            if (!$user instanceof User) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $accountType = strtolower(trim((string) ($user->account_type ?? '')));
            if (!in_array($accountType, ['principal', 'principal_encadreur', 'encadreur'], true)) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
            if ($schoolCode === '') {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $assignedClassCodes = null;
            if ($accountType === 'encadreur') {
                $assignedClassCodes = (new EncadreurClassScope())
                    ->assignedClassCodesForEncadreur($user);
                if ($assignedClassCodes === []) {
                    return response()->json([]);
                }
            }

            $requestedClass = trim((string) $request->input('CodeClasse', ''));
            if ($requestedClass !== '') {
                $classIsInSchool = Classe::query()
                    ->where('CodeClasse', $requestedClass)
                    ->where('CodeEtablissement', $schoolCode)
                    ->exists();
                if (!$classIsInSchool
                    || ($assignedClassCodes !== null
                        && !in_array($requestedClass, $assignedClassCodes, true))) {
                    return response()->json(['error' => 'Unauthorized'], 403);
                }
            }

            $attendanceEvents = Conduite::query()
                ->join('classes as event_class', 'event_class.CodeClasse', '=', 'conduites.CodeClasse')
                ->join('eleves as event_student', function ($join) {
                    $join->on('event_student.CodeEleve', '=', 'conduites.CodeEleve')
                        ->on('event_student.CodeClasse', '=', 'conduites.CodeClasse');
                })
                ->where('event_class.CodeEtablissement', $schoolCode)
                ->whereIn(DB::raw("UPPER(COALESCE(conduites.CodeEtatCond, ''))"), ['A', 'R'])
                ->when($requestedClass !== '', fn ($query) => $query->where('conduites.CodeClasse', $requestedClass))
                ->when(
                    $assignedClassCodes !== null,
                    fn ($query) => $query->whereIn('conduites.CodeClasse', $assignedClassCodes)
                )
                ->select([
                    'conduites.id',
                    'conduites.CodeEleve',
                    'conduites.CodeClasse',
                    'conduites.CodeEnseignement',
                    'conduites.CodeMatiere',
                    'conduites.DateEnreg',
                    'conduites.CodeEtatCond',
                    'conduites.created_at',
                    'event_class.LibelleClasse as class_name',
                    'event_student.Nom as student_last_name',
                    'event_student.Prenom as student_first_name',
                ])
                ->orderByDesc('conduites.DateEnreg')
                ->orderByDesc('conduites.created_at')
                ->limit(50)
                ->get()
                ->map(function ($event) use ($schoolCode) {
                    $status = strtoupper((string) $event->CodeEtatCond);
                    $studentName = trim((string) ($event->student_last_name ?? '').' '.(string) ($event->student_first_name ?? ''));

                    return [
                        'event_type' => 'attendance',
                        'id' => (int) $event->id,
                        'CodeEtablissement' => $schoolCode,
                        'CodeEleve' => (string) $event->CodeEleve,
                        'CodeClasse' => (string) $event->CodeClasse,
                        'CodeEnseignement' => (string) ($event->CodeEnseignement ?? ''),
                        'CodeMatiere' => (string) ($event->CodeMatiere ?? ''),
                        'date_absence' => (string) $event->DateEnreg,
                        'parent_status' => '',
                        'teacher_status' => $status,
                        'status' => 'attendance',
                        'notes' => $status === 'A' ? 'Élève absent' : 'Élève en retard',
                        'student_name' => $studentName,
                        'student_code' => (string) $event->CodeEleve,
                        'class_name' => (string) ($event->class_name ?? ''),
                        'created_at' => $event->created_at,
                    ];
                });

            $investigationQuery = InvestigationAlert::query()
                ->where('CodeEtablissement', $schoolCode)
                ->whereExists(function ($query) {
                    $query->select(DB::raw(1))
                        ->from('classes as investigation_class')
                        ->whereColumn('investigation_class.CodeClasse', 'investigation_alerts.CodeClasse')
                        ->whereColumn('investigation_class.CodeEtablissement', 'investigation_alerts.CodeEtablissement')
                        ->whereExists(function ($studentQuery) {
                            $studentQuery->select(DB::raw(1))
                                ->from('eleves as investigation_student')
                                ->whereColumn('investigation_student.CodeEleve', 'investigation_alerts.CodeEleve')
                                ->whereColumn('investigation_student.CodeClasse', 'investigation_alerts.CodeClasse');
                        });
                })
                ->when($requestedClass !== '', fn ($query) => $query->where('CodeClasse', $requestedClass))
                ->when(
                    $assignedClassCodes !== null,
                    fn ($query) => $query->whereIn('CodeClasse', $assignedClassCodes)
                )
                ->orderByDesc('date_absence')
                ->orderByDesc('created_at')
                ->limit(50);
            $investigations = $investigationQuery->get();
            $studentsByCode = Eleve::query()
                ->whereIn('CodeEleve', $investigations->pluck('CodeEleve')->unique())
                ->get()
                ->keyBy('CodeEleve');
            $classNamesByCode = Classe::query()
                ->whereIn('CodeClasse', $investigations->pluck('CodeClasse')->unique())
                ->where('CodeEtablissement', $schoolCode)
                ->pluck('LibelleClasse', 'CodeClasse');
            $investigationEvents = $investigations->map(function ($alert) use ($studentsByCode, $classNamesByCode) {
                $student = $studentsByCode->get($alert->CodeEleve);
                $payload = $alert->toArray();
                $payload['event_type'] = 'investigation';
                $payload['student_name'] = $student
                    ? trim((string) ($student->Nom ?? '').' '.(string) ($student->Prenom ?? ''))
                    : '';
                $payload['student_code'] = (string) ($alert->CodeEleve ?? '');
                $payload['class_name'] = (string) ($classNamesByCode->get($alert->CodeClasse) ?? '');

                return $payload;
            });

            $events = $attendanceEvents
                ->concat($investigationEvents)
                ->sortByDesc(function ($event) {
                    return (string) ($event['date_absence'] ?? '')
                        .' '.(string) ($event['created_at'] ?? '');
                })
                ->take(50)
                ->values();

            return response()->json($events);
        }

        if ($action == 'UPDATE_DASHBOARD_ALERT') {
            $user = $request->user();
            if (!$user instanceof User) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $accountType = strtolower(trim((string) ($user->account_type ?? '')));
            if (!in_array($accountType, ['principal', 'principal_encadreur', 'encadreur'], true)) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $request->validate([
                'id' => 'required|integer|min:1',
                'status' => 'required|in:validated,rejected',
                'notes' => 'nullable|string|max:2000',
            ]);
            $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
            if ($schoolCode === '') {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            $result = DB::transaction(function () use (
                $user,
                $accountType,
                $schoolCode,
                $request
            ) {
                $alert = InvestigationAlert::query()
                    ->whereKey($request->input('id'))
                    ->where('CodeEtablissement', $schoolCode)
                    ->lockForUpdate()
                    ->first();
                if (!$alert) {
                    return ['not_found' => true];
                }

                if (strtolower(trim((string) $alert->status)) !== 'pending') {
                    return ['already_resolved' => true];
                }

                if ($accountType === 'encadreur'
                    && !(new EncadreurClassScope())->ensureClassAccessForEncadreur(
                        $user,
                        (string) $alert->CodeClasse
                    )) {
                    return ['forbidden' => true];
                }

                if ($request->input('status') === 'validated') {
                    if (!$this->teacherAttendanceStorageIsReady()) {
                        return ['teacher_attendance_storage_unavailable' => true];
                    }

                    $class = Classe::query()
                        ->where('CodeClasse', $alert->CodeClasse)
                        ->where('CodeEtablissement', $alert->CodeEtablissement)
                        ->first();
                    if (!$class) {
                        return ['class_not_found' => true];
                    }

                    $course = Enseignement::query()
                        ->where('CodeEnseignement', $alert->CodeEnseignement)
                        ->where('CodeClasse', $alert->CodeClasse)
                        ->when(
                            $alert->CodeMatiere === null,
                            fn ($query) => $query->whereNull('CodeMatiere'),
                            fn ($query) => $query->where('CodeMatiere', $alert->CodeMatiere)
                        )
                        ->where(function ($query) use ($alert) {
                            $query->where('CodeEtablissement', $alert->CodeEtablissement)
                                ->orWhereNull('CodeEtablissement')
                                ->orWhere('CodeEtablissement', '');
                        })
                        ->first();
                    if (!$course) {
                        return ['course_not_found' => true];
                    }

                    $teacherSummary = $this->resolveTeacherSummaryForCourse($course);
                    $teacherCode = trim((string) ($teacherSummary['code'] ?? ''));
                    $teacher = $teacherCode === ''
                        ? null
                        : User::query()
                            ->where('code', $teacherCode)
                            ->where('account_type', 'enseignant')
                            ->first();
                    if (!$teacher) {
                        return ['teacher_not_found' => true];
                    }

                    $attendance = Conduite::query()
                        ->where('CodeEleve', $alert->CodeEleve)
                        ->where('CodeClasse', $alert->CodeClasse)
                        ->where('CodeEnseignement', $alert->CodeEnseignement)
                        ->where('DateEnreg', $alert->date_absence)
                        ->whereExists(function ($query) use ($alert) {
                            $query->select(DB::raw(1))
                                ->from('classes as attendance_class')
                                ->whereColumn(
                                    'attendance_class.CodeClasse',
                                    'conduites.CodeClasse'
                                )
                                ->where(
                                    'attendance_class.CodeEtablissement',
                                    $alert->CodeEtablissement
                                );
                        })
                        ->when(
                            $alert->CodeMatiere === null,
                            fn ($query) => $query->whereNull('CodeMatiere'),
                            fn ($query) => $query->where(
                                'CodeMatiere',
                                $alert->CodeMatiere
                            )
                        )
                        ->lockForUpdate()
                        ->first();

                    if (!$attendance) {
                        return ['attendance_not_found' => true];
                    }

                    $sessionKey = TeacherAttendance::makeSessionKey(
                        (string) $alert->CodeEtablissement,
                        (string) $teacher->code,
                        (string) $alert->CodeEnseignement,
                        (string) $alert->CodeClasse,
                        (string) $alert->CodeMatiere,
                        (string) $alert->date_absence,
                        $attendance->HeureMatiere
                    );
                    TeacherAttendance::updateOrCreate(
                        ['session_key' => $sessionKey],
                        [
                            'CodeEtablissement' => (string) $alert->CodeEtablissement,
                            'CodeEnseignant' => (string) $teacher->code,
                            'CodeEnseignement' => (string) $alert->CodeEnseignement,
                            'CodeClasse' => (string) $alert->CodeClasse,
                            'CodeMatiere' => $alert->CodeMatiere,
                            'attendance_date' => $alert->date_absence,
                            'session_time' => $attendance->HeureMatiere,
                            'presence_status' => TeacherAttendance::STATUS_PRESENT,
                        ]
                    );
                }

                $alert->status = $request->input('status');
                $alert->notes = trim((string) $request->input('notes', ''))
                    ?: ($alert->notes ?? '');
                $alert->resolved_by = (string) $user->code;
                $alert->resolved_at = now();
                $alert->save();

                return ['alert' => $alert];
            });

            if (isset($result['not_found'])) {
                return response()->json(['error' => 'Investigation not found'], 404);
            }
            if (isset($result['forbidden'])) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }
            if (isset($result['already_resolved'])) {
                return response()->json([
                    'error' => 'Investigation has already been resolved.',
                ], 409);
            }
            if (isset($result['attendance_not_found'])) {
                return response()->json([
                    'error' => 'Matching student roll-call session not found.',
                ], 409);
            }
            if (isset($result['class_not_found'])) {
                return response()->json(['error' => 'Alert class is outside the school scope.'], 409);
            }
            if (isset($result['course_not_found'])) {
                return response()->json(['error' => 'Matching teaching assignment not found.'], 409);
            }
            if (isset($result['teacher_not_found'])) {
                return response()->json(['error' => 'No assigned teacher could be resolved.'], 409);
            }
            if (isset($result['teacher_attendance_storage_unavailable'])) {
                return response()->json([
                    'error' => 'Teacher attendance storage is not ready. Apply the teacher attendance migration.',
                ], 503);
            }

            return response()->json([
                'status' => 'success',
                'alert' => $result['alert'],
            ]);
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

            $subjectLabel = trim((string) ($course->matiere?->LibelleMatiere ?? ''));
            $dispatcher = new NotificationDispatchService();
            $dispatcher->dispatchHomeworkNotification(
                (string) $course->CodeClasse,
                $subjectLabel,
                $teacherCode,
                (string) ($course->CodeEtablissement ?? ''),
                (string) $devoir->id,
                $titre,
                (string) $devoir->dateDuDevoir
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

            $request->validate([
                'DateEnreg' => 'required|string|max:255',
            ]);

            $statuses = $this->decodeJsonArrayInput($request->input('statuses', '[]'));
            if (!is_array($statuses) || empty($statuses)) {
                return response()->json(['message' => 'Invalid attendance'], 422);
            }

            $students = Eleve::where('CodeClasse', $course->CodeClasse)
                ->pluck('CodeEleve')->all();
            $studentCodes = array_flip($students);
            $allowedStatuses = ['P', 'A', 'R'];

            foreach ($statuses as $status) {
                if (!is_array($status)
                    || !isset($status['CodeEleve'], $status['status'])
                    || !is_string($status['CodeEleve'])
                    || !is_string($status['status'])
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

            $this->createInvestigationAlertsForAttendance(
                $course,
                (string) $request->DateEnreg
            );

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
                    [
                        'school_code' => (string) ($course->CodeEtablissement ?? ''),
                        'class_code' => (string) $course->CodeClasse,
                        'teaching_code' => (string) $course->CodeEnseignement,
                    ]
                );
            }

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

            $this->createInvestigationAlertsForAttendance($course, $date);

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
                    [
                        'school_code' => (string) ($course->CodeEtablissement ?? ''),
                        'class_code' => (string) $course->CodeClasse,
                        'teaching_code' => (string) $course->CodeEnseignement,
                    ]
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

    private function teacherAttendanceStorageIsReady(): bool
    {
        if (!Schema::hasTable('teacher_attendances')) {
            return false;
        }

        foreach ([
            'session_key',
            'CodeEtablissement',
            'CodeEnseignant',
            'CodeEnseignement',
            'CodeClasse',
            'CodeMatiere',
            'attendance_date',
            'session_time',
            'presence_status',
        ] as $column) {
            if (!Schema::hasColumn('teacher_attendances', $column)) {
                return false;
            }
        }

        return true;
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

    private function dashboardJustificationDetailForUser(User $user, int $id): ?array
    {
        $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
        if ($schoolCode === '') {
            return null;
        }

        $justification = AbsenceJustification::query()
            ->join(
                'eleves as justification_student',
                'justification_student.CodeEleve',
                '=',
                'absence_justifications.CodeEleve'
            )
            ->join('classes as justification_class', function ($join) {
                $join->on(
                    'justification_class.CodeClasse',
                    '=',
                    'justification_student.CodeClasse'
                )->on(
                    'justification_class.CodeEtablissement',
                    '=',
                    'absence_justifications.CodeEtablissement'
                );
            })
            ->where('absence_justifications.id', $id)
            ->where('absence_justifications.CodeEtablissement', $schoolCode)
            ->select([
                'absence_justifications.id',
                'absence_justifications.CodeEtablissement',
                'absence_justifications.CodeEleve',
                'justification_student.CodeClasse',
                'justification_student.Nom as student_last_name',
                'justification_student.Prenom as student_first_name',
                'justification_class.LibelleClasse as class_name',
                'absence_justifications.parent_code',
                'absence_justifications.parent_name',
                'absence_justifications.document_path',
                'absence_justifications.justification',
                'absence_justifications.created_at',
                'absence_justifications.reviewed_by',
                'absence_justifications.reviewed_at',
                DB::raw("COALESCE(NULLIF(absence_justifications.motif, ''), NULLIF(absence_justifications.reason, ''), '') as reason"),
                DB::raw('COALESCE(absence_justifications.date_absence, absence_justifications.absence_date) as absence_date'),
                DB::raw("COALESCE(NULLIF(absence_justifications.statut, ''), NULLIF(absence_justifications.status, ''), '') as status"),
            ])
            ->first();

        if (!$justification) {
            return null;
        }

        if (strtolower(trim((string) ($user->account_type ?? ''))) === 'encadreur'
            && !(new EncadreurClassScope())->ensureClassAccessForEncadreur(
                $user,
                (string) $justification->CodeClasse
            )) {
            return null;
        }

        $parentCode = (string) ($justification->parent_code ?? '');
        $parent = $parentCode !== ''
            ? User::query()->where('code', $parentCode)->first(['nom', 'prenom', 'contacts'])
            : null;
        $absenceDate = (string) ($justification->absence_date ?? '');
        $parsedAbsenceDate = $absenceDate !== ''
            ? date_create_immutable($absenceDate)
            : false;
        $documentPath = trim((string) ($justification->document_path ?? ''));
        $documentUrl = $documentPath === ''
            ? ''
            : (preg_match('/^https?:\/\//i', $documentPath)
                ? $documentPath
                : Storage::disk('public')->url($documentPath));
        $schoolName = (string) (
            Etablissement::query()
                ->where('CodeEtablissement', $schoolCode)
                ->value('Nom') ?? $schoolCode
        );

        return [
            'id' => (int) $justification->id,
            'CodeEtablissement' => (string) $justification->CodeEtablissement,
            'school_name' => $schoolName,
            'CodeEleve' => (string) $justification->CodeEleve,
            'student_name' => trim(
                (string) ($justification->student_last_name ?? '').' '.
                (string) ($justification->student_first_name ?? '')
            ),
            'CodeClasse' => (string) $justification->CodeClasse,
            'class_name' => (string) ($justification->class_name ?? ''),
            'absence_date' => $parsedAbsenceDate
                ? $parsedAbsenceDate->format('Y-m-d')
                : $absenceDate,
            'reason' => (string) ($justification->reason ?? ''),
            'justification' => (string) ($justification->justification ?? ''),
            'parent_code' => $parentCode,
            'parent_name' => trim(
                (string) ($justification->parent_name
                    ?: (($parent->nom ?? '').' '.($parent->prenom ?? '')))
            ),
            'parent_contacts' => (string) ($parent->contacts ?? ''),
            'document_path' => $documentPath,
            'document_url' => $documentUrl,
            'status' => (string) ($justification->status ?? ''),
            'parent_attendance_status' => 'A',
            'created_at' => (string) ($justification->created_at ?? ''),
            'reviewed_by' => (string) ($justification->reviewed_by ?? ''),
            'reviewed_at' => (string) ($justification->reviewed_at ?? ''),
        ];
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

    private function createInvestigationAlertsForAttendance($course, string $attendanceDate): void
    {
        if (!$course) {
            return;
        }

        $classCode = trim((string) ($course->CodeClasse ?? ''));
        $courseCode = trim((string) ($course->CodeEnseignement ?? ''));
        if ($classCode === '' || $courseCode === '') {
            return;
        }

        $class = Classe::query()->where('CodeClasse', $classCode)->first();
        if (!$class) {
            return;
        }

        $schoolCode = trim((string) ($class->CodeEtablissement ?? ''));
        if ($schoolCode === '') {
            return;
        }

        $courseSchoolCode = trim((string) ($course->CodeEtablissement ?? ''));
        if ($courseSchoolCode !== '' && $courseSchoolCode !== $schoolCode) {
            return;
        }

        $rollCallDate = date_create_immutable($attendanceDate);
        if ($rollCallDate === false) {
            return;
        }
        $calendarDate = $rollCallDate->format('Y-m-d');

        $attendanceRecords = Conduite::query()
            ->where('CodeEnseignement', $courseCode)
            ->where('CodeClasse', $classCode)
            ->where('DateEnreg', $attendanceDate)
            ->get([
                'CodeEleve',
                'CodeClasse',
                'CodeEnseignement',
                'CodeMatiere',
                'DateEnreg',
                'CodeEtatCond',
            ]);

        $studentCodes = $attendanceRecords->pluck('CodeEleve')
            ->map(fn ($studentCode) => trim((string) $studentCode))
            ->filter()
            ->unique()
            ->values();
        if ($studentCodes->isEmpty()) {
            return;
        }

        $justifiedStudentCodes = AbsenceJustification::query()
            ->where('CodeEtablissement', $schoolCode)
            ->whereIn('CodeEleve', $studentCodes)
            ->whereDate('absence_date', $calendarDate)
            ->where(function ($query) {
                $query->whereIn('status', ['pending', 'validated', 'approved'])
                    ->orWhereIn('statut', ['En attente', 'validée']);
            })
            ->pluck('CodeEleve')
            ->map(fn ($studentCode) => trim((string) $studentCode))
            ->flip();

        foreach ($attendanceRecords as $attendanceRecord) {
            $studentCode = trim((string) $attendanceRecord->CodeEleve);
            $attendanceClassCode = trim((string) $attendanceRecord->CodeClasse);
            $recordCourseCode = trim((string) $attendanceRecord->CodeEnseignement);
            $teacherStatus = strtoupper(trim((string) $attendanceRecord->CodeEtatCond));
            if ($studentCode === ''
                || $attendanceClassCode === ''
                || $recordCourseCode === ''
                || $teacherStatus !== 'P') {
                continue;
            }

            if (!$justifiedStudentCodes->has($studentCode)) {
                continue;
            }

            InvestigationAlert::firstOrCreate([
                'CodeEtablissement' => $schoolCode,
                'CodeEleve' => $studentCode,
                'CodeClasse' => $attendanceClassCode,
                'date_absence' => $calendarDate,
            ], [
                'CodeEnseignement' => $recordCourseCode,
                'CodeMatiere' => $attendanceRecord->CodeMatiere,
                'parent_status' => 'A',
                'teacher_status' => $teacherStatus,
                'status' => 'pending',
                'notes' => 'Parent justification exists, but student appeared in teacher roll call.',
            ]);
        }
    }
}
