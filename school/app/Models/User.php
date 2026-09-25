<?php

namespace App\Models;

use App\Models\Eleve;
use App\Models\Student;
use App\Models\Enseignement;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Notifications\Notifiable;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $primaryKey = 'code';
    public $incrementing = false;

    // In Laravel 6.0+ make sure to also set $keyType
    protected $keyType = 'string';
    
    protected $fillable = [
        'nom',
        'prenom',
        'contacts',
        'sex',
        'email',
        'login',
        'code',
        'account_type',
        'text_password',
        'password',
        'address'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];


    public function enfants()
    {
        return $this->hasMany(Eleve::class,'code');
    }

    /**
     * Get all of the enseignements for the User
     *
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function enseignements()
    {
        return $this->hasMany(Enseignement::class, 'code');
    }

}
