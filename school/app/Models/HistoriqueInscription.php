<?php

namespace App\Models;

use App\Models\Inscription;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HistoriqueInscription extends Model
{   
    // protected $primaryKey = 'CodeInscription';

    use HasFactory;
    protected $fillable = [
        'NUMFAC',
        'CodeInscription',
        'CodeEleve',
        'DateInscription',
        'Tranche',
        'codeannee',
        'Montantins',
        'Avance',
        'Reste',
        'Montantt',
        'libinscrip',
        'heure',
        'caissier', 
        'remise'
    ];

    public function inscription()
    {
        return $this->belongsTo(Inscription::class, 'NUMFAC', 'NUMFAC');
    }
}
