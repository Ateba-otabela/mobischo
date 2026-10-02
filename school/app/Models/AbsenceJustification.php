<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AbsenceJustification extends Model
{
    use HasFactory;

    protected $fillable = [
        'CodeEleve',
        'CodeEtablissement',
        'absence_date',
        'date_absence',
        'reason',
        'motif',
        'justification',
        'status',
        'statut',
        'parent_code',
        'parent_name',
        'reviewed_by',
        'reviewed_at',
        'document_path',
    ];

    protected $casts = [
        'date_absence' => 'date:Y-m-d',
        'absence_date' => 'date:Y-m-d',
    ];

    public function setDateAbsenceAttribute($value): void
    {
        $this->attributes['date_absence'] = $value;
        $this->attributes['absence_date'] = $value;
    }

    public function setMotifAttribute($value): void
    {
        $this->attributes['motif'] = $value;
        $this->attributes['reason'] = $value;
    }

    public function setStatutAttribute($value): void
    {
        $this->attributes['statut'] = $value;
        $this->attributes['status'] = $value === 'En attente' ? 'pending' : $value;
    }

    public function setStatusAttribute($value): void
    {
        $this->attributes['status'] = $value;
        $this->attributes['statut'] = $value === 'pending' ? 'En attente' : $value;
    }

    public function getStatutAttribute($value): string
    {
        return $value !== null ? $value : (
            $this->attributes['status'] ?? ''
        );
    }

    public function getStatusAttribute($value): string
    {
        return $value !== null ? $value : (
            $this->attributes['statut'] ?? ''
        );
    }
}
