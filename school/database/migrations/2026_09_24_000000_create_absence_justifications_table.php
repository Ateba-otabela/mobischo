<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('absence_justifications', function (Blueprint $table) {
            $table->id();
            $table->string('parent_code');
            $table->string('CodeEleve');
            $table->date('date_absence');
            $table->string('motif');
            $table->text('justification');
            $table->string('piece_jointe')->nullable();
            $table->string('statut')->default('En attente');
            $table->timestamps();

            $table->index(['CodeEleve', 'date_absence']);
            $table->index('parent_code');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('absence_justifications');
    }
};
