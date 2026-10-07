<?php

namespace App\Imports\Importers;

use App\Imports\AbstractCsvImporter;
use App\Models\Annee;
use App\Models\Classe;
use App\Models\Eleve;

class StudentImporter extends AbstractCsvImporter
{
    private $yearExists = [];
    private $classExists = [];

    protected function modelClass(): string
    {
        return Eleve::class;
    }

    public function type(): string
    {
        return 'students';
    }

    public function displayName(): string
    {
        return __('csv_import.types.students');
    }

    public function identifierColumn(): string
    {
        return 'CodeEleve';
    }

    protected function columnDefinitions(): array
    {
        return [
            'CodeEleve' => $this->requiredString(),
            'CodeAnnee' => $this->requiredString(),
            'CodeClasse' => $this->requiredString(),
            'code' => $this->optionalString(),
            'CodeConduite' => $this->optionalString(),
            'Nom' => $this->optionalString(),
            'Prenom' => $this->optionalString(),
            'DateNaissance' => $this->optionalString(),
            'LieuNaissance' => $this->optionalString(),
            'Sex' => $this->optionalString(),
            'Nationalite' => $this->optionalString(),
            'dateinscription' => $this->requiredString(),
            'photo' => $this->optionalString(),
            'Excl' => $this->optionalString(),
            'Nomp' => $this->optionalString(),
            'TelP' => $this->optionalString(),
            'Image' => $this->optionalString(),
            'strimage' => $this->optionalString(),
            'Nomm' => $this->optionalString(),
            'REGION' => $this->optionalString(),
            'DEPART' => $this->optionalString(),
            'RELIGION' => $this->optionalString(),
            'SITREG' => $this->optionalString(),
            'ACTIVEEPS' => $this->optionalString(),
            'PROFP' => $this->optionalString(),
            'NOMT' => $this->optionalString(),
            'PROFM' => $this->optionalString(),
            'ADRESSE' => $this->optionalString(),
            'RESIDENT' => $this->optionalString(),
            'TELM' => $this->optionalString(),
            'TELT' => $this->optionalString(),
            'PERSONCON' => $this->optionalString(),
            'RESERVE1' => $this->optionalString(),
            'RESERVE2' => $this->optionalString(),
            'RESERVE3' => $this->optionalString(),
            'RESERVE4' => $this->optionalString(),
        ];
    }

    public function validateRow(array $row): array
    {
        $errors = parent::validateRow($row);

        $yearCode = trim((string) ($row['CodeAnnee'] ?? ''));
        if ($yearCode !== '' && !$this->yearExists($yearCode)) {
            $errors['CodeAnnee'] = __('csv_import.validation.year_missing');
        }

        $classCode = trim((string) ($row['CodeClasse'] ?? ''));
        if ($classCode !== '' && !$this->classExists($classCode)) {
            $errors['CodeClasse'] = __('csv_import.validation.class_missing');
        }

        return $errors;
    }

    private function yearExists(string $code): bool
    {
        if (!array_key_exists($code, $this->yearExists)) {
            $this->yearExists[$code] = Annee::query()
                ->where('CodeAnnee', $code)
                ->exists();
        }

        return $this->yearExists[$code];
    }

    private function classExists(string $code): bool
    {
        if (!array_key_exists($code, $this->classExists)) {
            $this->classExists[$code] = Classe::query()
                ->where('CodeClasse', $code)
                ->exists();
        }

        return $this->classExists[$code];
    }
}
