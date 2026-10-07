<?php

namespace Tests\Feature;

use App\Models\Classe;
use App\Models\Eleve;
use App\Models\Enseignement;
use App\Models\Matiere;
use App\Models\Note;
use App\Models\SequenceEvaluation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StudentSequenceMarksApiTest extends TestCase
{
    use RefreshDatabase;

    private function createClass(string $code, string $school): Classe
    {
        return Classe::create([
            'CodeClasse' => $code,
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => $code,
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => $school,
        ]);
    }

    private function createStudent(string $code, string $class, ?string $parent): Eleve
    {
        return Eleve::create([
            'CodeEleve' => $code,
            'CodeAnnee' => 'YEAR-1',
            'CodeClasse' => $class,
            'dateinscription' => '2024-09-01',
            'Nom' => $code,
            'Prenom' => 'Student',
            'code' => $parent,
        ]);
    }

    private function createMarkSet(string $class, string $school): void
    {
        SequenceEvaluation::create([
            'CodeEvaluation' => 'SEQ-1',
            'LibelleEvaluation' => 'Sequence 1',
        ]);

        foreach ([
            ['TEACH-MATH', 'MAT-MATH', 'Mathematics', '14'],
            ['TEACH-ENG', 'MAT-ENG', 'English', '16'],
        ] as [$teachingCode, $subjectCode, $subjectName, $value]) {
            Matiere::create([
                'CodeMatiere' => $subjectCode,
                'LibelleMatiere' => $subjectName,
                'ordre' => '1',
                'CodeEtablissement' => $school,
            ]);

            Enseignement::create([
                'CodeEnseignement' => $teachingCode,
                'CodeMatiere' => $subjectCode,
                'code' => 'TEACHER-1',
                'CodeClasse' => $class,
                'CodeEtablissement' => $school,
            ]);

            Note::create([
                'CodeEnseignement' => $teachingCode,
                'CodeEleve' => 'STUDENT-1',
                'CodeEvaluation' => 'SEQ-1',
                'CodeAppreciation' => null,
                'valeur' => $value,
                'coef' => '2',
                'Total' => $value,
                'Dateeng' => '2024-10-01',
                'CodeAnnee' => 'YEAR-1',
            ]);
        }
    }

    private function requestMarks(string $studentCode = 'STUDENT-1')
    {
        return $this->postJson('/api/notes/student-sequence', [
            'action' => 'GET_STUDENT_SEQUENCE_MARKS',
            'codeEleve' => $studentCode,
            'codeEvaluation' => 'SEQ-1',
        ]);
    }

    private function requestSequenceAvailability(string $studentCode = 'STUDENT-1')
    {
        return $this->postJson('/api/notes/student-sequence', [
            'action' => 'GET_STUDENT_SEQUENCE_AVAILABILITY',
            'codeEleve' => $studentCode,
        ]);
    }

    public function test_parent_can_fetch_all_sequence_marks_without_sending_a_year(): void
    {
        $class = $this->createClass('CLASS-1', 'SCHOOL-1');
        $parent = User::create([
            'code' => 'PARENT-1',
            'nom' => 'Parent',
            'prenom' => 'One',
            'sex' => 'F',
            'login' => 'parent-one',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'parent',
        ]);
        $this->createStudent('STUDENT-1', $class->CodeClasse, $parent->code);
        $this->createMarkSet($class->CodeClasse, 'SCHOOL-1');
        Sanctum::actingAs($parent, ['mobischo:mobile']);

        $response = $this->requestMarks();

        $response->assertOk()->assertJsonCount(2);
        $subjects = collect($response->json())->pluck('LibelleMatiere')->all();
        $this->assertSame(['English', 'Mathematics'], $subjects);
        $response->assertJsonFragment(['valeur' => '14']);
        $response->assertJsonFragment(['valeur' => '16']);
        $this->assertArrayNotHasKey('CodeAnnee', $response->json()[0]);
    }

    public function test_parent_cannot_fetch_another_parents_child_or_arbitrary_student(): void
    {
        $class = $this->createClass('CLASS-1', 'SCHOOL-1');
        $parent = User::create([
            'code' => 'PARENT-1',
            'nom' => 'Parent',
            'prenom' => 'One',
            'sex' => 'F',
            'login' => 'parent-one',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'parent',
        ]);
        $this->createStudent('STUDENT-1', $class->CodeClasse, 'PARENT-2');
        $this->createMarkSet($class->CodeClasse, 'SCHOOL-1');
        Sanctum::actingAs($parent, ['mobischo:mobile']);

        $this->requestMarks()->assertForbidden();
        $this->requestMarks('DOES-NOT-EXIST')->assertNotFound();
    }

    public function test_principal_can_fetch_marks_only_for_students_in_their_school(): void
    {
        $schoolClass = $this->createClass('CLASS-1', 'SCHOOL-1');
        $otherClass = $this->createClass('CLASS-2', 'SCHOOL-2');
        $principal = User::create([
            'code' => 'PRINCIPAL-1',
            'nom' => 'Principal',
            'prenom' => 'One',
            'sex' => 'F',
            'login' => 'principal-one',
            'contacts' => '222',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $this->createStudent('STUDENT-1', $schoolClass->CodeClasse, null);
        $this->createStudent('STUDENT-2', $otherClass->CodeClasse, null);
        $this->createMarkSet($schoolClass->CodeClasse, 'SCHOOL-1');
        Sanctum::actingAs($principal, ['mobischo:mobile']);

        $this->requestMarks()->assertOk()->assertJsonCount(2);
        $this->requestMarks('STUDENT-2')->assertForbidden();
    }

    public function test_valid_sequence_with_no_marks_returns_an_empty_list(): void
    {
        $class = $this->createClass('CLASS-1', 'SCHOOL-1');
        $parent = User::create([
            'code' => 'PARENT-1',
            'nom' => 'Parent',
            'prenom' => 'One',
            'sex' => 'F',
            'login' => 'parent-one',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'parent',
        ]);
        $this->createStudent('STUDENT-1', $class->CodeClasse, $parent->code);
        SequenceEvaluation::create([
            'CodeEvaluation' => 'SEQ-1',
            'LibelleEvaluation' => 'Sequence 1',
        ]);
        Sanctum::actingAs($parent, ['mobischo:mobile']);

        $this->requestMarks()->assertOk()->assertExactJson([]);
    }

    public function test_parent_sequence_availability_comes_from_the_childs_actual_marks(): void
    {
        $class = $this->createClass('CLASS-1', 'SCHOOL-1');
        $parent = User::create([
            'code' => 'PARENT-1',
            'nom' => 'Parent',
            'prenom' => 'One',
            'sex' => 'F',
            'login' => 'parent-one',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'parent',
        ]);
        $this->createStudent('STUDENT-1', $class->CodeClasse, $parent->code);
        $this->createStudent('STUDENT-2', $class->CodeClasse, 'PARENT-2');
        $this->createMarkSet($class->CodeClasse, 'SCHOOL-1');
        SequenceEvaluation::create([
            'CodeEvaluation' => 'SEQ-2',
            'LibelleEvaluation' => 'Sequence 2',
        ]);
        Note::create([
            'CodeEnseignement' => 'TEACH-MATH',
            'CodeEleve' => 'STUDENT-1',
            'CodeEvaluation' => 'SEQ-2',
            'CodeAppreciation' => null,
            'valeur' => null,
            'coef' => null,
            'Total' => null,
            'Dateeng' => '2024-10-01',
            'CodeAnnee' => 'YEAR-1',
        ]);
        Sanctum::actingAs($parent, ['mobischo:mobile']);

        $response = $this->requestSequenceAvailability();

        $response->assertOk()->assertJsonCount(2)->assertJson([
            ['CodeEvaluation' => 'SEQ-1', 'hasMarks' => true],
            ['CodeEvaluation' => 'SEQ-2', 'hasMarks' => false],
        ]);
        $this->assertArrayNotHasKey('CodeAnnee', $response->json()[0]);
        $this->requestSequenceAvailability('STUDENT-2')->assertForbidden();
    }

    public function test_sequence_availability_keeps_parent_and_principal_authorization(): void
    {
        $schoolClass = $this->createClass('CLASS-1', 'SCHOOL-1');
        $otherClass = $this->createClass('CLASS-2', 'SCHOOL-2');
        $principal = User::create([
            'code' => 'PRINCIPAL-1',
            'nom' => 'Principal',
            'prenom' => 'One',
            'sex' => 'F',
            'login' => 'principal-one',
            'contacts' => '222',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $this->createStudent('STUDENT-1', $schoolClass->CodeClasse, null);
        $this->createStudent('STUDENT-2', $otherClass->CodeClasse, null);
        $this->createMarkSet($schoolClass->CodeClasse, 'SCHOOL-1');
        Sanctum::actingAs($principal, ['mobischo:mobile']);

        $this->requestSequenceAvailability()->assertOk();
        $this->requestSequenceAvailability('STUDENT-2')->assertForbidden();
    }

    public function test_school_manager_cannot_bypass_notes_authentication(): void
    {
        $this->postJson('/api/school_manager', [
            'action' => 'GET_STUDENT_SEQUENCE_MARKS',
            'codeEleve' => 'STUDENT-1',
            'codeEvaluation' => 'SEQ-1',
        ])->assertUnauthorized();
    }
}
