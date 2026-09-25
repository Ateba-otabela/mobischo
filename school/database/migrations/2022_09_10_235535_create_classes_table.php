<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateClassesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('classes', function (Blueprint $table) {
            $table->string('CodeClasse')->primary();;
            $table->string('CodeTypeClasse');
            $table->string('LibelleClasse');
            $table->string('CodeCycle');
            $table->string('CodeSpecialite');
            $table->string('codetypeinscrip');
            $table->string('CodeEtablissement');
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
        Schema::dropIfExists('classes');
    }
}
