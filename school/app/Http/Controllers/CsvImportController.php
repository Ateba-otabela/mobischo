<?php

namespace App\Http\Controllers;

use App\Imports\CsvImportManager;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use InvalidArgumentException;

class CsvImportController extends Controller
{
    private const PENDING_SESSION_KEY = 'csv_import.pending';
    private const RESULTS_SESSION_KEY = 'csv_import.results';

    private $manager;

    public function __construct(CsvImportManager $manager)
    {
        $this->manager = $manager;
    }

    public function index()
    {
        $this->manager->cleanupExpiredFiles();

        return view('admin.imports.index', [
            'importers' => $this->manager->importers(),
        ]);
    }

    public function downloadTemplate(string $type)
    {
        try {
            $importer = $this->manager->importer($type);
            $csv = $this->manager->templateCsv($type);
        } catch (InvalidArgumentException $exception) {
            abort(404);
        }

        return response($csv, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="' . $type . '-template.csv"',
        ]);
    }

    public function upload(Request $request)
    {
        $validated = $request->validate([
            'import_type' => ['required', 'string', 'in:schools,classes,subjects,academic-years,students'],
            'csv_file' => ['required', 'file', 'max:10240'],
        ]);

        try {
            $this->manager->importer($validated['import_type']);
            $token = $this->manager->storeUpload($request->file('csv_file'));
        } catch (InvalidArgumentException $exception) {
            return back()->withErrors(['csv_file' => $exception->getMessage()])->withInput();
        } catch (\Throwable $exception) {
            report($exception);
            Log::error('Échec de conservation d’un fichier d’importation CSV.', [
                'exception' => get_class($exception),
            ]);

            return back()->withErrors(['csv_file' => __('csv_import.errors.upload_failed')])->withInput();
        }

        $request->session()->put(self::PENDING_SESSION_KEY . '.' . $token, [
            'type' => $validated['import_type'],
            'file_name' => $request->file('csv_file')->getClientOriginalName(),
        ]);

        return redirect()->route('admin.imports.preview', $token);
    }

    public function preview(Request $request, string $token)
    {
        $pending = $this->pendingImport($request, $token);
        try {
            $preview = $this->manager->preview(
                $pending['type'],
                $this->manager->sourcePath($token),
                $pending['file_name']
            );
        } catch (InvalidArgumentException $exception) {
            return redirect()->route('admin.imports.index')
                ->withErrors(['csv_file' => $exception->getMessage()]);
        } catch (\Throwable $exception) {
            report($exception);
            Log::error('Échec de lecture d’un fichier d’importation CSV.', [
                'exception' => get_class($exception),
            ]);

            return redirect()->route('admin.imports.index')
                ->withErrors(['csv_file' => __('csv_import.errors.preview_failed')]);
        }

        return view('admin.imports.preview', [
            'token' => $token,
            'preview' => $preview,
        ]);
    }

    public function confirm(Request $request, string $token)
    {
        $pending = $this->pendingImport($request, $token);
        try {
            $result = $this->manager->importConfirmed(
                $pending['type'],
                $this->manager->sourcePath($token),
                $pending['file_name']
            );
            $this->manager->saveResult($token, $result);
            $this->manager->deleteSource($token);
        } catch (InvalidArgumentException $exception) {
            return redirect()->route('admin.imports.preview', $token)
                ->withErrors(['import' => $exception->getMessage()]);
        } catch (\Throwable $exception) {
            report($exception);
            Log::error('Échec de confirmation d’un import CSV.', [
                'type' => $pending['type'],
                'exception' => get_class($exception),
            ]);

            return redirect()->route('admin.imports.preview', $token)
                ->withErrors(['import' => __('csv_import.errors.import_failed')]);
        }

        $request->session()->forget(self::PENDING_SESSION_KEY . '.' . $token);
        $request->session()->put(self::RESULTS_SESSION_KEY . '.' . $token, true);

        return redirect()->route('admin.imports.result', $token);
    }

    public function result(Request $request, string $token)
    {
        abort_unless($request->session()->get(self::RESULTS_SESSION_KEY . '.' . $token), 404);

        try {
            $result = $this->manager->result($token);
        } catch (\Throwable $exception) {
            report($exception);
            Log::error('Échec de lecture du résultat d’un import CSV.', [
                'exception' => get_class($exception),
            ]);

            return redirect()->route('admin.imports.index')
                ->withErrors(['import' => __('csv_import.errors.result_unavailable')]);
        }

        return view('admin.imports.result', [
            'result' => $result,
            'token' => $token,
            'hasFailedCsv' => $this->manager->failedCsvPath($token) !== null,
        ]);
    }

    public function downloadFailedRows(Request $request, string $token)
    {
        abort_unless($request->session()->get(self::RESULTS_SESSION_KEY . '.' . $token), 404);
        $path = $this->manager->failedCsvPath($token);
        abort_unless($path !== null, 404);

        return response()->download($path, 'lignes-en-echec.csv', [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }

    private function pendingImport(Request $request, string $token): array
    {
        abort_unless(preg_match('/^[a-f0-9]{48}$/', $token) === 1, 404);
        $pending = $request->session()->get(self::PENDING_SESSION_KEY . '.' . $token);
        abort_unless(
            is_array($pending) &&
            isset($pending['type'], $pending['file_name']) &&
            Storage::disk('local')->exists('private/csv-imports/' . $token . '.csv'),
            404
        );

        return $pending;
    }
}
