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

        DB::table('users')->insert([
            [
                'code' => 'principal-a',
                'account_type' => 'principal',
                'admin' => false,
                'CodeEtablissement' => 'school-a',
            ],
            [
                'code' => 'teacher-a',
                'nom' => 'TEACHER',
                'prenom' => 'ALPHA',
                'account_type' => 'enseignant',
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
                'CodeEtablissement' => 'school-a',
            ],
            [
                'code' => 'parent-a',
                'nom' => 'PARENT',
                'prenom' => 'ACCOUNT',
                'account_type' => 'parent',
                'CodeEtablissement' => 'school-a',
            ],
            [
                'code' => 'teacher-foreign',
                'nom' => 'OTHER',
                'prenom' => 'SCHOOL',
                'account_type' => 'enseignant',
                'CodeEtablissement' => 'school-b',
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
            ],
            [
                'CodeEnseignement' => 'course-a2',
                'CodeClasse' => 'class-a',
                'CodeEtablissement' => 'school-a',
                'code' => 'teacher-a',
                'CodeEnseignant2' => 'teacher-b',
            ],
            [
                'CodeEnseignement' => 'course-a3',
                'CodeClasse' => 'class-a',
                'CodeEtablissement' => null,
                'code' => 'teacher-b',
                'CodeEnseignant2' => null,
            ],
            [
                'CodeEnseignement' => 'course-b1',
                'CodeClasse' => 'class-b',
                'CodeEtablissement' => 'school-b',
                'code' => 'teacher-foreign',
                'CodeEnseignant2' => null,
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
}
