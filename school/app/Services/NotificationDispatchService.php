<?php

namespace App\Services;

use App\Models\Eleve;
use App\Models\Enseignement;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Collection;

class NotificationDispatchService
{
    public function __construct(protected ?FcmNotificationService $fcm = null)
    {
        $this->fcm ??= new FcmNotificationService();
    }

    public function dispatchAttendanceNotification(string $studentCode, string $attendanceDate, string $status, string $actorCode, array $context = []): array
    {
        $normalizedStatus = strtoupper(trim($status));
        if ($normalizedStatus === 'P') {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $student = Eleve::query()->where('CodeEleve', $studentCode)->first();
        if (!$student) {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $classCode = trim((string) ($context['class_code'] ?? (string) ($student->CodeClasse ?? '')));
        $schoolCode = trim((string) ($context['school_code'] ?? ''));
        if ($schoolCode === '' && $classCode !== '') {
            $class = \App\Models\Classe::query()->where('CodeClasse', $classCode)->first();
            $schoolCode = trim((string) ($class?->CodeEtablissement ?? ''));
        }

        $studentName = trim((string) (($student->Nom ?? '') . ' ' . ($student->Prenom ?? '')));
        $parentCode = trim((string) ($student->code ?? ''));

        $summary = ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];

        if ($parentCode !== '' && $parentCode !== $actorCode) {
            $parentTitle = 'Absence de votre enfant';
            $parentBody = sprintf(
                '%s a été marqué(e) %s le %s.',
                $studentName !== '' ? $studentName : 'Votre enfant',
                $this->statusLabel($normalizedStatus),
                $attendanceDate
            );

            $parentResult = $this->notifyUser($parentCode, $parentTitle, $parentBody, [
                'type' => 'attendance',
                'student_code' => $studentCode,
                'class_code' => $classCode,
                'school_code' => $schoolCode,
                'attendance_date' => $attendanceDate,
                'status' => $normalizedStatus,
                'recipient_role' => 'parent',
            ]);

            foreach (['sent', 'attempted', 'failed', 'invalidated'] as $key) {
                $summary[$key] += (int) ($parentResult[$key] ?? 0);
            }
        }

        return $summary;
    }

    public function dispatchHomeworkNotification(string $classCode, string $subjectLabel, string $teacherCode, string $schoolCode, ?string $homeworkId = null, ?string $assignmentTitle = null): array
    {
        $parentCodes = $this->parentCodesForClass($classCode, $schoolCode);
        if ($parentCodes->isEmpty()) {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $title = 'Nouveau devoir';
        $assignmentTitle = trim((string) $assignmentTitle);
        $body = $assignmentTitle !== ''
            ? sprintf(
                'Nouveau devoir de %s : %s (classe %s).',
                $subjectLabel !== '' ? $subjectLabel : 'matière',
                $assignmentTitle,
                $classCode
            )
            : sprintf(
                'Nouveau devoir de %s pour la classe %s.',
                $subjectLabel !== '' ? $subjectLabel : 'matière',
                $classCode
            );

        $summary = ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        foreach ($parentCodes as $parentCode) {
            if ($parentCode === $teacherCode) {
                continue;
            }

            $result = $this->notifyUser($parentCode, $title, $body, [
                'type' => 'homework',
                'class_code' => $classCode,
                'school_code' => $schoolCode,
                'subject' => $subjectLabel,
                'homework_id' => $homeworkId ?? '',
                'assignment_title' => $assignmentTitle,
            ]);

            foreach (['sent', 'attempted', 'failed', 'invalidated'] as $key) {
                $summary[$key] += (int) ($result[$key] ?? 0);
            }
        }

        return $summary;
    }

    public function dispatchConvocationNotification(array $studentCodes, string $teacherCode, array $context = []): array
    {
        $schoolCode = trim((string) ($context['school_code'] ?? ''));
        $classCode = trim((string) ($context['class_code'] ?? ''));
        $uniqueStudentCodes = array_values(array_unique(array_filter(array_map('strval', $studentCodes), fn ($value) => trim($value) !== '')));

        if ($uniqueStudentCodes === []) {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $students = Eleve::query()->whereIn('CodeEleve', $uniqueStudentCodes)->get();
        $summary = ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];

        foreach ($students as $student) {
            $parentCode = trim((string) ($student->code ?? ''));
            if ($parentCode === '' || $parentCode === $teacherCode) {
                continue;
            }

            $studentName = trim((string) (($student->Nom ?? '') . ' ' . ($student->Prenom ?? '')));
            $title = 'Convocation';
            $body = sprintf('Convocation pour %s.', $studentName !== '' ? $studentName : 'votre enfant');

            $result = $this->notifyUser($parentCode, $title, $body, [
                'type' => 'convocation',
                'student_code' => (string) ($student->CodeEleve ?? ''),
                'class_code' => $classCode,
                'school_code' => $schoolCode,
            ]);

            foreach (['sent', 'attempted', 'failed', 'invalidated'] as $key) {
                $summary[$key] += (int) ($result[$key] ?? 0);
            }
        }

        return $summary;
    }

    public function dispatchAbsenceJustificationNotification(string $studentCode, string $parentCode, array $context = []): array
    {
        $student = Eleve::query()->where('CodeEleve', $studentCode)->first();
        if (!$student) {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $schoolCode = trim((string) ($context['school_code'] ?? ''));
        $classCode = trim((string) ($student->CodeClasse ?? ''));
        $teacherCodes = $this->responsibleTeacherCodesForClass($classCode, $schoolCode);
        if ($teacherCodes->isEmpty()) {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $studentName = trim((string) (($student->Nom ?? '') . ' ' . ($student->Prenom ?? '')));
        $title = 'Justification d\'absence';
        $body = sprintf('Une justification d\'absence a été soumise pour %s.', $studentName !== '' ? $studentName : 'votre enfant');

        $summary = ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        foreach ($teacherCodes as $teacherCode) {
            if ($teacherCode === '' || $teacherCode === $parentCode) {
                continue;
            }

            $result = $this->notifyUser($teacherCode, $title, $body, [
                'type' => 'absence_justification',
                'student_code' => $studentCode,
                'class_code' => $classCode,
                'school_code' => $schoolCode,
            ]);

            foreach (['sent', 'attempted', 'failed', 'invalidated'] as $key) {
                $summary[$key] += (int) ($result[$key] ?? 0);
            }
        }

        return $summary;
    }

    protected function notifyUser(string $userCode, string $title, string $body, array $data = []): array
    {
        $context = [
            'user_code' => $userCode,
            'notification_type' => (string) ($data['type'] ?? ''),
            'recipient_role' => (string) ($data['recipient_role'] ?? ''),
        ];

        Log::info('Notification dispatch attempted.', $context);

        try {
            $result = $this->fcm->sendToUser($userCode, $title, $body, $data);
        } catch (\Throwable $exception) {
            Log::error('Notification dispatch threw an exception.', $context + [
                'exception' => get_class($exception),
                'error' => $exception->getMessage(),
            ]);

            throw $exception;
        }

        Log::info('Notification dispatch completed.', $context + [
            'attempted' => (int) ($result['attempted'] ?? 0),
            'succeeded' => (int) ($result['succeeded'] ?? 0),
            'failed' => (int) ($result['failed'] ?? 0),
            'invalidated' => (int) ($result['invalidated'] ?? 0),
        ]);

        $sent = (int) (($result['succeeded'] ?? 0) > 0 ? 1 : 0);
        return [
            'sent' => $sent,
            'attempted' => (int) ($result['attempted'] ?? 0),
            'failed' => (int) ($result['failed'] ?? 0),
            'invalidated' => (int) ($result['invalidated'] ?? 0),
        ];
    }

    protected function parentCodesForClass(string $classCode, string $schoolCode): Collection
    {
        $parentCodes = Eleve::query()
            ->where('CodeClasse', $classCode)
            ->whereNotNull('code')
            ->where('code', '!=', '')
            ->pluck('code')
            ->filter()
            ->unique()
            ->values();

        return User::query()
            ->whereIn('code', $parentCodes)
            ->where('account_type', 'parent')
            ->where(function ($query) {
                $query->where('admin', false)->orWhereNull('admin');
            })
            ->when($schoolCode !== '', fn ($query) => $query->where('CodeEtablissement', $schoolCode))
            ->pluck('code')
            ->filter()
            ->unique()
            ->values();
    }

    protected function responsibleTeacherCodesForClass(string $classCode, string $schoolCode): Collection
    {
        $teacherCodes = Enseignement::query()
            ->where('CodeClasse', $classCode)
            ->when($schoolCode !== '', fn ($query) => $query->where('CodeEtablissement', $schoolCode))
            ->get()
            ->flatMap(function ($course) {
                $codes = [];
                $primary = trim((string) ($course->code ?? ''));
                $secondary = trim((string) ($course->CodeEnseignant2 ?? ''));

                if ($primary !== '') {
                    $codes[] = $primary;
                }
                if ($secondary !== '') {
                    $codes[] = $secondary;
                }

                return $codes;
            })
            ->filter()
            ->unique()
            ->values();

        return $teacherCodes;
    }

    protected function statusLabel(string $status): string
    {
        return match (strtoupper($status)) {
            'A' => 'absent(e)',
            'R' => 'en retard',
            default => 'absent(e)',
        };
    }
}
