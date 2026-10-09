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
                @if ($selectedSchool)
                    <input type="hidden" name="CodeEtablissement" value="{{ $selectedSchool->CodeEtablissement }}">
                @endif
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
                            <li class="nav-item">
                                <a class="nav-link" id="principal-tab-fill" data-toggle="tab" href="#principal-fill" role="tab" aria-controls="principal-fill" aria-selected="false">
                                    Principal
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
                                            <select name="school_id" class="form-control js-encadreur-school" required>
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
                                    <div class="form-group pt-1 js-encadreur-classes-row">
                                        <label>Classes attribuées</label>
                                        <div class="js-encadreur-classes-list"
                                             data-user-id=""
                                             data-classes-url="{{ route('admin.users.classes', ['school' => '__SCHOOL__']) }}">
                                            <span class="text-muted">Chargement des classes...</span>
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
                            <div class="tab-pane" id="principal-fill" role="tabpanel" aria-labelledby="principal-tab-fill">
                                <form action="{{ route('add_user_complete') }}" method="POST">
                                    @csrf
                                    <div class="row">
                                        <div class="col-lg-4 col-12">
                                            <label>Nom du Principal</label>
                                            <input type="text" name="nom" class="form-control" required>
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Prénom du Principal</label>
                                            <input type="text" name="prenom" class="form-control" required>
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Genre</label>
                                            <select name="sex" class="form-control" required>
                                                <option value="0">Masculin</option>
                                                <option value="1">Féminin</option>
                                            </select>
                                        </div>
                                    </div>
                                    <div class="row pt-1">
                                        <div class="col-lg-4 col-12">
                                            <label>Contacts</label>
                                            <input type="text" name="contacts" class="form-control" required>
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Établissement</label>
                                            <select name="school_id" class="form-control" required>
                                                <option value="">Choisir un établissement</option>
                                                @foreach ($schools as $school)
                                                    <option value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                                @endforeach
                                            </select>
                                        </div>
                                        <div class="col-lg-4 col-12">
                                            <label>Code</label>
                                            <input type="text" name="code" class="form-control" required>
                                        </div>
                                    </div>
                                    <input type="password" class="d-none" name="password" value="00000000">
                                    <input type="hidden" name="account_type" value="principal">
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                            <span>Annuler</span>
                                        </button>
                                        <button type="submit" class="btn btn-primary ml-1">
                                            <span>Créer</span>
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
        
        @if (!$selectedSchool)
            <div class="alert alert-info mt-2" role="status">
                Choisissez un établissement pour afficher ses utilisateurs.
            </div>
        @else
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
                                    <h6 class="media-heading mb-0">{{ $user->enfants_count }}</h6>
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
                                        <a class="dropdown-item" href="#" data-edit-user data-edit-url="{{ route('admin.users.edit-form', ['user_id' => $user->code, 'CodeEtablissement' => $selectedSchool->CodeEtablissement, 'page' => $users->currentPage()]) }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
                                        <a class="dropdown-item" href="#" data-assign-student data-user-id="{{ $user->code }}" data-user-name="{{ $user->nom }} {{ $user->prenom }}"><i class="bx bx-edit-alt mr-1"></i>Attribuer un eleve</a>
                                        <a class="dropdown-item" href="#" data-delete-user data-user-name="{{ $user->nom }} {{ $user->prenom }}"><i class="bx bx-trash mr-1"></i>Supprimmer</a>
                                    </div>
                                </div>
                                
                                

                            </td>
                        </tr>                
                        @empty
                        <tr><td colspan="6">{{ $selectedSchool ? 'Aucun utilisateur enregistré pour cet établissement.' : 'Aucun utilisateur disponible.' }}</td></tr>
                        @endforelse
                        
                        
                    </tbody>
                </table>
        </div>
        @if ($users->hasPages())
            <div class="d-flex justify-content-center mt-2">
                {{ $users->links() }}
            </div>
        @endif
        @endif
        
        <div class="modal fade text-left" id="user-edit-modal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                <div class="modal-content" id="user-edit-modal-content">
                    <div class="modal-body">Chargement...</div>
                </div>
            </div>
        </div>
        <div class="modal fade text-left" id="user-assignment-modal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                <div class="modal-content">
                    <form id="user-assignment-form" method="GET" action="{{ route('assign_student_choose_class', ['parent_id' => '__PARENT_ID__']) }}">
                        <div class="modal-header bg-info">
                            <h5 class="modal-title white" id="user-assignment-title">Attribuer un nouvel eleve</h5>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="bx bx-x"></i></button>
                        </div>
                        <div class="modal-body">
                            Choisissez un etablissement
                            <hr class="line">
                            <label for="assignment-school">Etablissement</label>
                            <select class="form-control" id="assignment-school" name="CodeEtablissement">
                                @foreach ($schools as $school)
                                    <option value="{{ $school->CodeEtablissement }}" {{ $selectedSchool && $selectedSchool->CodeEtablissement == $school->CodeEtablissement ? 'selected' : '' }}>{{ $school->Nom }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-light-secondary" data-dismiss="modal"><span>Annuler</span></button>
                            <button type="submit" class="btn btn-info ml-1"><span>Liste des eleves</span></button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        <div class="modal fade text-left" id="user-delete-modal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                <div class="modal-content">
                    <div class="modal-header bg-danger">
                        <h5 class="modal-title white">Supprimmer <span id="user-delete-name"></span></h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="bx bx-x"></i></button>
                    </div>
                    <div class="modal-body">
                        Confirmez-vous vouloir suprimmer cet utilisateur ?
                        <br>NB: Toutes les données relatives à cet utilisateur seront supprimées et il ne sera pas possible de les récupérer.
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light-secondary" data-dismiss="modal"><span>Annuler</span></button>
                        <a href="#" class="btn btn-danger ml-1"><span>Oui, Suprimmer</span></a>
                    </div>
                </div>
            </div>
        </div>

    </div>
</div>

<style>
#user-edit-modal .modal-content {
    max-height: calc(100vh - 3.5rem);
    overflow: hidden;
}

