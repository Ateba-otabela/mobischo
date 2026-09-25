<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Convocation extends Model
{
    use HasFactory;
    protected $fillable = [
        'code',
        'CodeEleve',
        'motif',
        'description',
        'CodeEnseignement',
        'CodeMatiere',
        'dateConvocation',
        'timeConvocation'
    ];
}
