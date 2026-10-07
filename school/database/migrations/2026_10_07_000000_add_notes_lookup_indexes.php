<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AddNotesLookupIndexes extends Migration
{
    public function up()
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement(
                'CREATE INDEX notes_student_year_lookup ON notes (CodeEleve(64), CodeAnnee(32))'
            );
            DB::statement(
                'CREATE INDEX notes_course_year_lookup ON notes (CodeEnseignement(64), CodeAnnee(32))'
            );

            return;
        }

        Schema::table('notes', function (Blueprint $table): void {
            $table->index(['CodeEleve', 'CodeAnnee'], 'notes_student_year_lookup');
            $table->index(['CodeEnseignement', 'CodeAnnee'], 'notes_course_year_lookup');
        });
    }

    public function down()
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement('DROP INDEX notes_student_year_lookup ON notes');
            DB::statement('DROP INDEX notes_course_year_lookup ON notes');

            return;
        }

        Schema::table('notes', function (Blueprint $table): void {
            $table->dropIndex('notes_student_year_lookup');
            $table->dropIndex('notes_course_year_lookup');
        });
    }
}
