<?php

namespace App\Services;

use App\Models\Eleve;
use App\Models\Conduite;
use App\Models\Classe;
use App\Models\EncadreurClasse;
use App\Models\Enseignement;
use App\Models\User;
use Illuminate\Support\Carbon;
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
        if (!in_array($normalizedStatus, ['A', 'R'], true)) {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $student = Eleve::query()->where('CodeEleve', $studentCode)->first();
        if (!$student) {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $classCode = trim((string) ($context['class_code'] ?? (string) ($student->CodeClasse ?? '')));
        $schoolCode = trim((string) ($context['school_code'] ?? ''));
        $class = null;
        if ($schoolCode === '' && $classCode !== '') {
            $class = Classe::query()->where('CodeClasse', $classCode)->first();
            $schoolCode = trim((string) ($class?->CodeEtablissement ?? ''));
        }
        if ($class === null && $classCode !== '') {
            $class = Classe::query()
                ->where('CodeClasse', $classCode)
                ->when($schoolCode !== '', fn ($query) => $query->where('CodeEtablissement', $schoolCode))
                ->first();
        }
        $className = trim((string) ($class?->LibelleClasse ?? ''));

        $studentName = trim((string) (($student->Nom ?? '') . ' ' . ($student->Prenom ?? '')));
        $parentCode = trim((string) ($student->code ?? ''));

        $attendanceTitle = null;
        $attendanceBody = null;
        if (in_array($normalizedStatus, ['A', 'R'], true)) {
            $teachingCode = trim((string) ($context['teaching_code'] ?? ''));
            if ($teachingCode !== '') {
                $teaching = Enseignement::query()
                    ->with('matiere')
                    ->where('CodeEnseignement', $teachingCode)
                    ->first();
                $attendance = Conduite::query()
                    ->where('CodeEleve', $studentCode)
                    ->where('CodeEnseignement', $teachingCode)
                    ->where('DateEnreg', $attendanceDate)
                    ->orderByDesc('created_at')
                    ->first();
                $subjectName = trim((string) ($teaching?->matiere?->LibelleMatiere ?? ''));

                if ($subjectName !== '' && $attendance?->created_at) {
                    $dateLabel = Carbon::parse($attendance->DateEnreg)
                        ->locale('fr')
                        ->translatedFormat('j F Y');
                    $timeLabel = Carbon::parse($attendance->created_at)->format('H:i');
                    $subjectPhrase = $this->subjectPhrase($subjectName);

                    if ($normalizedStatus === 'A') {
                        $attendanceTitle = 'Absence scolaire';
                        $attendanceBody = sprintf(
                            '%s n’était pas présent au cours %s le %s à %s.',
                            $studentName !== '' ? $studentName : 'L’élève',
                            $subjectPhrase,
                            $dateLabel,
                            $timeLabel
                        );
                    } else {
                        $attendanceTitle = 'Retard scolaire';
                        $attendanceBody = sprintf(
                            '%s a été en retard au cours %s le %s à %s.',
                            $studentName !== '' ? $studentName : 'L’élève',
                            $subjectPhrase,
                            $dateLabel,
                            $timeLabel
                        );
                    }
                }
            }
        }

        $summary = ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];

        if ($parentCode !== '' && $parentCode !== $actorCode) {
            $parentTitle = $attendanceTitle ?? 'Absence de votre enfant';
            $parentBody = $attendanceBody ?? sprintf(
                '%s a été marqué(e) %s le %s.',
                $studentName !== '' ? $studentName : 'Votre enfant',
                $this->statusLabel($normalizedStatus),
                $attendanceDate
            );

            $parentResult = $this->notifyUser($parentCode, $parentTitle, $parentBody, [
                'type' => 'attendance',
                'student_code' => $studentCode,
                'school_code' => $schoolCode,
                'attendance_date' => $attendanceDate,
                'status' => $normalizedStatus,
                'recipient_role' => 'parent',
            ]);

            foreach (['sent', 'attempted', 'failed', 'invalidated'] as $key) {
                $summary[$key] += (int) ($parentResult[$key] ?? 0);
            }
        }

        if ($schoolCode !== '') {
            $encadreurCodes = EncadreurClasse::query()
                ->where('CodeClasse', $classCode)
                ->where('CodeEtablissement', $schoolCode)
                ->pluck('code')
                ->filter()
                ->unique()
                ->values();
            $encadreurs = User::query()
                ->whereIn('code', $encadreurCodes)
                ->where('account_type', 'encadreur')
                ->where('CodeEtablissement', $schoolCode)
                ->where('code', '!=', $actorCode)
                ->get(['code']);

            $staffTitle = $attendanceTitle ?? ($normalizedStatus === 'A'
                ? 'Élève absent'
                : 'Élève en retard');
            $staffBody = $attendanceBody ?? sprintf(
                '%s a été marqué(e) %s le %s.',
                $studentName !== '' ? $studentName : 'Un élève',
                $this->statusLabel($normalizedStatus),
                $attendanceDate
            );
            if ($className !== '') {
                $staffBody .= ' Classe : '.$className.'.';
            }

            foreach ($encadreurs as $encadreur) {
                $staffResult = $this->notifyUser((string) $encadreur->code, $staffTitle, $staffBody, [
                    'type' => 'attendance',
                    'student_code' => $studentCode,
                    'class_code' => $classCode,
                    'class_name' => $className,
                    'school_code' => $schoolCode,
                    'attendance_date' => $attendanceDate,
                    'status' => $normalizedStatus,
                    'recipient_role' => 'encadreur',
                ]);

                foreach (['sent', 'attempted', 'failed', 'invalidated'] as $key) {
                    $summary[$key] += (int) ($staffResult[$key] ?? 0);
                }
            }
        }

        return $summary;
    }

    public function dispatchHomeworkNotification(string $classCode, string $subjectLabel, string $teacherCode, string $schoolCode, ?string $homeworkId = null, ?string $assignmentTitle = null, ?string $deadline = null): array
    {
        $parentCodes = $this->parentCodesForClass($classCode, $schoolCode);
        if ($parentCodes->isEmpty()) {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $title = 'Devoir à remettre';
        $deadline = trim((string) $deadline);
        $subjectLabel = trim($subjectLabel);
        if ($deadline === '' || $subjectLabel === '') {
            throw new \InvalidArgumentException('A homework subject and deadline are required to build the notification.');
        }

        $deadlineDate = Carbon::parse($deadline)->locale('fr')->translatedFormat('j F Y');
        $deadlineTime = Carbon::parse($deadline)->format('H:i');
        $body = sprintf(
            'Votre enfant a un devoir %s à remettre avant le %s à %s.',
            $this->subjectPhrase($subjectLabel),
            $deadlineDate,
            $deadlineTime
        );
        $assignmentTitle = trim((string) $assignmentTitle);

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

    public function dispatchAbsenceJustificationToEncadreurs(
        int $justificationId,
        string $studentCode,
        string $studentName,
        string $classCode,
        string $absenceDate,
        string $schoolCode
    ): array {
        $encadreurCodes = EncadreurClasse::query()
            ->where('CodeClasse', $classCode)
            ->where('CodeEtablissement', $schoolCode)
            ->pluck('code')
            ->filter()
            ->unique()
            ->values();

        if ($encadreurCodes->isEmpty()) {
            return ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        }

        $recipients = User::query()
            ->whereIn('code', $encadreurCodes)
            ->where('account_type', 'encadreur')
            ->where('CodeEtablissement', $schoolCode)
            ->pluck('code')
            ->filter()
            ->unique()
            ->values();

        $summary = ['sent' => 0, 'attempted' => 0, 'failed' => 0, 'invalidated' => 0];
        foreach ($recipients as $recipientCode) {
            $result = $this->notifyUser(
                (string) $recipientCode,
                'Nouvelle justification d\'absence',
                sprintf('Une justification d\'absence a été soumise pour %s.', $studentName),
                [
                    'type' => 'absence_justification',
                    'recipient_role' => 'encadreur',
                    'justification_id' => (string) $justificationId,
                    'student_code' => $studentCode,
                    'class_code' => $classCode,
                    'school_code' => $schoolCode,
                    'absence_date' => $absenceDate,
                ]
            );

            foreach (['sent', 'attempted', 'failed', 'invalidated'] as $key) {
                $summary[$key] += (int) ($result[$key] ?? 0);
            }
        }

        return $summary;
    }

    protected function notifyUser(string $userCode, string $title, string $body, array $data = []): array
    {
        $user = User::query()->where('code', $userCode)->first();
        if ($user) {
            $user->notify(new \App\Notifications\MobischoDatabaseNotification(
                $title,
                $body,
                $data
            ));
        }

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

    private function subjectPhrase(string $subjectName): string
    {
        $subjectName = trim($subjectName);
        $preposition = preg_match('/^[aeiouyàâäéèêëîïôöùûüÿ]/iu', $subjectName) === 1
            ? 'd’'
            : 'de ';

        return $preposition.$subjectName;
    }
}
