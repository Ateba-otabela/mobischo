<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateNotesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('notes', function (Blueprint $table) {
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
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('notes');
    }
}
