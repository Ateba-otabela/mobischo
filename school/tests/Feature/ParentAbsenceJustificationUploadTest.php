<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ParentAbsenceJustificationUploadTest extends TestCase
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

        Schema::create('users', function (Blueprint $table): void {
            $table->string('code')->primary();
            $table->string('nom');
            $table->string('prenom');
            $table->string('contacts')->nullable();
            $table->string('sex')->nullable();
            $table->string('login')->nullable();
            $table->string('account_type');
            $table->string('CodeEtablissement')->nullable();
            $table->boolean('admin')->default(false);
            $table->string('password')->nullable();
            $table->timestamps();
        });

        Schema::create('classes', function (Blueprint $table): void {
            $table->string('CodeClasse')->primary();
            $table->string('CodeEtablissement');
            $table->string('LibelleClasse');
            $table->timestamps();
        });

        Schema::create('eleves', function (Blueprint $table): void {
            $table->string('CodeEleve')->primary();
            $table->string('code')->nullable();
            $table->string('CodeClasse');
            $table->string('CodeAnnee')->nullable();
            $table->string('Nom')->nullable();
            $table->string('Prenom')->nullable();
            $table->string('dateinscription')->nullable();
            $table->timestamps();
        });

        Schema::create('absence_justifications', function (Blueprint $table): void {
            $table->id();
            $table->string('CodeEleve');
            $table->string('CodeEtablissement')->nullable();
            $table->date('absence_date')->nullable();
            $table->date('date_absence')->nullable();
            $table->text('reason')->nullable();
            $table->text('motif')->nullable();
            $table->text('justification')->nullable();
            $table->string('status')->default('pending');
            $table->string('statut')->default('En attente');
            $table->string('parent_code');
            $table->string('parent_name')->nullable();
            $table->string('reviewed_by')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->string('document_path')->nullable();
            $table->timestamps();
        });

        Schema::create('enseignements', function (Blueprint $table): void {
            $table->string('CodeEnseignement')->primary();
            $table->string('CodeClasse');
            $table->string('CodeEtablissement');
            $table->string('code')->nullable();
            $table->string('CodeEnseignant2')->nullable();
        });

        Schema::create('encadreur_classes', function (Blueprint $table): void {
            $table->id();
            $table->string('code');
            $table->string('CodeClasse');
            $table->string('CodeEtablissement');
        });

        DB::table('users')->insert([
            'code' => 'PARENT-1',
            'nom' => 'Parent',
            'prenom' => 'Test',
            'account_type' => 'parent',
            'CodeEtablissement' => 'SCHOOL-1',
            'password' => bcrypt('test-password'),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('classes')->insert([
            'CodeClasse' => 'CLASS-1',
            'CodeEtablissement' => 'SCHOOL-1',
            'LibelleClasse' => 'Class 1',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('eleves')->insert([
            'CodeEleve' => 'STUDENT-1',
            'code' => 'PARENT-1',
            'CodeClasse' => 'CLASS-1',
            'Nom' => 'Student',
            'Prenom' => 'Test',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Storage::fake('public');
        Sanctum::actingAs(User::findOrFail('PARENT-1'), ['mobischo:mobile']);
    }

    public function test_parent_can_submit_justification_without_a_document(): void
    {
        $this->post('/api/parent/absence-justifications', $this->submissionPayload(), [
            'Accept' => 'application/json',
        ])
            ->assertOk()
            ->assertJsonPath('status', 'success');

        $this->assertDatabaseHas('absence_justifications', [
            'CodeEleve' => 'STUDENT-1',
            'parent_code' => 'PARENT-1',
            'document_path' => null,
        ]);
    }

    public function test_parent_can_submit_and_store_a_pdf_justification_document(): void
    {
        $payload = $this->submissionPayload();
        $payload['document'] = UploadedFile::fake()->create('medical-proof.pdf', 32, 'application/pdf');

        $response = $this->post('/api/parent/absence-justifications', $payload, [
            'Accept' => 'application/json',
        ])
            ->assertOk()
            ->assertJsonPath('status', 'success');

        $justification = DB::table('absence_justifications')->first();
        $this->assertNotNull($justification->document_path);
        $this->assertStringStartsWith('absence-justifications/', $justification->document_path);
        Storage::disk('public')->assertExists($justification->document_path);
        $this->assertSame($justification->id, $response->json('id'));
    }

    public function test_parent_receives_validation_error_for_an_unsupported_document_type(): void
    {
        $payload = $this->submissionPayload();
        $payload['document'] = UploadedFile::fake()->create('notes.txt', 1, 'text/plain');

        $this->post('/api/parent/absence-justifications', $payload, [
            'Accept' => 'application/json',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('document');

        $this->assertDatabaseCount('absence_justifications', 0);
        Storage::disk('public')->assertDirectoryEmpty('absence-justifications');
    }

    private function submissionPayload(): array
    {
        return [
            'action' => 'SUBMIT_ABSENCE_JUSTIFICATION',
            'CodeEleve' => 'STUDENT-1',
            'date_absence' => '2026-10-07',
            'reason' => 'Maladie',
            'justification' => 'Student was ill and could not attend school.',
        ];
    }
}
