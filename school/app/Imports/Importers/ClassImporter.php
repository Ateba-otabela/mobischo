<?php

namespace App\Imports\Importers;

use App\Imports\AbstractCsvImporter;
use App\Models\Classe;
use App\Models\Etablissement;

class ClassImporter extends AbstractCsvImporter
{
    private $schoolExists = [];

    protected function modelClass(): string
    {
        return Classe::class;
    }

    public function type(): string
    {
        return 'classes';
    }

    public function displayName(): string
    {
        return __('csv_import.types.classes');
    }

    public function identifierColumn(): string
    {
        return 'CodeClasse';
    }

    protected function columnDefinitions(): array
    {
        return [
            'CodeClasse' => $this->requiredString(),
            'CodeTypeClasse' => $this->requiredString(),
            'LibelleClasse' => $this->requiredString(),
            'CodeCycle' => $this->requiredString(),
            'CodeSpecialite' => $this->requiredString(),
            'codetypeinscrip' => $this->requiredString(),
            'CodeEtablissement' => $this->requiredString(),
        ];
    }

    public function validateRow(array $row): array
    {
        $errors = parent::validateRow($row);
        $schoolCode = trim((string) ($row['CodeEtablissement'] ?? ''));

        if ($schoolCode !== '' && !$this->schoolExists($schoolCode)) {
            $errors['CodeEtablissement'] = __('csv_import.validation.school_missing');
        }

        return $errors;
    }

    private function schoolExists(string $code): bool
    {
        if (!array_key_exists($code, $this->schoolExists)) {
            $this->schoolExists[$code] = Etablissement::query()
                ->where('CodeEtablissement', $code)
                ->exists();
        }

        return $this->schoolExists[$code];
    }
}
