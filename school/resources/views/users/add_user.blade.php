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
        @if ($errors->any())
            <div class="alert alert-warning" role="alert">
                @foreach ($errors->all() as $error)
                    <div>{{ $error }}</div>
                @endforeach
            </div>
        @endif
        <div class="card-heading ">
            <div class="row justify-content-center mb-lg-0 mb-2">
                <div class="col-lg-8 col-12">
                    <h4>
                        <a href="#" onclick="history.back()"><i class="bx bx-left-arrow-circle" style="font-size: 1.5rem"></i></a>
                        Ajouter un nouvel utilisateur
                    </h4>
                    <p class="card-description">Remplissez le formulaire ci-dessous et validez</p>
                </div>
                <div class="col-lg-4 col-12 text-lg-right">
                    <button type="button" class="btn btn-outline-primary" data-toggle="modal" data-target="#import">
                        Importer
                    </button>
                    <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#primary">
                        + Ajouter
                    </button>
                </div>
            </div>
        </div>
        

        <!--primary theme Modal -->
<div class="modal fade text-left" id="import" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
        <div class="modal-content">

            <form action="{{ route('import_users') }}" enctype="multipart/form-data" method="POST">
                @csrf
            <div class="modal-header bg-dark">
                <h5 class="modal-title white" id="myModalLabel160">Importer un fichier CSV d'utilisateurs</h5>
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

        
        
        <!--primary theme Modal -->
        <div class="modal fade text-left" id="primary" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                <div class="modal-content">
                    
                    
                    <div class="modal-header bg-primary">
                        <h5 class="modal-title white" id="myModalLabel160">Ajoutez un utilisateur</h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <i class="bx bx-x"></i>
                        </button>
                    </div>
                    <div class="modal-body">
                        Remplissez le formulaire ci-dessous et validez
                        <hr class="line">
                        
                        <!-- Nav tabs -->
                        <ul class="nav nav-tabs nav-fill" id="myTab" role="tablist">
                            <li class="nav-item">
                                <a class="nav-link active" id="home-tab-fill" data-toggle="tab" href="#home-fill" role="tab" aria-controls="home-fill" aria-selected="true">
                                    Administrateur
                                </a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link" id="profile-tab-fill" data-toggle="tab" href="#profile-fill" role="tab" aria-controls="profile-fill" aria-selected="false">
                                    Membre du personel
                                </a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link" id="messages-tab-fill" data-toggle="tab" href="#messages-fill" role="tab" aria-controls="messages-fill" aria-selected="false">
                                    Parent
                                </a>
                            </li>
                            <li class="nav-item">
                                <a class="nav-link" id="settings-tab-fill" data-toggle="tab" href="#settings-fill" role="tab" aria-controls="settings-fill" aria-selected="false">
                                    Encardreur
                                </a>
                            </li>
                        </ul>
                        
                        
                        <!-- Tab panes -->
                        <div class="tab-content pt-1">
                            
                            
                            <div class="tab-pane active" id="home-fill" role="tabpanel" aria-labelledby="home-tab-fill">    
                                <form action="{{ route('add_user_complete') }}" method="POST" enctype="multipart/form-data">
                                    @csrf
                                    <div class="row">
                                        <div class="col-lg-4 col-12">
                                            <label>Noms de l'administrateur</label>
                                            <input type="text" name="nom" value="{{ old('nom') }}" class="form-control" placeholder="Hermann">
                                        </div> 
                                        <div class="col-lg-4 col-12">
                                            <label>Prenoms de l'administrateur</label>
                                            <input type="text" name="prenom" value="{{ old('prenom') }}" class="form-control" placeholder="Ryan">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Genre</label>
                                            <select name="sex" class="form-control">
                                                <option value="0">Masculin</option>
                                                <option value="1">Feminin</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="row pt-1">
                                        <div class="col-lg-4 col-12">
                                            <label>Contacts</label>
                                            <input type="text" name="contacts" value="{{ old('contacts') }}" class="form-control" placeholder="652686163">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Login</label>
                                            <input type="text" name="login" value="{{ old('login') }}" class="form-control" placeholder="ateba2001">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Code</label>
                                            <input type="text" name="code" value="{{ old('code') }}" class="form-control" placeholder="11356">
                                        </div>
                                    </div>
                                    <input id="password" type="password" class="form-control d-none " name="password" value="00000000">
                                    <input id="password-confirm" type="password" class="form-control d-none" name="password_confirmation" value="00000000">
                                    <input type="hidden" name="account_type" value="administrateur" id="account_type">
                                    
                                    <br>
                                    @if ($errors->any())
                                    <div class="alert alert-danger">
                                        <ul>
                                            @foreach ($errors->all() as $error)
                                            <li>{{ $error }}</li>
                                            @endforeach
                                        </ul>
                                    </div>
                                    @endif
                                    <br>
                                    
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                            <i class="bx bx-x d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Annuler</span>
                                        </button>
                                        <button type="submit" class="btn btn-primary ml-1">
                                            <i class="bx bx-check d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Creer</span>
                                        </button>
                                    </div>
                                </form>
                            </div>
                            
                            
                            <div class="tab-pane" id="profile-fill" role="tabpanel" aria-labelledby="profile-tab-fill">
                                <form action="{{ route('add_user_complete') }}" method="POST" enctype="multipart/form-data">
                                    @csrf
                                    
                                    <div class="row">
                                        <div class="col-lg-4 col-12">
                                            <label>Noms</label>
                                            <input type="text" name="nom" value="{{ old('nom') }}" class="form-control" placeholder="Hermann">
                                        </div> 
                                        <div class="col-lg-4 col-12">
                                            <label>Prenoms</label>
                                            <input type="text" name="prenom" value="{{ old('prenom') }}" class="form-control" placeholder="Ryan">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Genre</label>
                                            <select name="sex" class="form-control">
                                                <option value="0">Masculin</option>
                                                <option value="1">Feminin</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="row pt-1">
                                        <div class="col-lg-4 col-12">
                                            <label>Contacts</label>
                                            <input type="text" name="contacts" value="{{ old('contacts') }}" class="form-control" placeholder="652686163">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Matricule</label>
                                            <input type="text" name="matricule" value="{{ old('matricule') }}" class="form-control" placeholder="ENS12212022">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Reserve 1</label>
                                           <select class="form-control" name="reserve1">
                                               <option>PRINCIPAL</option>
                                               <option>ENSEIGNANT</option>
                                               <option>SURVEILLANT</option>
                                               <option>CONTROLLEUR</option>
                                               <option>LINGER</option>
                                               <option>AGENT D'ENTRETIEN</option>
                                               <option>GARDIEN DE NUIT</option>
                                               <option>GARDIEN DU JOUR</option>
                                               <option>CUISINIERE</option>
                                               <option>FACTOTUM</option>
                                               <option>VICE PRINCIPAL</option>
                                               <option>AUMONIER</option>
                                               <option>PREFET 1</option>
                                               <option>SECRETAIRE</option>
                                           </select>
                                        </div>
                                    </div>

                                    <div class="row pt-1">
                                        <div class="col-lg-4 col-12">
                                            <label>Code</label>
                                            <input type="text" name="code" value="{{ old('code') }}" class="form-control" placeholder="11356">
                                        </div>
                                        <div class="col-lg-8 col-12">
                                            <label>Etablissement</label>
                                            <select name="school_id" class="text-center form-control">
                                                @foreach ($schools as $school)
                                                    <option value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                                @endforeach
                                            </select>
                                        </div>
                                    </div>

                                    <input id="password" type="password" class="form-control d-none " name="password" value="00000000">
                                    <input id="password-confirm" type="password" class="form-control d-none" name="password_confirmation" value="00000000">
                                    <input type="hidden" name="account_type" value="enseignant" id="account_type">
                                    <br>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                            <i class="bx bx-x d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Annuler</span>
                                        </button>
                                        <button type="submit" class="btn btn-primary ml-1">
                                            <i class="bx bx-check d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Creer</span>
                                        </button>
                                    </div>
                                    
                                </form>
                            </div>
                            
                            <div class="tab-pane" id="messages-fill" role="tabpanel" aria-labelledby="messages-tab-fill">
                                <form action="{{ route('add_user_complete') }}" method="POST" enctype="multipart/form-data">
                                    @csrf
                                    
                                    <div class="row">
                                        <div class="col-lg-4 col-12">
                                            <label>Nom du parent</label>
                                            <input type="text" name="nom" value="{{ old('nom') }}" class="form-control" placeholder="Hermann">
                                        </div> 
                                        <div class="col-lg-4 col-12">
                                            <label>Prenom du parent</label>
                                            <input type="text" name="prenom" value="{{ old('prenom') }}" class="form-control" placeholder="Ryan">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Genre</label>
                                            <select name="sex" class="form-control">
                                                <option value="0">Masculin</option>
                                                <option value="1">Feminin</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="row pt-1">
                                        <div class="col-lg-4 col-12">
                                            <label>Contacts</label>
                                            <input type="text" name="contacts" value="{{ old('contacts') }}" class="form-control" placeholder="652686163">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Address</label>
                                            <input type="text" name="adresse" value="{{ old('adresse') }}" class="form-control" placeholder="Yaounde, ESSOS">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Etablissement de l'enfant</label>
                                            <select name="school_id" class="text-center form-control">
                                                @foreach ($schools as $school)
                                                    <option value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                                @endforeach
                                            </select>
                                        </div>
                                    </div>
                                    
                                    <input id="password" type="password" class="form-control d-none " name="password" value="00000000">
                                    <input id="password-confirm" type="password" class="form-control d-none" name="password_confirmation" value="00000000">
                                    <input type="hidden" name="account_type" value="parent" id="account_type">
                                    <br>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                            <i class="bx bx-x d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Annuler</span>
                                        </button>
                                        <button type="submit" class="btn btn-primary ml-1">
                                            <i class="bx bx-check d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Creer</span>
                                        </button>
                                    </div>
                                </form>
                            </div>
                            <div class="tab-pane" id="settings-fill" role="tabpanel" aria-labelledby="settings-tab-fill">
                                <form action="{{ route('add_user_complete') }}" method="POST" enctype="multipart/form-data">
                                    @csrf
                                    <div class="row">
                                        <div class="col-lg-4 col-12">
                                            <label>Noms de l'encardreur</label>
                                            <input type="text" name="nom" class="form-control" placeholder="Hermann">
                                        </div> 
                                        <div class="col-lg-4 col-12">
                                            <label>Prenoms de l'encardreur</label>
                                            <input type="text" name="prenom" class="form-control" placeholder="Ryan">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Genre</label>
                                            <select name="sex" class="form-control">
                                                <option value="male">Male</option>
                                                <option value="female">Female</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="row pt-1">
                                        <div class="col-lg-4 col-12">
                                            <label>Contacts</label>
                                            <input type="text" name="contacts" class="form-control" placeholder="652686163">
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Etablissement</label>
                                            <select name="school_id" class="form-control" required>
                                                @foreach ($schools as $school)
                                                    <option value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                                @endforeach
                                            </select>
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Code</label>
                                            <input type="text" name="code" class="form-control" placeholder="Code encadreur" required>
                                        </div>
                                    </div>
                                    <input id="password" type="password" class="form-control d-none " name="password" value="00000000">
                                    <input id="password-confirm" type="password" class="form-control d-none" name="password_confirmation" value="00000000">
                                    
                                    <input type="hidden" name="account_type" value="encadreur" id="account_type">
                                    <br>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                            <i class="bx bx-x d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Annuler</span>
                                        </button>
                                        <button type="submit" class="btn btn-primary ml-1">
                                            <i class="bx bx-check d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Creer</span>
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                        
                        
                    </div>
                    
                    
                    
                    
                </div>
            </div>
        </div>
        <hr class="line">

        <form action="{{ route('add_user') }}" method="GET" class="mb-2">
            <div class="form-row align-items-end">
                <div class="col-md-9">
                    <label for="user-school-filter">Établissement</label>
                    <select name="CodeEtablissement" id="user-school-filter" class="form-control" required>
                        <option value="">Choisir un établissement</option>
                        @foreach ($schools as $school)
                            <option value="{{ $school->CodeEtablissement }}" {{ $selectedSchool && $selectedSchool->CodeEtablissement == $school->CodeEtablissement ? 'selected' : '' }}>{{ $school->Nom }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-3 mt-1 mt-md-0">
                    <button type="submit" class="btn btn-outline-primary">Afficher les utilisateurs</button>
                </div>
            </div>
        </form>
        
        <div class="table-responsive">
            <table class="table table-striped table-hover zero-configuration">
                <thead>
                    <tr>
                        <th>Code</th>
                        <th>Noms et Prenoms</th>
                        <th>Identifiants</th>
                        <th>Enfants</th>
                        <th>Contacts</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    
                    @forelse ($users as $user)
                    <tr>
                        <td>
                            {{ $user->code }}
                        </td>
                        <td class="pr-75">
                            <div class="media align-items-center">
                                <a class="media-left mr-50" href="#">
                                    
                                    @if ($user->photo_path == '')
                                    <img src="../../../app-assets/images/portrait/small/avatar-s-19.jpg" alt="avatar" class="rounded-circle" height="30" width="30">
                                    @else
                                    <img src="{{ Storage::url($user->photo_path) }}" alt="avatar" class="rounded-circle" height="30" width="30">
                                    @endif
                                    
                                </a>
                                <div class="media-body">
                                    <h6 class="media-heading mb-0 text-uppercase">
                                        @if($user->sex == '0')
                                        Mr.
                                        @else
                                        Mme.
                                        @endif
                                        {{ $user->nom }} {{ $user->prenom }}</h6>
                                        <span class="font-small-3">
                                            {{ $user->account_type }}
                                        </span>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div class="media-body">
                                    <h6 class="media-heading mb-0">{{ $user->login }}</h6>
                                    {{-- <span class="font-small-2">{{ $user->text_password }}</span> --}}
                                </div>
                                
                            </td>
                            <td>
                                <div class="media-body">
                                    <h6 class="media-heading mb-0">{{ count($user->enfants) }}</h6>
                                    <span class="font-small-2"></span>
                                </div>
                                
                            </td>
                            <td>
                                <div class="media-body">
                                    <h6 class="media-heading mb-0">6{{ $user->contacts }}</h6>
                                    <span class="font-small-1">{{ $user->created_at }}</span>
                                </div>
                            </td>
                            <td class="text-center py-1">
                                <div class="dropdown">
                                    <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                                    <div class="dropdown-menu dropdown-menu-right">
                                        <a class="dropdown-item" href="#"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                        <a class="dropdown-item" href="#" data-toggle="modal" data-target="#modify{{ $user->code }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
                                        <a class="dropdown-item" href="#" data-toggle="modal" data-target="#add_student{{ $user->code }}"><i class="bx bx-edit-alt mr-1"></i>Attribuer un eleve</a>
                                        <a class="dropdown-item" href="#" data-toggle="modal" data-target="#delete{{ $user->code }}"><i class="bx bx-trash mr-1"></i>Supprimmer</a>
                                    </div>
                                </div>
                                
                                
                                <div class="modal fade text-left" id="modify{{ $user->code }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                    <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                        <div class="modal-content">
                                            
                                            <form action="{{ route('save_user',['user_id'=>$user->code]) }}" method="POST" enctype="multipart/form-data">
                                                @csrf
                                                <div class="modal-header bg-info">
                                                    <h5 class="modal-title white" id="myModalLabel160">Modifier : 
                                                        @if($user->sex == '0')
                                                        Mr. 
                                                        @else
                                                        Mme. 
                                                        @endif
                                                        <span class="text-uppercase">
                                                            {{ $user->nom }} {{ $user->prenoms }}
                                                        </span>
                                                    </h5>
                                                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                        <i class="bx bx-x"></i>
                                                    </button>
                                                </div>
                                                <div class="modal-body">
                                                    Remplissez le formulaire ci-dessous et validez
                                                    <hr class="line">
                                                    
                                                    <input type="hidden" name="user_id" value="{{ $user->code }}">
                                                    
                                                    <div class="row pb-1">
                                                        <div class="col-lg-4 col-12">
                                                            <label>Noms</label>
                                                            <input type="text" name="nom" class="form-control" value="{{ $user->nom }}">
                                                        </div> 
                                                        <div class="col-lg-4 col-12">
                                                            <label>Prenoms</label>
                                                            <input type="text" name="prenom" class="form-control" value="{{ $user->prenom }}">
                                                        </div>
                                                        <div class="col-lg-4 col-12">
                                                            <label>Profil</label>
                                                             
                                                            <select name="account_type" class="form-control" oninput="DisplaySchool(this.value, {{ $user->code }})" onchange="DisplaySchool(this.value,{{ $user->code }})">
                                                            @if ($user->account_type == 'administrateur')
                                                                <option value="administrateur">Administrateur</option>
                                                                <option value="enseignant">Enseignant</option>
                                                                <option value="parent">Parent</option>
                                                                <option value="tuteur">Encardreur</option>
                                                          
                                                            @elseif ($user->account_type == 'enseignant')
                                                           
                                                                <option value="enseignant">Enseignant</option>
                                                                <option value="administrateur">Administrateur</option>
                                                                <option value="parent">Parent</option>
                                                                <option value="tuteur">Encardreur</option>
                                                            
                                                            @elseif ($user->account_type == 'parent')
                                                            
                                                                <option value="parent">Parent</option>
                                                                <option value="administrateur">Administrateur</option>
                                                                <option value="enseignant">Enseignant</option>
                                                                <option value="tuteur">Encardreur</option>
                                                           
                                                            @elseif ($user->account_type == 'tuteur')
                                                            
                                                                <option value="tuteur">Encardreur</option>
                                                                <option value="administrateur">Administrateur</option>
                                                                <option value="enseignant">Enseignant</option>
                                                                <option value="parent">Parent</option>
                                                            
                                                            @endif
                                                            </select>
                                                        </div>
                                                    </div>
                                                    <div class="row pb-1">
                                                        <div class="col-lg-4 col-12">
                                                            <label>Genre</label>
                                                            <select name="sex" class="form-control">
                                                                @if($user->sex == '0')
                                                                <option value="0">Masculin</option>
                                                                <option value="1">Feminin</option>
                                                                @else
                                                                <option value="1">Feminin</option>
                                                                <option value="0">Masculin</option>
                                                                @endif
                                                            </select>
                                                        </div>
                                                        <div class="col-lg-4 col-12">
                                                            <label>Contacts</label>
                                                            <input type="text" name="contacts" class="form-control" value="{{ $user->contacts }}">
                                                        </div>
                                                        <div class="col-lg-4 col-12">
                                                            <label>Photo de Profil</label>
                                                            <input type="file" name="RepPhoto" class="form-control" accept="*">
                                                        </div>
                                                    </div>
                                                    
                                                    <div class="row pb-1">
                                                        <div class="col-lg-4 col-12">
                                                            <label>Code</label>
                                                            <input type="text" name="code" class="form-control" value="{{ $user->code }}">
                                                        </div>
                                                        <div class="col-lg-4 col-12">
                                                            <label>Login</label>
                                                            <input type="text" class="form-control" name="login" value="{{ $user->login }}">
                                                        </div>
                                                        <div class="col-lg-4 col-12">
                                                            <label>Mot de passe</label>
                                                            <input id="password" type="text" value="{{ $user->text_password }}" class="form-control @error('password') is-invalid @enderror" name="password" required autocomplete="new-password">
                                                        </div>
                                                    </div>
                                                  
                                                    <div class="row" id="display_school{{ $user->code }}">
                                                        <div class="col-12">
                                                            <label>Etablissement {{ $user->CodeEtablissement }}</label>
                                                            <select name="school_id" class="text-center form-control">
                                                                @foreach ($schools as $school)
                                                                
                                                                    @if($user->CodeEtablissement == $school->CodeEtablissement)
                                                                        <option selected="selected" value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                                                    @else
                                                                        <option value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                                                    @endif

                                                                @endforeach
                                                            </select>
                                                        </div>
                                                    </div>
                                                    <hr class="line">
                                                    @foreach ($user->enfants as $student)
                                                    <div class="row pb-1">
                                                        <div class="col-lg-8 col-12">
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
                                                                    <small class="text-muted d-block">Code Eleve : {{ $student->CodeEleve }}</small>
                                                                </div>
                                                            </div>
                                                        </div>
                                                        <div class="col-lg-4 col-12 text-right">
                                                            <a href="{{ route('remove_student',['parent_id'=>$user->code,'student_id'=>$student->CodeEleve]) }}" class="btn btn-info">Retirer</a>
                                                        </div>
                                                    @endforeach
                                                   
                                                    
                                                </div>
                                                <div class="modal-footer">
                                                    <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                                        <i class="bx bx-x d-block d-sm-none"></i>
                                                        <span class="d-none d-sm-block">Annuler</span>
                                                    </button>
                                                    <button type="submit" class="btn btn-info ml-1">
                                                        <i class="bx bx-check d-block d-sm-none"></i>
                                                        <span class="d-none d-sm-block">Sauvegarder</span>
                                                    </button>
                                                </div>
                                            </form>
                                            
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="modal fade text-left" id="add_student{{ $user->code }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                    <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                        <div class="modal-content">
                                            
                                            <form action="{{ route('assign_student_choose_class',['parent_id'=>$user->code]) }}">
                                                
                                                <div class="modal-header bg-info">
                                                    <h5 class="modal-title white" id="myModalLabel160">Attribuer un nouvel eleve a : 
                                                        @if($user->sex == '0')
                                                        Mr. 
                                                        @else
                                                        Mme. 
                                                        @endif
                                                        <span class="text-uppercase">
                                                            {{ $user->nom }} {{ $user->prenoms }}
                                                        </span>
                                                    </h5>
                                                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                        <i class="bx bx-x"></i>
                                                    </button>
                                                </div>
                                                <div class="modal-body">
                                                    Choisissez un etablissement
                                                    <hr class="line">
                                                    
                                                    <div class="row pb-1">
                                                        <div class="col-12">
                                                            <label>Etablissement</label>
                                                           <select class="form-control" name="CodeEtablissement">
                                                            @foreach ($schools as $school)
                                                                <option value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                                            @endforeach
                                                           </select>
                                                        </div> 
                                                    </div>

                                                    

                                                    
                                                </div>
                                                <div class="modal-footer">
                                                    <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                                        <i class="bx bx-x d-block d-sm-none"></i>
                                                        <span class="d-none d-sm-block">Annuler</span>
                                                    </button>
                                                    <button type="submit" class="btn btn-info ml-1">
                                                        <i class="bx bx-check d-block d-sm-none"></i>
                                                        <span class="d-none d-sm-block">Liste des eleves</span>
                                                    </button>
                                                </div>
                                            </form>
                                            
                                        </div>
                                    </div>
                                </div>

                                
                                <div class="modal fade text-left" id="delete{{ $user->code }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                    <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                        <div class="modal-content">
                                            <div class="modal-header bg-danger">
                                                <h5 class="modal-title white" id="myModalLabel160">Supprimmer {{ $user->name }}</h5>
                                                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                    <i class="bx bx-x"></i>
                                                </button>
                                            </div>
                                            <div class="modal-body">
                                                Confirmez-vous vouloir suprimmer cette etablissement ?
                                                <br>
                                                NB: Toutes les données relatives à cette école seront supprimées et il ne sera pas possible de les récupérer
                                            </div>
                                            <div class="modal-footer">
                                                <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                                    <i class="bx bx-x d-block d-sm-none"></i>
                                                    <span class="d-none d-sm-block">Annuler</span>
                                                </button>
                                                <a href="#" class="btn btn-danger ml-1">
                                                    <i class="bx bx-check d-block d-sm-none"></i>
                                                    <span class="d-none d-sm-block">Oui, Suprimmer</span>
                                                </a>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </td>
                        </tr>                
                        @empty
                        <tr><td colspan="6">{{ $selectedSchool ? 'Aucun utilisateur enregistré pour cet établissement.' : 'Aucun utilisateur disponible.' }}</td></tr>
                        @endforelse
                        
                        
                    </tbody>
                </table>
            </table>
        </div>
        
    </div>
</div>


<script>

// To avoid displaying schools to administrator accounts upon modification
function DisplaySchool(account_type,user_id){
    school_id = 'display_school'+ user_id
    var school_row = document.getElementById(school_id);
    if(account_type == 'administrateur'){
        school_row.classList.remove('d-block');
        school_row.classList.add('d-none');
    }
    else{
        school_row.classList.remove('d-none');
        school_row.classList.add('d-block');
    }
}
    </script>



@endsection