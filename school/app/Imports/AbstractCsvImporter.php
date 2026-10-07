<?php

namespace App\Imports;

use App\Imports\Contracts\CsvImporterInterface;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

abstract class AbstractCsvImporter implements CsvImporterInterface
{
    abstract protected function modelClass(): string;

    abstract protected function columnDefinitions(): array;

    public function columns(): array
    {
        return array_keys($this->columnDefinitions());
    }

    public function requiredColumns(): array
    {
        return array_keys(array_filter(
            $this->columnDefinitions(),
            static function (array $definition): bool {
                return $definition['required'];
            }
        ));
    }

    public function validateRow(array $row): array
    {
        $errors = [];

        foreach ($this->columnDefinitions() as $column => $definition) {
            $value = $row[$column] ?? '';
            if ($value === '' || $value === null) {
                if ($definition['required']) {
                    $errors[$column] = __('csv_import.validation.required');
                }

                continue;
            }

            if (!is_string($value)) {
                $errors[$column] = __('csv_import.validation.invalid');
                continue;
            }

            if (Str::length($value) > 255) {
                $errors[$column] = __('csv_import.validation.too_long');
            }
        }

        return $errors;
    }

    public function exists(string $identifier): bool
    {
        $modelClass = $this->modelClass();

        return $modelClass::query()
            ->where($this->identifierColumn(), $identifier)
            ->exists();
    }

    public function existingIdentifiers(array $identifiers): array
    {
        $modelClass = $this->modelClass();
        $existing = [];

        foreach (array_chunk(array_values(array_unique($identifiers)), 500) as $chunk) {
            $matches = $modelClass::query()
                ->whereIn($this->identifierColumn(), $chunk)
                ->pluck($this->identifierColumn());

            foreach ($matches as $identifier) {
                $existing[] = (string) $identifier;
            }
        }

        return $existing;
    }

    public function create(array $row): void
    {
        $attributes = [];
        foreach ($this->columns() as $column) {
            if (!array_key_exists($column, $row)) {
                continue;
            }

            $value = $row[$column];
            if ($value === '') {
                $value = null;
            }

            $attributes[$column] = $value;
        }

        /** @var Model $modelClass */
        $modelClass = $this->modelClass();
        $modelClass::query()->create($attributes);
    }

    protected function requiredString(): array
    {
        return ['required' => true];
    }

    protected function optionalString(): array
    {
        return ['required' => false];
    }

}
