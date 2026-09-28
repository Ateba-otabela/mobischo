<?php

namespace App\Services;

use App\Models\User;

class PrincipalContextService
{
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
        $context = $this->resolve($user);
        if ($context === null || !$user->tokenCan('ai:chat')) {
            return null;
        }

        return $context;
    }
}