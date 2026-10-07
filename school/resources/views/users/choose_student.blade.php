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
            <div class="row justify-content-center mb-lg-0 mb-2">
                <div class="col-lg-10 col-12">
                    <h4>
                        <a href="#" onclick="history.back()"><i class="bx bx-left-arrow-circle" style="font-size: 1.5rem"></i></a>
                       Choisissez un eleve pour l'assigner a 
                       
                       @if ($parent->sex == 'masculin')
                        Mr. 
                        @else
                        Mme. 
                       @endif
                       <span class="text-uppercase">{{ $parent->nom }} {{ $parent->prenom }}</span>

                    </h4>
                    <p class="card-description">Remplissez le formulaire ci-dessous et validez</p>
                </div>
                
                <div class="col-lg-2 col-12 text-lg-right">
                    <button type="button" class="btn btn-outline-primary" data-toggle="modal" data-target="#primary">
                        Chercher
                    </button>
                </div>
            </div>
            
        </div>
        
        
        <hr class="line">
        
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>Noms et Prenoms</th>
                        <th>Classe</th>
                        <th>Parent</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    
                    @forelse ($students as $student)
                    <tr>
                        <td>
                            <div class="list-left d-flex">
                                <div class="list-icon mr-1">
                                    <div class="avatar bg-rgba-primary m-0">
                                        <div class="avatar-content">
                                            <i class="bx bxs-zap text-info font-size-base"></i>
                                        </div>
                                    </div>
                                </div>
                                <div class="list-content">
                                    <span class="list-title">{{ $student->Nom }} {{ $student->Prenom }}</span>
                                    <small class="text-muted d-block">Code Eleve : {{ $student->CodeEleve }}</small>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="media-body">
                                <h6 class="media-heading mb-0">{{ optional($student->classe)->LibelleClasse }}</h6>
                                <span class="font-small-2">Sex :
                                    @if ($student->sex == '0')
                                    Masculin
                                    @else
                                    Feminin
                                    @endif    
                                </span>
                            </div>
                            
                        </td>
                        <td>
                            <div class="media-body">
                                <h6 class="media-heading mb-0">{{ $student->Nomp }}</h6>
                                <span class="font-small-2">Contacts : +237 6 {{ $student->TelP }}</span>
                            </div>
                            
                        </td>
                        <td class="text-center py-1">
                            <a href="{{ route('assign_student_complete',['parent_id'=>$parent->code,'student_id'=>$student->CodeEleve,'code_annee'=>$student->CodeAnnee]) }}" class="btn btn-primary btn-sm">Assigner</a>
                            {{-- <div class="dropdown">
                                <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                                <div class="dropdown-menu dropdown-menu-right">
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#details{{ $student->CodeEleve }}"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#modify{{ $student->CodeEleve }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
                                    
                                </div>
                            </div> --}}
                            
                            {{-- <div class="modal fade text-left" id="details{{ $student->CodeEleve }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                    <div class="modal-content">
                                        
                                        <div class="modal-header bg-info">
                                            <h5 class="modal-title white" id="myModalLabel160">Modifier l'eleve : {{ $student->LibelleClasse }}</h5>
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
                                                                    <span class="list-title">{{ $student->CodeEleve }}</span><br>
                                                                    <small class="text-muted d-blocek">Code Eleve</small>
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
                                                                    <span class="list-title">{{ $student->Nom }} {{ $student->Prenom }}</span>
                                                                    <small class="text-muted d-block">Noms et Prenoms</small>
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
                                                                        @if($student->CodeAnnee == 5)
                                                                        2011/2012
                                                                        @elseif ($student->CodeAnnee == 6)
                                                                        2012/2013
                                                                        @elseif ($student->CodeAnnee == 7)
                                                                        2013/2014
                                                                        @elseif ($student->CodeAnnee == 8)
                                                                        2014/2015
                                                                        @elseif ($student->CodeAnnee == 9)
                                                                        2015/2016
                                                                        @elseif ($student->CodeAnnee == 10)
                                                                        2016/2017
                                                                        @elseif ($student->CodeAnnee == 11)
                                                                        2017/2018
                                                                        @elseif ($student->CodeAnnee == 12)
                                                                        2018/2019
                                                                        @elseif ($student->CodeAnnee == 13)
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
                                                                    <span class="list-title">{{ optional($student->classe)->LibelleClasse }}</span>
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
                                                                    <span class="list-title">{{ $student->RELIGION }}</span>
                                                                    <small class="text-muted d-block">Religion</small>
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
                                                                       {{ $student->Nomm}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Nom de la mere</small>
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
                                                                       {{ $student->REGION}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Region</small>
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
                                                                       {{ $student->DEPART}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Departement</small>
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
                                                                       @if($student->ACTIVEEPS == '1')
                                                                        OUI
                                                                       @else
                                                                        NON 
                                                                       @endif
                                                                    </span>
                                                                    <small class="text-muted d-block">Active EPS</small>
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
                                                                    <span class="list-title">{{ $student->DateNaissance }}</span>
                                                                    <small class="text-muted d-block">Date de naissance</small>
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
                                                                    <span class="list-title">{{ $student->LieuNaissance }}</span>
                                                                    <small class="text-muted d-block">Lieu de naissance</small>
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
                                                                        @if ($student->sex == 0)
                                                                        masculin
                                                                        @else
                                                                        feminin
                                                                        @endif
                                                                    </span>
                                                                    <small class="text-muted d-block">Sex</small>
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
                                                                       {{ $student->dateinscription}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Date Inscription</small>
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
                                                                       {{ $student->Nomp}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Nom du Parent</small>
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
                                                                      +237 6 {{ $student->TelP}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Telephone du Parent</small>
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
                                                                      {{ $student->ADRESSE }}
                                                                    </span>
                                                                    <small class="text-muted d-block">Adresse</small>
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
                                                                      +237 6 {{ $student->TELT}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Telephone du tuteur</small>
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
                                                                      {{ $student->RESERVE1}}
                                                                    </span>
                                                                    <small class="text-muted d-block">Reserve 1</small>
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
                            </div> --}}
                            
                        
                            
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