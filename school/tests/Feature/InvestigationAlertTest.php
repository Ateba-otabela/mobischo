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
use App\Models\TeacherAttendance;
use App\Models\User;
use App\Http\Controllers\API;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
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

    private function createJustificationStudent(
        string $studentCode,
        string $parentCode,
        string $classCode = 'CL-JUST',
        string $schoolCode = 'SCHOOL-1'
    ): Eleve
    {
        Classe::firstOrCreate([
            'CodeClasse' => $classCode,
        ], [
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe Justification',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => $schoolCode,
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
            'CodeEtablissement' => $schoolCode,
        ]);
    }

    private function createDashboardJustification(
        string $studentCode,
        string $schoolCode,
        string $absenceDate,
        string $reason,
        string $createdAt,
        string $status = 'pending',
        string $legacyColumns = ''
    ): void {
        $legacyFields = explode(',', $legacyColumns);
        DB::table('absence_justifications')->insert([
            'CodeEleve' => $studentCode,
            'CodeEtablissement' => $schoolCode,
            'absence_date' => in_array('date', $legacyFields, true) ? $absenceDate : null,
            'date_absence' => in_array('date', $legacyFields, true) ? null : $absenceDate,
            'reason' => $reason,
            'motif' => in_array('reason', $legacyFields, true) ? '' : $reason,
            'justification' => 'Explication',
            'status' => $status,
            'statut' => in_array('status', $legacyFields, true) ? '' : 'En attente',
            'parent_code' => 'P-DASH-J',
            'created_at' => $createdAt,
            'updated_at' => $createdAt,
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

    public function test_principal_dashboard_justifications_are_school_scoped_and_limited_to_three_latest(): void
    {
        $principal = User::create([
            'code' => 'PR-JUST-DASH',
            'nom' => 'Principal',
            'prenom' => 'Justifications',
            'sex' => 'M',
            'login' => 'principal-just-dash',
            'contacts' => '333',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        foreach (range(1, 4) as $index) {
            $studentCode = "E-JUST-DASH-$index";
            $this->createJustificationStudent($studentCode, "P-$studentCode");
            $this->createDashboardJustification(
                $studentCode,
                'SCHOOL-1',
                "2026-10-0$index",
                "Motif $index",
                sprintf('2026-10-01 00:00:%02d', $index),
                legacyColumns: $index === 4 ? 'date,reason,status' : ''
            );
        }

        $this->createJustificationStudent(
            'E-JUST-DASH-OTHER',
            'P-JUST-DASH-OTHER',
            'CL-JUST-DASH-OTHER',
            'SCHOOL-2'
        );
        $this->createDashboardJustification(
            'E-JUST-DASH-OTHER',
            'SCHOOL-2',
            '2026-10-31',
            'Autre école',
            '2026-10-31 00:00:00'
        );

        Sanctum::actingAs($principal, ['mobischo:mobile']);
        $response = $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_JUSTIFICATIONS',
            'CodeEtablissement' => 'SCHOOL-2',
            'per_page' => 3,
        ])->assertOk();

        $this->assertCount(3, $response->json('data'));
        $this->assertSame(4, $response->json('total'));
        $this->assertSame(
            ['E-JUST-DASH-4', 'E-JUST-DASH-3', 'E-JUST-DASH-2'],
            array_column($response->json('data'), 'CodeEleve')
        );
        $response
            ->assertJsonPath('data.0.student_name', 'Student E-JUST-DASH-4')
            ->assertJsonPath('data.0.class_name', 'Classe Justification')
            ->assertJsonPath('data.0.reason', 'Motif 4')
            ->assertJsonPath('data.0.absence_date', '2026-10-04')
            ->assertJsonPath('data.0.status', 'pending');
    }

    public function test_encadreur_dashboard_justifications_are_limited_to_assigned_classes(): void
    {
        $encadreur = User::create([
            'code' => 'ENC-JUST-DASH',
            'nom' => 'Encadreur',
            'prenom' => 'Justifications',
            'sex' => 'M',
            'login' => 'encadreur-just-dash',
            'contacts' => '333',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        foreach ([
            ['E-JUST-DASH-A', 'CL-JUST-DASH-A'],
            ['E-JUST-DASH-B', 'CL-JUST-DASH-B'],
        ] as [$studentCode, $classCode]) {
            $this->createJustificationStudent($studentCode, "P-$studentCode", $classCode);
            $this->createDashboardJustification(
                $studentCode,
                'SCHOOL-1',
                '2026-10-01',
                $classCode,
                "2026-10-01 00:00:0".($studentCode === 'E-JUST-DASH-A' ? '1' : '2')
            );
        }
        EncadreurClasse::create([
            'code' => 'ENC-JUST-DASH',
            'CodeClasse' => 'CL-JUST-DASH-A',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);

        Sanctum::actingAs($encadreur, ['mobischo:mobile']);
        $response = $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_JUSTIFICATIONS',
            'CodeEtablissement' => 'SCHOOL-2',
            'CodeClasse' => 'CL-JUST-DASH-B',
            'per_page' => 20,
        ])->assertOk();

        $this->assertCount(1, $response->json('data'));
        $response->assertJsonPath('data.0.CodeEleve', 'E-JUST-DASH-A');
        $response->assertJsonPath('data.0.CodeClasse', 'CL-JUST-DASH-A');
    }

    public function test_parent_cannot_access_dashboard_justifications(): void
    {
        $parent = $this->createJustificationParent('P-JUST-DASH-NO', 'parent-just-dash-no');
        Sanctum::actingAs($parent, ['mobischo:mobile']);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_JUSTIFICATIONS',
        ])->assertForbidden();
    }

    public function test_principal_can_view_and_validate_a_pending_absence_justification_once(): void
    {
        $principal = User::create([
            'code' => 'PR-JUST-VALIDATE',
            'nom' => 'Principal',
            'prenom' => 'Validate',
            'sex' => 'M',
            'login' => 'principal-just-validate',
            'contacts' => '333',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $fixture = $this->createAttendanceMismatchFixture(['E-JUST-VALIDATE']);
        $this->createDashboardJustification(
            'E-JUST-VALIDATE',
            'SCHOOL-1',
            '2026-10-03',
            'Rendez-vous médical',
            '2026-10-01 12:00:00'
        );
        $id = (int) DB::table('absence_justifications')
            ->where('CodeEleve', 'E-JUST-VALIDATE')
            ->value('id');
        DB::table('absence_justifications')
            ->where('id', $id)
            ->update(['absence_date' => '2026-10-03']);
        Sanctum::actingAs($principal, ['mobischo:mobile']);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_JUSTIFICATION_DETAIL',
            'id' => $id,
        ])->assertOk()
            ->assertJsonPath('justification.student_name', 'Student E-JUST-VALIDATE')
            ->assertJsonPath('justification.CodeEtablissement', 'SCHOOL-1')
            ->assertJsonPath('justification.CodeClasse', 'CL-MISMATCH')
            ->assertJsonPath('justification.absence_date', '2026-10-03')
            ->assertJsonPath('justification.parent_attendance_status', 'A')
            ->assertJsonPath('justification.status', 'En attente');

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'VALIDATE_DASHBOARD_JUSTIFICATION',
            'id' => $id,
        ])->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('message', 'Absence validée.')
            ->assertJsonPath('justification.status', 'validée')
            ->assertJsonPath('justification.parent_attendance_status', 'A');

        $this->assertDatabaseHas('absence_justifications', [
            'id' => $id,
            'status' => 'approved',
            'statut' => 'validée',
            'reviewed_by' => 'PR-JUST-VALIDATE',
        ]);
        $this->assertNotNull(
            DB::table('absence_justifications')->where('id', $id)->value('reviewed_at')
        );

        Conduite::create([
            'DateEnreg' => '2026-10-03',
            'CodeEleve' => 'E-JUST-VALIDATE',
            'CodeEtatCond' => 'P',
            'CodeClasse' => 'CL-MISMATCH',
            'CodeAnnee' => 'AN-1',
            'CodeMatiere' => 'MAT-MISMATCH',
            'CodeEnseignement' => $fixture['course_code'],
        ]);
        $alertHelper = new \ReflectionMethod(
            API::class,
            'createInvestigationAlertsForAttendance'
        );
        $alertHelper->setAccessible(true);
        $alertHelper->invoke(
            new API(),
            Enseignement::where('CodeEnseignement', $fixture['course_code'])->firstOrFail(),
            '2026-10-03'
        );
        $this->assertDatabaseHas('investigation_alerts', [
            'CodeEleve' => 'E-JUST-VALIDATE',
            'parent_status' => 'A',
            'teacher_status' => 'P',
        ]);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'VALIDATE_DASHBOARD_JUSTIFICATION',
            'id' => $id,
        ])->assertStatus(409);
    }

    public function test_principal_cannot_view_or_validate_another_schools_justification(): void
    {
        $principal = User::create([
            'code' => 'PR-JUST-OTHER-SCHOOL',
            'nom' => 'Principal',
            'prenom' => 'School',
            'sex' => 'M',
            'login' => 'principal-just-other-school',
            'contacts' => '333',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $this->createJustificationStudent(
            'E-JUST-OTHER-SCHOOL',
            'P-JUST-OTHER',
            'CL-JUST-OTHER',
            'SCHOOL-2'
        );
        $this->createDashboardJustification(
            'E-JUST-OTHER-SCHOOL',
            'SCHOOL-2',
            '2026-10-03',
            'Autre école',
            '2026-10-01 12:00:00'
        );
        $id = (int) DB::table('absence_justifications')
            ->where('CodeEleve', 'E-JUST-OTHER-SCHOOL')
            ->value('id');
        Sanctum::actingAs($principal, ['mobischo:mobile']);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_JUSTIFICATION_DETAIL',
            'id' => $id,
        ])->assertNotFound();
        $this->postJson('/api/dashboard/alerts', [
            'action' => 'VALIDATE_DASHBOARD_JUSTIFICATION',
            'id' => $id,
        ])->assertNotFound();
        $this->assertDatabaseHas('absence_justifications', [
            'id' => $id,
            'status' => 'pending',
        ]);
    }

    public function test_encadreur_can_only_view_and_validate_justifications_for_assigned_classes(): void
    {
        $encadreur = User::create([
            'code' => 'ENC-JUST-VALIDATE',
            'nom' => 'Encadreur',
            'prenom' => 'Validate',
            'sex' => 'M',
            'login' => 'encadreur-just-validate',
            'contacts' => '333',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        foreach ([
            ['E-JUST-ASSIGNED', 'CL-JUST-ASSIGNED'],
            ['E-JUST-UNASSIGNED', 'CL-JUST-UNASSIGNED'],
        ] as [$studentCode, $classCode]) {
            $this->createJustificationStudent(
                $studentCode,
                "P-$studentCode",
                $classCode
            );
            $this->createDashboardJustification(
                $studentCode,
                'SCHOOL-1',
                '2026-10-03',
                $studentCode,
                '2026-10-01 12:00:00'
            );
        }
        EncadreurClasse::create([
            'code' => 'ENC-JUST-VALIDATE',
            'CodeClasse' => 'CL-JUST-ASSIGNED',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $assignedId = (int) DB::table('absence_justifications')
            ->where('CodeEleve', 'E-JUST-ASSIGNED')
            ->value('id');
        $unassignedId = (int) DB::table('absence_justifications')
            ->where('CodeEleve', 'E-JUST-UNASSIGNED')
            ->value('id');
        Sanctum::actingAs($encadreur, ['mobischo:mobile']);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_JUSTIFICATION_DETAIL',
            'id' => $assignedId,
        ])->assertOk()
            ->assertJsonPath('justification.CodeClasse', 'CL-JUST-ASSIGNED');
        $this->postJson('/api/dashboard/alerts', [
            'action' => 'VALIDATE_DASHBOARD_JUSTIFICATION',
            'id' => $assignedId,
        ])->assertOk()
            ->assertJsonPath('justification.status', 'validée');
        $this->assertDatabaseHas('absence_justifications', [
            'id' => $assignedId,
            'status' => 'approved',
            'statut' => 'validée',
        ]);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'GET_DASHBOARD_JUSTIFICATION_DETAIL',
            'id' => $unassignedId,
        ])->assertNotFound();
        $this->postJson('/api/dashboard/alerts', [
            'action' => 'VALIDATE_DASHBOARD_JUSTIFICATION',
            'id' => $unassignedId,
        ])->assertForbidden();
        $this->assertDatabaseHas('absence_justifications', [
            'id' => $unassignedId,
            'status' => 'pending',
        ]);
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

    public function test_validating_investigation_updates_exact_attendance_and_resolves_alert_once(): void
    {
        $fixture = $this->createPendingInvestigationValidationFixture(
            'ELE-INV-VALIDATE',
            'PR-INV-VALIDATE'
        );
        $principal = $fixture['principal'];
        $attendance = $fixture['attendance'];
        $alert = $fixture['alert'];
        Sanctum::actingAs($principal, ['mobischo:mobile']);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'UPDATE_DASHBOARD_ALERT',
            'id' => $alert->id,
            'status' => 'validated',
            'teacher_code' => 'T-UNTRUSTED',
        ])->assertOk()
            ->assertJsonPath('alert.status', 'validated')
            ->assertJsonPath('alert.resolved_by', 'PR-INV-VALIDATE');

        $this->assertDatabaseHas('conduites', [
            'id' => $attendance->id,
            'CodeEleve' => 'ELE-INV-VALIDATE',
            'CodeClasse' => 'CL-MISMATCH',
            'CodeEnseignement' => $fixture['course_code'],
            'CodeMatiere' => 'MAT-MISMATCH',
            'DateEnreg' => '2026-09-28',
            'CodeEtatCond' => 'A',
        ]);
        $this->assertDatabaseHas('teacher_attendances', [
            'CodeEtablissement' => 'SCHOOL-1',
            'CodeEnseignant' => $fixture['teacher_code'],
            'CodeEnseignement' => $fixture['course_code'],
            'CodeClasse' => 'CL-MISMATCH',
            'CodeMatiere' => 'MAT-MISMATCH',
            'attendance_date' => '2026-09-28',
            'session_time' => '1',
            'presence_status' => 'present',
        ]);
        $this->assertDatabaseHas('investigation_alerts', [
            'id' => $alert->id,
            'status' => 'validated',
            'resolved_by' => 'PR-INV-VALIDATE',
        ]);
        $this->assertNotNull(
            DB::table('investigation_alerts')
                ->where('id', $alert->id)
                ->value('resolved_at')
        );
        $this->assertDatabaseHas('absence_justifications', [
            'CodeEleve' => 'ELE-INV-VALIDATE',
            'status' => 'approved',
            'statut' => 'validée',
        ]);
        $this->withoutMiddleware(\Illuminate\Routing\Middleware\ThrottleRequests::class);
        $this->postJson('/api/school_manager', [
            'action' => 'GET_PRINCIPAL_ATTENDANCE',
        ])->assertOk()
            ->assertJsonFragment([
                'teacher_presence_status' => 'present',
            ]);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'UPDATE_DASHBOARD_ALERT',
            'id' => $alert->id,
            'status' => 'validated',
        ])->assertStatus(409);
    }

    public function test_validation_updates_existing_teacher_presence_without_duplicating_it(): void
    {
        $fixture = $this->createPendingInvestigationValidationFixture(
            'ELE-INV-UPDATE-PRESENCE',
            'PR-INV-UPDATE-PRESENCE'
        );
        $sessionKey = TeacherAttendance::makeSessionKey(
            'SCHOOL-1',
            $fixture['teacher_code'],
            $fixture['course_code'],
            'CL-MISMATCH',
            'MAT-MISMATCH',
            '2026-09-28',
            '1'
        );
        TeacherAttendance::create([
            'session_key' => $sessionKey,
            'CodeEtablissement' => 'SCHOOL-1',
            'CodeEnseignant' => $fixture['teacher_code'],
            'CodeEnseignement' => $fixture['course_code'],
            'CodeClasse' => 'CL-MISMATCH',
            'CodeMatiere' => 'MAT-MISMATCH',
            'attendance_date' => '2026-09-28',
            'session_time' => '1',
            'presence_status' => 'absent',
        ]);
        Sanctum::actingAs($fixture['principal'], ['mobischo:mobile']);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'UPDATE_DASHBOARD_ALERT',
            'id' => $fixture['alert']->id,
            'status' => 'validated',
        ])->assertOk();

        $this->assertSame(1, TeacherAttendance::where('session_key', $sessionKey)->count());
        $this->assertDatabaseHas('teacher_attendances', [
            'session_key' => $sessionKey,
            'presence_status' => 'present',
        ]);
    }

    public function test_validation_rolls_back_when_teacher_presence_write_fails(): void
    {
        $fixture = $this->createPendingInvestigationValidationFixture(
            'ELE-INV-PRESENCE-FAIL',
            'PR-INV-PRESENCE-FAIL'
        );
        Sanctum::actingAs($fixture['principal'], ['mobischo:mobile']);
        $eventName = 'eloquent.saving: '.TeacherAttendance::class;
        Event::listen($eventName, static function () {
            throw new \RuntimeException('Teacher presence write failed.');
        });

        try {
            $this->postJson('/api/dashboard/alerts', [
                'action' => 'UPDATE_DASHBOARD_ALERT',
                'id' => $fixture['alert']->id,
                'status' => 'validated',
            ]);
        } catch (\RuntimeException $exception) {
            $this->assertSame('Teacher presence write failed.', $exception->getMessage());
        } finally {
            Event::forget($eventName);
        }

        $this->assertDatabaseHas('investigation_alerts', [
            'id' => $fixture['alert']->id,
            'status' => 'pending',
        ]);
        $this->assertDatabaseMissing('teacher_attendances', [
            'session_key' => TeacherAttendance::makeSessionKey(
                'SCHOOL-1',
                $fixture['teacher_code'],
                $fixture['course_code'],
                'CL-MISMATCH',
                'MAT-MISMATCH',
                '2026-09-28',
                '1'
            ),
        ]);
        $this->assertDatabaseHas('conduites', [
            'id' => $fixture['attendance']->id,
            'CodeEtatCond' => 'A',
        ]);
    }

    public function test_principal_cannot_validate_an_investigation_from_another_school(): void
    {
        $fixture = $this->createPendingInvestigationValidationFixture(
            'ELE-INV-OTHER-SCHOOL',
            'PR-INV-OTHER-SCHOOL'
        );
        $fixture['alert']->CodeEtablissement = 'SCHOOL-2';
        $fixture['alert']->save();
        Sanctum::actingAs($fixture['principal'], ['mobischo:mobile']);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'UPDATE_DASHBOARD_ALERT',
            'id' => $fixture['alert']->id,
            'status' => 'validated',
        ])->assertNotFound();

        $this->assertDatabaseHas('investigation_alerts', [
            'id' => $fixture['alert']->id,
            'status' => 'pending',
        ]);
        $this->assertDatabaseCount('teacher_attendances', 0);
    }

    public function test_encadreur_can_validate_only_an_assigned_class_investigation(): void
    {
        $fixture = $this->createPendingInvestigationValidationFixture(
            'ELE-INV-ENC-SCOPE',
            'PR-INV-ENC-SCOPE'
        );
        $encadreur = User::create([
            'code' => 'ENC-INV-SCOPE',
            'nom' => 'Encadreur',
            'prenom' => 'Scope',
            'sex' => 'M',
            'login' => 'enc-investigation-scope',
            'contacts' => '334',
            'password' => bcrypt('secret'),
            'account_type' => 'encadreur',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        EncadreurClasse::create([
            'code' => 'ENC-INV-SCOPE',
            'CodeClasse' => 'CL-MISMATCH',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $unassignedAlert = InvestigationAlert::create([
            'CodeEtablissement' => 'SCHOOL-1',
            'CodeEleve' => 'ELE-INV-ENC-SCOPE',
            'CodeClasse' => 'UNASSIGNED-CLASS',
            'CodeEnseignement' => 'UNASSIGNED-COURSE',
            'CodeMatiere' => 'UNASSIGNED-SUBJECT',
            'date_absence' => '2026-09-28',
            'parent_status' => 'A',
            'teacher_status' => 'P',
            'status' => 'pending',
        ]);
        Sanctum::actingAs($encadreur, ['mobischo:mobile']);

        $this->postJson('/api/dashboard/alerts', [
            'action' => 'UPDATE_DASHBOARD_ALERT',
            'id' => $fixture['alert']->id,
            'status' => 'validated',
        ])->assertOk();
        $this->postJson('/api/dashboard/alerts', [
            'action' => 'UPDATE_DASHBOARD_ALERT',
            'id' => $unassignedAlert->id,
            'status' => 'validated',
        ])->assertForbidden();

        $this->assertDatabaseHas('investigation_alerts', [
            'id' => $unassignedAlert->id,
            'status' => 'pending',
        ]);
        $this->assertDatabaseCount('teacher_attendances', 1);
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

    private function createAttendanceMismatchFixture(array $studentCodes): array
    {
        User::create([
            'code' => 'T-MISMATCH',
            'nom' => 'Teacher',
            'prenom' => 'One',
            'sex' => 'M',
            'login' => 'teacher-mismatch',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'enseignant',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        Classe::create([
            'CodeClasse' => 'CL-MISMATCH',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Classe Investigation',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        Matiere::create([
            'CodeMatiere' => 'MAT-MISMATCH',
            'LibelleMatiere' => 'Mathématiques',
            'ordre' => '1',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        Enseignement::create([
            'CodeEnseignement' => 'ENS-MISMATCH',
            'CodeMatiere' => 'MAT-MISMATCH',
            'code' => 'T-MISMATCH',
            'CodeClasse' => 'CL-MISMATCH',
            'CodeEtablissement' => 'SCHOOL-1',
            'NBRHEURE' => '1',
        ]);

        foreach ($studentCodes as $studentCode) {
            Eleve::create([
                'CodeEleve' => $studentCode,
                'CodeAnnee' => 'AN-1',
                'CodeClasse' => 'CL-MISMATCH',
                'dateinscription' => '2024-09-01',
                'Nom' => 'Student',
                'Prenom' => $studentCode,
                'Sex' => 'F',
                'code' => 'P-'.$studentCode,
                'CodeEtablissement' => 'SCHOOL-1',
            ]);
        }

        return [
            'course_code' => 'ENS-MISMATCH',
            'teacher_code' => 'T-MISMATCH',
        ];
    }

    private function createPendingInvestigationValidationFixture(
        string $studentCode,
        string $principalCode
    ): array {
        $principal = User::create([
            'code' => $principalCode,
            'nom' => 'Principal',
            'prenom' => 'Investigation',
            'sex' => 'M',
            'login' => strtolower($principalCode),
            'contacts' => '333',
            'password' => bcrypt('secret'),
            'account_type' => 'principal',
            'CodeEtablissement' => 'SCHOOL-1',
        ]);
        $fixture = $this->createAttendanceMismatchFixture([$studentCode]);
        DB::table('absence_justifications')->insert([
            'CodeEleve' => $studentCode,
            'CodeEtablissement' => 'SCHOOL-1',
            'absence_date' => '2026-09-28',
            'date_absence' => '2026-09-28',
            'reason' => 'Rendez-vous médical',
            'motif' => 'Rendez-vous médical',
            'justification' => 'Parent absence declaration',
            'status' => 'approved',
            'statut' => 'validée',
            'parent_code' => 'P-'.$studentCode,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $attendance = Conduite::create([
            'DateEnreg' => '2026-09-28',
            'CodeEleve' => $studentCode,
            'CodeEtatCond' => 'A',
            'CodeClasse' => 'CL-MISMATCH',
            'CodeAnnee' => 'AN-1',
            'CodeMatiere' => 'MAT-MISMATCH',
            'CodeEnseignement' => $fixture['course_code'],
            'HeureMatiere' => '1',
        ]);
        $alert = InvestigationAlert::create([
            'CodeEtablissement' => 'SCHOOL-1',
            'CodeEleve' => $studentCode,
            'CodeClasse' => 'CL-MISMATCH',
            'CodeEnseignement' => $fixture['course_code'],
            'CodeMatiere' => 'MAT-MISMATCH',
            'date_absence' => '2026-09-28',
            'parent_status' => 'A',
            'teacher_status' => 'P',
            'status' => 'pending',
            'notes' => 'Parent justification exists, but student appeared in teacher roll call.',
        ]);

        return $fixture + [
            'principal' => $principal,
            'attendance' => $attendance,
            'alert' => $alert,
            'student_code' => $studentCode,
        ];
    }

    private function addAttendanceJustification(
        string $studentCode,
        string $absenceDate,
        string $status = 'En attente'
    ): AbsenceJustification {
        return AbsenceJustification::create([
            'CodeEleve' => $studentCode,
            'CodeEtablissement' => 'SCHOOL-1',
            'absence_date' => $absenceDate,
            'parent_code' => 'P-'.$studentCode,
            'reason' => 'Rendez-vous médical',
            'justification' => 'Consultation médicale programmée.',
            'statut' => $status,
        ]);
    }

    private function submitTeacherAttendance(
        array $fixture,
        string $date,
        array $statuses
    ) {
        return $this->postJson('/api/school_manager', [
            'action' => 'SAVE_TEACHER_ATTENDANCE',
            'CodeEnseignement' => $fixture['course_code'],
            'teacher_code' => $fixture['teacher_code'],
            'DateEnreg' => $date,
            'CodeAnnee' => 'AN-1',
            'statuses' => $statuses,
        ]);
    }

    public function test_matching_parent_justification_and_roll_call_create_investigation_alert(): void
    {
        $fixture = $this->createAttendanceMismatchFixture(['ELE-MATCH']);
        $this->addAttendanceJustification('ELE-MATCH', '2026-09-28');

        $this->submitTeacherAttendance($fixture, '2026-09-28', [[
            'CodeEleve' => 'ELE-MATCH',
            'status' => 'P',
        ]])->assertOk()->assertJson(['status' => 'success']);

        $this->assertDatabaseHas('investigation_alerts', [
            'CodeEtablissement' => 'SCHOOL-1',
            'CodeEleve' => 'ELE-MATCH',
            'CodeClasse' => 'CL-MISMATCH',
            'CodeEnseignement' => 'ENS-MISMATCH',
            'CodeMatiere' => 'MAT-MISMATCH',
            'date_absence' => '2026-09-28',
            'parent_status' => 'A',
            'teacher_status' => 'P',
            'status' => 'pending',
            'notes' => 'Parent justification exists, but student appeared in teacher roll call.',
        ]);
    }

    public function test_justified_student_not_in_roll_call_does_not_create_investigation_alert(): void
    {
        $fixture = $this->createAttendanceMismatchFixture(['ELE-JUSTIFIED', 'ELE-OTHER']);
        $this->addAttendanceJustification('ELE-JUSTIFIED', '2026-09-28');

        $this->submitTeacherAttendance($fixture, '2026-09-28', [[
            'CodeEleve' => 'ELE-OTHER',
            'status' => 'P',
        ]])->assertOk();

        $this->assertDatabaseCount('investigation_alerts', 0);
    }

    public function test_justification_for_different_date_does_not_create_investigation_alert(): void
    {
        $fixture = $this->createAttendanceMismatchFixture(['ELE-DATE']);
        $this->addAttendanceJustification('ELE-DATE', '2026-09-27');

        $this->submitTeacherAttendance($fixture, '2026-09-28', [[
            'CodeEleve' => 'ELE-DATE',
            'status' => 'P',
        ]])->assertOk();

        $this->assertDatabaseCount('investigation_alerts', 0);
    }

    public function test_roll_call_without_a_matching_justification_does_not_create_an_alert_for_absence_or_lateness(): void
    {
        $fixture = $this->createAttendanceMismatchFixture(['ELE-ABSENT', 'ELE-LATE']);

        $this->submitTeacherAttendance($fixture, '2026-09-28', [
            ['CodeEleve' => 'ELE-ABSENT', 'status' => 'A'],
            ['CodeEleve' => 'ELE-LATE', 'status' => 'R'],
        ])->assertOk();

        $this->assertDatabaseCount('investigation_alerts', 0);
    }

    public function test_reprocessing_same_attendance_creates_only_one_investigation_alert(): void
    {
        $fixture = $this->createAttendanceMismatchFixture(['ELE-REPEAT']);
        $this->addAttendanceJustification('ELE-REPEAT', '2026-09-28');
        $statuses = [['CodeEleve' => 'ELE-REPEAT', 'status' => 'P']];

        $this->submitTeacherAttendance($fixture, '2026-09-28', $statuses)->assertOk();
        $this->submitTeacherAttendance($fixture, '2026-09-28', $statuses)->assertOk();

        $this->assertDatabaseCount('investigation_alerts', 1);
        $this->assertDatabaseCount('conduites', 1);
    }

    public function test_production_values_updated_attendance_create_one_investigation_alert(): void
    {
        User::create([
            'code' => 'T-PROD-TEST',
            'nom' => 'Teacher',
            'prenom' => 'Production Test',
            'sex' => 'M',
            'login' => 'teacher-prod-test',
            'contacts' => '111',
            'password' => bcrypt('secret'),
            'account_type' => 'enseignant',
            'CodeEtablissement' => '16801',
        ]);
        Classe::create([
            'CodeClasse' => '1065',
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Production Test Class',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => '16801',
        ]);
        Matiere::create([
            'CodeMatiere' => 'GEO',
            'LibelleMatiere' => 'Geography',
            'ordre' => '1',
            'CodeEtablissement' => '16801',
        ]);
        Enseignement::create([
            'CodeEnseignement' => '1065GEO',
            'CodeMatiere' => 'GEO',
            'code' => 'T-PROD-TEST',
            'CodeClasse' => '1065',
            'CodeEtablissement' => '16801',
            'NBRHEURE' => '1',
        ]);
        Eleve::create([
            'CodeEleve' => 'S201753896',
            'CodeAnnee' => 'AN-1',
            'CodeClasse' => '1065',
            'dateinscription' => '2024-09-01',
            'Nom' => 'Production',
            'Prenom' => 'Student',
            'Sex' => 'F',
            'code' => 'P-PROD-TEST',
            'CodeEtablissement' => null,
        ]);
        DB::table('absence_justifications')->insert([
            'CodeEleve' => 'S201753896',
            'CodeEtablissement' => '16801',
            'absence_date' => '2026-10-03',
            'date_absence' => '2026-10-03',
            'reason' => 'Rendez-vous médical',
            'motif' => 'Rendez-vous médical',
            'justification' => 'Production-value regression test',
            'status' => 'approved',
            'statut' => 'validée',
            'parent_code' => 'P-PROD-TEST',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $attendance = Conduite::create([
            'DateEnreg' => '2026-10-03',
            'CodeEleve' => 'S201753896',
            'CodeEtatCond' => 'A',
            'CodeClasse' => '1065',
            'CodeAnnee' => 'AN-1',
            'CodeMatiere' => 'GEO',
            'CodeEnseignement' => '1065GEO',
            'HeureMatiere' => '1',
        ]);
        $request = [
            'action' => 'UPDATE_TEACHER_ATTENDANCE',
            'CodeEnseignement' => '1065GEO',
            'teacher_code' => 'T-PROD-TEST',
            'DateEnreg' => '2026-10-03',
            'records' => [[
                'id' => (string) $attendance->id,
                'status' => 'P',
            ]],
        ];

        $this->postJson('/api/school_manager', $request)->assertOk();
        $this->postJson('/api/school_manager', $request)->assertOk();

        $this->assertDatabaseHas('conduites', [
            'id' => $attendance->id,
            'CodeEleve' => 'S201753896',
            'CodeClasse' => '1065',
            'CodeEnseignement' => '1065GEO',
            'CodeMatiere' => 'GEO',
            'DateEnreg' => '2026-10-03',
            'CodeEtatCond' => 'P',
        ]);
        $this->assertDatabaseCount('investigation_alerts', 1);
        $this->assertDatabaseHas('investigation_alerts', [
            'CodeEtablissement' => '16801',
            'CodeEleve' => 'S201753896',
            'CodeClasse' => '1065',
            'CodeEnseignement' => '1065GEO',
            'CodeMatiere' => 'GEO',
            'date_absence' => '2026-10-03',
            'parent_status' => 'A',
            'teacher_status' => 'P',
            'status' => 'pending',
        ]);
    }

    public function test_null_course_school_resolves_from_class_and_creates_one_investigation_alert(): void
    {
        $fixture = $this->createAttendanceMismatchFixture(['ELE-NULL-COURSE-SCHOOL']);
        $this->addAttendanceJustification(
            'ELE-NULL-COURSE-SCHOOL',
            '2026-09-28'
        );
        Conduite::create([
            'DateEnreg' => '2026-09-28',
            'CodeEleve' => 'ELE-NULL-COURSE-SCHOOL',
            'CodeEtatCond' => 'P',
            'CodeClasse' => 'CL-MISMATCH',
            'CodeAnnee' => 'AN-1',
            'CodeMatiere' => 'MAT-MISMATCH',
            'CodeEnseignement' => $fixture['course_code'],
            'HeureMatiere' => '1',
        ]);

        $course = Enseignement::where(
            'CodeEnseignement',
            $fixture['course_code']
        )->firstOrFail();
        $course->CodeEtablissement = null;
        $alertHelper = new \ReflectionMethod(
            API::class,
            'createInvestigationAlertsForAttendance'
        );
        $alertHelper->setAccessible(true);
        $alertHelper->invoke(new API(), $course, '2026-09-28');

        $this->assertDatabaseCount('investigation_alerts', 1);
        $this->assertDatabaseHas('investigation_alerts', [
            'CodeEtablissement' => 'SCHOOL-1',
            'CodeEleve' => 'ELE-NULL-COURSE-SCHOOL',
            'CodeClasse' => 'CL-MISMATCH',
            'CodeEnseignement' => 'ENS-MISMATCH',
            'CodeMatiere' => 'MAT-MISMATCH',
            'date_absence' => '2026-09-28',
            'teacher_status' => 'P',
        ]);
    }

    public function test_course_and_class_school_conflict_fails_closed_without_alert(): void
    {
        $fixture = $this->createAttendanceMismatchFixture(['ELE-SCHOOL-CONFLICT']);
        $this->addAttendanceJustification('ELE-SCHOOL-CONFLICT', '2026-09-28');
        Enseignement::where('CodeEnseignement', $fixture['course_code'])
            ->update(['CodeEtablissement' => 'SCHOOL-2']);

        $this->submitTeacherAttendance($fixture, '2026-09-28', [[
            'CodeEleve' => 'ELE-SCHOOL-CONFLICT',
            'status' => 'P',
        ]])->assertOk();

        $this->assertDatabaseCount('investigation_alerts', 0);
    }

    public function test_multiple_matching_justifications_create_alerts_only_for_present_teacher_status(): void
    {
        $fixture = $this->createAttendanceMismatchFixture([
            'ELE-MULTI-1',
            'ELE-MULTI-2',
            'ELE-MULTI-3',
        ]);
        $this->addAttendanceJustification('ELE-MULTI-1', '2026-09-28');
        $this->addAttendanceJustification('ELE-MULTI-2', '2026-09-28');
        $this->addAttendanceJustification('ELE-MULTI-3', '2026-09-28');

        $this->submitTeacherAttendance($fixture, '2026-09-28', [
            ['CodeEleve' => 'ELE-MULTI-1', 'status' => 'P'],
            ['CodeEleve' => 'ELE-MULTI-2', 'status' => 'R'],
            ['CodeEleve' => 'ELE-MULTI-3', 'status' => 'A'],
        ])->assertOk();

        $this->assertDatabaseCount('investigation_alerts', 1);
        $this->assertDatabaseHas('investigation_alerts', [
            'CodeEleve' => 'ELE-MULTI-1',
            'teacher_status' => 'P',
        ]);
        $this->assertDatabaseMissing('investigation_alerts', [
            'CodeEleve' => 'ELE-MULTI-2',
        ]);
        $this->assertDatabaseMissing('investigation_alerts', [
            'CodeEleve' => 'ELE-MULTI-3',
        ]);
    }

    public function test_teacher_attendance_still_saves_roll_call_without_justifications(): void
    {
        $fixture = $this->createAttendanceMismatchFixture(['ELE-ATTENDANCE']);

        $this->submitTeacherAttendance($fixture, '2026-09-28', [[
            'CodeEleve' => 'ELE-ATTENDANCE',
            'status' => 'P',
        ]])->assertOk()->assertJson(['status' => 'success']);

        $this->assertDatabaseHas('conduites', [
            'CodeEleve' => 'ELE-ATTENDANCE',
            'CodeClasse' => 'CL-MISMATCH',
            'CodeEnseignement' => 'ENS-MISMATCH',
            'DateEnreg' => '2026-09-28',
            'CodeEtatCond' => 'P',
        ]);
        $this->assertDatabaseCount('investigation_alerts', 0);
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
