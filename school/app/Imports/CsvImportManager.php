<?php

namespace App\Imports;

use App\Imports\Contracts\CsvImporterInterface;
use App\Imports\Importers\AcademicYearImporter;
use App\Imports\Importers\ClassImporter;
use App\Imports\Importers\SchoolImporter;
use App\Imports\Importers\StudentImporter;
use App\Imports\Importers\SubjectImporter;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use InvalidArgumentException;
use RuntimeException;

class CsvImportManager
{
    private const DIRECTORY = 'private/csv-imports';
    private const MAX_FILE_KILOBYTES = 10240;
    private const MAX_ROWS = 20000;
    private const RETENTION_SECONDS = 86400;

    /** @var CsvImporterInterface[] */
    private $importers;

    public function __construct()
    {
        $importers = [
            new SchoolImporter(),
            new ClassImporter(),
            new SubjectImporter(),
            new AcademicYearImporter(),
            new StudentImporter(),
        ];

        $this->importers = [];
        foreach ($importers as $importer) {
            $this->importers[$importer->type()] = $importer;
        }
    }

    public function importers(): array
    {
        return array_values($this->importers);
    }

    public function importer(string $type): CsvImporterInterface
    {
        if (!isset($this->importers[$type])) {
            throw new InvalidArgumentException(__('csv_import.errors.unsupported_type'));
        }

        return $this->importers[$type];
    }

    public function templateCsv(string $type): string
    {
        $importer = $this->importer($type);
        $handle = fopen('php://temp', 'w+');
        if ($handle === false) {
            throw new RuntimeException(__('csv_import.errors.template_failed'));
        }

        if (fputcsv($handle, $importer->columns(), ';') === false) {
            fclose($handle);
            throw new RuntimeException(__('csv_import.errors.template_failed'));
        }

        rewind($handle);
        $csv = stream_get_contents($handle);
        fclose($handle);
        if ($csv === false) {
            throw new RuntimeException(__('csv_import.errors.template_failed'));
        }

        return "\xEF\xBB\xBF" . $csv;
    }

    public function storeUpload(UploadedFile $file): string
    {
        if (strtolower($file->getClientOriginalExtension()) !== 'csv') {
            throw new InvalidArgumentException(__('csv_import.errors.csv_extension'));
        }

        $mime = strtolower((string) $file->getMimeType());
        $allowedMimes = [
            'text/plain',
            'text/csv',
            'application/csv',
            'application/vnd.ms-excel',
            'application/octet-stream',
        ];
        if ($mime !== '' && !in_array($mime, $allowedMimes, true)) {
            throw new InvalidArgumentException(__('csv_import.errors.csv_mime'));
        }

        if ($file->getSize() === 0) {
            throw new InvalidArgumentException(__('csv_import.errors.empty_file'));
        }
        if ($file->getSize() > self::MAX_FILE_KILOBYTES * 1024) {
            throw new InvalidArgumentException(__('csv_import.errors.file_too_large'));
        }

        $token = bin2hex(random_bytes(24));
        $storedPath = $file->storeAs(self::DIRECTORY, $token . '.csv', 'local');
        if ($storedPath === false) {
            throw new RuntimeException(__('csv_import.errors.upload_failed'));
        }

        return $token;
    }

    public function sourcePath(string $token): string
    {
        $this->assertToken($token);
        $path = Storage::disk('local')->path(self::DIRECTORY . '/' . $token . '.csv');
        if (!is_file($path)) {
            throw new RuntimeException(__('csv_import.errors.source_unavailable'));
        }

        return $path;
    }

