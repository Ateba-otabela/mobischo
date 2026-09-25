<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTrancheScholaritesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('tranche_scholarites', function (Blueprint $table) {
            $table->string('code');
            $table->primary('code');
            $table->string('CodeEtablissement')->default('11201');
            $table->string('libellet');
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
        Schema::dropIfExists('tranche_scholarites');
    }
}
