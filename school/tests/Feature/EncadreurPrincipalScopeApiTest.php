<?php

namespace Tests\Feature;

use App\Models\Classe;
use App\Models\Eleve;
use App\Models\EncadreurClasse;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EncadreurPrincipalScopeApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->artisan('migrate:fresh', ['--seed' => false]);
    }

    protected function createSchoolClasses(): array
    {
        $schoolOne = 'SCHOOL-1';
        $schoolTwo = 'SCHOOL-2';

        $classA = Classe::create([
            'CodeClasse' => 'CL-A',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe A',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => $schoolOne,
        ]);

        $classB = Classe::create([
            'CodeClasse' => 'CL-B',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe B',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => $schoolOne,
        ]);

        $classOut = Classe::create([
            'CodeClasse' => 'CL-X',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe Etranger',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => $schoolTwo,
        ]);

        return [$classA, $classB, $classOut];
    }

    public function test_encadreur_can_only_fetch_assigned_classes_and_students(): void
    {
        [$classA, $classB, $classOut] = $this->createSchoolClasses();

        $encadreur = User::create([
            'code' => 'ENC-API',
            'nom' => 'Encadreur',
            'prenom' => 'Test',
            'sex' => 'M',
            'login' => 'encapi',
            'contacts' => '123',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        EncadreurClasse::create([
            'code' => 'ENC-API',
            'CodeClasse' => 'CL-A',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Eleve::create([
            'CodeEleve' => 'ELE-1',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-A',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Alpha',
            'Prenom' => 'One',
            'Sex' => 'M',
            'code' => null,
        ]);

        Eleve::create([
            'CodeEleve' => 'ELE-2',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-B',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Beta',
            'Prenom' => 'Two',
            'Sex' => 'F',
            'code' => null,
        ]);

        Eleve::create([
            'CodeEleve' => 'ELE-3',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-X',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Gamma',
            'Prenom' => 'Three',
            'Sex' => 'M',
            'code' => null,
        ]);

        $response = $this->postJson('/api/school_manager', [
            'action' => 'GET_PRINCIPAL_CLASSES',
            'code' => 'ENC-API',
        ]);

        $response->assertOk();
        $classCodes = array_map(fn ($item) => $item['CodeClasse'], $response->json());
        $this->assertSame(['CL-A'], $classCodes);

        $studentResponse = $this->postJson('/api/school_manager', [
            'action' => 'GET_COURSE_STUDENTS',
            'code' => 'ENC-API',
            'codeClasse' => 'CL-A',
        ]);

        $studentResponse->assertOk();
        $this->assertSame(['ELE-1'], array_column($studentResponse->json(), 'CodeEleve'));

        $forbiddenStudents = $this->postJson('/api/school_manager', [
            'action' => 'GET_COURSE_STUDENTS',
            'code' => 'ENC-API',
            'codeClasse' => 'CL-B',
        ]);

        $forbiddenStudents->assertStatus(403);
    }

    public function test_principal_still_sees_all_school_classes_and_students(): void
    {
        [$classA, $classB, $classOut] = $this->createSchoolClasses();

        $principal = User::create([
            'code' => 'PR-API',
            'nom' => 'Principal',
            'prenom' => 'Test',
            'sex' => 'M',
            'login' => 'principalapi',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'admin' => true,
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Eleve::create([
            'CodeEleve' => 'ELE-4',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-A',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Principal',
            'Prenom' => 'A',
            'Sex' => 'M',
            'code' => null,
        ]);

        Eleve::create([
            'CodeEleve' => 'ELE-5',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-B',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Principal',
            'Prenom' => 'B',
            'Sex' => 'F',
            'code' => null,
        ]);

        $classesResponse = $this->postJson('/api/school_manager', [
            'action' => 'GET_PRINCIPAL_CLASSES',
            'code' => 'PR-API',
        ]);

        $classesResponse->assertOk();
        $classCodes = array_map(fn ($item) => $item['CodeClasse'], $classesResponse->json());
        $this->assertContains('CL-A', $classCodes);
        $this->assertContains('CL-B', $classCodes);
        $this->assertNotContains('CL-X', $classCodes);

        $details = $this->postJson('/api/school_manager', [
            'action' => 'GET_PRINCIPAL_CLASS_DETAILS',
            'code' => 'PR-API',
            'CodeClasse' => 'CL-A',
        ]);

        $details->assertOk();
        $this->assertEquals('CL-A', $details->json('CodeClasse'));
    }

    public function test_encadreur_cannot_access_unassigned_class_details_or_cross_school_data(): void
    {
        [$classA, $classB, $classOut] = $this->createSchoolClasses();

        $encadreur = User::create([
            'code' => 'ENC-UNAUTH',
            'nom' => 'Encadreur',
            'prenom' => 'Blocked',
            'sex' => 'M',
            'login' => 'encunauth',
            'contacts' => '999',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        EncadreurClasse::create([
            'code' => 'ENC-UNAUTH',
            'CodeClasse' => 'CL-A',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $unassigned = $this->postJson('/api/school_manager', [
            'action' => 'GET_PRINCIPAL_CLASS_DETAILS',
            'code' => 'ENC-UNAUTH',
            'CodeClasse' => 'CL-B',
        ]);

        $unassigned->assertStatus(403);

        $crossSchool = $this->postJson('/api/school_manager', [
            'action' => 'GET_PRINCIPAL_CLASS_DETAILS',
            'code' => 'ENC-UNAUTH',
            'CodeClasse' => 'CL-X',
        ]);

        $crossSchool->assertStatus(403);
    }
}
