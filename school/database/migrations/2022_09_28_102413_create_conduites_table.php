<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateConduitesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('conduites', function (Blueprint $table) {
            $table->id();
            $table->string('DateEnreg');
            $table->string('CodeEleve');
            $table->string('Nombre')->nullable();
            $table->string('CodeEtatCond')->nullable();
            $table->string('CodeClasse')->nullable();
            $table->string('CodeAnnee')->nullable();
            $table->string('CodeMatiere')->nullable();
            $table->string('CodeEnseignement')->nullable();
            $table->string('HeureMatiere')->nullable();
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
        Schema::dropIfExists('conduites');
    }
}
