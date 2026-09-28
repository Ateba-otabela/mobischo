<?php

namespace App\Services;

use App\Models\Classe;
use App\Models\Eleve;
use App\Models\EncadreurClasse;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;

class EncadreurClassScope
{
    public function assignedClassCodesForEncadreur(User $user): array
    {
        if (!$this->isEncadreur($user)) {
            return [];
        }

        $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
        if ($schoolCode === '') {
            return [];
        }

        $assignedCodes = EncadreurClasse::query()
            ->where('code', (string) $user->code)
            ->where('CodeEtablissement', $schoolCode)
            ->pluck('CodeClasse')
            ->filter()
            ->map(fn ($value) => (string) $value)
            ->unique()
            ->values()
            ->all();

        if ($assignedCodes === []) {
            return [];
        }

        $validCodes = Classe::query()
            ->where('CodeEtablissement', $schoolCode)
            ->whereIn('CodeClasse', $assignedCodes)
            ->pluck('CodeClasse')
            ->map(fn ($value) => (string) $value)
            ->unique()
            ->values()
            ->all();

        return $validCodes;
    }

    public function ensureClassAccessForEncadreur(User $user, string $codeClasse): bool
    {
        if (!$this->isEncadreur($user)) {
            return false;
        }

        $schoolCode = trim((string) ($user->CodeEtablissement ?? ''));
        if ($schoolCode === '') {
            return false;
        }

        $requestedClass = trim((string) $codeClasse);
        if ($requestedClass === '') {
            return false;
        }

        return EncadreurClasse::query()
            ->where('code', (string) $user->code)
            ->where('CodeEtablissement', $schoolCode)
            ->where('CodeClasse', $requestedClass)
            ->exists()
            && Classe::query()
                ->where('CodeClasse', $requestedClass)
                ->where('CodeEtablissement', $schoolCode)
                ->exists();
    }

    public function listStudentsForEncadreur(User $user, ?string $codeClasse = null): Builder
    {
        if (!$this->isEncadreur($user)) {
            return Eleve::query()->whereRaw('0 = 1');
        }

        $assignedCodes = $this->assignedClassCodesForEncadreur($user);
        if ($assignedCodes === []) {
            return Eleve::query()->whereRaw('0 = 1');
        }

        $query = Eleve::query()->whereIn('CodeClasse', $assignedCodes);

        if ($codeClasse !== null) {
            $requestedClass = trim((string) $codeClasse);
            if ($requestedClass === '') {
                return Eleve::query()->whereRaw('0 = 1');
            }

            if (!$this->ensureClassAccessForEncadreur($user, $requestedClass)) {
                return Eleve::query()->whereRaw('0 = 1');
            }

            $query->where('CodeClasse', $requestedClass);
        }

        return $query->orderBy('Nom')->orderBy('Prenom');
    }

    protected function isEncadreur(User $user): bool
    {
        $accountType = strtolower(trim((string) ($user->account_type ?? '')));

        return $accountType === 'encadreur';
    }
}