#user-edit-modal-content > .modal-body {
    min-height: 0;
    overflow-y: auto;
}

#user-edit-modal-content .user-edit-form {
    min-height: 0;
}

#user-edit-modal-content .js-encadreur-classes-list {
    max-height: 18rem;
    overflow-y: auto;
    padding: 0.5rem;
}
</style>

<script>
document.addEventListener('DOMContentLoaded', function () {
    function loadClasses(select, schoolCode, selectedCodes) {
        select.innerHTML = '';
        select.setCustomValidity('');
        select.dataset.loadState = 'loading';
        if (!schoolCode) {
            select.disabled = true;
            select.dataset.loadState = 'error';
            return;
        }

        select.disabled = true;
        var requestId = String(Number(select.dataset.requestId || 0) + 1);
        select.dataset.requestId = requestId;
        var url = select.dataset.classesUrl.replace('__SCHOOL__', encodeURIComponent(schoolCode));

        fetch(url, { headers: { 'Accept': 'application/json' } })
            .then(function (response) {
                if (!response.ok) {
                    throw new Error('classes-request-failed');
                }
                return response.json();
            })
            .then(function (classes) {
                if (select.dataset.requestId !== requestId) {
                    return;
                }
                if (classes.length === 0) {
                    var emptyOption = document.createElement('option');
                    emptyOption.disabled = true;
                    emptyOption.textContent = 'Aucune classe pour cet établissement.';
                    select.appendChild(emptyOption);
                    select.disabled = false;
                    select.dataset.loadState = 'loaded';
                    return;
                }
                classes.forEach(function (schoolClass) {
                    var option = document.createElement('option');
                    option.value = schoolClass.CodeClasse;
                    option.textContent = schoolClass.LibelleClasse + ' (' + schoolClass.CodeClasse + ')';
                    option.selected = selectedCodes.indexOf(schoolClass.CodeClasse) !== -1;
                    select.appendChild(option);
                });
                select.disabled = false;
                select.dataset.loadState = 'loaded';
            })
            .catch(function () {
                if (select.dataset.requestId !== requestId) {
                    return;
                }
                var errorOption = document.createElement('option');
                errorOption.disabled = true;
                errorOption.textContent = 'Impossible de charger les classes. Modifiez l’établissement pour réessayer.';
                select.appendChild(errorOption);
                select.dataset.loadState = 'error';
            });
    }

    document.querySelectorAll('.js-encadreur-classes').forEach(function (select) {
        var userId = select.dataset.userId;
        var form = select.closest('form');
        var schoolSelect = form.querySelector('.js-encadreur-school');
        var wrapper = userId ? document.getElementById('encadreur-classes-row-' + userId) : null;
        var selectedCodes = wrapper ? JSON.parse(wrapper.dataset.selectedClasses || '[]') : [];

        if (schoolSelect) {
            schoolSelect.addEventListener('change', function () {
                loadClasses(select, schoolSelect.value, []);
            });
        }
        var accountType = form.querySelector('.js-user-account-type');
        if (!accountType || accountType.value === 'encadreur') {
            loadClasses(select, schoolSelect ? schoolSelect.value : '', selectedCodes);
        }
        form.addEventListener('submit', function (event) {
            var currentAccountType = form.querySelector('.js-user-account-type');
            if ((!currentAccountType || currentAccountType.value === 'encadreur')
                && select.dataset.loadState !== 'loaded') {
                event.preventDefault();
                select.setCustomValidity('Attendez le chargement des classes ou réessayez.');
                select.reportValidity();
            }
        });
    });

    document.querySelectorAll('.js-user-account-type').forEach(function (select) {
        select.addEventListener('change', function () {
            DisplaySchool(select.value, select.dataset.userId);
            if (select.value === 'encadreur') {
                var form = select.closest('form');
                var classSelect = form.querySelector('.js-encadreur-classes');
                var schoolSelect = form.querySelector('.js-encadreur-school');
                var wrapper = document.getElementById('encadreur-classes-row-' + select.dataset.userId);
                var selectedCodes = wrapper ? JSON.parse(wrapper.dataset.selectedClasses || '[]') : [];
                if (classSelect && schoolSelect) {
                    loadClasses(classSelect, schoolSelect.value, selectedCodes);
                }
            }
        });
        DisplaySchool(select.value, select.dataset.userId);
    });
});

