<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateEncadreurClassesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('encadreur_classes', function (Blueprint $table) {
            $table->id();
            $table->string('code');
            $table->string('CodeClasse');
            $table->string('CodeEtablissement');
            $table->timestamps();

            $table->unique(['CodeEtablissement', 'code', 'CodeClasse'], 'encadreur_classes_unique_assignment');
            $table->index('code');
            $table->index('CodeClasse');
            $table->index('CodeEtablissement');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('encadreur_classes');
    }
}
