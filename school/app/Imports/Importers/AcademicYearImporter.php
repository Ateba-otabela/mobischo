<?php

namespace App\Imports\Importers;

use App\Imports\AbstractCsvImporter;
use App\Models\Annee;

class AcademicYearImporter extends AbstractCsvImporter
{
    protected function modelClass(): string
    {
        return Annee::class;
    }

    public function type(): string
    {
        return 'academic-years';
    }

    public function displayName(): string
    {
        return __('csv_import.types.academic_years');
    }

    public function identifierColumn(): string
    {
        return 'CodeAnnee';
    }

    protected function columnDefinitions(): array
    {
        return [
            'CodeAnnee' => $this->requiredString(),
            'Libelle' => $this->requiredString(),
        ];
    }
}
