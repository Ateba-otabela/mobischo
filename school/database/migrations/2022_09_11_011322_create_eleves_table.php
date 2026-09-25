<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateElevesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('eleves', function (Blueprint $table) {
            $table->string('CodeEleve');
            $table->string('code')->nullable();
            $table->string('CodeAnnee');
            $table->string('CodeClasse');
            $table->string('CodeConduite')->nullable();
            $table->string('Nom')->nullable();
            $table->string('Prenom')->nullable();
            $table->string('DateNaissance')->nullable();
            $table->string('LieuNaissance')->nullable();
            $table->string('Sex')->nullable();
            $table->string('Nationalite')->nullable();
            $table->string('dateinscription');
            $table->string('photo')->nullable();
            $table->string('Excl')->nullable();
            $table->string('Nomp')->nullable();
            $table->string('TelP')->nullable();
            $table->string('Image')->nullable();
            $table->string('strimage')->nullable();
            $table->string('Nomm')->nullable();
            $table->string('REGION')->nullable();
            $table->string('DEPART')->nullable();
            $table->string('RELIGION')->nullable();
            $table->string('SITREG')->nullable();
            $table->string('ACTIVEEPS')->nullable();
            $table->string('PROFP')->nullable();
            $table->string('NOMT')->nullable();
            $table->string('PROFM')->nullable();
            $table->string('ADRESSE')->nullable();
            $table->string('RESIDENT')->nullable();
            $table->string('TELM')->nullable();
            $table->string('TELT')->nullable();
            $table->string('PERSONCON')->nullable();
            $table->string('RESERVE1')->nullable();
            $table->string('RESERVE2')->nullable();
            $table->string('RESERVE3')->nullable();
            $table->string('RESERVE4')->nullable();
            $table->primary('CodeEleve');
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
        Schema::dropIfExists('eleves');
    }
}
