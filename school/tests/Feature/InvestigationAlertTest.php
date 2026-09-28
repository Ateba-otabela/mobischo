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
use Tests\TestCase;

class InvestigationAlertTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->artisan('migrate:fresh', ['--seed' => false]);
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
