<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Devoir extends Model
{
    use HasFactory;

    protected $table = 'devoirs';

    protected $fillable = [
        'titre',
        'description',
        'dateDuDevoir',
        'code',
        'CodeClasse',
        'CodeMatiere',
        'CodeEnseignement',
        'CodeEtablissement',
    ];
}
