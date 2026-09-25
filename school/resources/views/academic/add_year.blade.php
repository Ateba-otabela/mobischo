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
                Ajouter une nouvelle année scholaire
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
                        
                                    <form action="{{ route('import_years') }}" enctype="multipart/form-data" method="POST">
                                        @csrf
                                    <div class="modal-header bg-dark">
                                        <h5 class="modal-title white" id="myModalLabel160">Importer un fichier CSV d'annees scholaire</h5>
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

                    <form action="{{ route('add_year_complete') }}" method="POST" enctype="multipart/form-data">
                        @csrf
                    <div class="modal-header bg-primary">
                        <h5 class="modal-title white" id="myModalLabel160">Ajoutez une année</h5>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <i class="bx bx-x"></i>
                        </button>
                    </div>
                    <div class="modal-body">
                        Remplissez le formulaire ci-dessous et validez
                        <hr class="line">
                        <div class="row">
                            <div class="col-lg-6 col-12">
                                <label>Libelle</label>
                                <select class="form-control" name="Libelle">
                                    <option>2019/2020</option>
                                    <option>2020/2021</option>
                                    <option>2021/2022</option>
                                    <option>2022/2023</option>
                                    <option>2023/2024</option>
                                    <option>2024/2025</option>
                                    <option>2025/2026</option>
                                    <option>2026/2027</option>
                                    <option>2027/2028</option>
                                    <option>2028/2029</option>
                                    <option>2029/2030</option>
                                </select>
                            </div> 
                            <div class="col-lg-6 col-12">
                                <label>Code</label>
                                <input type="number" name="CodeAnnee" class="form-control" placeholder="1">
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
                    <th>Code Année</th>
                    <th>Libelle</th>
                    <th></th>
                    
                </tr>
            </thead>
            <tbody>

                @foreach ($years as $year)
                <tr>
                    <td>
                        {{ $year->CodeAnnee }}
                    </td>
                    <td class="pr-75">
                        <div class="media align-items-center">
                            <a class="media-left mr-50" href="#">

                                

                            </a>
                            
                            <div class="media-body">
                                <h6 class="media-heading mb-0">{{ $year->Libelle }}</h6>
                             
                            </div>
                        </div>
                    </td>
                    <td class="text-center py-1">
                        <div class="dropdown">
                            <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                            <div class="dropdown-menu dropdown-menu-right">
                                <a class="dropdown-item" href="#" data-toggle="modal" data-target="#details{{ $year->CodeAnnee }}"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                <a class="dropdown-item" href="#" data-toggle="modal" data-target="#modify{{ $year->CodeAnnee }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
                                <a class="dropdown-item" href="#" data-toggle="modal" data-target="#delete{{ $year->CodeAnnee }}"><i class="bx bx-trash mr-1"></i>Supprimmer</a>
                            </div>
                        </div>

                        <div class="modal fade text-left" id="details{{ $year->CodeAnnee }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                <div class="modal-content">
                                   
                                        <div class="modal-header bg-info">
                                        <h5 class="modal-title white" id="myModalLabel160">{{ $year->nom }}</h5>
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
                                                                <span class="list-title">{{ $year->nom }}</span>
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
                                                                <span class="list-title">{{ $year->CodeEtablissement }}</span>
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
                                                                <span class="list-title">{{ $year->pays }}</span>
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
                                                                <span class="list-title">{{ $year->tel }}</span>
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
                                                                <span class="list-title">{{ $year->fax }}</span>
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
                                                                <span class="list-title">{{ $year->created_at }}</span>
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


                        <div class="modal fade text-left" id="modify{{ $year->CodeAnnee }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                <div class="modal-content">
                                    <form action="{{ route('save_year',['year_id'=>$year->CodeAnnee]) }}" method="POST" enctype="multipart/form-data">
                                    @csrf
                                        <div class="modal-header bg-info">
                                        <h5 class="modal-title white" id="myModalLabel160">Modifier : {{ $year->Libelle }}</h5>
                                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                            <i class="bx bx-x"></i>
                                        </button>
                                    </div>
                                    <div class="modal-body">
                                        Remplissez le formulaire ci-dessous et validez
                                        <hr class="line">
                                        <div class="row">
                                            <div class="col-lg-6 col-12">
                                                <label>Code Annee</label>
                                                <input type="text" name="CodeAnnee" class="form-control" value="{{ $year->CodeAnnee }}">
                                            </div> 
                                            <div class="col-lg-6 col-12">
                                                <label>Libelle</label>
                                                <input type="text" name="Libelle" class="form-control" value="{{ $year->Libelle }}">
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

                        <div class="modal fade text-left" id="delete{{ $year->CodeAnnee }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                <div class="modal-content">
                                    <div class="modal-header bg-danger">
                                        <h5 class="modal-title white" id="myModalLabel160">Supprimmer l'annee scholaire : {{ $year->Libelle }}</h5>
                                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                            <i class="bx bx-x"></i>
                                        </button>
                                    </div>
                                    <div class="modal-body">
                                        Confirmez-vous vouloir suprimmer cette annee scholaire ?
                                        <br>
                                        NB: Toutes les données relatives à cette annee seront supprimées et il ne sera pas possible de les récupérer
                                    </div>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
                                            <i class="bx bx-x d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Annuler</span>
                                        </button>
                                        <a href="{{ route('delete_year',['year_id'=>$year->CodeAnnee]) }}" class="btn btn-danger ml-1">
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