<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\AiReadOnlyToolService;
use App\Services\GoogleAiService;
use Illuminate\Http\Client\Request as ClientRequest;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

class AiReadOnlyToolServiceTest extends TestCase
{
    private $principal;
    private $today;

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
                'foreign_key_constraints' => true,
            ],
        ]);
        DB::purge('sqlite');

        Schema::create('users', function (Blueprint $table) {
            $table->string('code')->primary();
            $table->string('nom')->nullable();
            $table->string('prenom')->nullable();
            $table->string('account_type')->default('enseignant');
            $table->boolean('admin')->default(false);
            $table->string('CodeEtablissement')->nullable();
            $table->string('password')->nullable();
            $table->string('text_password')->nullable();
            $table->string('remember_token')->nullable();
            $table->string('contacts')->nullable();
            $table->string('numcpt')->nullable();
        });
        Schema::create('classes', function (Blueprint $table) {
            $table->string('CodeClasse')->primary();
            $table->string('LibelleClasse');
            $table->string('CodeEtablissement');
        });
        Schema::create('encadreur_classes', function (Blueprint $table) {
            $table->increments('id');
            $table->string('code');
            $table->string('CodeClasse');
            $table->string('CodeEtablissement');
        });
        Schema::create('eleves', function (Blueprint $table) {
            $table->string('CodeEleve')->primary();
            $table->string('code')->nullable();
            $table->string('Nom')->nullable();
            $table->string('Prenom')->nullable();
            $table->string('Sex')->nullable();
            $table->string('CodeClasse');
            $table->string('DateNaissance')->nullable();
            $table->string('LieuNaissance')->nullable();
            $table->string('ADRESSE')->nullable();
            $table->string('TelP')->nullable();
            $table->string('TELM')->nullable();
            $table->string('TELT')->nullable();
            $table->string('Nomp')->nullable();
            $table->string('Image')->nullable();
            $table->string('PERSONCON')->nullable();
        });
        Schema::create('matieres', function (Blueprint $table) {
            $table->string('CodeMatiere')->primary();
            $table->string('LibelleMatiere');
            $table->string('CodeEtablissement');
        });
        Schema::create('enseignements', function (Blueprint $table) {
            $table->string('CodeEnseignement')->primary();
            $table->string('CodeMatiere');
            $table->string('code');
            $table->string('CodeEnseignant2')->nullable();
            $table->string('CodeClasse');
            $table->string('CodeEtablissement');
        });
        Schema::create('conduites', function (Blueprint $table) {
            $table->increments('id');
            $table->string('DateEnreg');
            $table->string('CodeEleve');
            $table->string('CodeEtatCond')->nullable();
            $table->string('CodeClasse')->nullable();
            $table->string('CodeMatiere')->nullable();
            $table->string('CodeEnseignement')->nullable();
            $table->string('HeureMatiere')->nullable();
        });
        Schema::create('notes', function (Blueprint $table) {
            $table->increments('id');
            $table->string('CodeEnseignement');
            $table->string('CodeEleve');
            $table->string('CodeEvaluation');
            $table->string('CodeAppreciation')->nullable();
            $table->string('valeur')->nullable();
            $table->string('coef')->nullable();
            $table->string('Total')->nullable();
            $table->string('Dateeng')->nullable();
            $table->string('CodeAnnee')->nullable();
        });
        Schema::create('convocations', function (Blueprint $table) {
            $table->increments('id');
            $table->string('code')->nullable();
            $table->string('CodeEleve')->nullable();
            $table->string('motif')->nullable();
            $table->string('description')->nullable();
            $table->string('CodeEnseignement')->nullable();
            $table->string('CodeMatiere')->nullable();
            $table->string('dateConvocation')->nullable();
        });
        Schema::create('devoirs', function (Blueprint $table) {
            $table->increments('id');
            $table->string('titre')->nullable();
            $table->text('description')->nullable();
            $table->string('dateDuDevoir')->nullable();
            $table->string('code')->nullable();
            $table->string('CodeClasse')->nullable();
            $table->string('CodeMatiere')->nullable();
            $table->string('CodeEnseignement')->nullable();
            $table->string('CodeEtablissement')->nullable();
        });
        Schema::create('ai_conversations', function (Blueprint $table) {
            $table->id();
            $table->string('user_code');
            $table->string('title')->nullable();
            $table->timestamps();
        });
        Schema::create('ai_messages', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('conversation_id');
            $table->string('role');
            $table->text('content');
            $table->timestamps();
        });

        $this->today = now()->toDateString();
        foreach ([
            [
                'code' => 'principal-a', 'nom' => 'Principal', 'prenom' => 'A',
                'account_type' => 'principal_encadreur', 'admin' => false,
                'CodeEtablissement' => 'school-a', 'password' => 'HASH_SECRET_A',
                'text_password' => 'PLAINTEXT_SECRET_A', 'remember_token' => 'TOKEN_SECRET_A',
            ],
            [
                'code' => 'teacher-a', 'nom' => 'Kouame', 'prenom' => 'Mina',
                'account_type' => 'enseignant', 'admin' => false, 'CodeEtablissement' => 'school-a',
                'password' => 'HASH_TEACHER', 'contacts' => 'PRIVATE_CONTACT', 'numcpt' => 'PRIVATE_ACCOUNT',
            ],
            [
                'code' => 'teacher-b', 'nom' => 'Other', 'prenom' => 'Teacher',
                'account_type' => 'enseignant', 'admin' => false, 'CodeEtablissement' => 'school-b',
            ],
            [
                'code' => 'parent-a', 'nom' => 'Parent', 'prenom' => 'A',
                'account_type' => 'parent', 'admin' => false, 'CodeEtablissement' => 'school-a',
            ],
            [
                'code' => 'parent-b', 'nom' => 'Parent', 'prenom' => 'B',
                'account_type' => 'parent', 'admin' => false, 'CodeEtablissement' => 'school-b',
            ],
            [
                'code' => 'encadreur-a', 'nom' => 'Encadreur', 'prenom' => 'A',
                'account_type' => 'encadreur', 'admin' => false, 'CodeEtablissement' => 'school-a',
            ],
        ] as $user) {
            DB::table('users')->insert($user);
        }
        DB::table('classes')->insert([
            ['CodeClasse' => 'class-a', 'LibelleClasse' => '6e A', 'CodeEtablissement' => 'school-a'],
            ['CodeClasse' => 'class-a2', 'LibelleClasse' => '6e B', 'CodeEtablissement' => 'school-a'],
            ['CodeClasse' => 'class-a3', 'LibelleClasse' => '6e C', 'CodeEtablissement' => 'school-a'],
            ['CodeClasse' => 'class-b', 'LibelleClasse' => '6e B', 'CodeEtablissement' => 'school-b'],
        ]);
        DB::table('matieres')->insert([
            ['CodeMatiere' => 'math-a', 'LibelleMatiere' => 'Mathématiques', 'CodeEtablissement' => 'school-a'],
            ['CodeMatiere' => 'math-b', 'LibelleMatiere' => 'Private school subject', 'CodeEtablissement' => 'school-b'],
        ]);
        DB::table('enseignements')->insert([
            ['CodeEnseignement' => 'course-a', 'CodeMatiere' => 'math-a', 'code' => 'teacher-a', 'CodeEnseignant2' => null, 'CodeClasse' => 'class-a', 'CodeEtablissement' => 'school-a'],
            ['CodeEnseignement' => 'course-a2', 'CodeMatiere' => 'math-a', 'code' => 'other-teacher-a', 'CodeEnseignant2' => 'teacher-a', 'CodeClasse' => 'class-a2', 'CodeEtablissement' => 'school-a'],
            ['CodeEnseignement' => 'course-b', 'CodeMatiere' => 'math-b', 'code' => 'teacher-b', 'CodeEnseignant2' => null, 'CodeClasse' => 'class-b', 'CodeEtablissement' => 'school-b'],
        ]);
        DB::table('encadreur_classes')->insert([
            'code' => 'encadreur-a',
            'CodeClasse' => 'class-a',
            'CodeEtablissement' => 'school-a',
        ]);
        foreach ([
            [
                'CodeEleve' => 'student-a1', 'code' => 'parent-a', 'Nom' => 'Diallo', 'Prenom' => 'Aminata',
                'Sex' => '0', 'CodeClasse' => 'class-a', 'DateNaissance' => '2012-01-01',
                'LieuNaissance' => 'PRIVATE_BIRTHPLACE', 'ADRESSE' => 'PRIVATE_ADDRESS',
                'TelP' => 'PRIVATE_PARENT_PHONE', 'TELM' => 'PRIVATE_MOBILE', 'Nomp' => 'PRIVATE_PARENT',
                'Image' => 'PRIVATE_PHOTO', 'PERSONCON' => 'PRIVATE_EMERGENCY',
            ],
            [
                'CodeEleve' => 'student-a2', 'code' => 'parent-a', 'Nom' => 'Traore', 'Prenom' => 'Moussa',
                'Sex' => '1', 'CodeClasse' => 'class-a',
            ],
            [
                'CodeEleve' => 'student-b1', 'code' => 'parent-b', 'Nom' => 'Other', 'Prenom' => 'Student',
                'Sex' => '1', 'CodeClasse' => 'class-b',
            ],
        ] as $student) {
            DB::table('eleves')->insert($student);
        }
        DB::table('notes')->insert([
            'CodeEnseignement' => 'course-a',
            'CodeEleve' => 'student-a1',
            'CodeEvaluation' => 'SEQ-1',
            'valeur' => '15',
            'coef' => '2',
            'Total' => '30',
            'Dateeng' => $this->today,
            'CodeAnnee' => 'YEAR-1',
        ]);
        DB::table('convocations')->insert([
            'code' => 'teacher-a',
            'CodeEleve' => 'student-a1',
            'motif' => 'Indiscipline',
            'description' => 'Convocation de test',
            'CodeEnseignement' => 'course-a',
            'CodeMatiere' => 'math-a',
            'dateConvocation' => $this->today,
        ]);
        DB::table('devoirs')->insert([
            'titre' => 'Exercices d’algèbre',
            'description' => 'Exercices chapitre 2',
            'dateDuDevoir' => $this->today,
            'code' => 'teacher-a',
            'CodeClasse' => 'class-a',
            'CodeMatiere' => 'math-a',
            'CodeEnseignement' => 'course-a',
            'CodeEtablissement' => 'school-a',
        ]);
        DB::table('conduites')->insert([
            ['DateEnreg' => $this->today, 'CodeEleve' => 'student-a1', 'CodeEtatCond' => 'P', 'CodeClasse' => 'class-a', 'CodeMatiere' => 'math-a', 'CodeEnseignement' => 'course-a', 'HeureMatiere' => '08:00'],
            ['DateEnreg' => $this->today, 'CodeEleve' => 'student-a2', 'CodeEtatCond' => 'A', 'CodeClasse' => 'class-a', 'CodeMatiere' => 'math-a', 'CodeEnseignement' => 'course-a', 'HeureMatiere' => '08:00'],
            ['DateEnreg' => $this->today, 'CodeEleve' => 'student-a1', 'CodeEtatCond' => 'A', 'CodeClasse' => 'class-a', 'CodeMatiere' => 'math-a', 'CodeEnseignement' => 'course-a', 'HeureMatiere' => '08:00'],
            ['DateEnreg' => $this->today, 'CodeEleve' => 'student-b1', 'CodeEtatCond' => 'P', 'CodeClasse' => 'class-b', 'CodeMatiere' => 'math-b', 'CodeEnseignement' => 'course-b', 'HeureMatiere' => '08:00'],
        ]);

        $this->principal = (new User())->forceFill([
            'code' => 'principal-a',
            'account_type' => 'principal_encadreur',
            'admin' => '0',
            'CodeEtablissement' => 'school-a',
        ]);
    }

    private function authorizePrincipal(): void
    {
        Sanctum::actingAs($this->principal, ['ai:chat']);
    }

    public function test_authorized_principal_can_use_every_registered_read_tool(): void
    {
        $this->authorizePrincipal();
        $tools = app(AiReadOnlyToolService::class);
        $toolsCalled = [
            ['searchStudents', ['classCode' => 'class-a']],
            ['getStudentProfile', ['studentCode' => 'student-a1']],
            ['getStudentAttendanceSummary', ['studentCode' => 'student-a1', 'dateFrom' => $this->today, 'dateTo' => $this->today]],
            ['getClassSummary', ['classCode' => 'class-a']],
            ['getClassRoster', ['classCode' => 'class-a']],
            ['getSchoolClassOverview', ['schoolCode' => 'school-a']],
            ['getAttendanceSummary', ['date' => $this->today]],
            ['getAttendanceSessionDetail', ['sessionId' => $this->today.'|course-a|08:00']],
            ['getTeacherAttendanceHistory', ['teacherCode' => 'teacher-a', 'dateFrom' => $this->today, 'dateTo' => $this->today]],
            ['getSchoolDashboardSummary', ['date' => $this->today]],
        ];

        foreach ($toolsCalled as $call) {
            $this->assertIsArray($tools->execute($this->principal, $call[0], $call[1]), $call[0]);
        }

        $summary = $tools->execute($this->principal, 'getAttendanceSummary', [
            'date' => $this->today,
            'classCode' => 'class-a',
        ]);
        $this->assertSame(2, $summary['attendance']['total']);
        $this->assertSame(0, $summary['attendance']['present']);
        $this->assertSame(2, $summary['attendance']['absent']);
        $this->assertSame(0, $summary['attendance']['late']);
        $this->assertSame($this->today.'|course-a|08:00', $summary['sessions'][0]['sessionId']);
    }

    public function test_parent_tools_only_return_records_for_linked_children(): void
    {
        $parent = (new User())->forceFill([
            'code' => 'parent-a',
            'account_type' => 'parent',
            'admin' => '0',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($parent, ['ai:chat']);
        DB::table('eleves')->insert([
            'CodeEleve' => 'other-parent-child',
            'code' => 'parent-b',
            'Nom' => 'Cross',
            'Prenom' => 'Parent',
            'Sex' => '0',
            'CodeClasse' => 'class-a3',
        ]);
        $tools = app(AiReadOnlyToolService::class);

        $declaredNames = array_column($tools->functionDeclarations($parent), 'name');
        $this->assertContains('get_my_children', $declaredNames);
        $this->assertContains('get_child_notes', $declaredNames);
        $this->assertNotContains('getSchoolDashboardSummary', $declaredNames);

        $children = $tools->execute($parent, 'get_my_children', []);
        $this->assertSame(['student-a1', 'student-a2'], array_column($children['children'], 'CodeEleve'));

        $parentWithoutChildren = (new User())->forceFill([
            'code' => 'parent-empty',
            'account_type' => 'parent',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($parentWithoutChildren, ['ai:chat']);
        $this->assertSame([], $tools->execute($parentWithoutChildren, 'get_my_children', [])['children']);

        $notes = $tools->execute($parent, 'get_child_notes', ['childCode' => 'student-a1']);
        $this->assertTrue($notes['found']);
        $this->assertSame('15', $notes['notes'][0]['value']);

        $attendance = $tools->execute($parent, 'get_child_attendance', [
            'childCode' => 'student-a1',
            'dateFrom' => $this->today,
            'dateTo' => $this->today,
        ]);
        $this->assertTrue($attendance['found']);
        $this->assertSame('student-a1', $attendance['student']['CodeEleve']);

        $absences = $tools->execute($parent, 'get_child_absences', [
            'childCode' => 'student-a1',
            'dateFrom' => $this->today,
            'dateTo' => $this->today,
        ]);
        $this->assertSame(1, $absences['totals']['absent']);

        $convocations = $tools->execute($parent, 'get_child_convocations', ['childCode' => 'student-a1']);
        $this->assertSame('Indiscipline', $convocations['convocations'][0]['reason']);

        $homework = $tools->execute($parent, 'get_child_homework', ['childCode' => 'student-a1']);
        $this->assertSame('Exercices d’algèbre', $homework['homework'][0]['title']);

        foreach ([
            ['get_child_notes', ['childCode' => 'other-parent-child']],
            ['get_child_notes', ['childCode' => 'student-b1']],
            ['get_child_attendance', ['childCode' => 'other-parent-child', 'dateFrom' => $this->today, 'dateTo' => $this->today]],
            ['get_child_attendance', ['childCode' => 'student-b1', 'dateFrom' => $this->today, 'dateTo' => $this->today]],
            ['get_child_absences', ['childCode' => 'other-parent-child', 'dateFrom' => $this->today, 'dateTo' => $this->today]],
            ['get_child_absences', ['childCode' => 'student-b1', 'dateFrom' => $this->today, 'dateTo' => $this->today]],
            ['get_child_convocations', ['childCode' => 'other-parent-child']],
            ['get_child_convocations', ['childCode' => 'student-b1']],
            ['get_child_messages', ['childCode' => 'other-parent-child']],
            ['get_child_messages', ['childCode' => 'student-b1']],
            ['get_child_homework', ['childCode' => 'other-parent-child']],
            ['get_child_homework', ['childCode' => 'student-b1']],
        ] as [$toolName, $arguments]) {
            $denial = $tools->execute($parent, $toolName, $arguments);
            $this->assertFalse($denial['found'], $toolName);
            $this->assertTrue($denial['access_denied'], $toolName);
            $this->assertStringContainsString('Accès refusé', $denial['message']);
        }

        try {
            $tools->execute($parent, 'getStudentProfile', ['studentCode' => 'student-a1']);
            $this->fail('Parent must not invoke Principal school tools.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('not authorized', $exception->getMessage());
        }
    }

    public function test_teacher_tools_are_limited_to_existing_teaching_assignments(): void
    {
        $teacher = (new User())->forceFill([
            'code' => 'teacher-a',
            'account_type' => 'enseignant',
            'admin' => '0',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($teacher, ['ai:chat']);
        $tools = app(AiReadOnlyToolService::class);

        $declaredNames = array_column($tools->functionDeclarations($teacher), 'name');
        $this->assertContains('get_my_classes', $declaredNames);
        $this->assertContains('get_class_students', $declaredNames);
        $this->assertNotContains('getSchoolDashboardSummary', $declaredNames);

        $classes = $tools->execute($teacher, 'get_my_classes', []);
        $this->assertSame(['class-a', 'class-a2'], array_column($classes['classes'], 'CodeClasse'));

        $assignments = $tools->execute($teacher, 'get_my_teaching_assignments', []);
        $this->assertSame(['course-a', 'course-a2'], array_column($assignments['assignments'], 'CodeEnseignement'));

        $students = $tools->execute($teacher, 'get_class_students', ['classCode' => 'class-a']);
        $this->assertSame(['student-a1', 'student-a2'], array_column($students['students'], 'CodeEleve'));

        $attendance = $tools->execute($teacher, 'get_class_attendance', [
            'classCode' => 'class-a',
            'dateFrom' => $this->today,
            'dateTo' => $this->today,
        ]);
        $this->assertSame(2, $attendance['attendance']['total']);

        $this->assertSame('class-a', $tools->execute($teacher, 'get_class_information', [
            'classCode' => 'class-a',
        ])['class']['CodeClasse']);

        $secondaryTeacherStudents = $tools->execute($teacher, 'get_class_students', ['classCode' => 'class-a2']);
        $this->assertSame([], $secondaryTeacherStudents['students']);

        foreach (['class-a3', 'class-b'] as $unauthorizedClass) {
            try {
                $tools->execute($teacher, 'get_class_students', ['classCode' => $unauthorizedClass]);
                $this->fail('Teacher must not access an unassigned class.');
            } catch (ValidationException $exception) {
                $this->assertNotEmpty($exception->errors());
            }
        }

        try {
            $tools->execute($teacher, 'getSchoolDashboardSummary', ['date' => $this->today]);
            $this->fail('Teacher must not invoke Principal school tools.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('not authorized', $exception->getMessage());
        }
    }

    public function test_encadreur_tools_are_limited_to_assigned_classes_not_the_whole_school(): void
    {
        $encadreur = (new User())->forceFill([
            'code' => 'encadreur-a',
            'account_type' => 'encadreur',
            'admin' => '0',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($encadreur, ['ai:chat']);
        $tools = app(AiReadOnlyToolService::class);

        $declarations = array_column($tools->functionDeclarations($encadreur), 'name');
        $this->assertContains('get_my_classes', $declarations);
        $this->assertNotContains('getSchoolDashboardSummary', $declarations);

        $classes = $tools->execute($encadreur, 'get_my_classes', []);
        $this->assertSame(['class-a'], array_column($classes['classes'], 'CodeClasse'));
        $students = $tools->execute($encadreur, 'get_class_students', ['classCode' => 'class-a']);
        $this->assertSame(['student-a1', 'student-a2'], array_column($students['students'], 'CodeEleve'));

        $attendance = $tools->execute($encadreur, 'get_class_attendance', [
            'classCode' => 'class-a',
            'dateFrom' => $this->today,
            'dateTo' => $this->today,
        ]);
        $this->assertSame(2, $attendance['attendance']['total']);

        foreach (['class-a2', 'class-b'] as $unauthorizedClass) {
            foreach ([
                ['get_class_students', ['classCode' => $unauthorizedClass]],
                ['get_class_attendance', [
                    'classCode' => $unauthorizedClass,
                    'dateFrom' => $this->today,
                    'dateTo' => $this->today,
                ]],
                ['get_class_information', ['classCode' => $unauthorizedClass]],
            ] as [$toolName, $arguments]) {
                $denial = $tools->execute($encadreur, $toolName, $arguments);
                $this->assertFalse($denial['found'], $toolName);
                $this->assertTrue($denial['access_denied'], $toolName);
                $this->assertStringContainsString('Accès refusé', $denial['message']);
            }
        }

        try {
            $tools->execute($encadreur, 'getSchoolDashboardSummary', ['date' => $this->today]);
            $this->fail('Encadreur must not invoke school-wide Principal tools.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('not authorized', $exception->getMessage());
        }
    }

    public function test_parent_scope_denial_is_returned_without_sending_rows_to_the_ai(): void
    {
        $parent = (new User())->forceFill([
            'code' => 'parent-a',
            'account_type' => 'parent',
            'admin' => '0',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($parent, ['ai:chat']);
        DB::table('eleves')->insert([
            'CodeEleve' => 'other-parent-child',
            'code' => 'parent-b',
            'Nom' => 'Cross',
            'Prenom' => 'Parent',
            'Sex' => '0',
            'CodeClasse' => 'class-a3',
        ]);
        config([
            'services.google_ai.api_key' => 'test-only-key',
            'services.google_ai.model' => 'test-model',
        ]);
        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [[
                    'content' => [
                        'role' => 'model',
                        'parts' => [[
                            'functionCall' => [
                                'name' => 'get_child_notes',
                                'args' => ['childCode' => 'other-parent-child'],
                                ],
                            ]],
                        ],
                    ]],
            ], 200),
        ]);

        $tools = app(AiReadOnlyToolService::class);
        $reply = app(GoogleAiService::class)->generateReply(
            'Show me this student’s grades.',
            [],
            fn ($name, array $arguments) => $tools->execute($parent, $name, $arguments),
            $tools->functionDeclarations($parent)
        );

        $this->assertSame(
            'Accès refusé : cet élève n’est pas associé à votre compte parent.',
            $reply
        );
        Http::assertSentCount(1);
        Http::assertSent(function (ClientRequest $request) {
            return !str_contains(json_encode($request->data()), 'other-parent-child');
        });
    }

    public function test_admin_flag_uses_school_bound_admin_context_not_global_scope(): void
    {
        $admin = (new User())->forceFill([
            'code' => 'legacy-admin-a',
            'account_type' => 'parent',
            'admin' => '1',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($admin, ['ai:chat']);

        $context = app(\App\Services\PrincipalContextService::class)->resolveForAi($admin);
        $this->assertSame('admin', $context['role']);
        $this->assertSame('school-a', $context['school_code']);

        $tools = app(AiReadOnlyToolService::class);
        $this->assertContains(
            'getSchoolDashboardSummary',
            array_column($tools->functionDeclarations($admin), 'name')
        );
        $this->assertFalse($tools->execute($admin, 'getStudentProfile', [
            'studentCode' => 'student-b1',
        ])['found']);

        $adminWithoutSchool = (new User())->forceFill([
            'code' => 'legacy-admin-no-school',
            'account_type' => 'parent',
            'admin' => '1',
            'CodeEtablissement' => '',
        ]);
        Sanctum::actingAs($adminWithoutSchool, ['ai:chat']);
        $this->assertNull(app(\App\Services\PrincipalContextService::class)->resolveForAi($adminWithoutSchool));
    }

    public function test_authenticated_chat_can_call_a_sanitized_read_tool_and_return_to_gemini(): void
    {
        $this->authorizePrincipal();
        config([
            'services.google_ai.api_key' => 'test-only-key',
            'services.google_ai.model' => 'test-model',
        ]);
        $requestCount = 0;
        Http::fake(function (ClientRequest $request) use (&$requestCount) {
            $requestCount++;
            if ($requestCount === 1) {
                return Http::response([
                    'candidates' => [[
                        'content' => [
                            'role' => 'model',
                            'parts' => [[
                                'functionCall' => [
                                    'name' => 'searchStudents',
                                    'args' => ['query' => 'Aminata'],
                                ],
                            ]],
                        ],
                    ]],
                ], 200);
            }

            return Http::response([
                'candidates' => [[
                    'content' => [
                        'role' => 'model',
                        'parts' => [['text' => 'Aminata Diallo est inscrite en 6e A.']],
                    ],
                ]],
            ], 200);
        });

        $this->postJson('/api/ai/chat', ['message' => 'Cherche Aminata'])
            ->assertOk()
            ->assertJson(['success' => true, 'message' => 'Aminata Diallo est inscrite en 6e A.']);

        Http::assertSent(function (ClientRequest $request) {
            $contents = $request['contents'];
            $functionResponse = $contents[2]['parts'][0]['functionResponse']['response'] ?? [];
            $student = $functionResponse['students'][0] ?? [];

            return ($student['CodeEleve'] ?? null) === 'student-a1'
                && ($student['Nom'] ?? null) === 'Diallo'
                && !array_key_exists('ADRESSE', $student)
                && !array_key_exists('TelP', $student)
                && !array_key_exists('DateNaissance', $student);
        });
    }

    public function test_parent_cannot_use_ai_chat_for_live_absence_data(): void
    {
        $parent = (new User())->forceFill([
            'code' => 'parent-a',
            'account_type' => 'parent',
            'admin' => '0',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($parent, ['ai:chat']);
        $this->postJson('/api/ai/chat', [
            'message' => 'Where can I see my child absences and how many are recorded?',
        ])->assertForbidden()->assertJson(['success' => false]);

        Http::assertNothingSent();
    }

    public function test_tool_audit_log_contains_only_safe_call_metadata(): void
    {
        $this->authorizePrincipal();
        Log::shouldReceive('info')
            ->once()
            ->with('Mobischo AI read-only tool completed.', Mockery::on(function ($context) {
                $this->assertSame('principal-a', $context['user_code']);
                $this->assertSame('principal_encadreur', $context['account_type']);
                $this->assertSame('getStudentProfile', $context['tool_name']);
                $this->assertTrue($context['success']);
                $this->assertNotEmpty($context['timestamp']);
                $this->assertSame(
                    ['user_code', 'account_type', 'tool_name', 'timestamp', 'success'],
                    array_keys($context)
                );
                return true;
            }));

        app(AiReadOnlyToolService::class)->execute($this->principal, 'getStudentProfile', [
            'studentCode' => 'student-a1',
        ]);
    }

    public function test_failed_tool_audit_log_does_not_include_arguments_or_results(): void
    {
        $this->authorizePrincipal();
        Log::shouldReceive('warning')
            ->once()
            ->with('Mobischo AI read-only tool failed.', Mockery::on(function ($context) {
                $this->assertSame('principal-a', $context['user_code']);
                $this->assertSame('executeSql', $context['tool_name']);
                $this->assertFalse($context['success']);
                $this->assertSame(
                    ['user_code', 'account_type', 'tool_name', 'timestamp', 'success'],
                    array_keys($context)
                );
                return true;
            }));

        try {
            app(AiReadOnlyToolService::class)->execute($this->principal, 'executeSql', [
                'sql' => 'SELECT secret FROM users',
            ]);
            $this->fail('Arbitrary SQL must remain unavailable.');
        } catch (InvalidArgumentException $exception) {
            $this->assertSame('Unsupported AI tool.', $exception->getMessage());
        }
    }

    public function test_tools_reject_unauthenticated_and_non_principal_users(): void
    {
        $unauthenticated = (new User())->forceFill([
            'code' => 'principal-a',
            'account_type' => 'principal_encadreur',
            'CodeEtablissement' => 'school-a',
        ]);
        try {
            app(AiReadOnlyToolService::class)->execute($unauthenticated, 'getSchoolDashboardSummary', ['date' => $this->today]);
            $this->fail('Unauthenticated user should not access AI tools.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('not authorized', $exception->getMessage());
        }

        Sanctum::actingAs($this->principal, ['wrong:ability']);
        try {
            app(AiReadOnlyToolService::class)->execute($this->principal, 'getSchoolDashboardSummary', ['date' => $this->today]);
            $this->fail('Principal without ai:chat ability should not access AI tools.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('not authorized', $exception->getMessage());
        }

        $nonPrincipal = (new User())->forceFill([
            'code' => 'teacher-a',
            'account_type' => 'enseignant',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($nonPrincipal, ['ai:chat']);
        try {
            app(AiReadOnlyToolService::class)->execute($nonPrincipal, 'getSchoolDashboardSummary', ['date' => $this->today]);
            $this->fail('Non-Principal should not access AI tools.');
        } catch (InvalidArgumentException $exception) {
            $this->assertStringContainsString('not authorized', $exception->getMessage());
        }
    }

    public function test_student_class_teacher_and_attendance_queries_are_school_scoped(): void
    {
        $this->authorizePrincipal();
        $tools = app(AiReadOnlyToolService::class);

        $this->assertFalse($tools->execute($this->principal, 'getStudentProfile', [
            'studentCode' => 'student-b1',
        ])['found']);
        $this->assertFalse($tools->execute($this->principal, 'getStudentAttendanceSummary', [
            'studentCode' => 'student-b1',
            'dateFrom' => $this->today,
            'dateTo' => $this->today,
        ])['found']);
        $studentSearch = $tools->execute($this->principal, 'searchStudents', ['query' => 'student']);
        $this->assertSame(
            ['student-a1', 'student-a2'],
            array_column($studentSearch['students'], 'CodeEleve')
        );

        foreach ([
            ['getClassSummary', ['classCode' => 'class-b']],
            ['getClassRoster', ['classCode' => 'class-b']],
            ['getAttendanceSummary', ['date' => $this->today, 'classCode' => 'class-b']],
            ['getTeacherAttendanceHistory', ['teacherCode' => 'teacher-b', 'dateFrom' => $this->today, 'dateTo' => $this->today]],
            ['getSchoolClassOverview', ['schoolCode' => 'school-b']],
        ] as $call) {
            try {
                $tools->execute($this->principal, $call[0], $call[1]);
                $this->fail($call[0].' should reject another school.');
            } catch (ValidationException $exception) {
                $this->assertNotEmpty($exception->errors());
            }
        }

        $summary = $tools->execute($this->principal, 'getSchoolDashboardSummary', ['date' => $this->today]);
        $this->assertSame(3, $summary['total_classes']);
        $this->assertSame(2, $summary['total_students']);
        $this->assertSame(1, $summary['total_teachers']);
        $this->assertSame(2, $summary['attendance']['total']);
    }

    public function test_tool_outputs_omit_sensitive_fields_and_secret_values(): void
    {
        $this->authorizePrincipal();
        $tools = app(AiReadOnlyToolService::class);
        $result = [
            $tools->execute($this->principal, 'getStudentProfile', ['studentCode' => 'student-a1']),
            $tools->execute($this->principal, 'searchStudents', ['query' => 'Aminata']),
            $tools->execute($this->principal, 'getClassRoster', ['classCode' => 'class-a']),
            $tools->execute($this->principal, 'getAttendanceSessionDetail', [
                'sessionId' => $this->today.'|course-a|08:00',
            ]),
        ];
        $json = json_encode($result);

        foreach ([
            'PRIVATE_BIRTHPLACE', 'PRIVATE_ADDRESS', 'PRIVATE_PARENT_PHONE', 'PRIVATE_MOBILE',
            'PRIVATE_PARENT', 'PRIVATE_PHOTO', 'PRIVATE_EMERGENCY', 'HASH_SECRET_A',
            'PLAINTEXT_SECRET_A', 'TOKEN_SECRET_A', 'PRIVATE_CONTACT', 'PRIVATE_ACCOUNT',
        ] as $blockedValue) {
            $this->assertStringNotContainsString($blockedValue, $json);
        }
        foreach ([
            'DateNaissance', 'LieuNaissance', 'ADRESSE', 'TelP', 'TELM', 'TELT',
            'Nomp', 'Image', 'PERSONCON', 'password', 'text_password', 'remember_token',
        ] as $blockedKey) {
            $this->assertArrayNotHasKey($blockedKey, $result[0]['student']);
        }

        $this->assertContains('users.password', $tools->permanentlyRestrictedFields());
        $this->assertContains('users.text_password', $tools->permanentlyRestrictedFields());
        $this->assertContains('users.remember_token', $tools->permanentlyRestrictedFields());
        $this->assertSame(['CodeEleve', 'Nom', 'Prenom', 'CodeClasse'], $tools->fieldAllowlist()['eleves']);
    }

    public function test_unknown_sql_tools_invalid_arguments_and_result_limits_are_rejected(): void
    {
        $this->authorizePrincipal();
        $tools = app(AiReadOnlyToolService::class);

        try {
            $tools->execute($this->principal, 'executeSql', ['sql' => 'DROP TABLE eleves']);
            $this->fail('Arbitrary SQL function must not be registered.');
        } catch (InvalidArgumentException $exception) {
            $this->assertSame('Unsupported AI tool.', $exception->getMessage());
        }

        foreach ([
            ['searchStudents', ['classCode' => 'class-a', 'sql' => 'SELECT * FROM users']],
            ['searchStudents', ['classCode' => 'class-a', 'limit' => 51]],
            ['getStudentAttendanceSummary', ['studentCode' => 'student-a1', 'dateFrom' => 'bad', 'dateTo' => $this->today]],
            ['getAttendanceSummary', ['date' => $this->today, 'unexpected' => 'value']],
            ['getTeacherAttendanceHistory', ['teacherCode' => 'teacher-a', 'dateFrom' => '2024-01-01', 'dateTo' => $this->today]],
        ] as $call) {
            try {
                $tools->execute($this->principal, $call[0], $call[1]);
                $this->fail($call[0].' should reject invalid arguments.');
            } catch (ValidationException $exception) {
                $this->assertNotEmpty($exception->errors());
            }
        }

        for ($index = 0; $index < 55; $index++) {
            DB::table('eleves')->insert([
                'CodeEleve' => 'student-extra-'.$index,
                'Nom' => 'Extra',
                'Prenom' => 'Student '.$index,
                'Sex' => '0',
                'CodeClasse' => 'class-a',
            ]);
        }
        $limited = $tools->execute($this->principal, 'searchStudents', [
            'classCode' => 'class-a',
            'limit' => 50,
        ]);
        $this->assertCount(50, $limited['students']);
        $this->assertTrue($limited['truncated']);
    }
}