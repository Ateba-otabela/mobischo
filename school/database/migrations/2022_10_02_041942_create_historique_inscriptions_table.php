<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHistoriqueInscriptionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('historique_inscriptions', function (Blueprint $table) {
            $table->string('NUMFAC');
            $table->string('CodeInscription');
            $table->string('CodeEleve');
            $table->dateTime('DateInscription')->nullable();
            $table->string('Tranche')->nullable();
            $table->string('codeannee');
            $table->unsignedFloat('Montantins')->nullable();
            $table->unsignedFloat('Avance')->nullable();
            $table->unsignedFloat('Reste')->nullable();
            $table->unsignedFloat('Montantt')->nullable();
            $table->string('libinscrip')->nullable();
            $table->string('heure')->nullable();
            $table->string('caissier')->nullable();
            $table->unsignedFloat('remise')->nullable();
            // $table->primary('NUMFAC');
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
        Schema::dropIfExists('historique_inscriptions');
    }
}
