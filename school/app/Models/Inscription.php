<?php

namespace App\Models;

use App\Models\Eleve;
use App\Models\HistoriqueInscription;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Inscription extends Model
{
    use HasFactory;
    protected $primaryKey = 'NUMFAC';
    public $incrementing = false;

    // In Laravel 6.0+ make sure to also set $keyType
    protected $keyType = 'string';
    
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

    public function eleve()
    {
        return $this->belongsTo(Eleve::class, 'CodeEleve');
    }

    public function historique_inscriptions()
    {
        return $this->hasMany(HistoriqueInscription::class, 'NUMFAC', 'NUMFAC');
    }
    /**
     * Get the tranche associated with the Inscription
     *
     * @return \Illuminate\Database\Eloquent\Relations\HasOne
     */
}
