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

            <form action="{{ route('sorted_inscriptions') }}" method="POST">
                @csrf

            <div class="row justify-content-center mb-lg-0 mb-2">
                <div class="col-4">
                    <h4>
                        <a href="#" onclick="history.back()"><i class="bx bx-left-arrow-circle" style="font-size: 1.5rem"></i></a>
                       Inscriptions 
                       @if ($classe)
                           de la {{ $classe->LibelleClasse }}
                       @endif
                    </h4>
                    
                </div>
                <div class="col-lg-2 col-12">
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

                 <div class="col-lg-2 col-12">
                    <label>Tranches</label>
                        <select class="form-control" name="code">
                            @foreach ($tranches as $school_tranche)
                               
                               @if($tranche)
                                   @if($tranche->code == $school_tranche->code)
                                   <option selected="selected" value="{{ $school_tranche->code }}">{{ $school_tranche->libellet }}</option>
                                   @endif
                                @endif
                                <option value="{{ $school_tranche->code }}">{{ $school_tranche->libellet }}</option>
                           @endforeach
                        </select>
                </div>

                 <div class="col-lg-2 col-12">
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

                 <div class="col-lg-1 col-12 text-lg-right pt-2">
                    <button type="submit" class="btn btn-primary">Chercher</button>
                 </div>
            </div>
            <p class="text-center pt-1 card-description">Entrez les parametres de recherche des inscriptions et validez</p>
            </form>
            
        </div>
        
        <hr class="line">
        
        <div class="table-responsive">
            <table class="table table-striped table-hover  zero-configuration">
                <thead>
                    <tr>
                        <th>#N. Facture</th>
                        <th>Montant</th>
                        <th>Montant Total</th>
                        <th>Eleve</th>
                        <th>Libelle</th>
                        <th></th>
                    </tr>
                </thead>

                <tbody>
                    @forelse ($inscriptions as $inscription)
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
                                    <div class="list-title">{{ $inscription->NUMFAC }}</div>
                                   <div class="font-small-2 text-muted"></div>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="list-left d-flex">
                                <div class="list-content">
                                    <div class="list-title">Inscription : {{ $inscription->Montantins }} FCFA</div>
                                   <div class="font-small-2 text-muted">Avance: {{ $inscription->Avance }} FCFA</div>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="list-left d-flex">
                                <div class="list-content">
                                    <div class="list-title">{{ $inscription->Montantt }} FCFA</div>
                                   <div class="font-small-2 text-muted">Reste: {{ $inscription->Reste }} FCFA</div>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="media-body">
                                <h6 class="media-heading mb-0">
                                    @if($inscription->eleve)
                                    {{ $inscription->eleve->Nom }} {{ $inscription->eleve->Prenom }}
                                    @endif
                                </h6>
                                <div class="text-muted font-small-2">
                                    @if($inscription->eleve)     
                                        @if($inscription->eleve->Sex == 0)
                                            masculin
                                        @else
                                            feminin
                                        @endif
                                    @endif
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="list-left d-flex">
                                <div class="list-content">
                                    <div class="list-title">{{ $inscription->libinscrip }}</div>
                                   <div class="font-small-2 text-muted">Annee: 
                                    @if($inscription->codeannee == 5)
                                    2011/2012
                                    @elseif ($inscription->codeannee == 6)
                                    2012/2013
                                    @elseif ($inscription->codeannee == 7)
                                    2013/2014
                                    @elseif ($inscription->codeannee == 8)
                                    2014/2015
                                    @elseif ($inscription->codeannee == 9)
                                    2015/2016
                                    @elseif ($inscription->codeannee == 10)
                                    2016/2017
                                    @elseif ($inscription->codeannee == 11)
                                    2017/2018
                                    @elseif ($inscription->codeannee == 12)
                                    2018/2019
                                    @elseif ($inscription->codeannee == 13)
                                    2022/2023
                                    @endif
                                    </div>
                                </div>
                            </div>
                        </td>
                        <td class="text-center py-1">
                            <div class="dropdown">
                                <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                                <div class="dropdown-menu dropdown-menu-right">
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#details{{ $inscription->NUMFAC }}"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                </div>
                            </div>


                            <div class="modal fade text-left" id="details{{ $inscription->NUMFAC }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                    <div class="modal-content">
                                        
                                        <div class="modal-header bg-info">
                                            <h5 class="modal-title white" id="myModalLabel160">Details sur l'inscription : {{ $inscription->NUMFAC }}</h5>
                                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                <i class="bx bx-x"></i>
                                            </button>
                                        </div>
                                        <div class="modal-body">
                                            
                                            <div class="row">
                                                <div class="col-lg-6 col-12">
                                                    <ul class="list-group list-group-flush">
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                            <div class="list-left d-flex">
                                                                <div class="list-icon mr-1">
                                                                    <div class="avatar bg-rgba-info m-0">
                                                                        <div class="avatar-content">
                                                                            <i class="bx bxs-zap text-info font-size-base"></i>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                                <div class="list-content">
                                                                    <span class="list-title">{{ $inscription->NUMFAC }}</span><br>
                                                                    <small class="text-muted d-blocek">Numero de Facture</small>
                                                                </div>
                                                            </div>
                                                            
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                            <div class="list-left d-flex">
                                                                <div class="list-icon mr-1">
                                                                    <div class="avatar bg-rgba-info m-0">
                                                                        <div class="avatar-content">
                                                                            <i class="bx bxs-zap text-info font-size-base"></i>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                                <div class="list-content">
                                                                    <span class="list-title">{{ $inscription->CodeInscription }}</span>
                                                                    <small class="text-muted d-block">Code Inscription</small>
                                                                </div>
                                                            </div>
                                                            
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
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
                                                                        @if($inscription->codeannee == 5)
                                                                        2011/2012
                                                                        @elseif ($inscription->codeannee == 6)
                                                                        2012/2013
                                                                        @elseif ($inscription->codeannee == 7)
                                                                        2013/2014
                                                                        @elseif ($inscription->codeannee == 8)
                                                                        2014/2015
                                                                        @elseif ($inscription->codeannee == 9)
                                                                        2015/2016
                                                                        @elseif ($inscription->codeannee == 10)
                                                                        2016/2017
                                                                        @elseif ($inscription->codeannee == 11)
                                                                        2017/2018
                                                                        @elseif ($inscription->codeannee == 12)
                                                                        2018/2019
                                                                        @elseif ($inscription->codeannee == 13)
                                                                        2022/2023
                                                                        @endif
                                                                        
                                                                    </span><br>
                                                                    <small class="text-muted d-blocek">Code Annee</small>
                                                                </div>
                                                            </div>
                                                            
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
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
                                                                        @if($inscription->eleve)
                                                                            {{ $inscription->eleve->Nom }} {{ $inscription->eleve->Prenom }}
                                                                        @endif
                                                                    </span>
                                                                    <small class="text-muted d-block">Eleve</small>
                                                                </div>
                                                            </div>
                                                            
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
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
                                                                        @if($inscription->eleve)
                                                                            {{ $inscription->eleve->classe->LibelleClasse }}
                                                                        @endif
                                                                    </span>
                                                                    <small class="text-muted d-block">Classe</small>
                                                                </div>
                                                            </div>
                                                            
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                            <div class="list-left d-flex">
                                                                <div class="list-icon mr-1">
                                                                    <div class="avatar bg-rgba-info m-0">
                                                                        <div class="avatar-content">
                                                                            <i class="bx bxs-zap text-info font-size-base"></i>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                                <div class="list-content">
                                                                    <span class="list-title">{{ $inscription->Tranche }}</span>
                                                                    <small class="text-muted d-block">Tranche</small>
                                                                </div>
                                                            </div>
                                                            
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
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
                                                                       {{ $inscription->remise}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Remise</small>
                                                                </div>
                                                            </div>
                                                        </li>
                                                        
                                                        

             
                                                    </ul>
                                                </div>
                                                <div class="col-lg-6 col-12">
                                                    <ul class="list-group list-group-flush">
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                            <div class="list-left d-flex">
                                                                <div class="list-icon mr-1">
                                                                    <div class="avatar bg-rgba-info m-0">
                                                                        <div class="avatar-content">
                                                                            <i class="bx bxs-zap text-info font-size-base"></i>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                                <div class="list-content">
                                                                    <span class="list-title">{{ $inscription->Montantins }} FCFA</span>
                                                                    <small class="text-muted d-block">Montant Inscription</small>
                                                                </div>
                                                            </div>
                                                            
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
                                                            <div class="list-left d-flex">
                                                                <div class="list-icon mr-1">
                                                                    <div class="avatar bg-rgba-info m-0">
                                                                        <div class="avatar-content">
                                                                            <i class="bx bxs-zap text-info font-size-base"></i>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                                <div class="list-content">
                                                                    <span class="list-title">{{ $inscription->Montantt }} FCFA</span>
                                                                    <small class="text-muted d-block">Montant Total</small>
                                                                </div>
                                                            </div>
                                                        </li>

                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
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
                                                                        {{ $inscription->Avance }} FCFA
                                                                    </span>
                                                                    <small class="text-muted d-block">Avance</small>
                                                                </div>
                                                            </div>
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
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
                                                                       {{ $inscription->Reste}} FCFA
                                                                    </span>
                                                                    <small class="text-muted d-block">Reste</small>
                                                                </div>
                                                            </div>
                                                        </li>
                                                       
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
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
                                                                       {{ $inscription->libinscrip}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Libelle Inscription</small>
                                                                </div>
                                                            </div>
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
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
                                                                      {{ $inscription->heure}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Heure</small>
                                                                </div>
                                                            </div>
                                                        </li>
                                                        <li style="padding: 0.5rem 1rem;" class="list-group-item list-group-item-action border-0 d-flex align-items-center justify-content-between">
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
                                                                      {{ $inscription->caissier }}
                                                                    </span>
                                                                    <small class="text-muted d-block">Cassier</small>
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
                    Liste vide !
                    @endforelse
                    
                    
                </tbody>
            </table>
        </table>
    </div>
    
</div>
</div>


@endsection