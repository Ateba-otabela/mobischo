<?php

namespace App\Services;

use App\Models\User;

class PrincipalContextService
{
    private const AI_ACCOUNT_TYPES = [
        'parent',
        'enseignant',
        'principal',
        'encadreur',
        'principal_encadreur',
        'administrateur',
    ];

    public function isPrincipal(User $user): bool
    {
        $accountType = strtolower(trim((string) ($user->account_type ?? '')));

        return (bool) $user->admin || in_array(
            $accountType,
            ['encadreur', 'principal', 'principal_encadreur', 'administrateur'],
            true
        );
    }

    public function resolve(User $user): ?array
    {
        if (!$this->isPrincipal($user)) {
            return null;
        }

        $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
        if ($schoolCode === '') {
            return null;
        }

        return [
            'school_code' => $schoolCode,
            'user' => $user,
        ];
    }

    public function resolveForAi(User $user): ?array
    {
        $role = $this->aiRole($user);
        if ($role === null || !$this->canUseAi($user) || !$user->tokenCan('ai:chat')) {
            return null;
        }

        $accountType = strtolower(trim((string) ($user->account_type ?? '')));
        $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));

        if (in_array($role, ['principal', 'principal_encadreur', 'administrateur', 'admin'], true)
            && $schoolCode === '') {
            return null;
        }

        $classScope = match ($role) {
            'principal', 'principal_encadreur', 'administrateur', 'admin' => [
                'type' => 'school',
                'school_code' => $schoolCode,
            ],
            'encadreur' => [
                'type' => 'encadreur_assigned_classes',
                'user_code' => (string) $user->code,
                'school_code' => $schoolCode,
            ],
            'enseignant' => [
                'type' => 'teacher_teaching_assignments',
                'teacher_code' => (string) $user->code,
                'school_code' => $schoolCode,
            ],
            default => ['type' => 'none'],
        };

        $studentScope = match ($role) {
            'parent' => [
                'type' => 'parent_linked_children',
                'parent_code' => (string) $user->code,
            ],
            'principal', 'principal_encadreur', 'administrateur', 'admin' => [
                'type' => 'school_classes',
                'school_code' => $schoolCode,
            ],
            'encadreur' => [
                'type' => 'encadreur_assigned_classes',
                'user_code' => (string) $user->code,
                'school_code' => $schoolCode,
            ],
            'enseignant' => [
                'type' => 'teacher_teaching_assignments',
                'teacher_code' => (string) $user->code,
                'school_code' => $schoolCode,
            ],
            default => ['type' => 'none'],
        };

        return [
            'user' => $user,
            'user_code' => (string) $user->code,
            'account_type' => $accountType,
            'role' => $role,
            'school_code' => $schoolCode,
            'class_scope' => $classScope,
            'student_scope' => $studentScope,
            'teacher_code' => $role === 'enseignant' ? (string) $user->code : null,
            'parent_code' => $role === 'parent' ? (string) $user->code : null,
        ];
    }

    public function canUseAi(User $user): bool
    {
        $role = $this->aiRole($user);
        if ($role === null) {
            return false;
        }

        if (in_array($role, ['principal', 'principal_encadreur', 'administrateur', 'admin'], true)
            && trim((string) ($user->CodeEtablissement ?? '')) === '') {
            return false;
        }

        return true;
    }

    private function aiRole(User $user): ?string
    {
        $accountType = strtolower(trim((string) ($user->account_type ?? '')));
        if (in_array($accountType, ['principal', 'encadreur', 'principal_encadreur', 'administrateur'], true)) {
            return $accountType;
        }

        if ((bool) $user->admin) {
            return 'admin';
        }

        return in_array($accountType, ['parent', 'enseignant'], true)
            ? $accountType
            : null;
    }
}