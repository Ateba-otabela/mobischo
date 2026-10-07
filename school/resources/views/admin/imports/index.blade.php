@extends('layouts.app')

@section('body')
<div class="row">
    <div class="col-12">
        <div class="content-header">
            <h1 class="content-header-title">{{ __('csv_import.title') }}</h1>
            <p class="text-muted">{{ __('csv_import.subtitle') }}</p>
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
    <div class="card-header">
        <h4 class="card-title">{{ __('csv_import.title') }}</h4>
    </div>
    <div class="card-body">
        <form method="POST" action="{{ route('admin.imports.upload') }}" enctype="multipart/form-data">
            @csrf
            <div class="form-group">
                <label for="import_type">{{ __('csv_import.type') }}</label>
                <select class="form-control" id="import_type" name="import_type" required>
                    @foreach ($importers as $importer)
                        <option value="{{ $importer->type() }}" {{ old('import_type') === $importer->type() ? 'selected' : '' }}>
                            {{ $importer->displayName() }}
                        </option>
                    @endforeach
                </select>
            </div>
            <div class="form-group">
                <label for="csv_file">{{ __('csv_import.file') }}</label>
                <input class="form-control-file" type="file" id="csv_file" name="csv_file" accept=".csv,text/csv" required>
                <small class="form-text text-muted">{{ __('csv_import.delimiter_note') }}</small>
            </div>
            <button class="btn btn-primary" type="submit">{{ __('csv_import.upload') }}</button>
        </form>
        <hr>
        <h5>{{ __('csv_import.templates_title') }}</h5>
        <ul class="mb-0">
            @foreach ($importers as $importer)
                <li>
                    <a href="{{ route('admin.imports.template', $importer->type()) }}">
                        {{ __('csv_import.download_template', ['type' => $importer->displayName()]) }}
                    </a>
                </li>
            @endforeach
        </ul>
    </div>
</div>
@endsection
