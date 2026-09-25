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

<!-- users view start -->
<section class="users-view">
    <!-- users view media object start -->
    <div class="row">
        <div class="col-12 col-sm-7">
            <div class="media mb-2">
                <a class="mr-1" href="#">
                    <img src="../../../app-assets/images/portrait/small/avatar-s-11.jpg" alt="users view avatar" class="users-avatar-shadow rounded-circle" height="64" width="64">
                </a>
                <div class="media-body pt-25">
                    <h4 class="media-heading"><span class="users-view-name">
                        @auth
                            {{ Auth::user()->nom }}  {{ Auth::user()->prenom }}
                        @endauth
                    </span><span class="text-muted font-medium-1"> @</span><span class="users-view-username text-muted font-medium-1 ">
                        
                        @auth
                        {{ Auth::user()->login }}
                        @endauth

                    </span></h4>
                    <span>Compte:</span>
                    <span class="users-view-id">
                        @auth
                        {{ Auth::user()->account_type }}
                            
                        @endauth
                    </span>
                </div>
            </div>
        </div>
        <div class="col-12 col-sm-5 px-0 d-flex justify-content-end align-items-center px-1 mb-2">
            {{-- <a href="#" class="btn btn-sm mr-25 border"><i class="bx bx-envelope font-small-3"></i></a> --}}
            <a href="#" class="btn btn-sm mr-25 btn-outline-primary" data-toggle="modal" data-target="#primary">Changer mot de passe</a>
            <a href="#" class="btn btn-sm btn-primary">Mofifier</a>
        </div>
    </div>





    <div class="modal fade text-left" id="primary" tabindex="-1" role="dialog" aria-labelledby="myModalLabel160" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable" role="document">
            <div class="modal-content">

                <form action="{{ route('update_password') }}" method="POST">
                    @csrf
                <div class="modal-header bg-primary">
                    <h5 class="modal-title white" id="myModalLabel160">Modifier votre mot de passe</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <i class="bx bx-x"></i>
                    </button>
                </div>
                <div class="modal-body">
                    Entrez le nouveau mot de passe puis validez
                    <hr class="line">
                    
                    <div class="row">
                        <div class="col-lg-4 col-12">
                            <label>Mot de passe</label>
                            <input type="password" name="old_password" class="form-control">
                            @error('old_password')
                                    <span class="text-danger">{{ $message }}</span>
                                @enderror
                        </div>
                        <div class="col-lg-4 col-12">
                            <label>Nouveaux mot de passe</label>
                            <input type="password" name="new_password" class="form-control">
                            @error('new_password')
                                    <span class="text-danger">{{ $message }}</span>
                                @enderror
                        </div> 
                        <div class="col-lg-4 col-12">
                            <label>Confirmez mot de passe</label>
                            <input type="password" name="new_password_confirmation" class="form-control" >
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
                        <span class="d-none d-sm-block">Modifier</span>
                    </button>
                </div>
                </form>

            </div>
        </div>
    </div>




    <!-- users view media object ends -->
    <!-- users view card data start -->
    <div class="card">
        <div class="card-content">
            <div class="card-body">
                <div class="row">
                    <div class="col-12">
                        <table class="table table-borderless">
                            <tbody>
                                <tr>
                                    <td>Code:</td>
                                    <td class="users-view-username">
                                        {{ Auth::user()->code }}
                                    </td>
                                </tr>
                                <tr>
                                    <td>Nom:</td>
                                    <td class="users-view-username">
                                        {{ Auth::user()->nom }}
                                    </td>
                                </tr>
                                <tr>
                                    <td>Prenom:</td>
                                    <td class="users-view-name">
                                        {{ Auth::user()->prenom }}
                                    </td>
                                </tr>
                                <tr>
                                    <td>Genre:</td>
                                    <td class="users-view-email">
                                        
                                        @if(Auth::user()->sex == '0')
                                        Masculin
                                        @else
                                        Feminin
                                        @endif
                                        
                                    </td>
                                </tr>
                                <tr>
                                    <td>Contacts:</td>
                                    <td>
                                       +237  {{ Auth::user()->contacts }}
                                    </td>
                                </tr>
    
                            </tbody>
                        </table>
                        
                        
                    </div>
                    
                </div>
            </div>
        </div>
    </div>
    <!-- users view card data ends -->
    <!-- users view card details start -->
    {{-- <div class="card">
        <div class="card-content">
            <div class="card-body">
                <div class="row bg-primary bg-lighten-5 rounded mb-2 mx-25 text-center text-lg-left">
                    <div class="col-12 col-sm-4 p-2">
                        <h6 class="text-primary mb-0">Posts: <span class="font-large-1 align-middle">125</span></h6>
                    </div>
                    <div class="col-12 col-sm-4 p-2">
                        <h6 class="text-primary mb-0">Followers: <span class="font-large-1 align-middle">534</span></h6>
                    </div>
                    <div class="col-12 col-sm-4 p-2">
                        <h6 class="text-primary mb-0">Following: <span class="font-large-1 align-middle">256</span></h6>
                    </div>
                </div>
                
            </div>
        </div>
    </div> --}}
    <!-- users view card details ends -->

</section>
<!-- users view ends -->
@endsection