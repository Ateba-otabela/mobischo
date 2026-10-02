<?php

namespace Tests\Feature;

use App\Models\AbsenceJustification;
use App\Models\Classe;
use App\Models\Conduite;
use App\Models\Eleve;
use App\Models\Enseignement;
use App\Models\EncadreurClasse;
use App\Models\InvestigationAlert;
use App\Models\Matiere;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class InvestigationAlertTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->artisan('migrate:fresh', ['--seed' => false]);
    }

    private function createJustificationParent(string $parentCode, string $login): User
    {
        return User::create([
            'code' => $parentCode,
            'nom' => 'Parent',
            'prenom' => $parentCode,
            'sex' => 'F',
            'login' => $login,
            'contacts' => '222',
            'password' => bcrypt('secret'),
            'account_type' => 'parent',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
    }

    private function createJustificationStudent(string $studentCode, string $parentCode, string $classCode = 'CL-JUST'): Eleve
    {
        Classe::firstOrCreate([
            'CodeClasse' => $classCode,
        ], [
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe Justification',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        return Eleve::create([
            'CodeEleve' => $studentCode,
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => $classCode,
            'dateinscription' => '2024-09-01',
            'Nom' => 'Student',
            'Prenom' => $studentCode,
            'Sex' => 'F',
            'code' => $parentCode,
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
    }

    private function submitJustification(string $parentCode, string $studentCode, array $overrides = [])
    {
        $parent = User::where('code', $parentCode)->firstOrFail();
        Sanctum::actingAs($parent, ['mobischo:mobile']);

        return $this->postJson('/api/parent/absence-justifications', array_merge([
            'action' => 'SUBMIT_ABSENCE_JUSTIFICATION',
            'CodeEleve' => $studentCode,
            'date_absence' => '2026-09-30',
            'reason' => 'Maladie',
            'justification' => 'Le parent signale une absence.',
        ], $overrides));
    }

    public function test_parent_can_submit_justification_for_own_child_and_default_status_is_pending(): void
    {
        $this->createJustificationParent('P-JUST-1', 'parent-just-1');
        $this->createJustificationStudent('E-JUST-1', 'P-JUST-1');

        $response = $this->submitJustification('P-JUST-1', 'E-JUST-1');

        $response->assertOk()->assertJsonPath('status', 'success');
        $justificationId = $response->json('id');
        $this->assertNotNull($justificationId);
        $this->assertDatabaseHas('absence_justifications', [
            'id' => $justificationId,
            'parent_code' => 'P-JUST-1',
            'CodeEleve' => 'E-JUST-1',
            'date_absence' => '2026-09-30',
            'motif' => 'Maladie',
            'justification' => 'Le parent signale une absence.',
            'statut' => 'En attente',
        ]);
    }

    public function test_parent_cannot_submit_justification_for_another_parents_child(): void
    {
        $this->createJustificationParent('P-JUST-1', 'parent-just-1');
        $this->createJustificationParent('P-JUST-2', 'parent-just-2');
        $this->createJustificationStudent('E-JUST-2', 'P-JUST-2');

        $this->submitJustification('P-JUST-1', 'E-JUST-2')
            ->assertForbidden()
            ->assertJson(['error' => 'Élève non autorisé.']);

        $this->assertDatabaseCount('absence_justifications', 0);
    }

    public function test_parent_can_submit_future_absence_without_attendance_record(): void
    {
        $this->createJustificationParent('P-JUST-1', 'parent-just-1');
        $this->createJustificationStudent('E-JUST-1', 'P-JUST-1');

        $today = now()->format('Y-m-d');
        $futureDate = now()->addDays(30)->format('Y-m-d');
        $this->submitJustification('P-JUST-1', 'E-JUST-1', [
            'date_absence' => $today,
        ])->assertOk()->assertJsonPath('status', 'success');
        $this->submitJustification('P-JUST-1', 'E-JUST-1', [
            'date_absence' => $futureDate,
        ])->assertOk()->assertJsonPath('status', 'success');

        $this->submitJustification('P-JUST-1', 'E-JUST-1', [
            'date_absence' => 'not-a-date',
        ])->assertUnprocessable()->assertJsonValidationErrors(['date_absence']);
        $this->submitJustification('P-JUST-1', 'E-JUST-1', [
            'reason' => 'Autre',
            'justification' => '',
        ])->assertUnprocessable()->assertJsonValidationErrors(['justification']);
        $this->submitJustification('P-JUST-1', 'E-JUST-1', [
            'reason' => '',
        ])->assertUnprocessable()->assertJsonValidationErrors(['reason']);

        $this->assertDatabaseHas('absence_justifications', [
            'CodeEleve' => 'E-JUST-1',
            'date_absence' => $futureDate,
            'reason' => 'Maladie',
            'status' => 'pending',
        ]);
        $this->assertDatabaseHas('absence_justifications', [
            'CodeEleve' => 'E-JUST-1',
            'date_absence' => $today,
            'reason' => 'Maladie',
            'status' => 'pending',
        ]);
        $this->assertDatabaseCount('conduites', 0);
    }

    public function test_parent_history_contains_own_existing_and_new_submissions_only(): void
    {
        $this->createJustificationParent('P-JUST-1', 'parent-just-1');
        $this->createJustificationParent('P-JUST-2', 'parent-just-2');
        $this->createJustificationStudent('E-JUST-1', 'P-JUST-1');
        $this->createJustificationStudent('E-JUST-2', 'P-JUST-2');

        AbsenceJustification::create([
            'parent_code' => 'P-JUST-1',
            'CodeEleve' => 'E-JUST-1',
            'date_absence' => '2026-09-29',
            'motif' => 'Rendez-vous',
            'justification' => 'Ancienne justification.',
            'statut' => 'validée',
        ]);
        AbsenceJustification::create([
            'parent_code' => 'P-JUST-2',
            'CodeEleve' => 'E-JUST-2',
            'date_absence' => '2026-09-30',
            'motif' => 'Maladie',
            'justification' => 'Autre parent.',
            'statut' => 'En attente',
        ]);
        AbsenceJustification::create([
            'parent_code' => 'P-JUST-2',
            'CodeEleve' => 'E-JUST-1',
            'date_absence' => '2026-09-28',
            'motif' => 'Maladie',
            'justification' => 'Ancien parent lié à cet enfant.',
            'statut' => 'En attente',
        ]);

        $submitted = $this->submitJustification('P-JUST-1', 'E-JUST-1');
        $submitted->assertOk()->assertJsonPath('status', 'success');

        Sanctum::actingAs(User::where('code', 'P-JUST-1')->firstOrFail(), ['mobischo:mobile']);
        $history = $this->postJson('/api/parent/absence-justifications', [
            'action' => 'GET_PARENT_ABSENCE_JUSTIFICATIONS',
        ])->assertOk();

        $this->assertCount(2, $history->json());
        $this->assertSame(
            ['E-JUST-1', 'E-JUST-1'],
            array_column($history->json(), 'CodeEleve')
        );
        $this->assertSame(
            ['En attente', 'validée'],
            array_column($history->json(), 'statut')
        );
    }

    public function test_principal_dashboard_alerts_are_limited_to_own_school(): void
    {
        $principal = User::create([
            'code' => 'PR-DASH-1',
            'nom' => 'Principal',
            'prenom' => 'One',
            'sex' => 'M',
            'login' => 'principal-dash-1',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $this->createJustificationStudent('E-DASH-1', 'P-DASH-1');
        Classe::create([
            'CodeClasse' => 'CL-DASH-OTHER',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Other School Class',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-2',
        ]);
        Eleve::create([
            'CodeEleve' => 'E-DASH-2',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-DASH-OTHER',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Other',
            'Prenom' => 'Student',
            'Sex' => 'M',
            'code' => 'P-DASH-2',
        ]);
        InvestigationAlert::create([
            'CodeEtablissement' => 'SCHOOL-1',
            'CodeEleve' => 'E-DASH-1',
            'CodeClasse' => 'CL-JUST',
            'date_absence' => '2026-10-01',
            'parent_status' => 'A',
            'teacher_status' => 'P',
            'status' => 'pending',
        ]);
        InvestigationAlert::create([
            'CodeEtablissement' => 'SCHOOL-2',
            'CodeEleve' => 'E-DASH-2',
            'CodeClasse' => 'CL-DASH-OTHER',
            'date_absence' => '2026-10-01',
            'parent_status' => 'A',
            'teacher_status' => 'P',
            'status' => 'pending',
        ]);
        Sanctum::actingAs($principal, ['mobischo:mobile']);

        $response = $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_ALERTS',
        ])->assertOk();

        $this->assertCount(1, $response->json());
        $response->assertJsonPath('0.CodeEtablissement', 'SCHOOL-1');
        $response->assertJsonPath('0.event_type', 'investigation');
    }

    public function test_encadreur_dashboard_alerts_are_limited_to_assigned_classes(): void
    {
        $encadreur = User::create([
            'code' => 'ENC-DASH-1',
            'nom' => 'Encadreur',
            'prenom' => 'One',
            'sex' => 'M',
            'login' => 'encadreur-dash-1',
            'contacts' => '222',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $this->createJustificationStudent('E-DASH-A', 'P-DASH-A', 'CL-DASH-A');
        $this->createJustificationStudent('E-DASH-B', 'P-DASH-B', 'CL-DASH-B');
        EncadreurClasse::create([
            'code' => 'ENC-DASH-1',
            'CodeClasse' => 'CL-DASH-A',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        foreach ([
            ['E-DASH-A', 'CL-DASH-A'],
            ['E-DASH-B', 'CL-DASH-B'],
        ] as [$studentCode, $classCode]) {
            InvestigationAlert::create([
                'CodeEtablissement' => 'SCHOOL-1',
                'CodeEleve' => $studentCode,
                'CodeClasse' => $classCode,
                'date_absence' => '2026-10-01',
                'parent_status' => 'A',
                'teacher_status' => 'P',
                'status' => 'pending',
            ]);
        }
        Sanctum::actingAs($encadreur, ['mobischo:mobile']);

        $response = $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_ALERTS',
        ])->assertOk();

        $this->assertCount(1, $response->json());
        $response->assertJsonPath('0.CodeClasse', 'CL-DASH-A');
    }

    public function test_principal_dashboard_returns_absence_and_late_attendance_events(): void
    {
        $principal = User::create([
            'code' => 'PR-DASH-ATT',
            'nom' => 'Principal',
            'prenom' => 'Attendance',
            'sex' => 'M',
            'login' => 'principal-dash-att',
            'contacts' => '333',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $this->createJustificationStudent('E-DASH-ATT', 'P-DASH-ATT');
        foreach ([
            ['2026-10-01', 'A'],
            ['2026-10-02', 'R'],
            ['2026-10-03', 'P'],
        ] as [$date, $status]) {
            Conduite::create([
                'DateEnreg' => $date,
                'CodeEleve' => 'E-DASH-ATT',
                'CodeEtatCond' => $status,
                'CodeClasse' => 'CL-JUST',
                'CodeAnnee' => 'AN-1',
            ]);
        }
        Sanctum::actingAs($principal, ['mobischo:mobile']);

        $response = $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_ALERTS',
        ])->assertOk();

        $attendanceEvents = array_values(array_filter(
            $response->json(),
            fn ($event) => $event['event_type'] === 'attendance'
        ));
        $this->assertCount(2, $attendanceEvents);
        $this->assertEqualsCanonicalizing(
            ['A', 'R'],
            array_column($attendanceEvents, 'teacher_status')
        );
        $this->assertSame(
            ['2026-10-02', '2026-10-01'],
            array_column($attendanceEvents, 'date_absence')
        );
    }

    public function test_dashboard_does_not_return_attendance_for_student_outside_event_class(): void
    {
        $principal = User::create([
            'code' => 'PR-DASH-SCOPE',
            'nom' => 'Principal',
            'prenom' => 'Scope',
            'sex' => 'M',
            'login' => 'principal-dash-scope',
            'contacts' => '333',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        Classe::create([
            'CodeClasse' => 'CL-OTHER-SCHOOL',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Other school class',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-2',
        ]);
        Eleve::create([
            'CodeEleve' => 'E-OTHER-SCHOOL',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-OTHER-SCHOOL',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Other',
            'Prenom' => 'Student',
            'Sex' => 'M',
            'code' => 'P-OTHER-SCHOOL',
            'CodeEtablissement' => 'SCHOOL-2',
        ]);
        Conduite::create([
            'DateEnreg' => '2026-10-01',
            'CodeEleve' => 'E-OTHER-SCHOOL',
            'CodeEtatCond' => 'A',
            'CodeClasse' => 'CL-JUST',
            'CodeAnnee' => 'AN-1',
        ]);
        Sanctum::actingAs($principal, ['mobischo:mobile']);

        $response = $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_ALERTS',
        ])->assertOk();

        $this->assertSame([], $response->json());
    }

    public function test_parent_cannot_read_dashboard_alerts(): void
    {
        $parent = $this->createJustificationParent('P-DASH-PARENT', 'parent-dash');
        Sanctum::actingAs($parent, ['mobischo:mobile']);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_ALERTS',
        ])->assertForbidden();
    }

    public function test_submission_requires_an_authenticated_parent_even_on_legacy_action_route(): void
    {
        $response = $this->postJson('/api/school_manager', [
            'action' => 'SUBMIT_ABSENCE_JUSTIFICATION',
            'code' => 'P-JUST-1',
            'CodeEleve' => 'E-JUST-1',
            'date_absence' => '2026-10-30',
            'reason' => 'Maladie',
        ]);

        $response->assertForbidden()->assertJson([
            'error' => 'Parent non autorisé.',
        ]);
    }

    public function test_parent_can_upload_a_supported_document_with_the_justification(): void
    {
        Storage::fake('public');
        $parent = $this->createJustificationParent('P-JUST-1', 'parent-just-1');
        $this->createJustificationStudent('E-JUST-1', 'P-JUST-1');
        Sanctum::actingAs($parent, ['mobischo:mobile']);

        $response = $this->post('/api/parent/absence-justifications', [
            'action' => 'SUBMIT_ABSENCE_JUSTIFICATION',
            'CodeEleve' => 'E-JUST-1',
            'date_absence' => '2026-10-30',
            'reason' => 'Rendez-vous médical',
            'justification' => 'Consultation médicale programmée.',
            'document' => UploadedFile::fake()
                ->createWithContent('certificat.pdf', "%PDF-1.4\nTest document\n")
                ->mimeType('application/pdf'),
        ]);

        $response->assertOk()->assertJsonPath('status', 'success');
        $path = AbsenceJustification::firstOrFail()->document_path;
        $this->assertNotEmpty($path);
        Storage::disk('public')->assertExists($path);
    }

    public function test_parent_absent_and_teacher_present_creates_investigation_alert(): void
    {
        $teacher = User::create([
            'code' => 'T-INV-1',
            'nom' => 'Teacher',
            'prenom' => 'One',
            'sex' => 'M',
            'login' => 'teacher1',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'enseignant',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $class = Classe::create([
            'CodeClasse' => 'CL-INV',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe Investigation',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Matiere::create([
            'CodeMatiere' => 'MAT-INV',
            'LibelleMatiere' => 'Mathématiques',
            'ordre' => '1',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $course = Enseignement::create([
            'CodeEnseignement' => 'ENS-INV',
            'CodeMatiere' => 'MAT-INV',
            'code' => 'T-INV-1',
            'CodeClasse' => 'CL-INV',
            'CodeEtablissement' => 'SCHOOL-1',
            'NBRHEURE' => '1',
        ]);

        $student = Eleve::create([
            'CodeEleve' => 'ELE-INV-1',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-INV',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Ibrahim',
            'Prenom' => 'Aissatou',
            'Sex' => 'F',
            'code' => 'P-INV-1',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        User::create([
            'code' => 'P-INV-1',
            'nom' => 'Parent',
            'prenom' => 'One',
            'sex' => 'F',
            'login' => 'parentinv',
            'contacts' => '222',
            'password' => bcrypt('secret'),
            'account_type' => 'parent',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        AbsenceJustification::create([
            'parent_code' => 'P-INV-1',
            'CodeEleve' => 'ELE-INV-1',
            'date_absence' => '2026-09-28',
            'motif' => 'Maladie',
            'justification' => 'Le parent signale une absence.',
            'statut' => 'En attente',
        ]);

        $response = $this->postJson('/api/school_manager', [
            'action' => 'SAVE_TEACHER_ATTENDANCE',
            'CodeEnseignement' => 'ENS-INV',
            'teacher_code' => 'T-INV-1',
            'DateEnreg' => '2026-09-28',
            'CodeAnnee' => 'AN-1',
            'statuses' => [[
                'CodeEleve' => 'ELE-INV-1',
                'status' => 'P',
            ]],
        ]);

        $response->assertOk();
        $this->assertSame(1, InvestigationAlert::count());
        $this->assertSame('pending', InvestigationAlert::first()->status);
        $this->assertSame('CL-INV', InvestigationAlert::first()->CodeClasse);
    }

    public function test_parent_absent_and_teacher_absent_does_not_create_investigation_alert(): void
    {
        $teacher = User::create([
            'code' => 'T-INV-2',
            'nom' => 'Teacher',
            'prenom' => 'Two',
            'sex' => 'M',
            'login' => 'teacher2',
            'contacts' => '113',
            'password' => bcrypt('secret'),
            'account_type' => 'enseignant',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Classe::create([
            'CodeClasse' => 'CL-INV-2',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe Investigation 2',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Matiere::create([
            'CodeMatiere' => 'MAT-INV-2',
            'LibelleMatiere' => 'Français',
            'ordre' => '1',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Enseignement::create([
            'CodeEnseignement' => 'ENS-INV-2',
            'CodeMatiere' => 'MAT-INV-2',
            'code' => 'T-INV-2',
            'CodeClasse' => 'CL-INV-2',
            'CodeEtablissement' => 'SCHOOL-1',
            'NBRHEURE' => '1',
        ]);

        Eleve::create([
            'CodeEleve' => 'ELE-INV-2',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-INV-2',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Hugo',
            'Prenom' => 'Mila',
            'Sex' => 'F',
            'code' => 'P-INV-2',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        User::create([
            'code' => 'P-INV-2',
            'nom' => 'Parent',
            'prenom' => 'Two',
            'sex' => 'F',
            'login' => 'parentinv2',
            'contacts' => '223',
            'password' => bcrypt('secret'),
            'account_type' => 'parent',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        AbsenceJustification::create([
            'parent_code' => 'P-INV-2',
            'CodeEleve' => 'ELE-INV-2',
            'date_absence' => '2026-09-29',
            'motif' => 'Rendez-vous',
            'justification' => 'Le parent signale une absence.',
            'statut' => 'En attente',
        ]);

        $response = $this->postJson('/api/school_manager', [
            'action' => 'SAVE_TEACHER_ATTENDANCE',
            'CodeEnseignement' => 'ENS-INV-2',
            'teacher_code' => 'T-INV-2',
            'DateEnreg' => '2026-09-29',
            'CodeAnnee' => 'AN-1',
            'statuses' => [[
                'CodeEleve' => 'ELE-INV-2',
                'status' => 'A',
            ]],
        ]);

        $response->assertOk();
        $this->assertSame(0, InvestigationAlert::count());
    }

    public function test_encadreur_sees_only_assigned_class_investigations(): void
    {
        $encadreur = User::create([
            'code' => 'ENC-INV',
            'nom' => 'Encadreur',
            'prenom' => 'One',
            'sex' => 'M',
            'login' => 'encinv',
            'contacts' => '444',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Classe::create([
            'CodeClasse' => 'CL-INV-A',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe A',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Classe::create([
            'CodeClasse' => 'CL-INV-B',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe B',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        EncadreurClasse::create([
            'code' => 'ENC-INV',
            'CodeClasse' => 'CL-INV-A',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $studentA = Eleve::create([
            'CodeEleve' => 'ELE-INV-A',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-INV-A',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Alpha',
            'Prenom' => 'A',
            'Sex' => 'M',
            'code' => 'P-INV-A',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        $studentB = Eleve::create([
            'CodeEleve' => 'ELE-INV-B',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => 'CL-INV-B',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Beta',
            'Prenom' => 'B',
            'Sex' => 'F',
            'code' => 'P-INV-B',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        AbsenceJustification::create([
            'parent_code' => 'P-INV-A',
            'CodeEleve' => 'ELE-INV-A',
            'date_absence' => '2026-09-30',
            'motif' => 'Maladie',
            'justification' => 'Absence signalée',
            'statut' => 'En attente',
        ]);

        AbsenceJustification::create([
            'parent_code' => 'P-INV-B',
            'CodeEleve' => 'ELE-INV-B',
            'date_absence' => '2026-09-30',
            'motif' => 'Maladie',
            'justification' => 'Absence signalée',
            'statut' => 'En attente',
        ]);

        $first = InvestigationAlert::create([
            'CodeEtablissement' => 'SCHOOL-1',
            'CodeEleve' => 'ELE-INV-A',
            'CodeClasse' => 'CL-INV-A',
            'CodeEnseignement' => 'ENS-1',
            'CodeMatiere' => 'MAT-1',
            'date_absence' => '2026-09-30',
            'teacher_status' => 'P',
            'parent_status' => 'A',
            'status' => 'pending',
            'notes' => 'Mismatch',
        ]);

        InvestigationAlert::create([
            'CodeEtablissement' => 'SCHOOL-1',
            'CodeEleve' => 'ELE-INV-B',
            'CodeClasse' => 'CL-INV-B',
            'CodeEnseignement' => 'ENS-2',
            'CodeMatiere' => 'MAT-2',
            'date_absence' => '2026-09-30',
            'teacher_status' => 'P',
            'parent_status' => 'A',
            'status' => 'pending',
            'notes' => 'Mismatch',
        ]);

        $response = $this->postJson('/api/school_manager', [
            'action' => 'GET_INVESTIGATIONS',
            'code' => 'ENC-INV',
        ]);

        $response->assertOk();
        $codes = array_map(fn ($item) => $item['CodeClasse'], $response->json());
        $this->assertSame(['CL-INV-A'], array_values(array_unique($codes)));
    }
}
