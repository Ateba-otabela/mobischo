<?php

namespace Tests\Feature;

use App\Models\Annee;
use App\Models\Classe;
use App\Models\Etablissement;
use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class CsvImportTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->createImportTables();
        Storage::fake('local');
        $this->actingAs($this->user(true));
    }

    public function test_preview_parses_quoted_accents_without_writing_records(): void
    {
        $previewUrl = $this->uploadCsv(
            'schools',
            "CodeEtablissement;Nom;Adresse;Tel;Fax\nSCH1;\"École; du Centre\";Centre;123;456\n"
        );

        $this->get($previewUrl)->assertOk()->assertSee('École; du Centre');
        $this->assertDatabaseCount('etablissements', 0);
    }

    /**
     * @dataProvider templateCases
     */
    public function test_csv_template_download_uses_exact_importer_headers(string $type, array $expectedHeaders): void
    {
        $response = $this->get(route('admin.imports.template', $type));
        $response->assertOk()
            ->assertHeader('content-type', 'text/csv; charset=UTF-8')
            ->assertHeader('content-disposition', 'attachment; filename="' . $type . '-template.csv"');

        $csv = $response->getContent();
        $this->assertStringStartsWith("\xEF\xBB\xBF", $csv);
        $handle = fopen('php://temp', 'w+');
        fwrite($handle, substr($csv, 3));
        rewind($handle);
        $this->assertSame($expectedHeaders, fgetcsv($handle, 1048576, ';'));
        $this->assertFalse(fgetcsv($handle, 1048576, ';'));
        fclose($handle);

        $importer = app(\App\Imports\CsvImportManager::class)->importer($type);
        $this->assertSame($importer->columns(), $expectedHeaders);
    }

    public function test_admin_import_page_links_to_templates_for_all_supported_types(): void
    {
        $response = $this->get(route('admin.imports.index'))->assertOk();

        foreach (['schools', 'classes', 'subjects', 'academic-years', 'students'] as $type) {
            $response->assertSee(route('admin.imports.template', $type), false);
        }
    }

    public static function templateCases(): array
    {
        return [
            'school' => [
                'schools',
                ['CodeEtablissement', 'Nom', 'Adresse', 'Tel', 'Fax', 'Pays', 'REPPHOTO'],
            ],
            'class' => [
                'classes',
                ['CodeClasse', 'CodeTypeClasse', 'LibelleClasse', 'CodeCycle', 'CodeSpecialite', 'codetypeinscrip', 'CodeEtablissement'],
            ],
            'subject' => [
                'subjects',
                ['CodeMatiere', 'LibelleMatiere', 'ordre', 'CodeEtablissement'],
            ],
            'academic year' => [
                'academic-years',
                ['CodeAnnee', 'Libelle'],
            ],
            'student' => [
                'students',
                [
                    'CodeEleve', 'CodeAnnee', 'CodeClasse', 'code', 'CodeConduite', 'Nom', 'Prenom',
                    'DateNaissance', 'LieuNaissance', 'Sex', 'Nationalite', 'dateinscription', 'photo',
                    'Excl', 'Nomp', 'TelP', 'Image', 'strimage', 'Nomm', 'REGION', 'DEPART', 'RELIGION',
                    'SITREG', 'ACTIVEEPS', 'PROFP', 'NOMT', 'PROFM', 'ADRESSE', 'RESIDENT', 'TELM',
                    'TELT', 'PERSONCON', 'RESERVE1', 'RESERVE2', 'RESERVE3', 'RESERVE4',
                ],
            ],
        ];
    }

    /**
     * @dataProvider supportedImportCases
     */
    public function test_each_supported_type_previews_valid_csv_without_writing(
        string $type,
        string $table,
        string $csv,
        string $identifierColumn,
        string $identifier
    ): void {
        $this->seedRelationshipsFor($type);

        $previewUrl = $this->uploadCsv($type, $csv);
        $this->get($previewUrl)->assertOk()->assertSee('Confirm import');

        $this->assertDatabaseCount($table, 0);
        $this->assertStringContainsString($identifier, $this->get($previewUrl)->getContent());
    }

    /**
     * @dataProvider supportedImportCases
     */
    public function test_each_supported_type_confirms_a_valid_new_record(
        string $type,
        string $table,
        string $csv,
        string $identifierColumn,
        string $identifier
    ): void {
        $this->seedRelationshipsFor($type);

        $previewUrl = $this->uploadCsv($type, $csv);
        $this->get($previewUrl)->assertOk()->assertSee('Confirm import');

        $resultUrl = $this->confirmImport($previewUrl);
        $this->get($resultUrl)->assertOk();
        $this->assertDatabaseHas($table, [$identifierColumn => $identifier]);
        $this->assertDatabaseCount($table, 1);
    }

    public static function supportedImportCases(): array
    {
        return [
            'school' => [
                'schools',
                'etablissements',
                "CodeEtablissement;Nom;Adresse;Tel;Fax\nSCH-NEW;École Nouvelle;Centre;123;456\n",
                'CodeEtablissement',
                'SCH-NEW',
            ],
            'class' => [
                'classes',
                'classes',
                "CodeClasse;CodeTypeClasse;LibelleClasse;CodeCycle;CodeSpecialite;codetypeinscrip;CodeEtablissement\nCLS-NEW;TYPE;Sixième;CYCLE;SPEC;INS;SCH-REF\n",
                'CodeClasse',
                'CLS-NEW',
            ],
            'subject' => [
                'subjects',
                'matieres',
                "CodeMatiere;LibelleMatiere;ordre;CodeEtablissement\nMAT-NEW;Mathématiques;A-1;SCH-REF\n",
                'CodeMatiere',
                'MAT-NEW',
            ],
            'academic year' => [
                'academic-years',
                'annees',
                "CodeAnnee;Libelle\nYEAR-NEW;Année 2026\n",
                'CodeAnnee',
                'YEAR-NEW',
            ],
            'student' => [
                'students',
                'eleves',
                "CodeEleve;CodeAnnee;CodeClasse;dateinscription;Nom;Prenom\nSTU-NEW;YEAR-REF;CLS-REF;2026-09-01;Élève;Test\n",
                'CodeEleve',
                'STU-NEW',
            ],
        ];
    }

    public function test_existing_database_record_is_skipped_without_being_overwritten(): void
    {
        Etablissement::query()->create([
            'CodeEtablissement' => 'SCH-EXISTING',
            'Nom' => 'Existing name',
            'Adresse' => 'Existing address',
            'Tel' => '111',
            'Fax' => '222',
        ]);

        $previewUrl = $this->uploadCsv(
            'schools',
            "CodeEtablissement;Nom;Adresse;Tel;Fax\nSCH-EXISTING;Replacement;New address;333;444\n"
        );
        $this->get($previewUrl)->assertOk()->assertSee('already exists');

        $resultUrl = $this->confirmImport($previewUrl);
        $this->get($resultUrl)->assertOk()->assertSee('Skipped');
        $this->assertDatabaseCount('etablissements', 1);
        $this->assertDatabaseHas('etablissements', [
            'CodeEtablissement' => 'SCH-EXISTING',
            'Nom' => 'Existing name',
            'Adresse' => 'Existing address',
        ]);
    }

    public function test_missing_required_columns_block_import_confirmation(): void
    {
        $previewUrl = $this->uploadCsv(
            'schools',
            "CodeEtablissement;Nom;Adresse;Tel\nSCH-MISSING;École;Centre;123\n"
        );

        $this->get($previewUrl)
            ->assertOk()
            ->assertSee(__('csv_import.headers.missing', ['column' => 'Fax']))
            ->assertDontSee('Confirm import');

        $resultUrl = $this->confirmImport($previewUrl);
            $this->get($resultUrl)
                ->assertOk()
                ->assertSee(__('csv_import.headers.missing', ['column' => 'Fax']));
            $this->assertDatabaseCount('etablissements', 0);
    }

    public function test_unknown_columns_warn_but_valid_rows_can_be_imported(): void
    {
        $previewUrl = $this->uploadCsv(
            'schools',
            "CodeEtablissement;Nom;Adresse;Tel;Fax;LegacyNote\nSCH-WARN;École;Centre;123;456;ignored\n"
        );

        $this->get($previewUrl)
            ->assertOk()
            ->assertSee(__('csv_import.headers.unknown', ['column' => 'LegacyNote']))
            ->assertSee('Confirm import');

        $this->get($this->confirmImport($previewUrl))->assertOk();
        $this->assertDatabaseHas('etablissements', [
            'CodeEtablissement' => 'SCH-WARN',
            'Nom' => 'École',
        ]);
    }

    public function test_failed_confirmed_transaction_rolls_back_all_new_rows(): void
    {
        $this->insertSchool('SCH-REF');
        DB::statement(
            "CREATE TRIGGER fail_class_insert BEFORE INSERT ON classes " .
            "WHEN NEW.CodeClasse = 'CLS-FAIL' BEGIN SELECT RAISE(ABORT, 'forced test failure'); END"
        );

        $previewUrl = $this->uploadCsv(
            'classes',
            "CodeClasse;CodeTypeClasse;LibelleClasse;CodeCycle;CodeSpecialite;codetypeinscrip;CodeEtablissement\n" .
            "CLS-FIRST;TYPE;First;CYCLE;SPEC;INS;SCH-REF\n" .
            "CLS-FAIL;TYPE;Fail;CYCLE;SPEC;INS;SCH-REF\n"
        );
        $this->get($previewUrl)->assertOk()->assertSee('Confirm import');

        $resultUrl = $this->confirmImport($previewUrl);
        $this->get($resultUrl)->assertOk()->assertSee('2');
        $this->assertDatabaseCount('classes', 0);
    }

    public function test_empty_csv_is_rejected_without_creating_an_import(): void
    {
        $response = $this->post(route('admin.imports.upload'), [
            'import_type' => 'schools',
            'csv_file' => UploadedFile::fake()->createWithContent('empty.csv', ''),
        ]);

        $response->assertRedirect()->assertSessionHasErrors('csv_file');
        $this->assertDatabaseCount('etablissements', 0);
    }

    public function test_malformed_row_is_reported_invalid_and_not_imported(): void
    {
        $previewUrl = $this->uploadCsv(
            'schools',
            "CodeEtablissement;Nom;Adresse;Tel;Fax\n" .
            "SCH-GOOD;Valid school;Centre;123;456\n" .
            "SCH-BAD;Invalid school;Centre;123;456;unexpected\n"
        );

        $this->get($previewUrl)
            ->assertOk()
            ->assertSee(__('csv_import.rows_invalid'))
            ->assertSee('more fields than the header');
        $this->assertDatabaseCount('etablissements', 0);

        $resultUrl = $this->confirmImport($previewUrl);
        $this->get($resultUrl)->assertOk()->assertSee('Failed');
        $this->assertDatabaseCount('etablissements', 1);
        $this->assertDatabaseHas('etablissements', [
            'CodeEtablissement' => 'SCH-GOOD',
            'Nom' => 'Valid school',
        ]);
        $this->assertDatabaseMissing('etablissements', [
            'CodeEtablissement' => 'SCH-BAD',
        ]);
    }

    public function test_student_preview_rejects_missing_year_and_class_and_non_admin_is_forbidden(): void
    {
        $previewUrl = $this->uploadCsv(
            'students',
            "CodeEleve;CodeAnnee;CodeClasse;dateinscription\nST1;UNKNOWN-YEAR;UNKNOWN-CLASS;2026-09-01\n"
        );

        $this->get($previewUrl)
            ->assertOk()
            ->assertSee(__('csv_import.validation.year_missing'))
            ->assertSee(__('csv_import.validation.class_missing'));

        auth()->logout();
        $this->actingAs($this->user(false));
        $this->get(route('admin.imports.index'))->assertForbidden();
    }

    /**
     * @dataProvider establishmentRelationshipCases
     */
    public function test_class_and_subject_reject_missing_establishment(
        string $type,
        string $csv,
        string $identifier
    ): void {
        $previewUrl = $this->uploadCsv($type, $csv);

        $this->get($previewUrl)
            ->assertOk()
            ->assertSee($identifier)
            ->assertSee(__('csv_import.validation.school_missing'));
    }

    public static function establishmentRelationshipCases(): array
    {
        return [
            'class' => [
                'classes',
                "CodeClasse;CodeTypeClasse;LibelleClasse;CodeCycle;CodeSpecialite;codetypeinscrip;CodeEtablissement\nCLS-NO-SCHOOL;TYPE;Sixième;CYCLE;SPEC;INS;UNKNOWN-SCHOOL\n",
                'CLS-NO-SCHOOL',
            ],
            'subject' => [
                'subjects',
                "CodeMatiere;LibelleMatiere;ordre;CodeEtablissement\nMAT-NO-SCHOOL;Mathématiques;A-1;UNKNOWN-SCHOOL\n",
                'MAT-NO-SCHOOL',
            ],
        ];
    }

    private function uploadCsv(string $type, string $csv): string
    {
        $response = $this->post(route('admin.imports.upload'), [
            'import_type' => $type,
            'csv_file' => UploadedFile::fake()->createWithContent($type . '.csv', $csv),
        ]);

        $response->assertRedirect();
        $previewUrl = $response->headers->get('Location');
        $this->assertIsString($previewUrl);
        $this->assertMatchesRegularExpression(
            '#/admin/imports/[a-f0-9]{48}/preview$#',
            parse_url($previewUrl, PHP_URL_PATH)
        );

        return $previewUrl;
    }

    private function confirmImport(string $previewUrl): string
    {
        preg_match('#/admin/imports/([a-f0-9]{48})/preview$#', parse_url($previewUrl, PHP_URL_PATH), $matches);
        $response = $this->post(route('admin.imports.confirm', $matches[1]));
        $response->assertRedirect();

        return $response->headers->get('Location');
    }

    private function seedRelationshipsFor(string $type): void
    {
        if (in_array($type, ['classes', 'subjects', 'students'], true)) {
            $this->insertSchool('SCH-REF');
        }

        if ($type === 'students') {
            Annee::query()->create([
                'CodeAnnee' => 'YEAR-REF',
                'Libelle' => 'Reference year',
            ]);
            $this->insertClass('CLS-REF', 'SCH-REF');
        }
    }

    private function insertSchool(string $code): void
    {
        Etablissement::query()->create([
            'CodeEtablissement' => $code,
            'Nom' => 'Reference school',
            'Adresse' => 'Centre',
            'Tel' => '123',
            'Fax' => '456',
        ]);
    }

    private function insertClass(string $code, string $schoolCode): void
    {
        Classe::query()->create([
            'CodeClasse' => $code,
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Reference class',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => $schoolCode,
        ]);
    }

    private function user(bool $isAdmin): User
    {
        $user = new User();
        $user->forceFill([
            'code' => $isAdmin ? 'admin-test' : 'user-test',
            'nom' => 'Test',
            'prenom' => 'User',
            'admin' => $isAdmin,
        ]);

        return $user;
    }

    private function createImportTables(): void
    {
        foreach (['eleves', 'matieres', 'classes', 'annees', 'etablissements'] as $table) {
            Schema::dropIfExists($table);
        }

        Schema::create('etablissements', function (Blueprint $table): void {
            $table->string('CodeEtablissement')->primary();
            $table->string('Pays')->default('Cameroun');
            $table->string('Nom');
            $table->string('Adresse');
            $table->string('Tel');
            $table->string('Fax');
            $table->string('REPPHOTO')->nullable();
            $table->timestamps();
        });

        Schema::create('annees', function (Blueprint $table): void {
            $table->string('CodeAnnee')->primary();
            $table->string('Libelle');
            $table->timestamps();
        });

        Schema::create('classes', function (Blueprint $table): void {
            $table->string('CodeClasse')->primary();
            $table->string('CodeTypeClasse');
            $table->string('LibelleClasse');
            $table->string('CodeCycle');
            $table->string('CodeSpecialite');
            $table->string('codetypeinscrip');
            $table->string('CodeEtablissement');
            $table->timestamps();
        });

        Schema::create('matieres', function (Blueprint $table): void {
            $table->string('CodeMatiere')->primary();
            $table->string('LibelleMatiere');
            $table->string('ordre');
            $table->string('CodeEtablissement');
            $table->timestamps();
        });

        Schema::create('eleves', function (Blueprint $table): void {
            $table->string('CodeEleve')->primary();
            $table->string('code')->nullable();
            $table->string('CodeAnnee');
            $table->string('CodeClasse');
            $table->string('CodeConduite')->nullable();
            $table->string('Nom')->nullable();
            $table->string('Prenom')->nullable();
            $table->string('DateNaissance')->nullable();
            $table->string('LieuNaissance')->nullable();
            $table->string('Sex')->nullable();
            $table->string('Nationalite')->nullable();
            $table->string('dateinscription');
            $table->string('photo')->nullable();
            $table->string('Excl')->nullable();
            $table->string('Nomp')->nullable();
            $table->string('TelP')->nullable();
            $table->string('Image')->nullable();
            $table->string('strimage')->nullable();
            $table->string('Nomm')->nullable();
            $table->string('REGION')->nullable();
            $table->string('DEPART')->nullable();
            $table->string('RELIGION')->nullable();
            $table->string('SITREG')->nullable();
            $table->string('ACTIVEEPS')->nullable();
            $table->string('PROFP')->nullable();
            $table->string('NOMT')->nullable();
            $table->string('PROFM')->nullable();
            $table->string('ADRESSE')->nullable();
            $table->string('RESIDENT')->nullable();
            $table->string('TELM')->nullable();
            $table->string('TELT')->nullable();
            $table->string('PERSONCON')->nullable();
            $table->string('RESERVE1')->nullable();
            $table->string('RESERVE2')->nullable();
            $table->string('RESERVE3')->nullable();
            $table->string('RESERVE4')->nullable();
            $table->timestamps();
        });
    }
}
