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
                        Ajouter une nouvelle classe
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
        
                    <form action="{{ route('import_classes') }}" enctype="multipart/form-data" method="POST">
                        @csrf
                    <div class="modal-header bg-dark">
                        <h5 class="modal-title white" id="myModalLabel160">Importer un fichier CSV de classes</h5>
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
                    
                    <form action="{{ route('add_class_complete') }}" method="POST">
                        @csrf
                        <div class="modal-header bg-primary">
                            <h5 class="modal-title white" id="myModalLabel160">Ajoutez unle classe</h5>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                <i class="bx bx-x"></i>
                            </button>
                        </div>
                        <div class="modal-body">
                            Remplissez le formulaire ci-dessous et validez
                            <hr class="line">
                            <div class="row">
                                <div class="col-lg-4 col-12">
                                    <label>Libelle de la classe</label>
                                    <input type="text" name="LibelleClasse" class="form-control" placeholder="6 eme">
                                </div> 
                                <div class="col-lg-4 col-12">
                                    <label>Code Classe</label>
                                    <input type="text" name="CodeClasse" class="form-control" placeholder="163">
                                </div>
                                <div class="col-lg-4 col-12">
                                    <label>Code Type de Classe</label>
                                    <input type="text" name="CodeTypeClasse" class="form-control" placeholder="653">
                                </div>
                            </div>
                            
                            <div class="row pt-lg-2">
                                <div class="col-lg-4 col-12">
                                    <label>Code Cycle</label>
                                    <input type="text" name="CodeCycle" class="form-control" placeholder="152">
                                </div> 
                                <div class="col-lg-4 col-12">
                                    <label>Code Specialite</label>
                                    <input type="text" class="form-control" name="CodeSpecialite" placeholder="11367">
                                </div>
                                <div class="col-lg-4 col-12">
                                    <label>Code Type Inscription</label>
                                    <input type="number" name="codetypeinscrip" placeholder="112" class="form-control">
                                </div>
                            </div>
                            <div class="row pt-1">
                                <div class="col-12">
                                    <label>Etablissement</label>
                                    <select name="CodeEtablissement" class="text-center form-control">
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
                        <th>Noms de classe</th>
                        <th>Codes</th>
                        <th>Etablissement</th>
                        <th></th>
                        
                    </tr>
                </thead>
                <tbody>
                    
                    @forelse ($classes as $class)
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
                                <h6 class="media-heading mb-0">{{ $class->etablissement->Nom }}</h6>
                                <span class="font-small-2">Code Etablissement : {{ $class->etablissement->CodeEtablissement }}</span>
                            </div>
                            
                        </td>
                        <td class="text-center py-1">
                            <div class="dropdown">
                                <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                                <div class="dropdown-menu dropdown-menu-right">
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#details{{ $class->CodeClasse }}"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#modify{{ $class->CodeClasse }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#delete{{ $class->CodeClasse }}"><i class="bx bx-trash mr-1"></i>Supprimmer</a>
                                </div>
                            </div>
                            
                            <div class="modal fade text-left" id="details{{ $class->CodeClasse }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                    <div class="modal-content">
                                        
                                        <div class="modal-header bg-info">
                                            <h5 class="modal-title white" id="myModalLabel160">{{ $class->LibelleClasse }}</h5>
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
                                                                    <span class="list-title">{{ $class->LibelleClasse }}</span>
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
                                                                    <span class="list-title">{{ $class->Codleeclasse }}</span>
                                                                    <small class="text-muted d-blocek">Codele classe</small>
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
                                                                    <span class="list-title">{{ $class->pays }}</span>
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
                                                                    <span class="list-title">{{ $class->tel }}</span>
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
                                                                    <span class="list-title">{{ $class->fax }}</span>
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
                                                                    <span class="list-title">{{ $class->created_at }}</span>
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
                            
                            
                            <div class="modal fade text-left" id="modify{{ $class->CodeClasse }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                    <div class="modal-content">
                                        <form action="{{ route('save_class',['class_id'=>$class->CodeClasse]) }}" method="POST">
                                            @csrf
                                            <div class="modal-header bg-info">
                                                <h5 class="modal-title white" id="myModalLabel160">Modifier la classe : {{ $class->LibelleClasse }}</h5>
                                                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                    <i class="bx bx-x"></i>
                                                </button>
                                            </div>
                                            <div class="modal-body">
                                                Remplissez le formulaire ci-dessous et validez
                                                <hr class="line">
                                                <div class="row">
                                                    <div class="col-lg-4 col-12">
                                                        <label>Noms de la classe {{ $class->CodeClasse }}</label>
                                                        <input type="text" name="LibelleClasse" class="form-control" value="{{ $class->LibelleClasse }}">
                                                    </div> 
                                                    <div class="col-lg-4 col-12">
                                                        <label>Code Classe</label>
                                                        <input type="text" name="CodeClasse" class="form-control" value="{{ $class->CodeClasse }}">
                                                    </div>
                                                    <div class="col-lg-4 col-12">
                                                        <label>Code Cycle</label>
                                                        <input type="text" name="CodeCycle" class="form-control" value="{{ $class->CodeCycle }}">
                                                    </div>
                                                </div>
                                                
                                                <div class="row pt-lg-2">
                                                    <div class="col-lg-4 col-12">
                                                        <label>Code Type De Classe</label>
                                                        <input type="text" name="CodeTypeClasse" class="form-control" value="{{ $class->CodeTypeClasse }}">
                                                    </div> 
                                                    <div class="col-lg-4 col-12">
                                                        <label>Code Specialite</label>
                                                        <input type="text" class="form-control" name="CodeSpecialite" value={{ $class->CodeSpecialite }}>
                                                    </div>
                                                    <div class="col-lg-4 col-12">
                                                        <label>Code Inscription</label>
                                                        <input type="text" name="codetypeinscrip" class="form-control" value={{ $class->codetypeinscrip }}>
                                                    </div>
                                                </div>
                                                
                                                <div class="row">
                                                    <div class="col-12">
                                                        <label>Etablissement</label>
                                                        <select name="CodeEtablissement" class="text-center form-control">
                                                            @foreach ($schools as $school)
                                                            
                                                            @if($class->etablissement->CodeEtablissement == $school->CodeEtablissement)
                                                            <option selected="selected" value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                                            @else
                                                            <option value="{{ $school->CodeEtablissement }}">{{ $school->Nom }}</option>
                                                            @endif
                                                            
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
                                                    <span class="d-none d-sm-block">Sauvegarder</span>
                                                </button>
                                            </div>
                                        </form>
                                        
                                    </div>
                                </div>
                            </div>
                            
                            
                            <div class="modal fade text-left" id="delete{{ $class->CodeClasse }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                                <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                    <div class="modal-content">
                                        <div class="modal-header bg-danger">
                                            <h5 class="modal-title white" id="myModalLabel160">Supprimmer {{ $class->LibelleClasse }}</h5>
                                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                                <i class="bx bx-x"></i>
                                            </button>
                                        </div>
                                        <div class="modal-body">
                                            Confirmez-vous vouloir suprimmeer cette classe ?
                                            <br>
                                            NB: Toutes les données relatives à cette classe seront supprimées et il ne sera pas possible de les récupérer
                                        </div>
                                        <div class="modal-footer">
                                            <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                                <i class="bx bx-x d-block d-sm-none"></i>
                                                <span class="d-none d-sm-block">Annuler</span>
                                            </button>
                                            <a href="{{ route('delete_class',['class_id'=>$class->CodeClasse]) }}" class="btn btn-danger ml-1">
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
                    Liste vide !
                    @endforelse
                    
                    
                </tbody>
            </table>
        </table>
    </div>
    
</div>
</div>


@endsection