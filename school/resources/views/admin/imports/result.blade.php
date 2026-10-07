@extends('layouts.app')

@section('body')
<div class="row">
    <div class="col-12">
        <div class="content-header">
            <h1 class="content-header-title">{{ __('csv_import.result_title') }} — {{ $result['displayName'] }}</h1>
            <p class="text-muted">{{ __('csv_import.result_intro') }}</p>
        </div>
    </div>
</div>

<div class="row">
    @foreach (['imported' => 'imported', 'skipped' => 'skipped', 'failed' => 'failed'] as $countKey => $labelKey)
        <div class="col-sm-4">
            <div class="card">
                <div class="card-body">
                    <p class="text-muted">{{ __('csv_import.' . $labelKey) }}</p>
                    <h2>{{ $result[$countKey] }}</h2>
                </div>
            </div>
        </div>
    @endforeach
</div>

<div class="card">
    <div class="card-body">
        <p><strong>{{ __('csv_import.source_file') }}:</strong> {{ $result['fileName'] }}</p>
        @if ($hasFailedCsv)
            <a class="btn btn-outline-primary mb-1" href="{{ route('admin.imports.failed', $token) }}">
                {{ __('csv_import.download_failures') }}
            </a>
        @endif
        <a class="btn btn-primary mb-1" href="{{ route('admin.imports.index') }}">{{ __('csv_import.another_import') }}</a>

        @if (count($result['rows']))
            <div class="table-responsive mt-1">
                <table class="table table-striped table-bordered">
                    <thead>
                        <tr>
                            <th>{{ __('csv_import.row') }}</th>
                            <th>{{ __('csv_import.identifier') }}</th>
                            <th>{{ __('csv_import.status') }}</th>
                            <th>{{ __('csv_import.details') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach (array_slice($result['rows'], 0, 100) as $row)
                            <tr>
                                <td>{{ $row['line'] }}</td>
                                <td>{{ $row['identifier'] }}</td>
                                <td>{{ __('csv_import.table_status.' . $row['status']) }}</td>
                                <td>{{ $row['reason'] }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            @if (count($result['rows']) > 100)
                <p class="text-muted">{{ __('csv_import.showing_first', ['count' => 100]) }}</p>
            @endif
        @endif
    </div>
</div>
@endsection
