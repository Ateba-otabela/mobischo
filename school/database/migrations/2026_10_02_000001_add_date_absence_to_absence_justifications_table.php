<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('absence_justifications')) {
            return;
        }

        if (!Schema::hasColumn('absence_justifications', 'date_absence')) {
            Schema::table('absence_justifications', function (Blueprint $table) {
                $table->date('date_absence')->nullable();
            });
        }

        if (Schema::hasColumn('absence_justifications', 'absence_date')) {
            DB::table('absence_justifications')
                ->whereNull('date_absence')
                ->whereNotNull('absence_date')
                ->update(['date_absence' => DB::raw('absence_date')]);
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('absence_justifications')
            && Schema::hasColumn('absence_justifications', 'date_absence')) {
            Schema::table('absence_justifications', function (Blueprint $table) {
                $table->dropColumn('date_absence');
            });
        }
    }
};
