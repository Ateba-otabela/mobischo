<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Validator;

class Controller extends BaseController
{
    use AuthorizesRequests, DispatchesJobs, ValidatesRequests;

    protected function readLegacyCsvRows(
        Request $request,
        int $minimumColumns,
        ?int $maximumColumns = null,
        array $expectedHeader = []
    ): array
    {
        $request->validate([
            'csv_file' => ['required', 'file', 'mimes:csv,txt'],
        ]);

        $handle = fopen($request->file('csv_file')->getRealPath(), 'rb');
        if ($handle === false) {
            throw ValidationException::withMessages([
                'csv_file' => 'Le fichier CSV ne peut pas être lu.',
            ]);
        }

        $rows = [];
        $line = 0;

        try {
            while (($row = fgetcsv($handle, 1000000, ';')) !== false) {
                $line++;
                if (count($row) === 1 && trim((string) $row[0]) === '') {
                    continue;
                }

                if ($rows === [] && isset($row[0])) {
                    $row[0] = preg_replace('/^\xEF\xBB\xBF/', '', (string) $row[0]);
                    if ($this->matchesLegacyCsvHeader($row, $expectedHeader, $minimumColumns, $maximumColumns)) {
                        continue;
                    }
                }

                if (count($row) < $minimumColumns || ($maximumColumns !== null && count($row) > $maximumColumns)) {
                    throw ValidationException::withMessages([
                        'csv_file' => "La ligne {$line} ne contient pas un nombre valide de colonnes.",
                    ]);
                }

                $rows[] = $row;
            }
        } finally {
            fclose($handle);
        }

        if ($rows === []) {
            throw ValidationException::withMessages([
                'csv_file' => 'Le fichier CSV ne contient aucune ligne de données.',
            ]);
        }

        return $rows;
    }

    private function matchesLegacyCsvHeader(
        array $row,
        array $expectedHeader,
        int $minimumColumns,
        ?int $maximumColumns
    ): bool
    {
        $columnCount = count($row);
        if ($expectedHeader === []
            || $columnCount < $minimumColumns
            || ($maximumColumns !== null && $columnCount > $maximumColumns)
            || ($maximumColumns !== null && $minimumColumns === $maximumColumns && $columnCount !== $maximumColumns)) {
            return false;
        }

        foreach ($expectedHeader as $index => $columnName) {
            if ($index >= count($row) || trim((string) $row[$index]) !== $columnName) {
                return false;
            }
        }

        return true;
    }

    protected function validateLegacyCsvRows(array $rows, array $rules): array
    {
        $validatedRows = [];

        foreach ($rows as $index => $row) {
            $row = array_map(static function ($value): string {
                return trim((string) $value);
            }, $row);
            foreach ($rules as $column => $rule) {
                if (($row[$column] ?? null) === ''
                    && strpos($rule, 'nullable|') === 0
                    && (strpos($rule, '|date') !== false
                        || strpos($rule, '|integer') !== false
                        || strpos($rule, '|numeric') !== false)) {
                    $row[$column] = null;
                }
            }

            $validator = Validator::make($row, $rules);
            if ($validator->fails()) {
                throw ValidationException::withMessages([
                    'csv_file' => 'La ligne '.($index + 1).' est invalide : '.$validator->errors()->first(),
                ]);
            }

            $validatedRows[] = $row;
        }

        return $validatedRows;
    }

}
