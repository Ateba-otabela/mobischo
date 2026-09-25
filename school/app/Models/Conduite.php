<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Conduite extends Model
{
    use HasFactory;
    protected $fillable = [
        'DateEnreg',
        'CodeEleve',
        'Nombre',
        'CodeEtatCond',
        'CodeClasse',
        'CodeAnnee',
        'CodeMatiere',
        'CodeEnseignement',
        'HeureMatiere'
    ];
}
