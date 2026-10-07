@extends('layouts.app')

@section('body')
<div class="row">
    <div class="col-12">
        <div class="content-header d-flex justify-content-between align-items-center">
            <div>
                <h1 class="content-header-title">{{ __('csv_import.preview_title') }} — {{ $preview['displayName'] }}</h1>
                <p class="text-muted">{{ __('csv_import.preview_intro') }}</p>
            </div>
            <a class="btn btn-outline-secondary" href="{{ route('admin.imports.index') }}">{{ __('csv_import.back') }}</a>
        </div>
    </div>
</div>

@if ($errors->any())
    <div class="alert alert-danger" role="alert">
        @foreach ($errors->all() as $error)
            <div>{{ $error }}</div>
        @endforeach
    </div>
@endif

<div class="card">
    <div class="card-body">
        <p><strong>{{ __('csv_import.source_file') }}:</strong> {{ $preview['fileName'] }}</p>
        <p><strong>{{ __('csv_import.detected_columns') }}:</strong>
            {{ $preview['detectedColumns'] ? implode(', ', $preview['detectedColumns']) : '—' }}
        </p>

        @if (count($preview['headerErrors']))
            <div class="alert alert-danger" role="alert">
                <strong>{{ __('csv_import.header_errors') }}</strong>
                <ul class="mb-0">
                    @foreach ($preview['headerErrors'] as $message)
                        <li>{{ $message }}</li>
                    @endforeach
                </ul>
            </div>
        @else
            <div class="alert alert-success" role="status">{{ __('csv_import.headers_ok') }}</div>
        @endif

        @if (count($preview['warnings']))
            <div class="alert alert-warning" role="alert">
                <strong>{{ __('csv_import.warnings') }}</strong>
                <ul class="mb-0">
                    @foreach ($preview['warnings'] as $message)
                        <li>{{ $message }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <h5>{{ __('csv_import.summary') }}</h5>
        <div class="row mb-2">
            @foreach ([
                'total' => 'rows_total',
                'newCount' => 'rows_new',
                'existingCount' => 'rows_existing',
                'duplicateCount' => 'rows_duplicate',
                'invalidCount' => 'rows_invalid',
            ] as $countKey => $labelKey)
                <div class="col-sm-6 col-lg">
                    <div class="border rounded p-1 mb-1">
                        <div class="text-muted">{{ __('csv_import.' . $labelKey) }}</div>
                        <strong>{{ $preview[$countKey] }}</strong>
                    </div>
                </div>
            @endforeach
        </div>

        @if (count($preview['rows']) === 0)
            <div class="alert alert-info" role="status">{{ __('csv_import.rows.empty') }}</div>
        @else
            @if (count($preview['rows']) > 100)
                <p class="text-muted">{{ __('csv_import.showing_first', ['count' => 100]) }}</p>
            @endif
            <div class="table-responsive">
                <table class="table table-striped table-bordered">
                    <thead>
                        <tr>
                            <th>{{ __('csv_import.row') }}</th>
                            <th>{{ __('csv_import.identifier') }}</th>
                            @foreach ($preview['recognizedColumns'] as $column)
                                @if ($column !== $preview['columns'][0])
                                    <th>{{ $column }}</th>
                                @endif
                            @endforeach
                            <th>{{ __('csv_import.status') }}</th>
                            <th>{{ __('csv_import.details') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach (array_slice($preview['rows'], 0, 100) as $row)
                            <tr>
                                <td>{{ $row['line'] }}</td>
                                <td>{{ $row['identifier'] }}</td>
                                @foreach ($preview['recognizedColumns'] as $column)
                                    @if ($column !== $preview['columns'][0])
                                        <td>{{ $row['data'][$column] ?? '' }}</td>
                                    @endif
                                @endforeach
                                <td>{{ __('csv_import.table_status.' . $row['status']) }}</td>
                                <td>{{ $row['reason'] }}</td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif

        <div class="d-flex flex-wrap">
            @if ($preview['canImport'])
                <form method="POST" action="{{ route('admin.imports.confirm', $token) }}" class="mr-1 mb-1">
                    @csrf
                    <button class="btn btn-primary" type="submit">{{ __('csv_import.confirm') }}</button>
                </form>
            @endif
            <a class="btn btn-outline-secondary mb-1" href="{{ route('admin.imports.index') }}">{{ __('csv_import.cancel') }}</a>
        </div>
    </div>
</div>
@endsection
