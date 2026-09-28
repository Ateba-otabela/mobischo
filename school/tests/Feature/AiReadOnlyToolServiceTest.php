<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\AiReadOnlyToolService;
use Illuminate\Http\Client\Request as ClientRequest;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;
use Laravel\Sanctum\Sanctum;
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
        Schema::create('eleves', function (Blueprint $table) {
            $table->string('CodeEleve')->primary();
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
        DB::table('users')->insert([
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
        ]);
        DB::table('classes')->insert([
            ['CodeClasse' => 'class-a', 'LibelleClasse' => '6e A', 'CodeEtablissement' => 'school-a'],
            ['CodeClasse' => 'class-b', 'LibelleClasse' => '6e B', 'CodeEtablissement' => 'school-b'],
        ]);
        DB::table('matieres')->insert([
            ['CodeMatiere' => 'math-a', 'LibelleMatiere' => 'Mathématiques', 'CodeEtablissement' => 'school-a'],
            ['CodeMatiere' => 'math-b', 'LibelleMatiere' => 'Private school subject', 'CodeEtablissement' => 'school-b'],
        ]);
        DB::table('enseignements')->insert([
            ['CodeEnseignement' => 'course-a', 'CodeMatiere' => 'math-a', 'code' => 'teacher-a', 'CodeClasse' => 'class-a', 'CodeEtablissement' => 'school-a'],
            ['CodeEnseignement' => 'course-b', 'CodeMatiere' => 'math-b', 'code' => 'teacher-b', 'CodeClasse' => 'class-b', 'CodeEtablissement' => 'school-b'],
        ]);
        DB::table('eleves')->insert([
            [
                'CodeEleve' => 'student-a1', 'Nom' => 'Diallo', 'Prenom' => 'Aminata',
                'Sex' => '0', 'CodeClasse' => 'class-a', 'DateNaissance' => '2012-01-01',
                'LieuNaissance' => 'PRIVATE_BIRTHPLACE', 'ADRESSE' => 'PRIVATE_ADDRESS',
                'TelP' => 'PRIVATE_PARENT_PHONE', 'TELM' => 'PRIVATE_MOBILE', 'Nomp' => 'PRIVATE_PARENT',
                'Image' => 'PRIVATE_PHOTO', 'PERSONCON' => 'PRIVATE_EMERGENCY',
            ],
            [
                'CodeEleve' => 'student-a2', 'Nom' => 'Traore', 'Prenom' => 'Moussa',
                'Sex' => '1', 'CodeClasse' => 'class-a',
            ],
            [
                'CodeEleve' => 'student-b1', 'Nom' => 'Other', 'Prenom' => 'Student',
                'Sex' => '1', 'CodeClasse' => 'class-b',
            ],
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
        $this->assertSame(1, $summary['total_classes']);
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