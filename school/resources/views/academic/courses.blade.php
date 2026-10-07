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
               Liste des matieres
            </h4>
            <p class="card-description">Etablissement : {{ $school->Nom }}</p>
            </div>
            <div class="col-lg-2 col-12 text-lg-right">
                <button type="button" class="btn btn-outline-primary" data-toggle="modal" data-target="#primary">
                   + Ajouter
                </button>
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
        <table class="table table-striped table-hover">
            <thead>
                <tr>
                    <th>Code Année</th>
                    <th>Libelle</th>
                    <th>Date de Creation</th>
                    
                </tr>
            </thead>
            <tbody>

                @forelse ($school->courses as $course)
                <tr>
                    <td>
                        {{ $course->CodeMatiere }}
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
                                <span class="list-title">{{ $course->LibelleMatiere }}</span>
                                <small class="text-muted d-block">Ordre : {{ $course->ordre }}</small>
                            </div>
                        </div> 
                    </td>
                        <td>
                            {{ $course->created_at }}
                        </td>
                    <td class="text-center py-1">

                        
                        <div class="dropdown">
                            <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                            <div class="dropdown-menu dropdown-menu-right">
                                <a class="dropdown-item" href="#" data-toggle="modal" data-target="#details{{ $course->CodeMatiere }}"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                {{-- <a class="dropdown-item" href="#" data-toggle="modal" data-target="#modify{{ $course->CodeMatiere }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
                                <a class="dropdown-item" href="#" data-toggle="modal" data-target="#delete{{ $course->CodeMatiere }}"><i class="bx bx-trash mr-1"></i>Supprimmer</a> --}}
                            </div>
                        </div>

                        {{-- <div class="modal fade text-left" id="details{{ $course->CodeMatiere }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                <div class="modal-content">
                                   
                                        <div class="modal-header bg-info">
                                        <h5 class="modal-title white" id="myModalLabel160">{{ $course->nom }}</h5>
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
                                                                <span class="list-title">{{ $course->nom }}</span>
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
                                                                <span class="list-title">{{ $course->CodeEtablissement }}</span>
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
                                                                <span class="list-title">{{ $course->pays }}</span>
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
                                                                <span class="list-title">{{ $course->tel }}</span>
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
                                                                <span class="list-title">{{ $course->fax }}</span>
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
                                                                <span class="list-title">{{ $course->created_at }}</span>
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
                        </div> --}}


                        {{-- <div class="modal fade text-left" id="modify{{ $course->CodeMatiere }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                <div class="modal-content">
                                    <form action="{{ route('save_year',['year_id'=>$course->CodeMatiere]) }}" method="POST" enctype="multipart/form-data">
                                    @csrf
                                        <div class="modal-header bg-info">
                                        <h5 class="modal-title white" id="myModalLabel160">Modifier : {{ $course->Libelle }}</h5>
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
                                                <input type="text" name="CodeAnnee" class="form-control" value="{{ $course->CodeMatiere }}">
                                            </div> 
                                            <div class="col-lg-6 col-12">
                                                <label>Libelle</label>
                                                <input type="text" name="Libelle" class="form-control" value="{{ $course->Libelle }}">
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

                        <div class="modal fade text-left" id="delete{{ $course->CodeMatiere }}" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
                            <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
                                <div class="modal-content">
                                    <div class="modal-header bg-danger">
                                        <h5 class="modal-title white" id="myModalLabel160">Supprimmer l'annee scholaire : {{ $course->Libelle }}</h5>
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
                                        <a href="{{ route('delete_year',['year_id'=>$course->CodeMatiere]) }}" class="btn btn-danger ml-1">
                                            <i class="bx bx-check d-block d-sm-none"></i>
                                            <span class="d-none d-sm-block">Oui, Suprimmer</span>
                                        </a>
                                    </div>
                                </div>
                            </div>
                        </div> --}}
                    </td>
                </tr>                
                @empty
                <tr><td colspan="4">Aucune matière enregistrée pour cet établissement.</td></tr>
                @endforelse


            </tbody>
        </table>
        </table>
        </div>
    </div>
</div>
@endsection