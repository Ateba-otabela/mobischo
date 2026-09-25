@extends('layouts.app')

@section('body')

@if (session()->has('message') )
{{-- <div class="text-center alert {{session('alert') ?? 'alert-success'}}">
    {{ session('message') }}
</div> --}}

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
{{-- <div class="text-center alert {{session('alert') ?? 'alert-success'}}">
    {{ session('message') }}
</div> --}}
@endif

<div class="card">
    <div class="card-body">
        <div class="card-heading ">
            <div class="row justify-content-center mb-lg-0 mb-2">
                <div class="col-12">
                    <h4>
                        <a href="#" onclick="history.back()"><i class="bx bx-left-arrow-circle" style="font-size: 1.5rem"></i></a>
                        Choisissez la classe et l'annee d'inscription
                    </h4>
                    <p class="card-description">Choissisez la classe de l'eleve puis l'annee </p>
                </div>
            </div>
            <div class="row justify-content-center mb-lg-0 mb-2">
                <div class="col-lg-2 col-12">
                        Etablissement:
                </div>
                <div class="col-lg-10 col-12">
                    {{ $school->Nom }}
            </div>
            </div>
        </div>
        <hr class="line">
        <form action="{{ route('choose_student',['parent_id'=>$parent_id]) }}">
            <div class="row">
            <div class="col-lg-6 col-12">
                <label>Classe</label>
                <select class="form-control" name="CodeClasse">
                    @foreach ($school->classes as $class)
                        <option value="{{ $class->CodeClasse }}">{{ $class->LibelleClasse }}</option>
                    @endforeach
                </select>
            </div>
            <div class="col-lg-6 col-12">
                <label>Annee Scholaire</label>
                <select class="form-control" name="CodeAnnee">
                    @foreach ($years as $year)
                        <option value="{{ $year->CodeAnnee }}">{{ $year->Libelle }}</option>
                    @endforeach
                </select>
            </div>
            
                <div class="col-12 pt-2">
                    <button type="submit" class="btn btn-primary">Obtenir la liste</button>
                </div>
            
            </div>
        </form>
    </div>
</div>


@endsection