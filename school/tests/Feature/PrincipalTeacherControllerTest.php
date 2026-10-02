<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PrincipalTeacherControllerTest extends TestCase
{
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
        });
        Schema::create('classes', function (Blueprint $table) {
            $table->string('CodeClasse')->primary();
            $table->string('LibelleClasse');
            $table->string('CodeEtablissement');
        });
        Schema::create('enseignements', function (Blueprint $table) {
            $table->string('CodeEnseignement')->primary();
            $table->string('CodeClasse');
            $table->string('CodeEtablissement')->nullable();
            $table->string('code')->nullable();
            $table->string('CodeEnseignant2')->nullable();
            $table->string('CodeMatiere')->nullable();
        });
        Schema::create('matieres', function (Blueprint $table) {
            $table->string('CodeMatiere')->primary();
            $table->string('LibelleMatiere');
        });
        Schema::create('teacher_attendances', function (Blueprint $table) {
            $table->id();
            $table->string('CodeEtablissement');
            $table->string('teacher_code');
            $table->string('CodeEnseignement');
            $table->string('CodeClasse');
            $table->string('CodeMatiere')->nullable();
            $table->date('attendance_date');
            $table->string('session')->nullable();
            $table->string('presence_status')->default('present');
            $table->string('session_key')->unique();
            $table->string('recorded_by')->nullable();
            $table->timestamps();
        });
        Schema::create('encadreur_classes', function (Blueprint $table) {
            $table->id();
            $table->string('code');
            $table->string('CodeClasse');
            $table->string('CodeEtablissement');
        });

        DB::table('users')->insert([
            [
                'code' => 'principal-a',
                'nom' => null,
                'prenom' => null,
                'account_type' => 'principal',
                'admin' => false,
                'CodeEtablissement' => 'school-a',
                'password' => null,
                'text_password' => null,
                'remember_token' => null,
                'contacts' => null,
            ],
            [
                'code' => 'teacher-a',
                'nom' => 'TEACHER',
                'prenom' => 'ALPHA',
                'account_type' => 'enseignant',
                'admin' => false,
                'CodeEtablissement' => 'school-a',
                'password' => 'DO_NOT_RETURN_PASSWORD',
                'text_password' => 'DO_NOT_RETURN_TEXT_PASSWORD',
                'remember_token' => 'DO_NOT_RETURN_REMEMBER_TOKEN',
                'contacts' => 'DO_NOT_RETURN_CONTACTS',
            ],
            [
                'code' => 'teacher-b',
                'nom' => 'TEACHER',
                'prenom' => 'BETA',
                'account_type' => 'enseignant',
                'admin' => false,
                'CodeEtablissement' => 'school-a',
                'password' => null,
                'text_password' => null,
                'remember_token' => null,
                'contacts' => null,
            ],
            [
                'code' => 'parent-a',
                'nom' => 'PARENT',
                'prenom' => 'ACCOUNT',
                'account_type' => 'parent',
                'admin' => false,
                'CodeEtablissement' => 'school-a',
                'password' => null,
                'text_password' => null,
                'remember_token' => null,
                'contacts' => null,
            ],
            [
                'code' => 'teacher-foreign',
                'nom' => 'OTHER',
                'prenom' => 'SCHOOL',
                'account_type' => 'enseignant',
                'admin' => false,
                'CodeEtablissement' => 'school-b',
                'password' => null,
                'text_password' => null,
                'remember_token' => null,
                'contacts' => null,
            ],
        ]);
        DB::table('classes')->insert([
            ['CodeClasse' => 'class-a', 'LibelleClasse' => '6e A', 'CodeEtablissement' => 'school-a'],
            ['CodeClasse' => 'class-b', 'LibelleClasse' => '6e B', 'CodeEtablissement' => 'school-b'],
        ]);
        DB::table('enseignements')->insert([
            [
                'CodeEnseignement' => 'course-a1',
                'CodeClasse' => 'class-a',
                'CodeEtablissement' => 'school-a',
                'code' => 'teacher-a',
                'CodeEnseignant2' => 'parent-a',
                'CodeMatiere' => 'GEO',
            ],
            [
                'CodeEnseignement' => 'course-a2',
                'CodeClasse' => 'class-a',
                'CodeEtablissement' => 'school-a',
                'code' => 'teacher-a',
                'CodeEnseignant2' => 'teacher-b',
                'CodeMatiere' => 'GEO',
            ],
            [
                'CodeEnseignement' => 'course-a3',
                'CodeClasse' => 'class-a',
                'CodeEtablissement' => null,
                'code' => 'teacher-b',
                'CodeEnseignant2' => null,
                'CodeMatiere' => 'GEO',
            ],
            [
                'CodeEnseignement' => 'course-b1',
                'CodeClasse' => 'class-b',
                'CodeEtablissement' => 'school-b',
                'code' => 'teacher-foreign',
                'CodeEnseignant2' => null,
                'CodeMatiere' => 'GEO',
            ],
        ]);
    }

    public function test_principal_receives_deduplicated_assigned_teachers_but_not_parent_secondary_codes(): void
    {
        $principal = (new User())->forceFill([
            'code' => 'principal-a',
            'account_type' => 'principal',
            'admin' => false,
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($principal, ['ai:chat']);

        $this->getJson('/api/principal/teacher-classes')
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.CodeClasse', 'class-a')
            ->assertJsonPath('0.LibelleClasse', '6e A')
            ->assertJsonPath('0.enseignants', [
                ['code' => 'teacher-a', 'full_name' => 'TEACHER ALPHA'],
                ['code' => 'teacher-b', 'full_name' => 'TEACHER BETA'],
            ])
            ->assertDontSee('PARENT ACCOUNT')
            ->assertDontSee('OTHER SCHOOL')
            ->assertDontSee('DO_NOT_RETURN_PASSWORD')
            ->assertDontSee('DO_NOT_RETURN_TEXT_PASSWORD')
            ->assertDontSee('DO_NOT_RETURN_REMEMBER_TOKEN')
            ->assertDontSee('DO_NOT_RETURN_CONTACTS');
    }

    public function test_teacher_directory_requires_sanctum_and_principal_authorization(): void
    {
        $this->getJson('/api/principal/teacher-classes')->assertUnauthorized();

        $teacher = (new User())->forceFill([
            'code' => 'teacher-a',
            'account_type' => 'enseignant',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($teacher, ['ai:chat']);
        $this->getJson('/api/principal/teacher-classes')->assertForbidden();

        $principalWithoutAbility = (new User())->forceFill([
            'code' => 'principal-a',
            'account_type' => 'principal',
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($principalWithoutAbility, ['other:ability']);
        $this->getJson('/api/principal/teacher-classes')->assertForbidden();
    }

    public function test_principal_gets_selected_teachers_presence_history_only(): void
    {
        DB::table('matieres')->insert([
            ['CodeMatiere' => 'GEO', 'LibelleMatiere' => 'Géographie'],
        ]);
        DB::table('teacher_attendances')->insert([
            [
                'CodeEtablissement' => 'school-a',
                'teacher_code' => 'teacher-a',
                'CodeEnseignement' => 'course-a1',
                'CodeClasse' => 'class-a',
                'CodeMatiere' => 'GEO',
                'attendance_date' => '2026-10-04',
                'session' => '08:00',
                'presence_status' => 'present',
                'session_key' => str_repeat('a', 64),
                'recorded_by' => 'principal-a',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'CodeEtablissement' => 'school-a',
                'teacher_code' => 'teacher-b',
                'CodeEnseignement' => 'course-a2',
                'CodeClasse' => 'class-a',
                'CodeMatiere' => 'GEO',
                'attendance_date' => '2026-10-03',
                'session' => '10:00',
                'presence_status' => 'absent',
                'session_key' => str_repeat('b', 64),
                'recorded_by' => 'principal-a',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'CodeEtablissement' => 'school-b',
                'teacher_code' => 'teacher-a',
                'CodeEnseignement' => 'course-b1',
                'CodeClasse' => 'class-b',
                'CodeMatiere' => 'GEO',
                'attendance_date' => '2026-10-02',
                'session' => '12:00',
                'presence_status' => 'present',
                'session_key' => str_repeat('c', 64),
                'recorded_by' => 'principal-a',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $principal = (new User())->forceFill([
            'code' => 'principal-a',
            'account_type' => 'principal',
            'admin' => false,
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($principal, ['ai:chat']);

        $this->getJson('/api/principal/teachers/teacher-a/attendance')
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.teacher_code', 'teacher-a')
            ->assertJsonPath('0.CodeEnseignement', 'course-a1')
            ->assertJsonPath('0.CodeClasse', 'class-a')
            ->assertJsonPath('0.CodeMatiere', 'GEO')
            ->assertJsonPath('0.attendance_date', '2026-10-04')
            ->assertJsonPath('0.session', '08:00')
            ->assertJsonPath('0.presence_status', 'present')
            ->assertJsonPath('0.class_name', '6e A')
            ->assertJsonPath('0.subject_name', 'Géographie');
    }

    public function test_encadreur_presence_history_is_limited_to_assigned_classes(): void
    {
        DB::table('classes')->insert([
            ['CodeClasse' => 'class-a2', 'LibelleClasse' => '6e A2', 'CodeEtablissement' => 'school-a'],
        ]);
        DB::table('enseignements')->insert([
            [
                'CodeEnseignement' => 'course-a4',
                'CodeClasse' => 'class-a2',
                'CodeEtablissement' => 'school-a',
                'code' => 'teacher-a',
                'CodeEnseignant2' => null,
                'CodeMatiere' => 'GEO',
            ],
        ]);
        DB::table('encadreur_classes')->insert([
            ['code' => 'encadreur-a', 'CodeClasse' => 'class-a', 'CodeEtablissement' => 'school-a'],
        ]);
        DB::table('teacher_attendances')->insert([
            [
                'CodeEtablissement' => 'school-a',
                'teacher_code' => 'teacher-a',
                'CodeEnseignement' => 'course-a1',
                'CodeClasse' => 'class-a',
                'CodeMatiere' => 'GEO',
                'attendance_date' => '2026-10-04',
                'session' => '08:00',
                'presence_status' => 'present',
                'session_key' => str_repeat('d', 64),
                'recorded_by' => 'encadreur-a',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'CodeEtablissement' => 'school-a',
                'teacher_code' => 'teacher-a',
                'CodeEnseignement' => 'course-a4',
                'CodeClasse' => 'class-a2',
                'CodeMatiere' => 'GEO',
                'attendance_date' => '2026-10-03',
                'session' => '10:00',
                'presence_status' => 'present',
                'session_key' => str_repeat('e', 64),
                'recorded_by' => 'encadreur-a',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $encadreur = (new User())->forceFill([
            'code' => 'encadreur-a',
            'account_type' => 'encadreur',
            'admin' => false,
            'CodeEtablissement' => 'school-a',
        ]);
        Sanctum::actingAs($encadreur, ['ai:chat']);

        $this->getJson('/api/principal/teachers/teacher-a/attendance')
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.CodeClasse', 'class-a');
    }
}
