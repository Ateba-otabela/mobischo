<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TeacherAttendance extends Model
{
    public const STATUS_PRESENT = 'present';

    protected $fillable = [
        'session_key',
        'CodeEtablissement',
        'CodeEnseignant',
        'CodeEnseignement',
        'CodeClasse',
        'CodeMatiere',
        'attendance_date',
        'session_time',
        'presence_status',
    ];

    public static function makeSessionKey(
        string $schoolCode,
        string $teacherCode,
        string $teachingCode,
        string $classCode,
        string $subjectCode,
        string $date,
        mixed $sessionTime
    ): string {
        return hash('sha256', implode('|', [
            trim($schoolCode),
            trim($teacherCode),
            trim($teachingCode),
            trim($classCode),
            trim($subjectCode),
            trim($date),
            trim((string) ($sessionTime ?? '')),
        ]));
    }
}
