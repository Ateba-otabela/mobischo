<?php

namespace App\Models;

use App\Models\Etablissement;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class TrancheScholarite extends Model
{
    protected $primaryKey = 'code';
    public $incrementing = false;
    protected $keyType = 'string';
    
    protected $fillable = [
        'code',
        'libellet'
    ];

    use HasFactory;

    public function etablissement()
    {
        return $this->belongsTo(Etablissement::class, 'CodeEtablissement');
    }
}
