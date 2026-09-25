<?php

namespace App\Models;

use App\Models\User;
use App\Models\Classe;
use App\Models\Inscription;
use App\Models\Enseignement;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Eleve extends Model
{
    use HasFactory;
    protected $primaryKey = 'CodeEleve';
    public $incrementing = false;

    // In Laravel 6.0+ make sure to also set $keyType
    protected $keyType = 'string';
    
    
    protected $fillable = [
        'CodeEleve',
        'CodeAnnee',
        'CodeClasse',
        'code',
        'CodeConduite',
        'Nom',
        'Prenom',
        'DateNaissance',
        'LieuNaissance',
        'Sex',
        'Nationalite',
        'dateinscription',
        'photo',
        'Excl',
        'Nomp',
        'TelP',
        'Image',
        'strimage',
        'Nomm',
        'REGION',
        'DEPART',
        'RELIGION',
        'SITREG',
        'ACTIVEEPS',
        'PROFP',
        'NOMT',
        'PROFM',
        'ADRESSE',
        'RESIDENT',
        'TELM',
        'TELT',
        'PERSONCON',
        'RESERVE1',
        'RESERVE2',
        'RESERVE3',
        'RESERVE4',
    ];

    public function classe()
    {
        return $this->belongsTo(Classe::class, 'CodeClasse');
    }

    public function parent()
    {
        return $this->belongsTo(User::class,'code');
    }

    public function inscriptions()
    {
        return $this->hasMany(Inscription::class, 'CodeEleve');
    }

    public function enseignements()
    {
        return $this->hasMany(Enseignement::class, 'CodeEleve');
    }
}