    public function preview(string $type, string $path, string $fileName): array
    {
        $importer = $this->importer($type);
        $parsed = $this->parse($importer, $path);

        return [
            'type' => $importer->type(),
            'displayName' => $importer->displayName(),
            'fileName' => $fileName,
            'columns' => $importer->columns(),
            'requiredColumns' => $importer->requiredColumns(),
            'detectedColumns' => $parsed['detectedColumns'],
            'recognizedColumns' => $parsed['recognizedColumns'],
            'unknownColumns' => $parsed['unknownColumns'],
            'missingColumns' => $parsed['missingColumns'],
            'headerErrors' => $parsed['headerErrors'],
            'warnings' => $parsed['warnings'],
            'rows' => $parsed['rows'],
            'total' => count($parsed['rows']),
            'newCount' => $this->countStatus($parsed['rows'], 'new'),
            'existingCount' => $this->countStatus($parsed['rows'], 'skipped'),
            'duplicateCount' => $this->countStatus($parsed['rows'], 'duplicate'),
            'invalidCount' => $this->countStatus($parsed['rows'], 'invalid'),
            'canImport' => empty($parsed['headerErrors']) && !$parsed['tooManyRows'],
            'tooManyRows' => $parsed['tooManyRows'],
        ];
    }

    public function importConfirmed(string $type, string $path, string $fileName): array
    {
        $preview = $this->preview($type, $path, $fileName);
        if (!$preview['canImport']) {
            throw new RuntimeException(__('csv_import.errors.header_blocked'));
        }

        $importer = $this->importer($type);
        $rows = $preview['rows'];
        $importIndexes = [];
        foreach ($rows as $index => $row) {
            if ($row['status'] === 'new') {
                $importIndexes[] = $index;
            }
        }

        try {
            if ($importIndexes !== []) {
                DB::transaction(function () use ($importer, &$rows, $importIndexes): void {
                    $identifiers = array_map(static function (int $index) use (&$rows): string {
                        return $rows[$index]['identifier'];
                    }, $importIndexes);
                    $existingIdentifiers = array_fill_keys(
                        $importer->existingIdentifiers($identifiers),
                        true
                    );

                    foreach ($importIndexes as $index) {
                        $identifier = $rows[$index]['identifier'];
                        if (isset($existingIdentifiers[$identifier])) {
                            $rows[$index]['status'] = 'skipped';
                            $rows[$index]['reason'] = __('csv_import.rows.already_exists');
                            continue;
                        }

                        $importer->create($rows[$index]['data']);
                        $rows[$index]['status'] = 'imported';
                        $rows[$index]['reason'] = __('csv_import.rows.created');
                    }
                });
            }
        } catch (\Throwable $exception) {
            report($exception);
            Log::error('Échec de la transaction d’import CSV.', [
                'type' => $type,
                'exception' => get_class($exception),
            ]);

            foreach ($importIndexes as $index) {
                if (in_array($rows[$index]['status'], ['new', 'imported'], true)) {
                    $rows[$index]['status'] = 'failed';
                    $rows[$index]['reason'] = __('csv_import.rows.transaction_rolled_back');
                }
            }
        }

        $imported = $this->countStatus($rows, 'imported');
        $skipped = $this->countStatus($rows, 'skipped') +
            $this->countStatus($rows, 'duplicate');
        $failed = $this->countStatus($rows, 'invalid') +
            $this->countStatus($rows, 'failed');

        return [
            'type' => $type,
            'displayName' => $importer->displayName(),
            'fileName' => $fileName,
            'total' => count($rows),
            'imported' => $imported,
            'skipped' => $skipped,
            'failed' => $failed,
            'rows' => $rows,
        ];
    }

