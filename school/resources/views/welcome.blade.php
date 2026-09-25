{{-- @extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">{{ __('Login') }}</div>
                
                <div class="card-body">
                    <form method="POST" action="{{ route('login') }}">
                        @csrf
                        
                        <div class="row mb-3">
                            <label for="phone" class="col-md-4 col-form-label text-md-end">{{ __('Phone Number') }}</label>
                            
                            <div class="col-md-6">
                                <input id="phone" type="text" class="form-control @error('phone') is-invalid @enderror" name="phone" value="{{ old('phone') }}" required autofocus autofocus>
                                
                                @error('phone')
                                <span class="invalid-feedback" role="alert">
                                    <strong>{{ $message }}</strong>
                                </span>
                                @enderror
                            </div>
                        </div>
                        
                        <div class="row mb-3">
                            <label for="password" class="col-md-4 col-form-label text-md-end">{{ __('Password') }}</label>
                            
                            <div class="col-md-6">
                                <input id="password" type="password" class="form-control @error('password') is-invalid @enderror" name="password" required autocomplete="current-password">
                                
                                @error('password')
                                <span class="invalid-feedback" role="alert">
                                    <strong>{{ $message }}</strong>
                                </span>
                                @enderror
                            </div>
                        </div>
                        
                        <div class="row mb-3">
                            <div class="col-md-6 offset-md-4">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" name="remember" id="remember" {{ old('remember') ? 'checked' : '' }}>
                                    
                                    <label class="form-check-label" for="remember">
                                        {{ __('Remember Me') }}
                                    </label>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row mb-0">
                            <div class="col-md-8 offset-md-4">
                                <button type="submit" class="btn btn-primary">
                                    {{ __('Login') }}
                                </button>
                                
                                @if (Route::has('password.request'))
                                <a class="btn btn-link" href="{{ route('password.request') }}">
                                    {{ __('Forgot Your Password?') }}
                                </a>
                                @endif
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection --}}



<!DOCTYPE html>
<html class="loading" lang="en" data-textdirection="ltr">
<!-- BEGIN: Head-->

<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=0">
    <meta name="description" content="Frest admin is super flexible, powerful, clean &amp; modern responsive bootstrap 4 admin template with unlimited possibilities.">
    <meta name="keywords" content="admin template, Frest admin template, dashboard template, flat admin template, responsive admin template, web app">
    <meta name="author" content="PIXINVENT">
    <title>MOBISCHO - Systeme de Gestion des ecoles</title>
    <link rel="apple-touch-icon" href="{{  url('/app-assets/images/ico/apple-icon-120.png')}}">
    <link rel="shortcut icon" type="image/x-icon" href="{{  url('/app-assets/images/ico/favicon.ico')}}">
    <link href="https://fonts.googleapis.com/css?family=Rubik:300,400,500,600%7CIBM+Plex+Sans:300,400,500,600,700" rel="stylesheet">
    
    <!-- BEGIN: Vendor CSS-->
    <link rel="stylesheet" type="text/css" href="{{  url('/app-assets/vendors/css/vendors.min.css') }}">
    <!-- END: Vendor CSS-->
    
    <!-- BEGIN: Theme CSS-->
    <link rel="stylesheet" type="text/css" href="{{  url('/app-assets/css/bootstrap.css') }}">
    <link rel="stylesheet" type="text/css" href="{{  url('/app-assets/css/bootstrap-extended.css') }}">
    <link rel="stylesheet" type="text/css" href="{{  url('/app-assets/css/colors.css') }}">
    <link rel="stylesheet" type="text/css" href="{{  url('/app-assets/css/components.css') }}">
    <link rel="stylesheet" type="text/css" href="{{  url('/app-assets/css/themes/dark-layout.css') }}">
    <link rel="stylesheet" type="text/css" href="{{  url('/app-assets/css/themes/semi-dark-layout.css') }}">
    <!-- END: Theme CSS-->
    
    <!-- BEGIN: Page CSS-->
    <link rel="stylesheet" type="text/css" href="{{  url('/app-assets/css/core/menu/menu-types/vertical-menu.css') }}">
    <link rel="stylesheet" type="text/css" href="{{  url('/app-assets/css/pages/authentication.css') }}">
    <!-- END: Page CSS-->
    
    <!-- BEGIN: Custom CSS-->
    <link rel="stylesheet" type="text/css" href="{{  url('/assets/css/style.css') }}">
    <!-- END: Custom CSS-->
