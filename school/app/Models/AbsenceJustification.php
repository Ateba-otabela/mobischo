<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AbsenceJustification extends Model
{
    use HasFactory;

    protected $fillable = [
        'parent_code',
        'CodeEleve',
        'date_absence',
        'motif',
        'justification',
        'piece_jointe',
        'statut',
    ];
}
