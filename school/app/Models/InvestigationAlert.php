<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InvestigationAlert extends Model
{
    use HasFactory;

    protected $fillable = [
        'CodeEtablissement',
        'CodeEleve',
        'CodeClasse',
        'CodeEnseignement',
        'CodeMatiere',
        'date_absence',
        'parent_status',
        'teacher_status',
        'status',
        'notes',
        'resolved_by',
        'resolved_at',
    ];
}
