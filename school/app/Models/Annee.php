<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Annee extends Model
{
    use HasFactory;
    protected $fillable = [
        'CodeAnnee',
        'Libelle'
    ];
    protected $primaryKey = 'CodeAnnee';

    public function notes()
    {
        return $this->hasMany(Note::class, 'CodeAnnee');
    }

}
