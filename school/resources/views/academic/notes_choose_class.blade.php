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
                <div class="col-lg-10 col-12">
                    <h4>
                        <a href="#" onclick="history.back()"><i class="bx bx-left-arrow-circle" style="font-size: 1.5rem"></i></a>
                        Choissisez une classe pour consulter les notes
                    </h4>
                    <p class="card-description">Remplissez le formulaire ci-dessous et validez</p>
                </div>
            </div>
        </div>
        
        
        
        <!--primary theme Modal -->

        <hr class="line">
        
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>Noms de classe</th>
                        <th>Codes</th>
                        <th>Etablissement</th>
                        <th></th>
                        
                    </tr>
                </thead>
                <tbody>
                    
                    @forelse ($school->classes as $class)
                    <tr>
                        <td>
                            <div class="list-left d-flex">
                                <div class="list-icon mr-1">
                                    <div class="avatar bg-rgba-info m-0">
                                        <div class="avatar-content">
                                            <i class="bx bxs-zap text-info font-size-base"></i>
                                        </div>
                                    </div>
                                </div>
                                <div class="list-content">
                                    <span class="list-title">{{ $class->LibelleClasse }}</span>
                                    <small class="text-muted d-block">Libelle</small>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="media-body">
                                <h6 class="media-heading mb-0">Code Cycle : {{ $class->CodeCycle }}</h6>
                                <span class="font-small-2">Code Classe : {{ $class->CodeClasse }} </span>
                            </div>
                            
                        </td>
                        <td>
                            <div class="media-body">
                                <h6 class="media-heading mb-0">{{ optional($class->etablissement)->Nom ?? '-' }}</h6>
                                <span class="font-small-2">Code Etablissement : {{ optional($class->etablissement)->CodeEtablissement ?? '-' }}</span>
                            </div>
                            
                        </td>
                        <td class="text-center py-1">
                            <a href="{{ route('notes',['CodeClasse'=>$class->CodeClasse,'CodeEtablissement'=>$class->CodeEtablissement]) }}" class="btn btn-outline-primary btn-sm">Continuer</a>
                        </td>
                    </tr>
                    @empty
                    Liste vide !
                    @endforelse
                    
                    
                </tbody>
            </table>
        </table>
    </div>
    
</div>
</div>


@endsection