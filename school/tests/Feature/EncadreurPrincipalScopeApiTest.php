<?php

namespace Tests\Feature;

use App\Models\Classe;
use App\Models\Eleve;
use App\Models\EncadreurClasse;
use App\Models\Enseignement;
use App\Models\Convocation;
use App\Models\Note;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
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

    public function test_student_year_notes_are_filtered_to_the_requested_child_and_year(): void
    {
        Note::create([
            'CodeEleve' => 'CHILD-A',
            'CodeEnseignement' => 'COURSE-A',
            'CodeEvaluation' => 'SEQ-1',
            'CodeAnnee' => 'YEAR-1',
            'valeur' => '15',
        ]);
        Note::create([
            'CodeEleve' => 'CHILD-B',
            'CodeEnseignement' => 'COURSE-A',
            'CodeEvaluation' => 'SEQ-1',
            'CodeAnnee' => 'YEAR-1',
            'valeur' => '18',
        ]);
        Note::create([
            'CodeEleve' => 'CHILD-A',
            'CodeEnseignement' => 'COURSE-A',
            'CodeEvaluation' => 'SEQ-1',
            'CodeAnnee' => 'YEAR-2',
            'valeur' => '12',
        ]);

        $response = $this->postJson('/api/school_manager', [
            'action' => 'GET_STUDENT_YEAR_MARKS',
            'codeEleve' => 'CHILD-A',
            'codeAnnee' => 'YEAR-1',
        ]);

        $response->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.CodeEleve', 'CHILD-A')
            ->assertJsonPath('0.CodeAnnee', 'YEAR-1');
    }

    public function test_course_year_notes_are_filtered_to_the_requested_course_and_year(): void
    {
        Note::create([
            'CodeEleve' => 'CHILD-A',
            'CodeEnseignement' => 'COURSE-A',
            'CodeEvaluation' => 'SEQ-1',
            'CodeAnnee' => 'YEAR-1',
            'valeur' => '15',
        ]);
        Note::create([
            'CodeEleve' => 'CHILD-B',
            'CodeEnseignement' => 'COURSE-B',
            'CodeEvaluation' => 'SEQ-1',
            'CodeAnnee' => 'YEAR-1',
            'valeur' => '18',
        ]);
        Note::create([
            'CodeEleve' => 'CHILD-A',
            'CodeEnseignement' => 'COURSE-A',
            'CodeEvaluation' => 'SEQ-1',
            'CodeAnnee' => 'YEAR-2',
            'valeur' => '12',
        ]);

        $response = $this->postJson('/api/school_manager', [
            'action' => 'GET_COURSE_YEAR_MARKS',
            'codeEnseignement' => 'COURSE-A',
            'codeAnnee' => 'YEAR-1',
        ]);

        $response->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.CodeEnseignement', 'COURSE-A')
            ->assertJsonPath('0.CodeAnnee', 'YEAR-1');
    }

    public function test_notes_loading_returns_an_empty_array_when_there_are_no_notes(): void
    {
        $this->postJson('/api/school_manager', [
            'action' => 'GET_STUDENT_YEAR_MARKS',
            'codeEleve' => 'CHILD-WITH-NO-NOTES',
            'codeAnnee' => 'YEAR-1',
        ])->assertOk()->assertExactJson([]);
    }

    public function test_bulk_notes_actions_reject_missing_scope_fields(): void
    {
        $this->postJson('/api/school_manager', [
            'action' => 'GET_STUDENT_YEAR_MARKS',
            'codeEleve' => 'CHILD-A',
        ])->assertUnprocessable();

        $this->postJson('/api/school_manager', [
            'action' => 'GET_COURSE_YEAR_MARKS',
            'codeAnnee' => 'YEAR-1',
        ])->assertUnprocessable();
    }

    public function test_principal_can_create_convocation_for_any_class_in_own_school_only(): void
    {
        [, $classB, $classOut] = $this->createSchoolClasses();

        User::create([
            'code' => 'PR-CONV',
            'nom' => 'Principal',
            'prenom' => 'Convocation',
            'sex' => 'M',
            'login' => 'principalconvocation',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'admin' => false,
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        User::create([
            'code' => 'TEACHER-CONV',
            'nom' => 'Teacher',
            'prenom' => 'Assigned',
            'sex' => 'M',
            'login' => 'teacherconvocation',
            'contacts' => '222',
            'password' => bcrypt('secret'),
            'account_type' => 'enseignant',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Enseignement::create([
            'CodeEnseignement' => 'ENS-B',
            'CodeMatiere' => 'MAT-B',
            'code' => 'TEACHER-CONV',
            'CodeClasse' => $classB->CodeClasse,
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        Enseignement::create([
            'CodeEnseignement' => 'ENS-X',
            'CodeMatiere' => 'MAT-X',
            'code' => 'TEACHER-CONV',
            'CodeClasse' => $classOut->CodeClasse,
            'CodeEtablissement' => 'SCHOOL-2',
        ]);

        Eleve::create([
            'CodeEleve' => 'ELE-B',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => $classB->CodeClasse,
            'dateinscription' => '2024-09-01',
            'Nom' => 'Student',
            'Prenom' => 'School One',
        ]);
        Eleve::create([
            'CodeEleve' => 'ELE-X',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => $classOut->CodeClasse,
            'dateinscription' => '2024-09-01',
            'Nom' => 'Student',
            'Prenom' => 'School Two',
        ]);

        $response = $this->post('/api/school_manager', [
            'action' => 'INSERT_CONVOCATION',
            'code' => 'PR-CONV',
            'CodeEleves' => json_encode(['ELE-B']),
            'CodeClasse' => $classB->CodeClasse,
            'CodeEnseignement' => 'ENS-B',
            'motif' => 'Indiscipline',
            'description' => 'Convocation test',
            'dateConvocation' => '2026-10-01',
        ]);

        $response->assertOk()->assertExactJson(['status' => 'success']);
        $this->assertDatabaseHas('convocations', [
            'code' => 'PR-CONV',
            'CodeEleve' => 'ELE-B',
            'CodeEnseignement' => 'ENS-B',
            'CodeMatiere' => 'MAT-B',
            'document_path' => null,
        ]);

        $crossSchoolResponse = $this->postJson('/api/school_manager', [
            'action' => 'INSERT_CONVOCATION',
            'code' => 'PR-CONV',
            'CodeEleves' => json_encode(['ELE-X']),
            'CodeClasse' => $classOut->CodeClasse,
            'CodeEnseignement' => 'ENS-X',
            'motif' => 'Indiscipline',
            'description' => 'Cross-school test',
            'dateConvocation' => '2026-10-01',
        ]);

        $crossSchoolResponse->assertForbidden();
        $this->assertSame(1, Convocation::where('code', 'PR-CONV')->count());
    }

    public function test_principal_convocation_attachment_is_stored_and_returned_in_listing(): void
    {
        [, $classB] = $this->createSchoolClasses();
        Storage::fake('public');

        User::create([
            'code' => 'PR-FILE',
            'nom' => 'Principal',
            'prenom' => 'File',
            'sex' => 'M',
            'login' => 'principalfile',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'admin' => false,
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        Enseignement::create([
            'CodeEnseignement' => 'ENS-FILE',
            'CodeMatiere' => 'MAT-FILE',
            'code' => 'TEACHER-FILE',
            'CodeClasse' => $classB->CodeClasse,
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        Eleve::create([
            'CodeEleve' => 'ELE-FILE',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => $classB->CodeClasse,
            'dateinscription' => '2024-09-01',
            'Nom' => 'Student',
            'Prenom' => 'Attachment',
        ]);

        $this->post('/api/school_manager', [
            'action' => 'INSERT_CONVOCATION',
            'code' => 'PR-FILE',
            'CodeEleves' => json_encode(['ELE-FILE']),
            'CodeClasse' => $classB->CodeClasse,
            'CodeEnseignement' => 'ENS-FILE',
            'motif' => 'Indiscipline',
            'description' => 'Convocation with attachment',
            'dateConvocation' => '2026-10-01',
            'document' => UploadedFile::fake()->create(
                'convocation.pdf',
                16,
                'application/pdf'
            ),
        ])->assertOk()->assertJsonPath('status', 'success');

        $convocation = Convocation::where('code', 'PR-FILE')->firstOrFail();
        $this->assertNotEmpty($convocation->document_path);
        Storage::disk('public')->assertExists($convocation->document_path);

        $listing = $this->postJson('/api/school_manager', [
            'action' => 'GET_TEACHER_CONVOCATIONS',
            'code' => 'PR-FILE',
        ])->assertOk()->assertJsonCount(1);
        $this->assertStringEndsWith(
            Storage::disk('public')->url($convocation->document_path),
            $listing->json('0.document_url')
        );
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
