@extends('layouts.app')

@section('body')

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

            <form action="{{ route('sorted_enseignements') }}">
            <div class="row justify-content-center mb-lg-0 mb-2">
            <div class="col-lg-7 col-12">
            <h4>
                <a href="#" onclick="history.back()"><i class="bx bx-left-arrow-circle" style="font-size: 1.5rem"></i></a>
               Liste des Enseignement
            </h4>
            <p class="card-description">Etablissement : {{ $school->Nom }}</p>
            </div>
            <div class="col-lg-3 col-12">
                <label>Classe</label>
                 <select class="form-control" name="CodeClasse">
                     @foreach ($school->classes as $school_classe)
                     
                     @if($classe)
                        @if($school_classe->CodeClasse == $classe->CodeClasse)
                        <option selected="selected" value="{{ $school_classe->CodeClasse }}">{{ $school_classe->LibelleClasse }}</option>
                        @endif
                    @endif

                     <option value="{{ $school_classe->CodeClasse }}">{{ $school_classe->LibelleClasse }}</option>
                     @endforeach
                 </select>
             </div>
            <div class="col-lg-2 col-12 pt-2 text-lg-right">
                <input type="hidden" name="CodeEtablissement" value="{{ $school->CodeEtablissement }}">
                <button type="submit" class="btn btn-outline-primary" >
                   Chercher
                </button>
            </div>
            </div>
            </form>

        </div>



        <!--primary theme Modal -->
        <hr class="line">

        <div class="table-responsive">
        <table class="table table-striped table-hover zero-configuration">
            <thead>
                <tr>
                    <th>Code</th>
                    <th>Libelle</th>
                    <th>Enseignant</th>
                    <th>Coefficient</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>

                @foreach ($enseignements as $enseignement)
                <tr>
                    <td>
                        {{ $enseignement->CodeEnseignement }}
                    </td>
                    <td>
                        <div class="list-left d-flex">
                            <div class="list-icon mr-1">
                                <div class="avatar bg-rgba-primary m-0">
                                    <div class="avatar-content">
                                        <i class="bx bxs-zap text-primary font-size-base"></i>
                                    </div>
                                </div>
                            </div>
                            <div class="list-content">
                                <span class="list-title">{{ $enseignement->matiere->LibelleMatiere }}</span>
                                <small class="text-muted d-block">Classe : {{ $enseignement->classe->LibelleClasse }}</small>
                            </div>
                        </div> 
                    </td>
                        <td>
                            <div class="list-left d-flex">
                                <div class="list-content">
                                    <span class="list-title">
                                        @if($enseignement->enseignant)

                                        @if($enseignement->enseignant->sex == '0')
                                        Mr. 
                                        @else
                                        Mme. 
                                        @endif
                                        {{ $enseignement->enseignant->nom }} {{ $enseignement->enseignant->prenom }}
                                        
                                        @endif
                                    </span>
                                    <small class="text-muted d-block">Contacts : 
                                        @if($enseignement->enseignant)
                                            6{{ $enseignement->enseignant->contacts }}
                                        @else
                                        - -
                                        @endif
                                    </small>
                                </div>
                            </div> 
                        </td>
                        <td>
                            {{ $enseignement->Coefficient }}
                        </td>
                    <td class="text-center py-1">
                        <div class="dropdown">
                            <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                            <div class="dropdown-menu dropdown-menu-right">
                                <a class="dropdown-item" href="#" data-toggle="modal" data-target="#details{{ $enseignement->CodeEnseignement }}"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                {{-- <a class="dropdown-item" href="#" data-toggle="modal" data-target="#modify{{ $enseignement->CodeMatiere }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
                                <a class="dropdown-item" href="#" data-toggle="modal" data-target="#delete{{ $enseignement->CodeMatiere }}"><i class="bx bx-trash mr-1"></i>Supprimmer</a> --}}
                            </div>
                        </div>

                        <div class="modal fade text-left" id="details{{ $enseignement->CodeEnseignement }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                <div class="modal-content">
                                   
                                        <div class="modal-header bg-info">
                                        <h5 class="modal-title white" id="myModalLabel160">{{ $enseignement->matiere->LibelleMatiere }}</h5>
                                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                            <i class="bx bx-x"></i>
                                        </button>
                                    </div>
                                    <div class="modal-body">
                                      
                                        <div class="row">
                                            <div class="col-lg-6 col-12">
                                                <ul class="list-group list-group-flush">

                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->CodeEnseignement }}</span>
                                                                <small class="text-muted d-block">Code Enseignement</small>
                                                            </div>
                                                        </div>
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->matiere->LibelleMatiere }}</span>
                                                                <small class="text-muted d-block">Libelle Enseignement</small>
                                                            </div>
                                                        </div>
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->NBRHEURE }}</span>
                                                                <small class="text-muted d-block">Nombre D'heures</small>
                                                            </div>
                                                        </div>
                                                       
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->CodeMatiere }}</span>
                                                                <small class="text-muted d-block">Code Matiere</small>
                                                            </div>
                                                        </div>
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->classe->LibelleClasse }}</span>
                                                                <small class="text-muted d-block">Classe</small>
                                                            </div>
                                                        </div>
                                                       
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->CodeClasse }}</span>
                                                                <small class="text-muted d-block">Code Classe</small>
                                                            </div>
                                                        </div>
                                                       
                                                    </li>

                                                </ul>
                                            </div>
                                            <div class="col-lg-6 col-12">
                                                <ul class="list-group list-group-flush">
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title"> 
                                                                @if($enseignement->enseignant)
                                                                    6{{ $enseignement->enseignant->contacts }}
                                                                @else
                                                                - -
                                                                @endif
                                                                </span>
                                                                <small class="text-muted d-block">Contacts Enseignant</small>
                                                            </div>
                                                        </div>
                                                       
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->CodeEtablissement }}</span>
                                                                <small class="text-muted d-block">Code Etablissement</small>
                                                            </div>
                                                        </div>
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->Coefficient }}</span>
                                                                <small class="text-muted d-block">Coefficient</small>
                                                            </div>
                                                        </div>
                                                       
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->Dateens }}</span>
                                                                <small class="text-muted d-block">Coefficient</small>
                                                            </div>
                                                        </div>
                                                       
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->DateModif }}</span>
                                                                <small class="text-muted d-block">Date de modification</small>
                                                            </div>
                                                        </div>
                                                       
                                                    </li>
                                                    <li class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                        <div class="list-left d-flex">
                                                            <div class="list-icon mr-1">
                                                                <div class="avatar bg-rgba-info m-0">
                                                                    <div class="avatar-content">
                                                                        <i class="bx bxs-zap text-info font-size-base"></i>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="list-content">
                                                                <span class="list-title">{{ $enseignement->RESERVE1 }}</span>
                                                                <small class="text-muted d-block">RESERVE 1</small>
                                                            </div>
                                                        </div>
                                                       
                                                    </li>
                                                </ul>
                                            </div>
                                        </div>
                
                                    </div>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                            <i class="bx bx-x d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Fermer</span>
                                        </button>
                                       
                                    </div>
                                   

                                </div>
                            </div>
                        </div>
                    </td>
                </tr>                
                @endforeach


            </tbody>
        </table>
        </table>
        </div>
    </div>
</div>
@endsection