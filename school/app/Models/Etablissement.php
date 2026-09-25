<?php

namespace App\Models;

use App\Models\Classe;
use App\Models\Matiere;
use App\Models\TrancheScholarite;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Etablissement extends Model
{
    use HasFactory;

    protected $primaryKey = 'CodeEtablissement';
    public $incrementing = false;

    // In Laravel 6.0+ make sure to also set $keyType
    protected $keyType = 'string';
    
    protected $fillable = [
        'CodeEtablissement',
        'Pays',
        'Nom',
        'Adresse',
        'Tel',
        'Fax',
        'REPPHOTO'
    ];

    public function classes()
    {
        return $this->hasMany(Classe::class,'CodeEtablissement');
    }

    public function tranches()
    {
        return $this->hasMany(TrancheScholarite::class,'CodeEtablissement');
    }

    public function courses()
    {
        return $this->hasMany(Matiere::class,'CodeEtablissement');
    }

    public function enseignements()
    {
        return $this->hasMany(Enseignement::class,'CodeEtablissement');
    }


}
