<?php

namespace App\Models;

use App\Models\Note;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class SequenceEvaluation extends Model
{
    use HasFactory;
    protected $primaryKey = 'CodeEvaluation';

    protected $fillable = [
        'CodeEvaluation',
        'LibelleEvaluation'
    ];

    public function notes()
    {
        return $this->hasMany(Note::class, 'CodeEvaluation');
    }
}