    public function saveResult(string $token, array $result): void
    {
        $this->assertToken($token);
        $json = json_encode($result, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($json === false || !Storage::disk('local')->put(self::DIRECTORY . '/' . $token . '.json', $json)) {
            throw new RuntimeException(__('csv_import.errors.result_save_failed'));
        }

        $failedRows = array_values(array_filter(
            $result['rows'],
            static function (array $row): bool {
                return in_array($row['status'], ['invalid', 'failed', 'duplicate'], true);
            }
        ));
        if ($failedRows === []) {
            return;
        }

        $handle = fopen('php://temp', 'w+');
        if ($handle === false) {
            throw new RuntimeException(__('csv_import.errors.report_failed'));
        }

        fputcsv($handle, [
            __('csv_import.row'),
            __('csv_import.identifier'),
            __('csv_import.table_status.failed'),
            __('csv_import.details'),
        ], ';');
        foreach ($failedRows as $row) {
            fputcsv($handle, [
                $row['line'],
                $this->spreadsheetSafe($row['identifier']),
                __('csv_import.table_status.' . $row['status']),
                $this->spreadsheetSafe($row['reason']),
            ], ';');
        }
        rewind($handle);
        $csv = stream_get_contents($handle);
        fclose($handle);

        if (!Storage::disk('local')->put(self::DIRECTORY . '/' . $token . '-failed.csv', $csv)) {
            throw new RuntimeException(__('csv_import.errors.report_save_failed'));
        }
    }

    public function result(string $token): array
    {
        $this->assertToken($token);
        $jsonPath = self::DIRECTORY . '/' . $token . '.json';
        if (!Storage::disk('local')->exists($jsonPath)) {
            throw new RuntimeException(__('csv_import.errors.result_unavailable'));
        }

        $result = json_decode(Storage::disk('local')->get($jsonPath), true);
        if (!is_array($result)) {
            throw new RuntimeException(__('csv_import.errors.result_unreadable'));
        }

        return $result;
    }

    public function failedCsvPath(string $token): ?string
    {
        $this->assertToken($token);
        $relativePath = self::DIRECTORY . '/' . $token . '-failed.csv';
        if (!Storage::disk('local')->exists($relativePath)) {
            return null;
        }

        return Storage::disk('local')->path($relativePath);
    }

    public function deleteSource(string $token): void
    {
        $this->assertToken($token);
        Storage::disk('local')->delete(self::DIRECTORY . '/' . $token . '.csv');
    }

    public function cleanupExpiredFiles(): void
    {
        $disk = Storage::disk('local');
        $directory = self::DIRECTORY;
        if (!$disk->exists($directory)) {
            return;
        }

        $cutoff = time() - self::RETENTION_SECONDS;
        foreach ($disk->files($directory) as $file) {
            if ($disk->lastModified($file) < $cutoff) {
                $disk->delete($file);
            }
        }
    }

    private function parse(CsvImporterInterface $importer, string $path): array
    {
        $handle = fopen($path, 'rb');
        if ($handle === false) {
            throw new RuntimeException(__('csv_import.errors.read_failed'));
        }

        $header = fgetcsv($handle, 1048576, ';');
        if ($header === false || $header === [null]) {
            fclose($handle);
            throw new InvalidArgumentException(__('csv_import.errors.no_header'));
        }

        if (isset($header[0])) {
            $header[0] = preg_replace('/^\xEF\xBB\xBF/', '', (string) $header[0]);
        }

        $columnLookup = [];
        foreach ($importer->columns() as $column) {
            $columnLookup[strtolower($column)] = $column;
        }

        $detectedColumns = [];
        $recognizedColumns = [];
        $unknownColumns = [];
        $headerErrors = [];
        $warnings = [];
        $positions = [];
        $seenHeaders = [];
        $seenIdentifiers = [];
        $candidateIdentifiers = [];

        foreach ($header as $position => $rawHeader) {
            $name = trim((string) $rawHeader);
            $key = strtolower($name);
            $detectedColumns[] = $name;

            if ($name === '') {
                $headerErrors[] = __('csv_import.headers.empty');
                continue;
            }
            if (isset($seenHeaders[$key])) {
                $headerErrors[] = __('csv_import.headers.duplicate', ['column' => $name]);
                continue;
            }
            $seenHeaders[$key] = true;

            if (!isset($columnLookup[$key])) {
                $unknownColumns[] = $name;
                continue;
            }

            $canonical = $columnLookup[$key];
            $positions[$position] = $canonical;
            $recognizedColumns[] = $canonical;
        }

        $missingColumns = array_values(array_diff(
            $importer->requiredColumns(),
            $recognizedColumns
        ));
        foreach ($missingColumns as $column) {
            $headerErrors[] = __('csv_import.headers.missing', ['column' => $column]);
        }
        foreach ($unknownColumns as $column) {
            $warnings[] = __('csv_import.headers.unknown', ['column' => $column]);
        }

        $rows = [];
        $csvLine = 1;
        $tooManyRows = false;
        $expectedFieldCount = count($header);

        while (($fields = fgetcsv($handle, 1048576, ';')) !== false) {
            $csvLine++;
            if ($fields === [null] || $this->isEmptyRow($fields)) {
                continue;
            }
            if (count($rows) >= self::MAX_ROWS) {
                $tooManyRows = true;
                break;
            }

            $data = array_fill_keys($importer->columns(), '');
            $errors = [];
            if (count($fields) > $expectedFieldCount) {
                foreach (array_slice($fields, $expectedFieldCount) as $extraValue) {
                    if (trim((string) $extraValue) !== '') {
                        $errors['_row'] = __('csv_import.rows.too_many_fields');
                        break;
                    }
                }
            }

            foreach ($positions as $position => $column) {
                $value = $fields[$position] ?? '';
                $value = trim((string) $value);
                if (preg_match('//u', $value) !== 1) {
                    $errors['_row'] = __('csv_import.rows.invalid_encoding');
                    continue;
                }
                $data[$column] = $value;
            }

            $errors += $importer->validateRow($data);
            $identifier = trim((string) ($data[$importer->identifierColumn()] ?? ''));
            $status = empty($errors) ? 'new' : 'invalid';
            $reason = empty($errors) ? __('csv_import.rows.ready') : implode(' ', array_values($errors));

            if ($identifier !== '' && empty($errors)) {
                if (isset($seenIdentifiers[$identifier])) {
                    $status = 'duplicate';
                    $reason = __('csv_import.rows.duplicate', ['line' => $seenIdentifiers[$identifier]]);
                } else {
                    $seenIdentifiers[$identifier] = $csvLine;
                    $candidateIdentifiers[$identifier] = true;
                }
            } elseif ($identifier !== '' && !isset($seenIdentifiers[$identifier])) {
                $seenIdentifiers[$identifier] = $csvLine;
            }

            $rows[] = [
                'line' => $csvLine,
                'identifier' => $identifier,
                'status' => $status,
                'reason' => $reason,
                'errors' => $errors,
                'data' => $data,
            ];
        }

        fclose($handle);
        $existingIdentifiers = array_fill_keys(
            $importer->existingIdentifiers(array_keys($candidateIdentifiers)),
            true
        );
        foreach ($rows as &$row) {
            if ($row['status'] === 'new' && isset($existingIdentifiers[$row['identifier']])) {
                $row['status'] = 'skipped';
                $row['reason'] = __('csv_import.rows.already_exists');
            }
        }
        unset($row);

        if ($tooManyRows) {
            $headerErrors[] = __('csv_import.errors.too_many_rows', ['count' => self::MAX_ROWS]);
        }

        return [
            'detectedColumns' => $detectedColumns,
            'recognizedColumns' => array_values(array_unique($recognizedColumns)),
            'unknownColumns' => $unknownColumns,
            'missingColumns' => $missingColumns,
            'headerErrors' => $headerErrors,
            'warnings' => $warnings,
            'rows' => $rows,
            'tooManyRows' => $tooManyRows,
        ];
    }

    private function isEmptyRow(array $fields): bool
    {
        foreach ($fields as $field) {
            if (trim((string) $field) !== '') {
                return false;
            }
        }

        return true;
    }

    private function countStatus(array $rows, string $status): int
    {
        return count(array_filter($rows, static function (array $row) use ($status): bool {
            return $row['status'] === $status;
        }));
    }

    private function spreadsheetSafe(string $value): string
    {
        if (preg_match('/^\s*[=+\-@]/u', $value) === 1) {
            return "'" . $value;
        }

        return $value;
    }

    private function assertToken(string $token): void
    {
        if (preg_match('/^[a-f0-9]{48}$/', $token) !== 1) {
            throw new InvalidArgumentException(__('csv_import.errors.invalid_reference'));
        }
    }
}
