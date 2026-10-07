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
        <div class="card-heading">

            <div class="row justify-content-center mb-lg-0 mb-2">
            <div class="col-12">
                <h4>
                    <a href="#" onclick="history.back()"><i class="bx bx-left-arrow-circle" style="font-size: 1.5rem"></i></a>
                Liste des notes de {{ optional(optional($enseignement)->matiere)->LibelleMatiere ?? '-' }} - {{ optional(optional($note)->sequence_evaluation)->LibelleEvaluation ?? '-' }} / {{ optional(optional($note)->annee)->Libelle ?? '-' }}
                </h4> 
                <p class="card-description">
                    Classe : {{ optional(optional(optional($note)->enseignement)->classe)->LibelleClasse ?? $classe->LibelleClasse }}
                </p>
                <p class="card-description">Etablissement : {{ $school->Nom }}</p>
            </div>
    
            </div>

            <form action="{{ route('sorted_notes') }}">
                <div class="row">
                    <div class="col-lg-4 col-12">
                        <label>Enseignement</label>
                            <select class="form-control" name="CodeEnseignement">
                                @foreach ($classe->enseignements as $school_enseignement)
                                
                                @if($enseignement)
                                    @if($enseignement->CodeEnseignement == $school_enseignement->CodeEnseignement)
                                    <option selected="selected" value="{{ $school_enseignement->CodeEnseignement }}">{{ optional($school_enseignement->matiere)->LibelleMatiere }}</option>
                                    @endif
                                @endif
                                    <option value="{{ $school_enseignement->CodeEnseignement }}">{{ optional($school_enseignement->matiere)->LibelleMatiere }}</option>
                            @endforeach
                            </select>
                    </div>

                    <div class="col-lg-3 col-12">
                        <label>Sequence Evaluation</label>
                            <select class="form-control" name="CodeEvaluation">
                                @foreach ($sequence_evaluations as $school_sequence)
                                
                                @if($sequence)
                                    @if($sequence->CodeEvaluation == $school_sequence->CodeEvaluation)
                                    <option selected="selected" value="{{ $school_sequence->CodeEvaluation }}">{{ $school_sequence->LibelleEvaluation }}</option>
                                    @else
                                    <option value="{{ $school_sequence->CodeEvaluation }}">{{ $school_sequence->LibelleEvaluation }}</option>
                                    @endif

                                @else
                                <option value="{{ $school_sequence->CodeEvaluation }}">{{ $school_sequence->LibelleEvaluation }}</option>

                                @endif
                            @endforeach
                            </select>
                    </div>

                    <div class="col-lg-3 col-12">
                        <label>Annee Scholaire</label>
                            <select class="form-control" name="CodeAnnee">
                                @foreach ($years as $school_year)
                                    
                                    @if($year)
                                        @if($year->CodeAnnee == $school_year->CodeAnnee)
                                        <option selected="selected" value="{{ $year->CodeAnnee }}">{{ $year->Libelle }}</option>
                                        @endif
                                    @endif
                                    <option value="{{ $school_year->CodeAnnee }}">{{ $school_year->Libelle }}</option>
                                    

                                @endforeach
                            </select>
                    </div>
                    <input type="hidden" name="CodeEtablissement" value="{{ $school->CodeEtablissement }}">
                    <input type="hidden" name="CodeClasse" value="{{ $classe->CodeClasse }}">

                    <div class="col-lg-2 col-12 text-lg-right pt-2">
                        <button type="submit" class="btn btn-primary">Chercher</button>
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
                    {{-- <th>Code</th> --}}
                    <th>Eleve</th>
                    <th>Enseignant</th>
                    <th>Coefficient</th>
                    <th>Notes</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>

                @forelse ($notes as $school_note)
                <tr>
                    
                    <td>
                        <div class="list-left d-flex">
                            <div class="list-icon mr-1">
                                @if($school_note->valeur > 9)
                                    <div class="avatar bg-rgba-success m-0">
                                        <div class="avatar-content">
                                            <i class="bx bxs-zap text-success font-size-base"></i>
                                        </div>
                                    </div>
                                    @else
                                    <div class="avatar bg-rgba-danger m-0">
                                        <div class="avatar-content">
                                            <i class="bx bxs-zap text-danger font-size-base"></i>
                                        </div>
                                    </div>
                                    @endif
                            </div>
                            <div class="list-content">
                                <span class="list-title">
                                    @if($school_note->eleve)
                                    {{ $school_note->eleve->Nom }} {{ $school_note->eleve->Prenom }}</span>
                                    @else
                                    - -
                                    @endif
                                <small class="text-muted d-block">Sex : 
                                    @if($school_note->eleve)
                                        @if ($school_note->eleve->Sex == '0')
                                        Masculin
                                        @else
                                        Feminin
                                        @endif
                                   
                                    @else
                                    - -
                                    @endif
                                </small>
                            </div>
                        </div> 
                    </td>

                        <td>
                            <div class="list-left d-flex">
                                <div class="list-content">
                                    <span class="list-title">
                                        @if($school_note->enseignement->enseignant)

                                        @if($school_note->enseignement->enseignant->sex == '0')
                                        Mr. 
                                        @else
                                        Mme. 
                                        @endif
                                        {{ $school_note->enseignement->enseignant->nom }} {{ $school_note->enseignement->enseignant->prenom }}
                                        
                                        @endif
                                    </span>
                                    <small class="text-muted d-block">Contacts : 
                                        @if($school_note->enseignement->enseignant)
                                            6{{ $school_note->enseignement->enseignant->contacts }}
                                        @else
                                        - -
                                        @endif
                                    </small>
                                </div>
                            </div> 
                        </td>

                        <td>
                            {{ $school_note->enseignement->Coefficient }}
                        </td>

                        <td>
                            <div class="list-left d-flex">
                                <div class="list-icon mr-1">

                                    @if($school_note->valeur > 9)
                                    <div class="avatar bg-rgba-success m-0">
                                        <div class="avatar-content">
                                            <i class="bx bxs-zap text-success font-size-base"></i>
                                        </div>
                                    </div>
                                    @else
                                    <div class="avatar bg-rgba-danger m-0">
                                        <div class="avatar-content">
                                            <i class="bx bxs-zap text-danger font-size-base"></i>
                                        </div>
                                    </div>
                                    @endif

                                </div>
                                <div class="list-content">
                                    <span class="list-title">
                                       {{ $school_note->valeur }}/20
                                    <small class="text-muted d-block">
                                        {{ $school_note->total }}/{{ $school_note->enseignement->Coefficient * 20 }}
                                    </small>
                                </div>
                            </div> 
                        </td>

                    <td class="text-center py-1">
                        <div class="dropdown">
                            <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                            <div class="dropdown-menu dropdown-menu-right">
                                <a class="dropdown-item" href="#" data-toggle="modal" data-target="#details{{ $school_note->CodeEnseignement }}"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                {{-- <a class="dropdown-item" href="#" data-toggle="modal" data-target="#modify{{ $note->CodeMatiere }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
                                <a class="dropdown-item" href="#" data-toggle="modal" data-target="#delete{{ $note->CodeMatiere }}"><i class="bx bx-trash mr-1"></i>Supprimmer</a> --}}
                            </div>
                        </div>

                        <div class="modal fade text-left" id="details{{ $school_note->CodeEnseignement }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                <div class="modal-content">
                                   
                                        <div class="modal-header bg-info">
                                        <h5 class="modal-title white" id="myModalLabel160">{{ $school_note->enseignement->matiere->LibelleMatiere }}</h5>
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
                                                                <span class="list-title">{{ $school_note->CodeEnseignement }}</span>
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
                                                                <span class="list-title">{{ $school_note->enseignement->matiere->LibelleMatiere }}</span>
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
                                                                <span class="list-title">{{ $school_note->NBRHEURE }}</span>
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
                                                                <span class="list-title">{{ $school_note->CodeMatiere }}</span>
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
                                                                <span class="list-title">{{ $school_note->enseignement->classe->LibelleClasse }}</span>
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
                                                                <span class="list-title">{{ $school_note->CodeClasse }}</span>
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
                                                                @if($school_note->enseignement && $school_note->enseignement->enseignant)
                                                                    6{{ $school_note->enseignement->enseignant->contacts }}
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
                                                                <span class="list-title">{{ $school_note->CodeEtablissement }}</span>
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
                                                                <span class="list-title">{{ $school_note->Coefficient }}</span>
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
                                                                <span class="list-title">{{ $school_note->Dateens }}</span>
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
                                                                <span class="list-title">{{ $school_note->DateModif }}</span>
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
                                                                <span class="list-title">{{ $school_note->RESERVE1 }}</span>
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
                @empty
                <tr>
                    <td colspan="5">Aucune note disponible pour cette classe et ces critères.</td>
                </tr>
                @endforelse


            </tbody>
        </table>
        </table>
        </div>
    </div>
</div>
@endsection