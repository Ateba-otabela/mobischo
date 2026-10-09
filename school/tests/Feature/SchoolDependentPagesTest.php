<?php

namespace Tests\Feature;

use App\Models\Annee;
use App\Models\Classe;
use App\Models\Eleve;
use App\Models\Etablissement;
use App\Models\SequenceEvaluation;
use App\Models\TrancheScholarite;
use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolDependentPagesTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->createSchoolPageTables();
    }

    public function test_add_student_loads_selected_school_students_without_throwing(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');
        $this->createYear('YEAR-1');
        $this->createStudent('STU-1', 'CLS-1', 'YEAR-1', 'Nina');

        $response = $this->get(route('add_student', [
            'CodeEtablissement' => '12301',
        ]));

        $response->assertOk()
            ->assertSee('12301')
            ->assertSee('Nina')
            ->assertSee('CLS-1');
    }

    public function test_add_student_handles_missing_and_invalid_school_codes_without_server_error(): void
    {
        $this->get(route('add_student'))
            ->assertRedirect(route('add_student_home'))
            ->assertSessionHasErrors('CodeEtablissement');

        $this->get(route('add_student', ['CodeEtablissement' => 'NOT-A-SCHOOL']))
            ->assertRedirect(route('add_student_home'))
            ->assertSessionHasErrors('CodeEtablissement');
    }

    public function test_add_student_shows_a_friendly_message_when_school_has_no_classes(): void
    {
        $this->createSchool('12301');

        $this->get(route('add_student', ['CodeEtablissement' => '12301']))
            ->assertRedirect(route('add_student_home', ['CodeEtablissement' => '12301']))
            ->assertSessionHasErrors('CodeEtablissement');
    }

    public function test_add_student_page_handles_a_school_with_classes_but_no_academic_years(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');

        $this->get(route('add_student', ['CodeEtablissement' => '12301']))
            ->assertOk()
            ->assertSee('Aucune année scolaire disponible');
    }

    public function test_sorted_students_returns_only_students_from_selected_school_class_and_year(): void
    {
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createClass('CLS-A', '12301');
        $this->createClass('CLS-B', '45601');
        $this->createYear('2026');
        $this->createStudent('STU-A', 'CLS-A', '2026', 'School One');
        $this->createStudent('STU-B', 'CLS-B', '2026', 'School Two');

        $this->get(route('sorted_students', [
            'CodeEtablissement' => '12301',
            'CodeClasse' => 'CLS-A',
            'CodeAnnee' => '2026',
        ]))
            ->assertOk()
            ->assertSee('School One')
            ->assertDontSee('School Two');
    }

    public function test_sorted_students_rejects_a_class_from_another_school(): void
    {
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createClass('CLS-OTHER', '45601');
        $this->createYear('2026');

        $this->get(route('sorted_students', [
            'CodeEtablissement' => '12301',
            'CodeClasse' => 'CLS-OTHER',
            'CodeAnnee' => '2026',
        ]))
            ->assertRedirect(route('add_student_home'))
            ->assertSessionHasErrors('CodeClasse');
    }

    public function test_class_list_is_scoped_to_the_selected_school(): void
    {
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createClass('CLS-A', '12301');
        $this->createClass('CLS-B', '45601');

        $this->get(route('add_class', ['CodeEtablissement' => '12301']))
            ->assertOk()
            ->assertSee('Class CLS-A')
            ->assertDontSee('Class CLS-B');
    }

    public function test_class_list_shows_existing_classes_without_a_school_filter(): void
    {
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createClass('CLS-A', '12301');
        $this->createClass('CLS-B', '45601');

        $this->get(route('add_class'))
            ->assertOk()
            ->assertSee('Class CLS-A')
            ->assertSee('Class CLS-B');
    }

    public function test_user_list_is_scoped_to_the_selected_school(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createUser('101', '12301', 'Teacher One');
        $this->createUser('202', '45601', 'Teacher Two');

        $this->get(route('add_user', ['CodeEtablissement' => '12301']))
            ->assertOk()
            ->assertSee('Teacher One')
            ->assertDontSee('Teacher Two')
            ->assertSee('data-edit-user')
            ->assertDontSee('id="modify101"')
            ->assertDontSee('id="add_student101"');
    }

    public function test_user_edit_form_is_loaded_on_demand(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createUser('101', '12301', 'Teacher One');

        $this->get(route('admin.users.edit-form', [
            'user_id' => '101',
            'CodeEtablissement' => '12301',
        ]))
            ->assertOk()
            ->assertSee('name="nom"', false)
            ->assertSee('name="prenom"', false)
            ->assertSee('js-encadreur-classes-list')
            ->assertSee('return_school', false);
    }

    public function test_user_list_requires_a_school_before_loading_users(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createUser('101', '12301', 'Teacher One');
        $this->createUser('202', '45601', 'Teacher Two');

        $userQueries = [];
        DB::listen(function (QueryExecuted $query) use (&$userQueries): void {
            if (preg_match('/\bfrom\s+[`"]?users\b/i', $query->sql)) {
                $userQueries[] = $query->sql;
            }
        });

        $this->get(route('add_user'))
            ->assertOk()
            ->assertSee('Choisissez un établissement pour afficher ses utilisateurs.')
            ->assertDontSee('Teacher One')
            ->assertDontSee('Teacher Two')
            ->assertViewHas('users', null);

        $this->assertSame([], $userQueries);
    }

    public function test_user_list_paginates_only_users_from_the_selected_school(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createSchool('45601');
        for ($index = 1; $index <= 27; $index++) {
            $this->createUser(
                (string) $index,
                '12301',
                'Teacher ' . str_pad((string) $index, 2, '0', STR_PAD_LEFT)
            );
        }
        $this->createUser('OTHER', '45601', 'Other School Teacher');

        $pageOne = $this->get(route('add_user', ['CodeEtablissement' => '12301']))
            ->assertOk()
            ->assertSee('Teacher 01')
            ->assertSee('Teacher 25')
            ->assertDontSee('Teacher 26')
            ->assertDontSee('Other School Teacher')
            ->viewData('users');

        $this->assertSame(25, $pageOne->count());
        $this->assertSame(27, $pageOne->total());
        $this->assertStringContainsString('CodeEtablissement=12301', $pageOne->url(2));
        $this->assertStringContainsString('page=2', $pageOne->url(2));

        $this->get(route('add_user', ['CodeEtablissement' => '12301', 'page' => 2]))
            ->assertOk()
            ->assertSee('Teacher 26')
            ->assertSee('Teacher 27')
            ->assertDontSee('Teacher 01')
            ->assertDontSee('Other School Teacher');
    }

    public function test_user_management_routes_require_an_administrator(): void
    {
        $this->get(route('add_user'))
            ->assertRedirect(route('login'));
        $this->get(route('admin.users.edit-form', ['user_id' => '101']))
            ->assertRedirect(route('login'));

        $this->actingAs(new User([
            'code' => 'NOT-ADMIN',
            'account_type' => 'enseignant',
            'admin' => false,
        ]));
        $this->get(route('add_user'))->assertForbidden();
        $this->get(route('admin.users.edit-form', ['user_id' => '101']))
            ->assertForbidden();

        $this->actingAsAdministrator();
        $this->get(route('add_user'))->assertOk();
    }

    public function test_class_csv_import_creates_valid_data_and_rejects_short_rows(): void
    {
        $this->createSchool('12301');

        $this->post(route('import_classes'), [
            'csv_file' => UploadedFile::fake()->createWithContent(
                'classes.csv',
                "CLS-CSV;TYPE;Imported class;CYCLE;SPEC;INS;12301\n"
            ),
        ])->assertRedirect('add_class');

        $this->assertDatabaseHas('classes', [
            'CodeClasse' => 'CLS-CSV',
            'LibelleClasse' => 'Imported class',
            'CodeEtablissement' => '12301',
        ]);

        $this->post(route('import_classes'), [
            'csv_file' => UploadedFile::fake()->createWithContent('short.csv', "CLS-BAD;TYPE\n"),
        ])->assertRedirect()
            ->assertSessionHasErrors('csv_file');
    }

    public function test_class_csv_import_rejects_unknown_school_references(): void
    {
        $this->post(route('import_classes'), [
            'csv_file' => UploadedFile::fake()->createWithContent(
                'classes.csv',
                "CLS-BAD;TYPE;Invalid class;CYCLE;SPEC;INS;MISSING\n"
            ),
        ])->assertRedirect('add_class')
            ->assertSessionHasErrors('csv_file');

        $this->assertDatabaseMissing('classes', ['CodeClasse' => 'CLS-BAD']);
    }

    public function test_subject_csv_import_uses_the_school_code_from_the_csv(): void
    {
        $this->createSchool('12301');

        $this->post(route('import_courses'), [
            'csv_file' => UploadedFile::fake()->createWithContent(
                'subjects.csv',
                "MAT-CSV;\"Français; grammaire\";1;12301\n"
            ),
        ])->assertRedirect('course_home');

        $this->assertDatabaseHas('matieres', [
            'CodeMatiere' => 'MAT-CSV',
            'LibelleMatiere' => 'Français; grammaire',
            'CodeEtablissement' => '12301',
        ]);
    }

    public function test_existing_admin_csv_buttons_import_valid_rows_for_academic_records(): void
    {
        $this->actingAsAdministrator();
        $this->post(route('import_schools'), [
            'csv_file' => $this->csvUpload(
                'schools.csv',
                "SCHOOL-CSV;Cameroun;Imported school;456;123\n"
            ),
        ])->assertRedirect('add_school');

        $this->post(route('import_classes'), [
            'csv_file' => $this->csvUpload(
                'classes.csv',
                "CLS-CSV;TYPE;Imported class;CYCLE;SPEC;INS;SCHOOL-CSV\n"
            ),
        ])->assertRedirect('add_class');

        $this->post(route('import_courses'), [
            'csv_file' => $this->csvUpload(
                'subjects.csv',
                "MAT-CSV;\"Français; grammaire\";1;SCHOOL-CSV\n"
            ),
        ])->assertRedirect('course_home');

        $this->post(route('import_years'), [
            'csv_file' => $this->csvUpload('years.csv', "2027;2027/2028\n"),
        ])->assertRedirect('add_year');

        $this->post(route('import_sequences'), [
            'csv_file' => $this->csvUpload('sequences.csv', "EVAL-CSV;Première séquence\n"),
        ])->assertRedirect('sequence_evaluation');

        $studentColumns = array_fill(0, 36, '');
        $studentColumns[0] = 'STU-CSV';
        $studentColumns[1] = '2027';
        $studentColumns[2] = 'CLS-CSV';
        $studentColumns[3] = 'CONDUITE';
        $studentColumns[4] = 'Élève';
        $studentColumns[5] = 'Test';
        $studentColumns[6] = '2012-03-04';
        $studentColumns[7] = 'Douala';
        $studentColumns[8] = 'F';
        $studentColumns[9] = 'Camerounaise';
        $studentColumns[10] = '2026-09-01';
        $studentColumns[11] = 'student-photo.jpg';
        $studentColumns[12] = '0';
        $studentColumns[13] = 'Parent One';
        $studentColumns[14] = '699111111';
        $studentColumns[15] = 'Parent Two';
        $studentColumns[16] = 'Centre';
        $studentColumns[17] = 'Wouri';
        $studentColumns[18] = 'Christianisme';
        $studentColumns[19] = 'Célibataire';
        $studentColumns[23] = '1';
        $studentColumns[24] = 'Enseignant parent';
        $studentColumns[25] = 'Tuteur';
        $studentColumns[28] = 'Enseignante mère';
        $studentColumns[29] = 'Bonapriso';
        $studentColumns[30] = '677222222';
        $studentColumns[31] = 'Urgence';
        $studentColumns[32] = 'STU-RES-1';
        $studentColumns[33] = 'STU-RES-2';
        $studentColumns[34] = 'STU-RES-3';
        $studentColumns[35] = 'STU-RES-4';
        $this->post(route('import_students'), [
            'csv_file' => $this->csvUpload('students.csv', implode(';', $studentColumns)."\n"),
        ])->assertRedirect('add_student_home');

        $teacherColumns = [
            'TEACHER-CSV', 'Teacher', 'Imported', '1980-01-02', 'Yaounde', 'Camerounaise', '0',
            '2000-09-01', 'teacher.csv', '123456', 'Grade A', '7', 'MAT-CSV', 'USR-RES-1',
            'USR-RES-2', 'USR-RES-3', 'USR-RES-4', 'USR-RES-5', 'USR-RES-6', 'CAT-A', 'ECH-A',
            'ACTIVE', 'USR-RES-7', 'USR-RES-8', 'USR-RES-9', 'BANK-1', 'ACCOUNT-1', 'RIB-1',
            'TAUX-1', 'SYNDICAT-1', 'ASSURE-1', 'SCHOOL-CSV',
        ];
        $this->post(route('import_users'), [
            'csv_file' => $this->csvUpload('teachers.csv', implode(';', $teacherColumns)."\n"),
        ])->assertRedirect(route('add_user'));

        $teachingColumns = [
            'ENSEIGNEMENT-CSV',
            'MAT-CSV',
            'TEACHER-CSV',
            'CLS-CSV',
            'SCHOOL-CSV',
            '2',
            'SPEC',
            'CYCLE',
            '2026-09-01 00:00:00',
            '',
            '',
            '4',
            '',
            '',
            '',
            '',
            '',
        ];
        $this->post(route('import_enseignements'), [
            'csv_file' => $this->csvUpload(
                'teachings.csv',
                implode(';', $teachingColumns)."\n"
            ),
        ])->assertRedirect('enseignement_home');

        $this->post(route('import_notes'), [
            'csv_file' => $this->csvUpload(
                'notes.csv',
                "ENSEIGNEMENT-CSV;STU-CSV;EVAL-CSV;;15;1;15;2026-09-01;2027\n"
            ),
        ])->assertRedirect('notes_home');

        $this->createSchool('11201');
        $this->post(route('import_tranches'), [
            'csv_file' => $this->csvUpload('tranches.csv', "TRANCHE-CSV;First payment\n"),
        ])->assertRedirect('tranches_scholarites_home');

        $registrationColumns = [
            'INVOICE-CSV',
            'REG-CSV',
            'STU-CSV',
            '2026-09-01 00:00:00',
            'TRANCHE-CSV',
            '2027',
            '100',
            '100',
            '0',
            '100',
            'Registration',
            '08:00',
            'Admin',
            '0',
        ];
        $this->post(route('import_inscriptions'), [
            'csv_file' => $this->csvUpload(
                'registrations.csv',
                implode(';', $registrationColumns)."\n"
            ),
        ])->assertRedirect('inscriptions_home');

        $registrationColumns[0] = 'HISTORY-CSV';
        $this->post(route('import_historique_inscriptions'), [
            'csv_file' => $this->csvUpload(
                'historical-registrations.csv',
                implode(';', $registrationColumns)."\n"
            ),
        ])->assertRedirect('historique_inscriptions_home');

        $this->assertDatabaseHas('etablissements', ['CodeEtablissement' => 'SCHOOL-CSV']);
        $this->assertDatabaseHas('classes', ['CodeClasse' => 'CLS-CSV']);
        $this->assertDatabaseHas('matieres', ['CodeMatiere' => 'MAT-CSV']);
        $this->assertDatabaseHas('annees', ['CodeAnnee' => '2027']);
        $this->assertDatabaseHas('sequence_evaluations', ['CodeEvaluation' => 'EVAL-CSV']);
        $this->assertDatabaseHas('eleves', ['CodeEleve' => 'STU-CSV', 'CodeAnnee' => '2027']);
        $this->assertDatabaseHas('eleves', [
            'CodeEleve' => 'STU-CSV',
            'DateNaissance' => '2012-03-04',
            'LieuNaissance' => 'Douala',
            'Sex' => 'F',
            'Nationalite' => 'Camerounaise',
            'dateinscription' => '2026-09-01',
            'photo' => 'student-photo.jpg',
            'Nomp' => 'Parent One',
            'TelP' => '699111111',
            'PROFP' => 'Enseignant parent',
            'PERSONCON' => 'Urgence',
            'RESERVE1' => 'STU-RES-1',
            'RESERVE2' => 'STU-RES-2',
            'RESERVE3' => 'STU-RES-3',
            'RESERVE4' => 'STU-RES-4',
        ]);
        $this->assertDatabaseHas('users', [
            'code' => 'TEACHER-CSV',
            'nom' => 'Teacher',
            'prenom' => 'Imported',
            'DateDeNaissance' => '1980-01-02',
            'LieuDeNaissance' => 'Yaounde',
            'nationalite' => 'Camerounaise',
            'sex' => '0',
            'DatePriseService' => '2000-09-01',
            'login' => 'teacher.csv',
            'contacts' => '123456',
            'cdegrade' => 'Grade A',
            'nbrand' => 7,
            'matricule' => 'MAT-CSV',
            'reserve1' => 'USR-RES-1',
            'reserve2' => 'USR-RES-2',
            'reserve3' => 'USR-RES-3',
            'reserve4' => 'USR-RES-4',
            'reserve5' => 'USR-RES-5',
            'reserve6' => 'USR-RES-6',
            'cat' => 'CAT-A',
            'echel' => 'ECH-A',
            'statut' => 'ACTIVE',
            'reserve7' => 'USR-RES-7',
            'reserve9' => 'USR-RES-9',
            'CodeBank' => 'BANK-1',
            'numcpt' => 'ACCOUNT-1',
            'ribcpt' => 'RIB-1',
            'TauhH' => 'TAUX-1',
            'syndicat' => 'SYNDICAT-1',
            'NumAssure' => 'ASSURE-1',
            'CodeEtablissement' => 'SCHOOL-CSV',
        ]);
        $this->assertDatabaseHas('enseignements', ['CodeEnseignement' => 'ENSEIGNEMENT-CSV']);
        $this->assertDatabaseHas('notes', ['CodeEleve' => 'STU-CSV']);
        $this->assertDatabaseHas('tranche_scholarites', ['code' => 'TRANCHE-CSV']);
        $this->assertDatabaseHas('inscriptions', ['NUMFAC' => 'INVOICE-CSV']);
        $this->assertDatabaseHas('historique_inscriptions', ['NUMFAC' => 'HISTORY-CSV']);

        $this->get(route('add_school'))
            ->assertOk()
            ->assertSee('Imported school');
        $this->get(route('add_class', ['CodeEtablissement' => 'SCHOOL-CSV']))
            ->assertOk()
            ->assertSee('Imported class');
        $this->get(route('courses', ['CodeEtablissement' => 'SCHOOL-CSV']))
            ->assertOk()
            ->assertSee('Français; grammaire');
        $this->get(route('enseignements', ['CodeEtablissement' => 'SCHOOL-CSV']))
            ->assertOk()
            ->assertSee('ENSEIGNEMENT-CSV');
        DB::flushQueryLog();
        DB::enableQueryLog();
        $notesPage = $this->get(route('notes', [
            'CodeClasse' => 'CLS-CSV',
            'CodeEtablissement' => 'SCHOOL-CSV',
        ]));
        $noteQueries = array_filter(
            DB::getQueryLog(),
            fn (array $query): bool => str_contains(strtolower($query['query']), 'from "notes"')
        );
        DB::disableQueryLog();
        $notesPage->assertOk()->assertSee('Élève');
        $this->assertCount(1, $noteQueries);
        $this->get(route('sorted_notes', [
            'CodeEtablissement' => 'SCHOOL-CSV',
            'CodeClasse' => 'CLS-CSV',
            'CodeEnseignement' => 'ENSEIGNEMENT-CSV',
            'CodeEvaluation' => 'EVAL-CSV',
            'CodeAnnee' => '2027',
        ]))
            ->assertOk()
            ->assertSee('Élève');
        $this->get(route('add_student', ['CodeEtablissement' => 'SCHOOL-CSV']))
            ->assertOk()
            ->assertSee('Élève');
        $this->get(route('add_year'))
            ->assertOk()
            ->assertSee('2027/2028');
        $this->get(route('sequence_evaluation'))
            ->assertOk()
            ->assertSee('Première séquence');
    }

    public function test_empty_csv_is_rejected_safely(): void
    {
        $this->post(route('import_classes'), [
            'csv_file' => UploadedFile::fake()->createWithContent('empty.csv', ''),
        ])->assertRedirect()
            ->assertSessionHasErrors('csv_file');
    }

    public function test_missing_csv_upload_is_rejected_safely(): void
    {
        $this->post(route('import_classes'))
            ->assertRedirect()
            ->assertSessionHasErrors('csv_file');
    }

    public function test_student_csv_import_rejects_unknown_year_and_class_references(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');
        $this->createYear('2026');

        $this->post(route('import_students'), [
            'csv_file' => UploadedFile::fake()->createWithContent(
                'students.csv',
                "STU-YEAR;MISSING-YEAR;CLS-1;CONDUITE;Nom;Prenom\n"
            ),
        ])->assertRedirect('add_student_home')
            ->assertSessionHasErrors('csv_file');

        $this->post(route('import_students'), [
            'csv_file' => UploadedFile::fake()->createWithContent(
                'students.csv',
                "STU-CLASS;2026;MISSING-CLASS;CONDUITE;Nom;Prenom\n"
            ),
        ])->assertRedirect('add_student_home')
            ->assertSessionHasErrors('csv_file');

        $this->assertDatabaseMissing('eleves', ['CodeEleve' => 'STU-YEAR']);
        $this->assertDatabaseMissing('eleves', ['CodeEleve' => 'STU-CLASS']);
    }

    /**
     * @dataProvider legacyImportRoutes
     */
    public function test_each_legacy_import_rejects_short_rows(string $routeName): void
    {
        if ($routeName === 'import_users') {
            $this->actingAsAdministrator();
        }

        $this->post(route($routeName), [
            'csv_file' => $this->csvUpload('short.csv', "too-short\n"),
        ])->assertRedirect()->assertSessionHasErrors('csv_file');
    }

    public static function legacyImportRoutes(): array
    {
        return [
            'schools' => ['import_schools'],
            'classes' => ['import_classes'],
            'subjects' => ['import_courses'],
            'notes' => ['import_notes'],
            'teachings' => ['import_enseignements'],
            'academic years' => ['import_years'],
            'evaluation sequences' => ['import_sequences'],
            'students' => ['import_students'],
            'users' => ['import_users'],
            'tuition tranches' => ['import_tranches'],
            'inscriptions' => ['import_inscriptions'],
            'historical inscriptions' => ['import_historique_inscriptions'],
        ];
    }

    public function test_legacy_import_rejects_wrong_file_type(): void
    {
        $this->post(route('import_classes'), [
            'csv_file' => UploadedFile::fake()->create('not-a-csv.pdf', 10, 'application/pdf'),
        ])->assertRedirect()->assertSessionHasErrors('csv_file');
    }

    public function test_legacy_import_rejects_malformed_and_excess_column_rows(): void
    {
        $this->post(route('import_classes'), [
            'csv_file' => $this->csvUpload('malformed.csv', "CLS-1;\"unterminated\n"),
        ])->assertRedirect()->assertSessionHasErrors('csv_file');

        $this->post(route('import_classes'), [
            'csv_file' => $this->csvUpload(
                'extra-columns.csv',
                "CLS-1;TYPE;Class;CYCLE;SPEC;INS;12301;unexpected\n"
            ),
        ])->assertRedirect()->assertSessionHasErrors('csv_file');

        $this->assertDatabaseMissing('classes', ['CodeClasse' => 'CLS-1']);
    }

    public function test_legacy_import_skips_exact_importer_header_and_keeps_headerless_rows(): void
    {
        $this->createSchool('12301');
        $this->post(route('import_classes'), [
            'csv_file' => $this->csvUpload(
                'classes.csv',
                "CodeClasse;CodeTypeClasse;LibelleClasse;CodeCycle;CodeSpecialite;codetypeinscrip;CodeEtablissement\n"
                    ."CLS-HEADER;TYPE;Header class;CYCLE;SPEC;INS;12301\n"
            ),
        ])->assertRedirect('add_class');

        $this->post(route('import_classes'), [
            'csv_file' => $this->csvUpload(
                'headerless-classes.csv',
                "CLS-NO-HEADER;TYPE;Headerless class;CYCLE;SPEC;INS;12301\n"
            ),
        ])->assertRedirect('add_class');

        $this->assertDatabaseHas('classes', ['CodeClasse' => 'CLS-HEADER']);
        $this->assertDatabaseHas('classes', ['CodeClasse' => 'CLS-NO-HEADER']);
        $this->assertDatabaseCount('classes', 2);
    }

    public function test_header_like_but_nonmatching_first_row_is_validated_as_data(): void
    {
        $this->createSchool('12301');

        $this->post(route('import_classes'), [
            'csv_file' => $this->csvUpload(
                'header-like.csv',
                "CodeClasseX;CodeTypeClasse;LibelleClasse;CodeCycle;CodeSpecialite;codetypeinscrip;MISSING-SCHOOL\n"
            ),
        ])->assertRedirect('add_class')->assertSessionHasErrors('csv_file');

        $this->assertDatabaseMissing('classes', ['CodeClasse' => 'CodeClasseX']);
    }

    public function test_student_update_preserves_optional_fields_when_present_csv_cells_are_blank(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');
        $this->createYear('2026');
        $this->createStudent('STU-BLANK', 'CLS-1', '2026', 'Existing name');
        DB::table('eleves')->where('CodeEleve', 'STU-BLANK')->update([
            'CodeConduite' => 'CONDUCT-1',
            'DateNaissance' => '2010-01-01',
            'PROFP' => 'Existing profession',
            'RESERVE1' => 'Existing reserve 1',
            'RESERVE4' => 'Existing reserve 4',
        ]);

        $columns = array_fill(0, 36, '');
        $columns[0] = 'STU-BLANK';
        $columns[1] = '2026';
        $columns[2] = 'CLS-1';
        $this->post(route('import_students'), [
            'csv_file' => $this->csvUpload('students.csv', implode(';', $columns)."\n"),
        ])->assertRedirect('add_student_home');

        $this->assertDatabaseHas('eleves', [
            'CodeEleve' => 'STU-BLANK',
            'CodeConduite' => 'CONDUCT-1',
            'Nom' => 'Existing name',
            'DateNaissance' => '2010-01-01',
            'PROFP' => 'Existing profession',
            'RESERVE1' => 'Existing reserve 1',
            'RESERVE4' => 'Existing reserve 4',
        ]);
    }

    public function test_new_student_import_accepts_blank_optional_csv_values(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');
        $this->createYear('2026');
        $columns = array_fill(0, 25, '');
        $columns[0] = 'STU-NEW-BLANK';
        $columns[1] = '2026';
        $columns[2] = 'CLS-1';
        $columns[4] = 'New';
        $columns[5] = 'Student';

        $this->post(route('import_students'), [
            'csv_file' => $this->csvUpload('students.csv', implode(';', $columns)."\n"),
        ])->assertRedirect('add_student_home');

        $this->assertDatabaseHas('eleves', [
            'CodeEleve' => 'STU-NEW-BLANK',
            'Nom' => 'New',
            'Prenom' => 'Student',
            'DateNaissance' => '',
            'PROFP' => '',
        ]);
    }

    public function test_existing_school_csv_record_is_updated_without_deleting_related_classes(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-KEEP', '12301');

        $this->post(route('import_schools'), [
            'csv_file' => $this->csvUpload('schools.csv', "12301;Cameroun;Updated school;999;888\n"),
        ])->assertRedirect('add_school');

        $this->assertDatabaseHas('etablissements', [
            'CodeEtablissement' => '12301',
            'Nom' => 'Updated school',
            'Tel' => '888',
        ]);
        $this->assertDatabaseHas('classes', ['CodeClasse' => 'CLS-KEEP']);
    }

    public function test_short_student_csv_update_preserves_existing_unmapped_student_data(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');
        $this->createYear('2026');
        $this->createStudent('STU-1', 'CLS-1', '2026', 'Existing name');
        DB::table('eleves')->where('CodeEleve', 'STU-1')->update([
            'code' => 'PARENT-1',
            'DateNaissance' => '2010-01-01',
            'Image' => 'existing-image.jpg',
            'RESIDENT' => 'Existing residence',
            'TELM' => '699000000',
            'PROFP' => 'Existing occupation',
        ]);

        $this->post(route('import_students'), [
            'csv_file' => $this->csvUpload(
                'students.csv',
                "STU-1;2026;CLS-1;CONDUITE;Updated;Student\n"
            ),
        ])->assertRedirect('add_student_home');

        $this->assertDatabaseHas('eleves', [
            'CodeEleve' => 'STU-1',
            'Nom' => 'Updated',
            'code' => 'PARENT-1',
            'DateNaissance' => '2010-01-01',
            'Image' => 'existing-image.jpg',
            'RESIDENT' => 'Existing residence',
            'TELM' => '699000000',
            'PROFP' => 'Existing occupation',
        ]);
    }

    public function test_notes_import_appends_using_auto_increment_id_without_deleting_existing_notes(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');
        $this->createYear('2026');
        $this->createStudent('STU-1', 'CLS-1', '2026', 'Existing');
        SequenceEvaluation::query()->create([
            'CodeEvaluation' => 'EVAL-1',
            'LibelleEvaluation' => 'Sequence 1',
        ]);
        DB::table('enseignements')->insert([
            'CodeEnseignement' => 'ENS-1',
            'CodeMatiere' => 'MAT-1',
            'code' => 'TEACHER-1',
            'CodeClasse' => 'CLS-1',
            'CodeEtablissement' => '12301',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('notes')->insert([
            'id' => 1,
            'CodeEnseignement' => 'UNRELATED-TEACHING',
            'CodeEleve' => 'STU-1',
            'CodeEvaluation' => 'EVAL-1',
            'CodeAnnee' => '2026',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $csv = "ENS-1;STU-1;EVAL-1;APP;15;1;15;2026-09-01;2026\n";
        $this->post(route('import_notes'), [
            'csv_file' => $this->csvUpload('notes.csv', $csv),
        ])->assertRedirect('notes_home');

        $this->assertDatabaseHas('notes', [
            'id' => 1,
            'CodeEnseignement' => 'UNRELATED-TEACHING',
        ]);
        $this->assertDatabaseHas('notes', [
            'id' => 2,
            'CodeEnseignement' => 'ENS-1',
            'CodeEleve' => 'STU-1',
            'CodeEvaluation' => 'EVAL-1',
            'CodeAnnee' => '2026',
            'Total' => '15',
        ]);

        $this->post(route('import_notes'), [
            'csv_file' => $this->csvUpload('notes.csv', $csv),
        ])->assertRedirect('notes_home');
        $this->assertDatabaseCount('notes', 3);
    }

    public function test_inscription_import_updates_existing_numfac_instead_of_duplicate_insert(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');
        $this->createYear('2026');
        $this->createStudent('STU-1', 'CLS-1', '2026', 'Student');
        TrancheScholarite::query()->create([
            'code' => 'TR-1',
            'libellet' => 'First tranche',
        ]);
        $firstCsv = "INV-1;REG-1;STU-1;2026-09-01 08:00:00;TR-1;2026;100;50;50;100;Fees;08:00;Admin;0\n";
        $this->post(route('import_inscriptions'), [
            'csv_file' => $this->csvUpload('inscriptions.csv', $firstCsv),
        ])->assertRedirect('inscriptions_home');

        $updatedCsv = "INV-1;REG-2;STU-1;2026-09-02 08:00:00;TR-1;2026;200;100;100;200;Updated fees;09:00;Admin;0\n";
        $this->post(route('import_inscriptions'), [
            'csv_file' => $this->csvUpload('inscriptions.csv', $updatedCsv),
        ])->assertRedirect('inscriptions_home');

        $this->assertDatabaseCount('inscriptions', 1);
        $this->assertDatabaseHas('inscriptions', [
            'NUMFAC' => 'INV-1',
            'CodeInscription' => 'REG-2',
            'Montantins' => 200,
            'libinscrip' => 'Updated fees',
        ]);
    }

    public function test_historical_inscription_import_appends_because_schema_has_no_primary_key(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');
        $this->createYear('2026');
        $this->createStudent('STU-1', 'CLS-1', '2026', 'Student');
        TrancheScholarite::query()->create([
            'code' => 'TR-1',
            'libellet' => 'First tranche',
        ]);
        $csv = "HIST-1;REG-1;STU-1;2026-09-01 08:00:00;TR-1;2026;100;50;50;100;Fees;08:00;Admin;0\n";

        $this->post(route('import_historique_inscriptions'), [
            'csv_file' => $this->csvUpload('history.csv', $csv),
        ])->assertRedirect('historique_inscriptions_home');
        $this->post(route('import_historique_inscriptions'), [
            'csv_file' => $this->csvUpload('history.csv', $csv),
        ])->assertRedirect('historique_inscriptions_home');

        $this->assertDatabaseCount('historique_inscriptions', 2);
        $this->assertDatabaseHas('historique_inscriptions', [
            'NUMFAC' => 'HIST-1',
            'CodeEleve' => 'STU-1',
        ]);
    }

    public function test_legacy_imports_reject_invalid_references_before_writing(): void
    {
        $this->actingAsAdministrator();
        $teacherColumns = array_fill(0, 32, '');
        $teacherColumns[0] = 'TEACHER-BAD-SCHOOL';
        $teacherColumns[1] = 'Teacher';
        $teacherColumns[2] = 'Invalid';
        $teacherColumns[6] = '0';
        $teacherColumns[8] = 'invalid-school.csv';
        $teacherColumns[9] = '123';
        $teacherColumns[31] = 'MISSING-SCHOOL';
        $this->post(route('import_users'), [
            'csv_file' => $this->csvUpload('teachers.csv', implode(';', $teacherColumns)."\n"),
        ])->assertRedirect('add_user')->assertSessionHasErrors('csv_file');
        $this->assertDatabaseMissing('users', ['code' => 'TEACHER-BAD-SCHOOL']);

        $this->post(route('import_enseignements'), [
            'csv_file' => $this->csvUpload(
                'teachings.csv',
                "ENS-BAD;MAT-MISSING;TEACHER-MISSING;CLS-MISSING;SCHOOL-MISSING;;;;;;;;;;;;\n"
            ),
        ])->assertRedirect('enseignement_home')->assertSessionHasErrors('csv_file');
        $this->assertDatabaseMissing('enseignements', ['CodeEnseignement' => 'ENS-BAD']);

        $this->post(route('import_notes'), [
            'csv_file' => $this->csvUpload(
                'notes.csv',
                "ENS-MISSING;STU-MISSING;EVAL-MISSING;;;;;;YEAR-MISSING\n"
            ),
        ])->assertRedirect('notes_home')->assertSessionHasErrors('csv_file');
        $this->assertDatabaseCount('notes', 0);

        $this->post(route('import_inscriptions'), [
            'csv_file' => $this->csvUpload(
                'inscriptions.csv',
                "INV-BAD;REG;STU-MISSING;2026-09-01;TR-MISSING;YEAR-MISSING;100;0;100;100;Fees;08:00;Admin;0\n"
            ),
        ])->assertRedirect('inscriptions_home')->assertSessionHasErrors('csv_file');
        $this->assertDatabaseMissing('inscriptions', ['NUMFAC' => 'INV-BAD']);

        $this->post(route('import_tranches'), [
            'csv_file' => $this->csvUpload('tranches.csv', "TR-BAD;Missing default school\n"),
        ])->assertRedirect('tranches_scholarites_home')->assertSessionHasErrors('csv_file');
        $this->assertDatabaseMissing('tranche_scholarites', ['code' => 'TR-BAD']);
    }

    public function test_user_import_exception_uses_standard_error_response(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('SCHOOL-IMPORT-FAILURE');

        DB::unprepared(
            "CREATE TRIGGER fail_user_import BEFORE INSERT ON users
            BEGIN
                SELECT RAISE(ABORT, 'password=DO_NOT_EXPOSE_PASSWORD; api_key=DO_NOT_EXPOSE_API_KEY; token=DO_NOT_EXPOSE_TOKEN');
            END;"
        );

        $columns = array_fill(0, 32, '');
        $columns[0] = 'IMPORT-FAILURE-USER';
        $columns[1] = 'Example';
        $columns[2] = 'Person';
        $columns[6] = 'F';
        $columns[8] = 'example.login';
        $columns[9] = '000000000';
        $columns[11] = '1';
        $columns[31] = 'SCHOOL-IMPORT-FAILURE';
        $header = implode(';', [
            'code', 'nom', 'prenom', 'DateDeNaissance', 'LieuDeNaissance', 'nationalite',
            'sex', 'DatePriseService', 'login', 'contacts', 'cdegrade', 'nbrand', 'matricule',
            'reserve1', 'reserve2', 'reserve3', 'reserve4', 'reserve5', 'reserve6', 'cat',
            'echel', 'statut', 'reserve7', 'reserve8', 'reserve9', 'CodeBank', 'numcpt',
            'ribcpt', 'TauhH', 'syndicat', 'NumAssure', 'CodeEtablissement',
        ]);
        $response = $this->post(route('import_users'), [
            'csv_file' => $this->csvUpload(
                'import-failure.csv',
                $header . "\n" . implode(';', $columns) . "\n"
            ),
        ]);

        $response->assertStatus(500);
    }

    public function test_notes_page_renders_a_friendly_empty_state_without_teaching_records(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');

        $this->get(route('notes', [
            'CodeClasse' => 'CLS-1',
            'CodeEtablissement' => '12301',
        ]))
            ->assertOk()
            ->assertSee('Aucune note disponible pour cette classe et ces critères.');
    }

    public function test_admin_dashboard_data_pages_render_when_their_collections_are_empty(): void
    {
        $routes = [
            'add_school',
            'add_class',
            'course_home',
            'notes_home',
            'enseignement_home',
            'add_student_home',
            'add_user',
            'add_year',
            'sequence_evaluation',
            'tranches_scholarites_home',
            'inscriptions_home',
            'historique_inscriptions_home',
        ];

        foreach ($routes as $routeName) {
            if ($routeName === 'add_user') {
                $this->actingAsAdministrator();
            }
            $this->get(route($routeName))
                ->assertOk();
        }
    }

    public function test_teaching_page_handles_missing_related_records(): void
    {
        $this->createSchool('12301');

        DB::table('enseignements')->insert([
            'CodeEnseignement' => 'ENS-ORPHAN',
            'CodeMatiere' => 'MISSING-SUBJECT',
            'code' => 'MISSING-TEACHER',
            'CodeClasse' => 'MISSING-CLASS',
            'CodeEtablissement' => '12301',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->get(route('enseignements', ['CodeEtablissement' => '12301']))
            ->assertOk()
            ->assertSee('ENS-ORPHAN');
    }

    public function test_academic_year_primary_key_configuration_matches_string_schema_and_create_route(): void
    {
        $this->assertFalse((new Annee())->getIncrementing());
        $this->assertSame('string', (new Annee())->getKeyType());
        $this->assertFalse((new SequenceEvaluation())->getIncrementing());
        $this->assertSame('string', (new SequenceEvaluation())->getKeyType());
        $this->assertFalse((new TrancheScholarite())->getIncrementing());
        $this->assertSame('string', (new TrancheScholarite())->getKeyType());
        $this->assertSame('NUMFAC', (new \App\Models\Inscription())->getKeyName());
        $this->assertFalse((new \App\Models\Inscription())->getIncrementing());

        $this->post(route('add_year_complete'), [
            'CodeAnnee' => '2027',
            'Libelle' => '2027/2028',
        ])->assertRedirect(route('add_year'));

        $this->assertDatabaseHas('annees', [
            'CodeAnnee' => '2027',
            'Libelle' => '2027/2028',
        ]);
    }

    public function test_delete_year_succeeds_and_invalid_year_id_returns_not_found(): void
    {
        $this->createYear('2026');

        $this->get(route('delete_year', ['year_id' => '2026']))
            ->assertRedirect(route('add_year'))
            ->assertSessionHas('message');

        $this->assertDatabaseMissing('annees', ['CodeAnnee' => '2026']);

        $this->get(route('delete_year', ['year_id' => 'missing']))
            ->assertNotFound();
    }

    public function test_class_creation_rejects_missing_or_nonexistent_school_without_database_error(): void
    {
        $payload = [
            'LibelleClasse' => 'Sixième',
            'CodeClasse' => 'CLS-NEW',
            'CodeTypeClasse' => 'TYPE',
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
        ];

        $this->post(route('add_class_complete'), $payload)
            ->assertRedirect()
            ->assertSessionHasErrors('CodeEtablissement');

        $this->post(route('add_class_complete'), $payload + [
            'CodeEtablissement' => 'NOT-A-SCHOOL',
        ])
            ->assertRedirect()
            ->assertSessionHasErrors('CodeEtablissement');
    }

    public function test_user_assignment_pages_reject_missing_parent_class_or_year_gracefully(): void
    {
        $this->actingAsAdministrator();
        $this->get(route('choose_student', [
            'parent_id' => 'MISSING-PARENT',
            'CodeClasse' => 'MISSING-CLASS',
            'CodeAnnee' => 'MISSING-YEAR',
        ]))
            ->assertRedirect(route('add_user'))
            ->assertSessionHasErrors('filters');

        $this->get(route('assign_student_complete', [
            'parent_id' => 'MISSING-PARENT',
            'student_id' => 'MISSING-STUDENT',
            'code_annee' => 'MISSING-YEAR',
        ]))
            ->assertRedirect(route('add_user'))
            ->assertSessionHasErrors('student');
    }

    public function test_admin_encadreur_form_creates_a_valid_encadreur_account(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createClass('CLS-A1', '12301');
        $this->createClass('CLS-A2', '12301');

        $this->post(route('add_user_complete'), [
            'account_type' => 'encadreur',
            'nom' => 'Ateba',
            'prenom' => 'Sam',
            'contacts' => '123456',
            'sex' => 'male',
            'code' => 'ENC-1',
            'school_id' => '12301',
            'password' => 'temporary-password',
            'class_ids' => ['CLS-A1', 'CLS-A2'],
        ])
            ->assertRedirect(route('add_user'));

        $this->assertDatabaseHas('users', [
            'code' => 'ENC-1',
            'account_type' => 'encadreur',
            'CodeEtablissement' => '12301',
        ]);
        $this->assertDatabaseHas('encadreur_classes', [
            'code' => 'ENC-1',
            'CodeClasse' => 'CLS-A1',
            'CodeEtablissement' => '12301',
        ]);
        $this->assertDatabaseHas('encadreur_classes', [
            'code' => 'ENC-1',
            'CodeClasse' => 'CLS-A2',
            'CodeEtablissement' => '12301',
        ]);
    }

    public function test_encadreur_class_assignments_remain_available_after_transition_to_teacher(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createClass('CLS-ASSIGNED', '12301');
        $this->createClass('CLS-UNASSIGNED', '12301');
        $this->createClass('CLS-OTHER-SCHOOL', '45601');
        $this->createUser('ENC-TRANSITION', '12301', 'Jean Dupont');
        DB::table('users')->where('code', 'ENC-TRANSITION')->update(['account_type' => 'encadreur']);
        DB::table('encadreur_classes')->insert([
            [
                'code' => 'ENC-TRANSITION',
                'CodeClasse' => 'CLS-ASSIGNED',
                'CodeEtablissement' => '12301',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'code' => 'ENC-TRANSITION',
                'CodeClasse' => 'CLS-OTHER-SCHOOL',
                'CodeEtablissement' => '45601',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
        DB::table('enseignements')->insert([
            [
                'CodeEnseignement' => 'ENS-ASSIGNED',
                'CodeMatiere' => 'MAT-1',
                'code' => 'OTHER-TEACHER',
                'CodeClasse' => 'CLS-ASSIGNED',
                'CodeEtablissement' => '12301',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'CodeEnseignement' => 'ENS-UNASSIGNED',
                'CodeMatiere' => 'MAT-2',
                'code' => 'OTHER-TEACHER',
                'CodeClasse' => 'CLS-UNASSIGNED',
                'CodeEtablissement' => '12301',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $this->get(route('admin.users.edit-form', ['user_id' => 'ENC-TRANSITION']))
            ->assertOk()
            ->assertSee('user-edit-form', false)
            ->assertSee('CLS-ASSIGNED', false);
        $this->get(route('add_user', ['CodeEtablissement' => '12301']))
            ->assertOk()
            ->assertSee('#user-edit-modal-content > .modal-body', false)
            ->assertSee('max-height: 18rem', false)
            ->assertSee('overflow-y: auto', false);

        $this->get(route('admin.users.classes', [
            'school' => '12301',
            'encadreur_code' => 'ENC-TRANSITION',
        ]))
            ->assertOk()
            ->assertJsonFragment([
                'CodeClasse' => 'CLS-ASSIGNED',
                'assignedToCurrentEncadreur' => true,
            ])
            ->assertJsonMissing(['CodeClasse' => 'CLS-OTHER-SCHOOL']);

        $this->post(route('save_user', ['user_id' => 'ENC-TRANSITION']), [
            'account_type' => 'enseignant',
            'nom' => 'Jean',
            'prenom' => 'Dupont',
            'contacts' => '123456',
            'sex' => '0',
            'login' => 'Jean Dupont',
            'code' => 'ENC-TRANSITION',
            'password' => 'temporary-password',
            'school_id' => '12301',
            'class_ids' => ['CLS-ASSIGNED'],
        ])->assertRedirect(route('add_user'));

        $this->assertDatabaseHas('encadreur_classes', [
            'code' => 'ENC-TRANSITION',
            'CodeClasse' => 'CLS-ASSIGNED',
            'CodeEtablissement' => '12301',
        ]);
        $this->assertDatabaseMissing('encadreur_classes', [
            'code' => 'ENC-TRANSITION',
            'CodeEtablissement' => '45601',
        ]);

        $this->postJson('/api/school_manager', [
            'action' => 'GET_TEACHER_COURSES',
            'teacher_code' => 'ENC-TRANSITION',
        ])
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonFragment(['CodeEnseignement' => 'ENS-ASSIGNED'])
            ->assertJsonMissing(['CodeEnseignement' => 'ENS-UNASSIGNED']);

        $this->post(route('save_user', ['user_id' => 'ENC-TRANSITION']), [
            'account_type' => 'encadreur',
            'nom' => 'Jean',
            'prenom' => 'Dupont',
            'contacts' => '123456',
            'sex' => '0',
            'login' => 'Jean Dupont',
            'code' => 'ENC-TRANSITION',
            'password' => 'temporary-password',
            'school_id' => '12301',
            'class_ids' => ['CLS-ASSIGNED'],
        ])->assertRedirect(route('add_user'));

        $this->assertSame(1, DB::table('encadreur_classes')
            ->where('code', 'ENC-TRANSITION')
            ->where('CodeClasse', 'CLS-ASSIGNED')
            ->count());
    }

    public function test_changing_encadreur_to_non_assignment_role_removes_class_assignments(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createClass('CLS-A1', '12301');
        $this->createUser('ENC-OTHER-ROLE', '12301', 'Former Encadreur');
        DB::table('users')->where('code', 'ENC-OTHER-ROLE')->update(['account_type' => 'encadreur']);
        DB::table('encadreur_classes')->insert([
            'code' => 'ENC-OTHER-ROLE',
            'CodeClasse' => 'CLS-A1',
            'CodeEtablissement' => '12301',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->post(route('save_user', ['user_id' => 'ENC-OTHER-ROLE']), [
            'account_type' => 'parent',
            'nom' => 'Former',
            'prenom' => 'Encadreur',
            'contacts' => '123456',
            'sex' => '0',
            'login' => 'Former Encadreur',
            'code' => 'ENC-OTHER-ROLE',
            'password' => 'temporary-password',
            'school_id' => '12301',
        ])->assertRedirect(route('add_user'));

        $this->assertDatabaseMissing('encadreur_classes', ['code' => 'ENC-OTHER-ROLE']);
    }

    public function test_encadreur_checkbox_list_shows_available_and_owned_class_status(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createClass('CLS-A1', '12301');
        $this->createClass('CLS-A2', '12301');
        $this->createUser('ENC-OWNER', '12301', 'Jean Dupont');
        DB::table('users')->where('code', 'ENC-OWNER')->update(['account_type' => 'encadreur']);
        DB::table('encadreur_classes')->insert([
            'code' => 'ENC-OWNER',
            'CodeClasse' => 'CLS-A1',
            'CodeEtablissement' => '12301',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->get(route('add_user', ['CodeEtablissement' => '12301']))
            ->assertOk()
            ->assertSee('js-encadreur-classes-list')
            ->assertSee("checkbox.type = 'checkbox'", false)
            ->assertSee("checkbox.name = 'class_ids[]'", false);

        $this->get(route('admin.users.classes', ['school' => '12301']))
            ->assertOk()
            ->assertJsonFragment([
                'CodeClasse' => 'CLS-A1',
                'assignedToEncadreurCode' => 'ENC-OWNER',
                'assignedToEncadreurName' => 'Jean Dupont Staff',
                'assignedToCurrentEncadreur' => false,
            ])
            ->assertJsonFragment([
                'CodeClasse' => 'CLS-A2',
                'assignedToEncadreurCode' => null,
                'assignedToEncadreurName' => null,
                'assignedToCurrentEncadreur' => false,
            ]);

        $this->get(route('admin.users.classes', [
            'school' => '12301',
            'encadreur_code' => 'ENC-OWNER',
        ]))
            ->assertOk()
            ->assertJsonFragment([
                'CodeClasse' => 'CLS-A1',
                'assignedToCurrentEncadreur' => true,
            ]);
    }

    public function test_encadreur_creation_rejects_another_encadreur_class_with_owner_details(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createClass('CLS-A1', '12301');
        $this->createUser('ENC-OWNER', '12301', 'Jean Dupont');
        DB::table('users')->where('code', 'ENC-OWNER')->update(['account_type' => 'encadreur']);
        DB::table('encadreur_classes')->insert([
            'code' => 'ENC-OWNER',
            'CodeClasse' => 'CLS-A1',
            'CodeEtablissement' => '12301',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->from(route('add_user', ['CodeEtablissement' => '12301']))
            ->post(route('add_user_complete'), [
                'account_type' => 'encadreur',
                'nom' => 'Ateba',
                'prenom' => 'Sam',
                'contacts' => '123456',
                'sex' => 'male',
                'code' => 'ENC-DUPLICATE',
                'school_id' => '12301',
                'password' => 'temporary-password',
                'class_ids' => ['CLS-A1'],
            ])
            ->assertRedirect(route('add_user', ['CodeEtablissement' => '12301']))
            ->assertSessionHasErrors('class_ids');

        $this->assertStringContainsString(
            'Classe déjà attribuée. La classe Class CLS-A1 est déjà attribuée à Jean Dupont Staff.',
            implode(' ', $response->getSession()->get('errors')->getBag('default')->get('class_ids'))
        );
        $this->assertDatabaseMissing('users', ['code' => 'ENC-DUPLICATE']);
    }

    public function test_encadreur_edit_keeps_own_classes_and_rejects_classes_owned_by_another_encadreur(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createClass('CLS-OWN', '12301');
        $this->createClass('CLS-OTHER', '12301');
        $this->createUser('ENC-EDIT', '12301', 'Edit Owner');
        $this->createUser('ENC-OWNER', '12301', 'Jean Dupont');
        DB::table('users')
            ->whereIn('code', ['ENC-EDIT', 'ENC-OWNER'])
            ->update(['account_type' => 'encadreur']);
        DB::table('encadreur_classes')->insert([
            [
                'code' => 'ENC-EDIT',
                'CodeClasse' => 'CLS-OWN',
                'CodeEtablissement' => '12301',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'code' => 'ENC-OWNER',
                'CodeClasse' => 'CLS-OTHER',
                'CodeEtablissement' => '12301',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $this->post(route('save_user', ['user_id' => 'ENC-EDIT']), [
            'account_type' => 'encadreur',
            'nom' => 'Edit',
            'prenom' => 'Owner',
            'contacts' => '123456',
            'sex' => '0',
            'login' => 'Edit Owner',
            'code' => 'ENC-EDIT',
            'password' => 'temporary-password',
            'school_id' => '12301',
            'class_ids' => ['CLS-OWN', 'CLS-OTHER'],
        ])
            ->assertRedirect()
            ->assertSessionHasErrors('class_ids');

        $errors = session('errors')->getBag('default')->get('class_ids');
        $this->assertStringContainsString('Class CLS-OTHER', implode(' ', $errors));
        $this->assertStringContainsString('Jean Dupont Staff', implode(' ', $errors));
        $this->assertDatabaseHas('encadreur_classes', [
            'code' => 'ENC-EDIT',
            'CodeClasse' => 'CLS-OWN',
            'CodeEtablissement' => '12301',
        ]);
        $this->assertDatabaseMissing('encadreur_classes', [
            'code' => 'ENC-EDIT',
            'CodeClasse' => 'CLS-OTHER',
        ]);
    }

    public function test_principal_creation_and_school_change_use_school_wide_access_without_class_assignments(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createClass('CLS-A1', '12301');
        $this->createClass('CLS-B1', '45601');

        $this->post(route('add_user_complete'), [
            'account_type' => 'principal',
            'nom' => 'Ateba',
            'prenom' => 'Sam',
            'contacts' => '123456',
            'sex' => '0',
            'code' => 'PRIN-1',
            'school_id' => '12301',
            'password' => 'temporary-password',
        ])->assertRedirect(route('add_user'));

        $this->assertDatabaseHas('users', [
            'code' => 'PRIN-1',
            'account_type' => 'principal',
            'CodeEtablissement' => '12301',
        ]);
        $this->assertDatabaseMissing('encadreur_classes', ['code' => 'PRIN-1']);

        $principal = User::findOrFail('PRIN-1');
        $this->assertSame('12301', app(\App\Services\PrincipalContextService::class)->resolve($principal)['school_code']);

        $this->post(route('save_user', ['user_id' => 'PRIN-1']), [
            'account_type' => 'principal',
            'nom' => $principal->nom,
            'prenom' => $principal->prenom,
            'contacts' => $principal->contacts,
            'sex' => $principal->sex,
            'login' => $principal->login,
            'code' => 'PRIN-1',
            'password' => 'temporary-password',
            'school_id' => '45601',
        ])->assertRedirect(route('add_user'));

        $principal->refresh();
        $this->assertSame('45601', $principal->CodeEtablissement);
        $this->assertSame('45601', app(\App\Services\PrincipalContextService::class)->resolve($principal)['school_code']);
        $this->assertDatabaseMissing('encadreur_classes', ['code' => 'PRIN-1']);
    }

    public function test_encadreur_rejects_classes_from_another_school_and_class_endpoint_is_school_scoped(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createClass('CLS-A1', '12301');
        $this->createClass('CLS-B1', '45601');

        $this->get(route('admin.users.classes', ['school' => '12301']))
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonFragment(['CodeClasse' => 'CLS-A1'])
            ->assertJsonMissing(['CodeClasse' => 'CLS-B1']);

        $this->post(route('add_user_complete'), [
            'account_type' => 'encadreur',
            'nom' => 'Ateba',
            'prenom' => 'Sam',
            'contacts' => '123456',
            'sex' => 'male',
            'code' => 'ENC-INVALID',
            'school_id' => '12301',
            'password' => 'temporary-password',
            'class_ids' => ['CLS-B1'],
        ])->assertSessionHasErrors('class_ids.0');

        $this->assertDatabaseMissing('users', ['code' => 'ENC-INVALID']);
        $this->get(route('admin.users.classes', ['school' => 'MISSING']))
            ->assertNotFound();
    }

    public function test_encadreur_edit_replaces_assignments_atomically_when_school_changes(): void
    {
        $this->actingAsAdministrator();
        $this->createSchool('12301');
        $this->createSchool('45601');
        $this->createClass('CLS-A1', '12301');
        $this->createClass('CLS-A2', '12301');
        $this->createClass('CLS-A3', '12301');
        $this->createClass('CLS-B1', '45601');
        $this->createUser('ENC-2', '12301', 'Encadreur');
        DB::table('users')->where('code', 'ENC-2')->update(['account_type' => 'encadreur']);
        DB::table('encadreur_classes')->insert([
            [
                'code' => 'ENC-2',
                'CodeClasse' => 'CLS-A1',
                'CodeEtablissement' => '12301',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'code' => 'ENC-2',
                'CodeClasse' => 'CLS-A2',
                'CodeEtablissement' => '12301',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        $encadreurScope = app(\App\Services\EncadreurClassScope::class);
        $encadreur = User::findOrFail('ENC-2');
        $this->assertTrue($encadreurScope->ensureClassAccessForEncadreur($encadreur, 'CLS-A1'));
        $this->assertFalse($encadreurScope->ensureClassAccessForEncadreur($encadreur, 'CLS-A3'));

        $this->post(route('save_user', ['user_id' => 'ENC-2']), [
            'account_type' => 'encadreur',
            'nom' => 'Encadreur',
            'prenom' => 'Staff',
            'contacts' => '123456',
            'sex' => '0',
            'login' => 'Encadreur',
            'code' => 'ENC-2',
            'password' => 'temporary-password',
            'school_id' => '12301',
            'class_ids' => ['CLS-A1'],
        ])->assertRedirect(route('add_user'));
        $this->assertDatabaseHas('encadreur_classes', [
            'code' => 'ENC-2',
            'CodeClasse' => 'CLS-A1',
        ]);
        $this->assertDatabaseMissing('encadreur_classes', [
            'code' => 'ENC-2',
            'CodeClasse' => 'CLS-A2',
        ]);

        $this->post(route('save_user', ['user_id' => 'ENC-2']), [
            'account_type' => 'encadreur',
            'nom' => 'Encadreur',
            'prenom' => 'Staff',
            'contacts' => '123456',
            'sex' => '0',
            'login' => 'Encadreur',
            'code' => 'ENC-2',
            'password' => 'temporary-password',
            'school_id' => '45601',
            'class_ids' => ['CLS-B1'],
        ])->assertRedirect('add_user');

        $this->assertDatabaseHas('encadreur_classes', [
            'code' => 'ENC-2',
            'CodeClasse' => 'CLS-B1',
            'CodeEtablissement' => '45601',
        ]);
        $this->assertDatabaseMissing('encadreur_classes', [
            'code' => 'ENC-2',
            'CodeEtablissement' => '12301',
        ]);
        $encadreur->refresh();
        $this->assertFalse($encadreurScope->ensureClassAccessForEncadreur($encadreur, 'CLS-A1'));
        $this->assertTrue($encadreurScope->ensureClassAccessForEncadreur($encadreur, 'CLS-B1'));
    }

    public function test_user_creation_rejects_invalid_type_or_missing_password_with_validation_errors(): void
    {
        $this->actingAsAdministrator();
        $this->post(route('add_user_complete'), [
            'account_type' => 'not-a-user-type',
        ])
            ->assertRedirect()
            ->assertSessionHasErrors('account_type');

        $this->post(route('add_user_complete'), [
            'account_type' => 'administrateur',
        ])
            ->assertRedirect()
            ->assertSessionHasErrors('password');
    }

    public function test_historical_inscription_resolves_student_using_the_real_invoice_key(): void
    {
        $this->createSchool('12301');
        $this->createClass('CLS-1', '12301');
        $this->createYear('2026');
        $this->createStudent('STU-1', 'CLS-1', '2026', 'Nina');

        DB::table('inscriptions')->insert([
            'NUMFAC' => 'INV-1',
            'CodeInscription' => 'REG-1',
            'CodeEleve' => 'STU-1',
            'DateInscription' => '2026-09-01 00:00:00',
            'Tranche' => 'TR-1',
            'codeannee' => '2026',
            'Montantins' => 100,
            'Avance' => 100,
            'Reste' => 0,
            'Montantt' => 100,
            'libinscrip' => 'Inscription',
            'heure' => '08:00',
            'caissier' => 'Admin',
            'remise' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('historique_inscriptions')->insert([
            'NUMFAC' => 'INV-1',
            'CodeInscription' => 'REG-1',
            'CodeEleve' => 'STU-1',
            'DateInscription' => '2026-09-01 00:00:00',
            'Tranche' => 'TR-1',
            'codeannee' => '2026',
            'Montantins' => 100,
            'Avance' => 100,
            'Reste' => 0,
            'Montantt' => 100,
            'libinscrip' => 'Inscription',
            'heure' => '08:00',
            'caissier' => 'Admin',
            'remise' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->get(route('historique_inscriptions', ['CodeEtablissement' => '12301']))
            ->assertOk()
            ->assertSee('Nina')
            ->assertSee('Class CLS-1');
    }

    public function test_admin_record_actions_return_not_found_for_missing_ids(): void
    {
        $this->actingAsAdministrator();
        $this->get(route('delete_school', ['school_id' => 'MISSING']))
            ->assertNotFound();
        $this->post(route('save_school', ['school_id' => 'MISSING']))
            ->assertNotFound();
        $this->get(route('delete_class', ['class_id' => 'MISSING']))
            ->assertNotFound();
        $this->post(route('save_class', ['class_id' => 'MISSING']))
            ->assertNotFound();
        $this->post(route('save_year', ['year_id' => 'MISSING']))
            ->assertNotFound();
        $this->post(route('save_user', ['user_id' => 'MISSING']))
            ->assertNotFound();
    }

    private function createSchoolPageTables(): void
    {
        foreach (['encadreur_classes', 'notes', 'enseignements', 'matieres', 'eleves', 'classes', 'annees', 'etablissements', 'users', 'sequence_evaluations', 'tranche_scholarites', 'inscriptions', 'historique_inscriptions'] as $table) {
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

        Schema::create('sequence_evaluations', function (Blueprint $table): void {
            $table->string('CodeEvaluation')->primary();
            $table->string('LibelleEvaluation');
            $table->timestamps();
        });

        Schema::create('tranche_scholarites', function (Blueprint $table): void {
            $table->string('code')->primary();
            $table->string('CodeEtablissement')->default('11201');
            $table->string('libellet');
            $table->timestamps();
        });

        Schema::create('inscriptions', function (Blueprint $table): void {
            $table->string('NUMFAC')->primary();
            $table->string('CodeInscription');
            $table->string('CodeEleve');
            $table->dateTime('DateInscription')->nullable();
            $table->string('Tranche')->nullable();
            $table->string('codeannee');
            $table->float('Montantins')->nullable();
            $table->float('Avance')->nullable();
            $table->float('Reste')->nullable();
            $table->float('Montantt')->nullable();
            $table->string('libinscrip')->nullable();
            $table->string('heure')->nullable();
            $table->string('caissier')->nullable();
            $table->float('remise')->nullable();
            $table->timestamps();
        });

        Schema::create('historique_inscriptions', function (Blueprint $table): void {
            $table->string('NUMFAC');
            $table->string('CodeInscription');
            $table->string('CodeEleve');
            $table->dateTime('DateInscription')->nullable();
            $table->string('Tranche')->nullable();
            $table->string('codeannee');
            $table->float('Montantins')->nullable();
            $table->float('Avance')->nullable();
            $table->float('Reste')->nullable();
            $table->float('Montantt')->nullable();
            $table->string('libinscrip')->nullable();
            $table->string('heure')->nullable();
            $table->string('caissier')->nullable();
            $table->float('remise')->nullable();
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

        Schema::create('enseignements', function (Blueprint $table): void {
            $table->string('CodeEnseignement')->primary();
            $table->string('CodeMatiere');
            $table->string('code');
            $table->string('CodeClasse');
            $table->string('CodeEtablissement');
            $table->string('Coefficient')->nullable();
            $table->string('CodeSpecialite')->nullable();
            $table->string('CodeCycle')->nullable();
            $table->dateTime('Dateens')->nullable();
            $table->string('CodeEnseignant2')->nullable();
            $table->string('DateModif')->nullable();
            $table->string('NBRHEURE')->nullable();
            $table->string('RESERVE1')->nullable();
            $table->string('RESERVE2')->nullable();
            $table->string('RESERVE3')->nullable();
            $table->string('RESERVE4')->nullable();
            $table->string('RESERVE5')->nullable();
            $table->timestamps();
        });

        Schema::create('notes', function (Blueprint $table): void {
            $table->id();
            $table->string('CodeEnseignement');
            $table->string('CodeEleve');
            $table->string('CodeEvaluation');
            $table->string('CodeAppreciation')->nullable();
            $table->string('valeur')->nullable();
            $table->string('coef')->nullable();
            $table->string('Total')->nullable();
            $table->string('Dateeng')->nullable();
            $table->string('CodeAnnee')->nullable();
            $table->timestamps();
        });

        Schema::create('users', function (Blueprint $table): void {
            $table->string('code')->primary();
            $table->string('nom');
            $table->string('prenom');
            $table->string('DateDeNaissance')->nullable();
            $table->string('LieuDeNaissance')->nullable();
            $table->string('nationalite')->default('Cameroun');
            $table->string('sex');
            $table->string('DatePriseService')->nullable();
            $table->string('login');
            $table->string('contacts');
            $table->string('cdegrade')->nullable();
            $table->integer('nbrand')->nullable();
            $table->string('matricule')->nullable();
            $table->string('reserve1')->nullable();
            $table->string('reserve2')->nullable();
            $table->string('reserve3')->nullable();
            $table->string('reserve4')->nullable();
            $table->string('reserve5')->nullable();
            $table->string('reserve6')->nullable();
            $table->string('cat')->nullable();
            $table->string('echel')->nullable();
            $table->string('statut')->nullable();
            $table->string('reserve7')->nullable();
            $table->string('reserve8')->nullable();
            $table->string('reserve9')->nullable();
            $table->string('CodeBank')->nullable();
            $table->string('CodeEtablissement')->nullable();
            $table->boolean('admin')->default(0);
            $table->string('account_type')->default('enseignant');
            $table->string('photo_path')->nullable();
            $table->string('text_password')->nullable();
            $table->string('gender')->nullable();
            $table->string('numcpt')->nullable();
            $table->string('ribcpt')->nullable();
            $table->string('TauhH')->nullable();
            $table->string('syndicat')->nullable();
            $table->string('NumAssure')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('encadreur_classes', function (Blueprint $table): void {
            $table->id();
            $table->string('code');
            $table->string('CodeClasse');
            $table->string('CodeEtablissement');
            $table->timestamps();
            $table->unique(['CodeEtablissement', 'code', 'CodeClasse']);
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

    private function createSchool(string $code): void
    {
        Etablissement::query()->create([
            'CodeEtablissement' => $code,
            'Nom' => 'School ' . $code,
            'Adresse' => 'Centre',
            'Tel' => '123',
            'Fax' => '456',
        ]);
    }

    private function createClass(string $code, string $schoolCode): void
    {
        Classe::query()->create([
            'CodeClasse' => $code,
            'CodeTypeClasse' => 'TYPE',
            'LibelleClasse' => 'Class ' . $code,
            'CodeCycle' => 'CYCLE',
            'CodeSpecialite' => 'SPEC',
            'codetypeinscrip' => 'INS',
            'CodeEtablissement' => $schoolCode,
        ]);
    }

    private function createYear(string $code): void
    {
        DB::table('annees')->insert([
            'CodeAnnee' => $code,
            'Libelle' => $code,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function createUser(string $code, string $schoolCode, string $name): void
    {
        DB::table('users')->insert([
            'code' => $code,
            'nom' => $name,
            'prenom' => 'Staff',
            'sex' => '0',
            'contacts' => '123456',
            'CodeEtablissement' => $schoolCode,
            'account_type' => 'enseignant',
            'login' => $name,
            'password' => 'unused-test-password',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function actingAsAdministrator(): void
    {
        $administrator = new User();
        $administrator->code = 'TEST-ADMIN';
        $administrator->account_type = 'administrateur';
        $administrator->admin = true;
        $this->actingAs($administrator);
    }

    private function createStudent(string $code, string $classCode, string $yearCode, string $name): void
    {
        Eleve::query()->create([
            'CodeEleve' => $code,
            'CodeClasse' => $classCode,
            'CodeAnnee' => $yearCode,
            'Nom' => $name,
            'Prenom' => 'Student',
            'dateinscription' => '2026-09-01',
        ]);
    }

    private function csvUpload(string $filename, string $contents): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($filename, $contents);
    }
}
