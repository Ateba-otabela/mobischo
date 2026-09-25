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
                        Liste des traches de scholarite
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
            <table class="table table-striped table-hover zero-configuration">
                <thead>
                    <tr>
                        <th>Code</th>
                        <th>Libellet</th>
                        <th>Date de creation</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    
                    @forelse ($school->tranches as $tranche)
                    <tr>
                        <td>
                            {{ $tranche->code }}
                        </td>
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
                                    <span class="list-title">{{ $tranche->libellet }}</span>
                                   
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="media-body">
                                <h6 class="media-heading mb-0">{{ $tranche->created_at }}</h6>
                            </div>
                        </td>
                        
                        <td class="text-center py-1">
                            <div class="dropdown">
                                <span class="bx bx-dots-vertical-rounded font-medium-3 dropdown-toggle nav-hide-arrow cursor-pointer" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" role="menu"></span>
                                <div class="dropdown-menu dropdown-menu-right">
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#details{{ $tranche->code }}"><i class="bx bxs-bar-chart-alt-2 mr-1"></i>Details</a>
                                    <a class="dropdown-item" href="#" data-toggle="modal" data-target="#modify{{ $tranche->code }}"><i class="bx bx-edit-alt mr-1"></i>Modifier</a>
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