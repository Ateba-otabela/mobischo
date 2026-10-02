<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('absence_justifications')) {
            return;
        }

        Schema::create('absence_justifications', function (Blueprint $table) {
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

            $table->index(['CodeEleve', 'absence_date', 'status']);
            $table->index(['CodeEleve', 'date_absence', 'statut']);
            $table->index(['parent_code', 'created_at']);
            $table->index(['CodeEtablissement', 'absence_date']);
            $table->index(['CodeEtablissement', 'date_absence']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('absence_justifications');
    }
};
