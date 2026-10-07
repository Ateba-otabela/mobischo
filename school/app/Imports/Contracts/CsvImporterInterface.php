<?php

namespace App\Imports\Contracts;

interface CsvImporterInterface
{
    public function type(): string;

    public function displayName(): string;

    public function columns(): array;

    public function requiredColumns(): array;

    public function identifierColumn(): string;

    public function validateRow(array $row): array;

    public function exists(string $identifier): bool;

    public function existingIdentifiers(array $identifiers): array;

    public function create(array $row): void;
}
