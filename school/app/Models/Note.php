<?php

namespace App\Models;

use App\Models\SequenceEvaluation;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Note extends Model
{
    use HasFactory;

    protected $fillable = [
        'Codeenseignement',
        'CodeEleve',
        'CodeEvaluation',
        'CodeAppreciation',
        'valeur',
        'coef',
        'total',
        'Dateeng',
        'codeannee'
    ];
    /**
     * Get the user that owns the Note
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function enseignement()
    {
        return $this->belongsTo(Enseignement::class, 'CodeEnseignement');
    }

    public function annee()
    {
        return $this->belongsTo(Annee::class, 'CodeAnnee');
    }

    public function sequence_evaluation()
    {
        return $this->belongsTo(SequenceEvaluation::class, 'CodeEvaluation');
    }


    public function eleve()
    {
        return $this->belongsTo(Eleve::class, 'CodeEleve');
    }
}
