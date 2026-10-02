<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('teacher_attendances', function (Blueprint $table) {
            $table->id();
            $table->char('session_key', 64)->unique();
            $table->string('CodeEtablissement');
            $table->string('CodeEnseignant');
            $table->string('CodeEnseignement');
            $table->string('CodeClasse');
            $table->string('CodeMatiere')->nullable();
            $table->date('attendance_date');
            $table->string('session_time')->nullable();
            $table->string('presence_status')->default('present');
            $table->timestamps();

            $table->index(['CodeEtablissement', 'CodeClasse', 'attendance_date']);
            $table->index(['CodeEnseignant', 'attendance_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('teacher_attendances');
    }
};
