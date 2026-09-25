<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateEnseignementsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('enseignements', function (Blueprint $table) {
            $table->string('CodeEnseignement');
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
            $table->string('LibgroupeMat')->nullable();
            $table->string('NBRHEURE')->nullable();
            $table->string('RESERVE1')->nullable();
            $table->string('RESERVE2')->nullable();
            $table->string('RESERVE3')->nullable();
            $table->string('RESERVE4')->nullable();
            $table->string('RESERVE5')->nullable();

            $table->primary('CodeEnseignement');
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
        Schema::dropIfExists('enseignements');
    }
}
