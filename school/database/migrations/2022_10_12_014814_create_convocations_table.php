<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateConvocationsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('convocations', function (Blueprint $table) {
            $table->id();
            $table->string('code')->nullable();
            $table->string('CodeEleve')->nullable();
            $table->string('motif')->nullable();
            $table->string('description')->nullable();
            $table->string('CodeEnseignement')->nullable();
            $table->string('CodeMatiere')->nullable();
            $table->string('dateConvocation')->nullable();
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
        Schema::dropIfExists('convocations');
    }
}
