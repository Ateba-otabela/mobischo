<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('investigation_alerts', function (Blueprint $table) {
            $table->id();
            $table->string('CodeEtablissement');
            $table->string('CodeEleve');
            $table->string('CodeClasse');
            $table->string('CodeEnseignement')->nullable();
            $table->string('CodeMatiere')->nullable();
            $table->date('date_absence');
            $table->string('parent_status')->default('A');
            $table->string('teacher_status')->default('P');
            $table->string('status')->default('pending');
            $table->text('notes')->nullable();
            $table->string('resolved_by')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();

            $table->index(['CodeEtablissement', 'CodeClasse', 'date_absence']);
            $table->index(['CodeEleve', 'date_absence']);
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('investigation_alerts');
    }
};