function DisplaySchool(accountType, userId) {
    var schoolRow = document.getElementById('display_school' + userId);
    var classesRow = document.getElementById('encadreur-classes-row-' + userId);
    if (schoolRow) {
        schoolRow.classList.toggle('d-none', accountType === 'administrateur');
    }
    if (classesRow) {
        classesRow.classList.toggle('d-none', ['encadreur', 'enseignant'].indexOf(accountType) === -1);
    }
}
</script>

<script>
document.addEventListener('DOMContentLoaded', function () {
    var editContent = document.getElementById('user-edit-modal-content');

    function initializeEncadreurClassList(form) {
        var classList = form.querySelector('.js-encadreur-classes-list');
        var schoolSelect = form.querySelector('.js-encadreur-school');
        var accountType = form.querySelector('.js-user-account-type');
        if (!classList || !schoolSelect) return;

        var userId = classList.dataset.userId || '';
        var requestId = 0;

        function loadClasses() {
            var currentRequest = ++requestId;
            classList.dataset.loadState = 'loading';
            classList.replaceChildren(document.createTextNode('Chargement des classes...'));
            var url = classList.dataset.classesUrl.replace(
                '__SCHOOL__',
                encodeURIComponent(schoolSelect.value)
            );
            var urlObject = new URL(url, window.location.origin);
            if (userId) urlObject.searchParams.set('encadreur_code', userId);
            fetch(urlObject.toString(), { headers: { 'Accept': 'application/json' } })
                .then(function (response) {
                    if (!response.ok) throw new Error('classes-request-failed');
                    return response.json();
                })
                .then(function (classes) {
                    if (currentRequest !== requestId) return;
                    classList.replaceChildren();
                    if (!classes.length) {
                        classList.textContent = 'Aucune classe pour cet établissement.';
                    }
                    classes.forEach(function (schoolClass) {
                        var row = document.createElement('div');
                        row.className = 'custom-control custom-checkbox mb-1';
                        var checkbox = document.createElement('input');
                        checkbox.type = 'checkbox';
                        checkbox.name = 'class_ids[]';
                        checkbox.value = schoolClass.CodeClasse;
                        checkbox.id = 'class-' + userId + '-' + schoolClass.CodeClasse;
                        checkbox.className = 'custom-control-input';

                        var assignedToCurrent = schoolClass.assignedToCurrentEncadreur === true;
                        var ownerName = schoolClass.assignedToEncadreurName || '';
                        var unavailable = !!ownerName && !assignedToCurrent;
                        checkbox.checked = assignedToCurrent;
                        checkbox.disabled = unavailable;

                        var label = document.createElement('label');
                        label.className = 'custom-control-label';
                        label.htmlFor = checkbox.id;
                        var className = document.createElement('strong');
                        className.textContent = schoolClass.LibelleClasse;
                        label.appendChild(className);
                        label.appendChild(document.createTextNode(' (' + schoolClass.CodeClasse + ')'));
                        if (unavailable) {
                            label.appendChild(document.createTextNode(' — Déjà attribuée à ' + ownerName));
                            row.classList.add('text-muted');
                        } else if (assignedToCurrent) {
                            label.appendChild(document.createTextNode(' — Attribuée à cet utilisateur'));
                        }

                        row.appendChild(checkbox);
                        row.appendChild(label);
                        classList.appendChild(row);
                    });
                    classList.dataset.loadState = 'loaded';
                })
                .catch(function () {
                    if (currentRequest !== requestId) return;
                    classList.dataset.loadState = 'error';
                    classList.textContent = 'Impossible de charger les classes. Modifiez l’établissement pour réessayer.';
                });
        }

        schoolSelect.addEventListener('change', loadClasses);
        if (!accountType || ['encadreur', 'enseignant'].indexOf(accountType.value) !== -1) loadClasses();
        form.addEventListener('submit', function (event) {
            if ((!accountType || ['encadreur', 'enseignant'].indexOf(accountType.value) !== -1)
                && classList.dataset.loadState !== 'loaded') {
                event.preventDefault();
                classList.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        });
        if (accountType) {
            accountType.addEventListener('change', function () {
                var schoolRow = document.getElementById('display_school' + accountType.dataset.userId);
                var classesRow = document.getElementById('encadreur-classes-row-' + accountType.dataset.userId);
                if (schoolRow) schoolRow.classList.toggle('d-none', accountType.value === 'administrateur');
                var hasClassAssignments = ['encadreur', 'enseignant'].indexOf(accountType.value) !== -1;
                if (classesRow) classesRow.classList.toggle('d-none', !hasClassAssignments);
                if (hasClassAssignments) loadClasses();
            });
        }
    }

    document.querySelectorAll('.js-encadreur-classes-list').forEach(function (classList) {
        initializeEncadreurClassList(classList.closest('form'));
    });

    function loadEditForm(url) {
        editContent.innerHTML = '<div class="modal-body">Chargement...</div>';
        fetch(url, { headers: { 'Accept': 'text/html' } })
            .then(function (response) {
                if (!response.ok) throw new Error('edit-form-request-failed');
                return response.text();
            })
            .then(function (html) {
                editContent.innerHTML = html;
                var form = editContent.querySelector('form');
                if (form) initializeEncadreurClassList(form);
            })
            .catch(function () {
                var body = document.createElement('div');
                body.className = 'modal-body';
                var message = document.createElement('div');
                message.className = 'alert alert-danger mb-0';
                message.textContent = 'Impossible de charger le formulaire. ';
                var retry = document.createElement('button');
                retry.type = 'button';
                retry.className = 'btn btn-link p-0';
                retry.textContent = 'Réessayer';
                retry.dataset.retryEdit = url;
                message.appendChild(retry);
                body.appendChild(message);
                editContent.replaceChildren(body);
            });
    }

    document.addEventListener('click', function (event) {
        var retry = event.target.closest('[data-retry-edit]');
        if (retry) {
            loadEditForm(retry.dataset.retryEdit);
            return;
        }

        var edit = event.target.closest('[data-edit-user]');
        if (edit) {
            event.preventDefault();
            $('#user-edit-modal').modal('show');
            loadEditForm(edit.dataset.editUrl);
            return;
        }

        var assignment = event.target.closest('[data-assign-student]');
        if (assignment) {
            event.preventDefault();
            var form = document.getElementById('user-assignment-form');
            if (!form.dataset.actionTemplate) form.dataset.actionTemplate = form.action;
            form.action = form.dataset.actionTemplate.replace('__PARENT_ID__', encodeURIComponent(assignment.dataset.userId));
            document.getElementById('user-assignment-title').textContent = 'Attribuer un nouvel eleve a : ' + assignment.dataset.userName;
            $('#user-assignment-modal').modal('show');
            return;
        }

        var deleteAction = event.target.closest('[data-delete-user]');
        if (deleteAction) {
            event.preventDefault();
            document.getElementById('user-delete-name').textContent = deleteAction.dataset.userName;
            $('#user-delete-modal').modal('show');
        }
    });
});
</script>



@endsection