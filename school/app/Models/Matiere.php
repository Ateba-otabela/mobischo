<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Matiere extends Model
{
    use HasFactory;
    protected $primaryKey = 'CodeMatiere';
    public $incrementing = false;

    // In Laravel 6.0+ make sure to also set $keyType
    protected $keyType = 'string';
    
    protected $fillable = [
        'CodeMatiere',
        'LibelleMatiere',
        'ordre',
        'CodeEtablissement'
    ];
    
    public function etablissement()
    {
        return $this->belongsTo(Etablissement::class, 'CodeEtablissement');
    }

    public function enseignement()
    {
        return $this->hasMany(Enseignement::class, 'CodeMatiere');
    }

}
