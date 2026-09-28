<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EncadreurClasse extends Model
{
    use HasFactory;

    protected $table = 'encadreur_classes';

    protected $fillable = [
        'code',
        'CodeClasse',
        'CodeEtablissement',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'code', 'code');
    }

    public function classe()
    {
        return $this->belongsTo(Classe::class, 'CodeClasse', 'CodeClasse');
    }
}
