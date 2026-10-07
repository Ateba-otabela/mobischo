<?php

namespace App\Imports\Importers;

use App\Imports\AbstractCsvImporter;
use App\Models\Etablissement;
use App\Models\Matiere;

class SubjectImporter extends AbstractCsvImporter
{
    private $schoolExists = [];

    protected function modelClass(): string
    {
        return Matiere::class;
    }

    public function type(): string
    {
        return 'subjects';
    }

    public function displayName(): string
    {
        return __('csv_import.types.subjects');
    }

    public function identifierColumn(): string
    {
        return 'CodeMatiere';
    }

    protected function columnDefinitions(): array
    {
        return [
            'CodeMatiere' => $this->requiredString(),
            'LibelleMatiere' => $this->requiredString(),
            'ordre' => $this->requiredString(),
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
