<?php

namespace App\Imports\Importers;

use App\Imports\AbstractCsvImporter;
use App\Models\Etablissement;

class SchoolImporter extends AbstractCsvImporter
{
    protected function modelClass(): string
    {
        return Etablissement::class;
    }

    public function type(): string
    {
        return 'schools';
    }

    public function displayName(): string
    {
        return __('csv_import.types.schools');
    }

    public function identifierColumn(): string
    {
        return 'CodeEtablissement';
    }

    protected function columnDefinitions(): array
    {
        return [
            'CodeEtablissement' => $this->requiredString(),
            'Nom' => $this->requiredString(),
            'Adresse' => $this->requiredString(),
            'Tel' => $this->requiredString(),
            'Fax' => $this->requiredString(),
            'Pays' => $this->optionalString(),
            'REPPHOTO' => $this->optionalString(),
        ];
    }

    public function create(array $row): void
    {
        if (($row['Pays'] ?? '') === '') {
            unset($row['Pays']);
        }

        parent::create($row);
    }
}
