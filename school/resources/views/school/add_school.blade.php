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
                <div class="col-lg-8 col-12">
                    <h4>
                        <a href="#" onclick="history.back()"><i class="bx bx-left-arrow-circle" style="font-size: 1.5rem"></i></a>
                        Ajouter un nouvel etablissement
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
                    
                    <form action="{{ route('import_schools') }}" enctype="multipart/form-data" method="POST">
                        @csrf
                        <div class="modal-header bg-dark">
                            <h5 class="modal-title white" id="myModalLabel160">Importer un fichier CSV</h5>
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
                    
                    <form action="{{ route('add_school_complete') }}" method="POST" enctype="multipart/form-data">
                        @csrf
                        <div class="modal-header bg-primary">
                            <h5 class="modal-title white" id="myModalLabel160">Ajoutez un etablissement</h5>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                <i class="bx bx-x"></i>
                            </button>
                        </div>
                        <div class="modal-body">
                            Remplissez le formulaire ci-dessous et validez
                            <hr class="line">
                            <div class="row">
                                <div class="col-lg-4 col-12">
                                    <label>Noms de l'etablissement</label>
                                    <input type="text" name="Nom" class="form-control" placeholder="College Jean Tabi" value="{{ old('Nom') }}">
                                    @error('Nom')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                    @enderror
                                </div> 
                                <div class="col-lg-4 col-12">
                                    <label>Contacts</label>
                                    <input type="text" name="Tel" class="form-control" placeholder="652686163" value="{{ old('Tel') }}">
                                    @error('Tel')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                    @enderror
                                </div>
                                <div class="col-lg-4 col-12">
                                    <label>Fax</label>
                                    <input type="text" name="Fax" class="form-control" placeholder="BP:653" value="{{ old('Fax') }}">
                                    @error('Fax')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                    @enderror
                                </div>
                            </div>
                            
                            <div class="row pt-lg-2">
                                <div class="col-lg-4 col-12">
                                    <label>Address</label>
                                    <input type="text" name="Adresse" class="form-control" placeholder="Yaounde" value="{{ old('Adresse') }}">
                                    @error('Adresse')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                    @enderror
                                </div> 
                                <div class="col-lg-4 col-12">
                                    <label>Code Etablissement</label>
                                    <input type="text" class="form-control" name="CodeEtablissement" placeholder="11367" value="{{ old('nom') }}">
                                    @error('CodeEtablissement')
                                    <span class="invalid-feedback" role="alert">
                                        <strong>{{ $message }}</strong>
                                    </span>
                                    @enderror
                                </div>
                                <div class="col-lg-4 col-12">
                                    <label>Logo</label>
                                    <input type="file" name="RepPhoto" class="form-control" accept="*">
                                </div>
                            </div>
                            
                        </div>
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
        <hr class="line">
        
        <div class="table-responsive">
            <table class="table table-striped table-hover zero-configuration">
                <thead>
                    <tr>
                        <th>Code</th>
                        <th>Noms d'etablissement</th>
                        <th>Address</th>
                        <th></th>
                        
                    </tr>
                </thead>
                <tbody>
                    
                    @foreach ($schools as $school)
                    <tr>
                        <td>
                            {{ $school->CodeEtablissement }}
                        </td>
                        <td class="pr-75">
                            <div class="media align-items-center">
                                <a class="media-left mr-50" href="#">
                                    
                                    @if ($school->REPPHOTO == NULL)
                                    <img src="../../../app-assets/images/raty/star-on-2.png" alt="avatar" class="rounded-circle" height="30" width="30">
                                    @else
                                    <img src="{{ Storage::url($school->REPPHOTO) }}" alt="avatar" class="rounded-circle" height="30" width="30">
                                    @endif
                                    
                                </a>
                                <div class="media-body">
                                    <h6 class="media-heading mb-0">{{ $school->Nom }}</h6>
                                    <span class="font-small-2">Contact: {{ $school->Tel }}</span>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="media-body">
                                <h6 class="media-heading mb-0">Fax: {{ $school->Fax }}</h6>
                                <span class="font-small-2">Pays: {{ $school->Pays }}</span>
                            </div>
                            
                        </td>
                        <td class="text-center py-1">
                            <div class="dropdown">
                                <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                                <div class="dropdown-menu dropdown-menu-right">
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#details{{ $school->CodeEtablissement }}"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#modify{{ $school->CodeEtablissement }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#delete{{ $school->CodeEtablissement }}"><i class="bx bx-trash mr-1"></i>Supprimmer</a>
                                </div>
                            </div>
                            
                            <div class="modal fade text-left" id="details{{ $school->CodeEtablissement }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                    <div class="modal-content">
                                        
                                        <div class="modal-header bg-info">
                                            <h5 class="modal-title white" id="myModalLabel160">{{ $school->Nom }}</h5>
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
                                                                    <span class="list-title">{{ $school->Nom }}</span>
                                                                    <small class="text-muted d-block">Nom</small>
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
                                                                    <span class="list-title">{{ $school->CodeEtablissement }}</span>
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
                                                                    <span class="list-title">{{ $school->Pays }}</span>
                                                                    <small class="text-muted d-block">Pays</small>
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
                                                                    <span class="list-title">{{ $school->Tel }}</span>
                                                                    <small class="text-muted d-block">Contacts</small>
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
                                                                    <span class="list-title">{{ $school->Fax }}</span>
                                                                    <small class="text-muted d-block">Fax</small>
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
                                                                    <span class="list-title">{{ $school->created_at }}</span>
                                                                    <small class="text-muted d-block">Date de Creation</small>
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
                            
                            
                            <div class="modal fade text-left" id="modify{{ $school->CodeEtablissement }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                    <div class="modal-content">
                                        <form action="{{ route('save_school',['school_id'=>$school->CodeEtablissement]) }}" method="POST" enctype="multipart/form-data">
                                            @csrf
                                            <div class="modal-header bg-info">
                                                <h5 class="modal-title white" id="myModalLabel160">Modifier : {{ $school->Nom }}</h5>
                                                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                    <i class="bx bx-x"></i>
                                                </button>
                                            </div>
                                            <div class="modal-body">
                                                Remplissez le formulaire ci-dessous et validez
                                                <hr class="line">
                                                <div class="row">
                                                    <div class="col-lg-4 col-12">
                                                        <label>Noms de l'etablissement</label>
                                                        <input type="text" name="Nom" class="form-control" value="{{ $school->Nom }}">
                                                    </div> 
                                                    <div class="col-lg-4 col-12">
                                                        <label>Contacts</label>
                                                        <input type="text" name="Tel" class="form-control" value="{{ $school->Tel }}">
                                                    </div>
                                                    <div class="col-lg-4 col-12">
                                                        <label>Fax</label>
                                                        <input type="text" name="Fax" class="form-control" value="{{ $school->Fax }}">
                                                    </div>
                                                </div>
                                                
                                                <div class="row pt-lg-2">
                                                    <div class="col-lg-4 col-12">
                                                        <label>Address</label>
                                                        <input type="text" name="Adresse" class="form-control" value="{{ $school->Adresse }}">
                                                    </div> 
                                                    <div class="col-lg-4 col-12">
                                                        <label>Code etablissement</label>
                                                        <input type="text" class="form-control" name="CodeEtablissement" value={{ $school->CodeEtablissement }}>
                                                    </div>
                                                    <div class="col-lg-4 col-12">
                                                        <label>Logo</label>
                                                        <input type="file" name="REPPHOTO" class="form-control" accept="*">
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
                                                    <span class="d-none d-sm-block">Sauvegarder</span>
                                                </button>
                                            </div>
                                        </form>
                                        
                                    </div>
                                </div>
                            </div>
                            
                            
                            <div class="modal fade text-left" id="delete{{ $school->CodeEtablissement }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                    <div class="modal-content">
                                        <div class="modal-header bg-danger">
                                            <h5 class="modal-title white" id="myModalLabel160">Supprimmer {{ $school->nom }}</h5>
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
                                            <a href="{{ route('delete_school',['school_id'=>$school->CodeEtablissement]) }}" class="btn btn-danger ml-1">
                                                <i class="bx bx-check d-block d-sm-none"></i>
                                                <span class="d-none d-sm-block">Oui, Suprimmer</span>
                                            </a>
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