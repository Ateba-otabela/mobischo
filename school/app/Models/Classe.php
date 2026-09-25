<?php

namespace App\Models;

use App\Models\Eleve;
use App\Models\Enseignement;
use App\Models\Etablissement;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Classe extends Model
{
    use HasFactory;

    protected $primaryKey = 'CodeClasse';
    public $incrementing = false;

    // In Laravel 6.0+ make sure to also set $keyType
    protected $keyType = 'string';
    
    protected $fillable = [
        'LibelleClasse',
        'CodeClasse',
        'CodeTypeClasse',
        'CodeCycle',
        'CodeSpecialite',
        'codetypeinscrip',
        'CodeEtablissement'
    ];

    /**
     * Get the etablissement that owns the Classe
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function etablissement()
    {
        return $this->belongsTo(Etablissement::class, 'CodeEtablissement');
    }

    public function students()
    {
        return $this->hasMany(Eleve::class,'CodeClasse');
    }

    public function enseignements()
    {
        return $this->hasMany(Enseignement::class, 'CodeClasse');
    }
}
