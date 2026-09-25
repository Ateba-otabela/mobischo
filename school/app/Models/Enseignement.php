<?php

namespace App\Models;

use App\Models\Note;
use App\Models\User;
use App\Models\Eleve;
use App\Models\Classe;
use App\Models\Etablissement;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Enseignement extends Model
{
    use HasFactory;
    
    protected $primaryKey = 'CodeEnseignement';
    public $incrementing = false;


    protected $fillable = [
        'CodeEnseignement',
        'CodeMatiere',
        'code',
        'CodeClasse',
        'CodeEtablissement',
        'Coefficient',
        'CodeSpecialite',
        'CodeCycle',
        'Dateens',
        'CodeEnseignant2',
        'DateModif',
        'NBRHEURE',
        'RESERVE1',
        'RESERVE2',
        'RESERVE3',
        'RESERVE4',
        'RESERVE5',
    ];
    // In Laravel 6.0+ make sure to also set $keyType
    protected $keyType = 'string';
    
    public function matiere()
    {
        return $this->belongsTo(Matiere::class, 'CodeMatiere');
    }
    
    public function classe()
    {
        return $this->belongsTo(Classe::class, 'CodeClasse');
    }

    public function enseignant()
    {
        return $this->belongsTo(User::class, 'code');
    }

    public function etablissement()
    {
        return $this->belongsTo(Etablissement::class, 'CodeEtablissement');
    }

    public function notes()
    {
        return $this->hasMany(Note::class, 'CodeEnseignement');
    }

}
