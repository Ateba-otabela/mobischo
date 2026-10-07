@extends('layouts.app')

@section('body')

@if ($errors->any())
    <div class="alert alert-warning" role="alert">
        @foreach ($errors->all() as $error)
            <div>{{ $error }}</div>
        @endforeach
    </div>
@endif

@if (session()->has('message') )
<div class="alert {{session('alert') ?? 'border-primary'}} alert-dismissible mb-2" role="alert">
    <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
    </button>
    <div class="d-flex align-items-center">
        <i class="bx bx-star"></i>
        <span>
            {{ session('message') }}
        </span>
    </div>
</div>

@endif

<div class="card">
    <div class="card-body">
        <div class="card-heading ">
            <div class="row justify-content-center mb-lg-0 mb-2">
                <div class="col-lg-8 col-12">
                    <h4>
                        <a href="#" onclick="history.back()"><i class="bx bx-left-arrow-circle" style="font-size: 1.5rem"></i></a>
                     Inscriptions
                    </h4>
                    <p class="card-description">Choisissez un etablissement pour continuer</p>
                </div>
                
                <div class="col-lg-4 col-12 text-lg-right">
                    <button type="button" class="btn btn-outline-primary" data-toggle="modal" data-target="#import">
                        Importer
                    </button>
                </div>
            </div>
            <hr class="line">

                                    <!--primary theme Modal -->
                                    <div class="modal fade text-left" id="import" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                        <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                            <div class="modal-content">
                                    
                                                <form action="{{ route('import_inscriptions') }}" enctype="multipart/form-data" method="POST">
                                                    @csrf
                                                <div class="modal-header bg-dark">
                                                    <h5 class="modal-title white" id="myModalLabel160">Importer un fichier CSV d'inscriptions</h5>
                                                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                        <i class="bx bx-x"></i>
                                                    </button>
                                                </div>
                                                <div class="modal-body">
                                                    Choissisez le fichier a importer et valider
                                                    <hr class="line">
                                                    
                                                    <div class="content-body">
                                                            <div class="row">
                                                                <div class="col-12">
                                                                    <fieldset class="form-group">
                                                                        <label for="basicInputFile">Fichier CSV</label>
                                                                        <div class="custom-file">
                                                                            <input type="file" name="csv_file" class="custom-file-input" id="inputGroupFile01" accept=".csv">
                                                                            <label class="custom-file-label" for="inputGroupFile01">Choisir le fichier CSV</label>
                                                                        </div>
                                                                    </fieldset>
                                                                </div>
                                                            </div>
                                                    </div>
                                                </div>
                                                <div class="modal-footer">
                                                    <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                                        <i class="bx bx-x d-block d-sm-none"></i>
                                                        <span class="d-none d-sm-block">Annuler</span>
                                                    </button>
                                                    <button type="submit" class="btn btn-dark ml-1">
                                                        <i class="bx bx-check d-block d-sm-none"></i>
                                                        <span class="d-none d-sm-block">Importer</span>
                                                    </button>
                                                </div>
                                                </form>
                                    
                                            </div>
                                        </div>
                                    </div>

            <div class="card-body">
                <label>Etablissement</label>

                <form action="{{ route('inscriptions') }}" method="GET">
                    <div class="row justify-content-between">
                        <div class="col-lg-10 col-12">
                            
                                <select name="CodeEtablissement" class="form-control">
                                    @foreach ($schools as $school)
                                        <option value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                    @endforeach
                                </select>
                        </div>
                        <div class="col-lg-2 col-12 text-lg-right">
                            <button type="submit" class="btn btn-primary" data-toggle="modal" data-target="#primary">
                                Liste
                            </button>
                        </div>
                    </div>
                </form>

            </div>
        </div>
    
</div>
</div>


@endsection