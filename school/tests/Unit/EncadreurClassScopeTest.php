<?php

namespace Tests\Unit;

use App\Models\Classe;
use App\Models\Eleve;
use App\Models\EncadreurClasse;
use App\Models\User;
use App\Services\EncadreurClassScope;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class EncadreurClassScopeTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->artisan('migrate:fresh', ['--seed' => false]);
    }

    public function test_assigned_class_codes_are_restricted_to_encadreur_and_school(): void
    {
        $encadreur = User::create([
            'code' => 'ENC-01',
            'nom' => 'Mouka',
            'prenom' => 'Alice',
            'sex' => 'F',
            'login' => 'enc01',
            'contacts' => '123',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $sameSchoolClassA = Classe::create([
            'CodeClasse' => 'CL-A',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe A',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $sameSchoolClassB = Classe::create([
            'CodeClasse' => 'CL-B',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe B',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $otherSchoolClass = Classe::create([
            'CodeClasse' => 'CL-OTHER',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Autre école',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-2',
        ]);

        EncadreurClasse::create([
            'code' => 'ENC-01',
            'CodeClasse' => 'CL-A',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        EncadreurClasse::create([
            'code' => 'ENC-01',
            'CodeClasse' => 'CL-B',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        EncadreurClasse::create([
            'code' => 'ENC-01',
            'CodeClasse' => 'CL-OTHER',
            'CodeEtablissement' => 'SCHOOL-2',
        ]);

        $scope = new EncadreurClassScope();

        $this->assertSame(['CL-A', 'CL-B'], $scope->assignedClassCodesForEncadreur($encadreur));
        $this->assertTrue($scope->ensureClassAccessForEncadreur($encadreur, 'CL-A'));
        $this->assertFalse($scope->ensureClassAccessForEncadreur($encadreur, 'CL-OTHER'));
        $this->assertFalse($scope->ensureClassAccessForEncadreur($encadreur, 'CL-Z'));
    }

    public function test_encadreur_list_students_returns_only_assigned_classes(): void
    {
        $encadreur = User::create([
            'code' => 'ENC-02',
            'nom' => 'Mouka',
            'prenom' => 'Blaise',
            'sex' => 'M',
            'login' => 'enc02',
            'contacts' => '456',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Classe::create([
            'CodeClasse' => 'CL-1',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe 1',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Classe::create([
            'CodeClasse' => 'CL-2',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe 2',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        EncadreurClasse::create([
            'code' => 'ENC-02',
            'CodeClasse' => 'CL-1',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Eleve::create([
            'CodeEleve' => 'ELE-1',
            'CodeClasse' => 'CL-1',
            'CodeAnnee' => 'AN-1',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Student',
            'Prenom' => 'One',
            'Sex' => 'M',
            'code' => null,
        ]);

        Eleve::create([
            'CodeEleve' => 'ELE-2',
            'CodeClasse' => 'CL-2',
            'CodeAnnee' => 'AN-1',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Student',
            'Prenom' => 'Two',
            'Sex' => 'F',
            'code' => null,
        ]);

        $scope = new EncadreurClassScope();
        $students = $scope->listStudentsForEncadreur($encadreur)->pluck('CodeEleve')->all();

        $this->assertSame(['ELE-1'], $students);
    }

    public function test_duplicate_assignment_is_rejected_by_unique_constraint(): void
    {
        User::create([
            'code' => 'ENC-03',
            'nom' => 'Mouka',
            'prenom' => 'Celine',
            'sex' => 'F',
            'login' => 'enc03',
            'contacts' => '789',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Classe::create([
            'CodeClasse' => 'CL-3',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe 3',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        EncadreurClasse::create([
            'code' => 'ENC-03',
            'CodeClasse' => 'CL-3',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $this->expectException(\Illuminate\Database\QueryException::class);

        EncadreurClasse::create([
            'code' => 'ENC-03',
            'CodeClasse' => 'CL-3',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
    }

    public function test_an_encadreur_with_no_assignments_gets_zero_classes(): void
    {
        $encadreur = User::create([
            'code' => 'ENC-04',
            'nom' => 'Mouka',
            'prenom' => 'Dona',
            'sex' => 'F',
            'login' => 'enc04',
            'contacts' => '101',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $scope = new EncadreurClassScope();

        $this->assertSame([], $scope->assignedClassCodesForEncadreur($encadreur));
        $this->assertFalse($scope->ensureClassAccessForEncadreur($encadreur, 'CL-404'));
    }

    public function test_principal_context_is_unchanged(): void
    {
        $principal = User::create([
            'code' => 'PR-01',
            'nom' => 'Principal',
            'prenom' => 'Test',
            'sex' => 'M',
            'login' => 'principal',
            'contacts' => '202',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
            'admin' => true,
        ]);

        $this->assertTrue((new \App\Services\PrincipalContextService())->isPrincipal($principal));
    }
}
