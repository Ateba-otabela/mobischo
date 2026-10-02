<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('absence_justifications')
            && !Schema::hasColumn('absence_justifications', 'document_path')) {
            Schema::table('absence_justifications', function (Blueprint $table) {
                $table->string('document_path')->nullable();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('absence_justifications')
            && Schema::hasColumn('absence_justifications', 'document_path')) {
            Schema::table('absence_justifications', function (Blueprint $table) {
                $table->dropColumn('document_path');
            });
        }
    }
};