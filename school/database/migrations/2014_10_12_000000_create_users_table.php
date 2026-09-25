<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateUsersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('users', function (Blueprint $table) {
            $table->string('code')->nullable();
            $table->string('nom');
            $table->string('prenom');
            
            $table->string('DateDeNaissance')->nullable();
            $table->string('LieuDeNaissance')->nullable();
            $table->string('nationalite')->default('Cameroun');
            
            $table->string('sex');
            $table->string('DatePriseService')->nullable();
            $table->string('login');

            $table->string('contacts');
            $table->string('cdegrade')->nullable();
            $table->integer('nbrand')->nullable();
            $table->string('matricule')->nullable();
            $table->string('reserve1')->nullable();
            $table->string('reserve2')->nullable();
            $table->string('reserve3')->nullable();
            $table->string('reserve4')->nullable();
            $table->string('reserve5')->nullable();
            $table->string('reserve6')->nullable();
            $table->string('cat')->nullable();
            $table->string('echel')->nullable();
            $table->string('statut')->nullable();
            $table->string('reserve7')->nullable();
            $table->string('reserve8')->nullable();
            $table->string('reserve9')->nullable();
            $table->string('CodeBank')->nullable();

            $table->string('CodeEtablissement')->nullable();
            
            $table->boolean('admin')->default(0);
            $table->string('account_type')->default('enseignant');
            $table->string('photo_path')->nullable();
            $table->string('text_password')->nullable();
            $table->string('gender')->nullable();

            
            
            $table->string('numcpt')->nullable();
            $table->string('ribcpt')->nullable();
            $table->string('TauhH')->nullable();
            $table->string('syndicat')->nullable();
            $table->string('NumAssure')->nullable();
            $table->primary('code');
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
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
        Schema::dropIfExists('users');
    }
}
