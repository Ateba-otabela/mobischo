@extends('layouts.app')

@section('body')

<div class="row">
    <div class="col-xl-4 col-md-4 col-12 dashboard-greetings">
        
        <div class="col-12 dashboard-users-success">
            <div class="card">
                <div class="card-body d-flex align-items-center justify-content-between">
                    <div class="d-flex align-items-center">
                        <div class="avatar bg-rgba-primary m-0 p-25 mr-75 mr-xl-2">
                            <div class="avatar-content">
                                <i class="bx bxs-school text-primary font-medium-2"></i>
                            </div>
                        </div>
                        <div class="total-amount">
                            <h5 class="mb-0">{{ $schools->count() }}</h5>
                            <small class="text-muted">Etablissements</small>
                        </div>
                    </div>
                    <div id="primary-line-chart"></div>
                </div>
            </div>
            <div class="card">
                <div class="card-body d-flex align-items-center justify-content-between">
                    <div class="d-flex align-items-center">
                        <div class="avatar bg-rgba-warning m-0 p-25 mr-75 mr-xl-2">
                            <div class="avatar-content">
                                <i class="bx bx-user text-warning font-medium-2"></i>
                            </div>
                        </div>
                        <div class="total-amount">
                            <h5 class="mb-0">{{ $students->count() }}</h5>
                            <small class="text-muted">Eleves</small>
                        </div>
                    </div>
                    <div id="warning-line-chart"></div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Website Analytics Starts-->
    <div class="col-md-8 col-sm-12 col-xl-8">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h4 class="card-title">Statistiques du system</h4>
                <i class="bx bx-dots-vertical-rounded font-medium-3 cursor-pointer"></i>
            </div>
            <div class="card-content">
                <div class="card-body pb-1">
                    <div class="d-flex justify-content-around align-items-center flex-wrap">
                        <div class="user-analytics">
                            <i class="bx bx-user mr-25 align-middle"></i>
                            <span class="align-middle text-muted">Administrateurs</span>
                            <div class="d-flex pt-2">
                                <div id="radial-success-chart"></div>
                                <h3 class="mt-1 ml-50">{{ $administrateurs->count() }}</h3>
                            </div>
                        </div>
                        <div class="sessions-analytics">
                            <i class="bx bx-trending-up align-middle mr-25"></i>
                            <span class="align-middle text-muted">Parents</span>
                            <div class="d-flex pt-2">
                                <div id="radial-warning-chart"></div>
                                <h3 class="mt-1 ml-50">{{ $parents->count() }}</h3>
                            </div>
                        </div>
                        <div class="bounce-rate-analytics">
                            <i class="bx bx-pie-chart-alt align-middle mr-25"></i>
                            <span class="align-middle text-muted">Enseignants</span>
                            <div class="d-flex pt-2">
                                <div id="radial-danger-chart"></div>
                                <h3 class="mt-1 ml-50">{{ $enseignants->count() }}</h3>
                            </div>
                        </div>
                        <div class="bounce-rate-analytics">
                            <i class="bx bx-pie-chart-alt align-middle mr-25"></i>
                            <span class="align-middle text-muted">Encardreurs</span>
                            <div class="d-flex pt-2">
                                <div id="profit-primary-chart"></div>
                                <h3 class="mt-1 ml-50">{{ $encardreurs->count() }}</h3>
                            </div>
                        </div>
                    </div>
                    
                </div>
            </div>
        </div>
        
    </div>
    
    
</div>

@endsection