</head>
<!-- END: Head-->

<!-- BEGIN: Body-->

<body class="vertical-layout vertical-menu-modern semi-dark-layout 1-column  navbar-sticky footer-static bg-full-screen-image  blank-page blank-page" data-open="click" data-menu="vertical-menu-modern" data-col="1-column" data-layout="semi-dark-layout">
    <!-- BEGIN: Content-->
    <div class="app-content content">
        <div class="content-overlay"></div>
        <div class="content-wrapper">
            <div class="content-header row">
            </div>
            <div class="content-body">
                <!-- login page start -->
                <section id="auth-login" class="row flexbox-container">
                    <div class="col-xl-8 col-11">
                        <div class="card bg-authentication mb-0">
                            <div class="row m-0">
                                <!-- left section-login -->
                                <div class="col-md-6 col-12 px-0">
                                    <div class="card disable-rounded-right mb-0 p-2 h-100 d-flex justify-content-center">
                                        <div class="card-header pb-1">
                                            <div class="card-title">
                                                <h1 class="text-center mb-2">MOBISCHO</h1>
                                            </div>
                                        </div>
                                        <div class="card-content">
                                            <div class="card-body">
                                                
                                                
                                                <div class="divider">
                                                    <div class="divider-text text-uppercase text-muted">
                                                        <small>Bienvenue sur MOBISCHO, connectez-vous</small>
                                                    </div>
                                                </div>
                                                
                                                @if (Route::has('login'))
                                                <div class="">
                                                    @auth
                                                    {{-- <div class="row"> --}}
                                                        <div class="col-12 text-center">
                                                            <a href="{{ url('/home') }}" class="btn btn-primary btn-block">Home</a>
                                                        </div>
                                                    {{-- </div> --}}
                                                    @else
                                                    
                                                    <div class="row">
                                                        <div class="col-lg-6 col-12">
                                                            <a href="{{ route('login') }}" class="btn btn-primary btn-block">Log in</a>
                                                            
                                                        </div>
                                                        
                                                        <div class="col-lg-6 col-12">
                                                            @if (Route::has('register'))
                                                            <a href="{{ route('register') }}" class="btn btn-outline-primary btn-block">Register</a>
                                                            @endif
                                                        </div>
                                                        
                                                    </div>
                                                    
                                                    
                                                    
                                                    @endauth
                                                </div>
                                                @endif
                                                
                                                <hr>
                                                
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <!-- right section image -->
                                <div class="col-md-6 d-md-block d-none text-center align-self-center p-3">
                                    <div class="card-content">
                                        <img class="img-fluid" src="../../../app-assets/images/pages/login.png" alt="branding logo">
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
                <!-- login page ends -->
                
            </div>
        </div>
    </div>
    <!-- END: Content-->
    
    
    <!-- BEGIN: Vendor JS-->
    <script src="{{  url('/app-assets/vendors/js/vendors.min.js')}}"></script>
    <script src="{{  url('/app-assets/fonts/LivIconsEvo/js/LivIconsEvo.tools.js')}}"></script>
    <script src="{{  url('/app-assets/fonts/LivIconsEvo/js/LivIconsEvo.defaults.js')}}"></script>
    <script src="{{  url('/app-assets/fonts/LivIconsEvo/js/LivIconsEvo.min.js')}}"></script>
    <!-- BEGIN Vendor JS-->
    
    <!-- BEGIN: Page Vendor JS-->
    <!-- END: Page Vendor JS-->
    
    <!-- BEGIN: Theme JS-->
    <script src="{{  url('/app-assets/js/scripts/configs/vertical-menu-dark.js')}}"></script>
    <script src="{{  url('/app-assets/js/core/app-menu.js')}}"></script>
    <script src="{{  url('/app-assets/js/core/app.js')}}"></script>
    <script src="{{  url('/app-assets/js/scripts/components.js')}}"></script>
    <script src="{{  url('/app-assets/js/scripts/footer.js')}}"></script>
    <!-- END: Theme JS-->
    
    <!-- BEGIN: Page JS-->
    
</body>
<!-- END: Body-->

</html>
