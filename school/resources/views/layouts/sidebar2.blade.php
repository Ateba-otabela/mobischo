    <!-- BEGIN: Main Menu-->

    <div class="main-menu menu-fixed menu-dark menu-accordion menu-shadow" data-scroll-to-active="true">
        <div class="navbar-header">
            <ul class="nav navbar-nav flex-row">
                <li class="nav-item mr-auto"><a class="navbar-brand" href="{{ route('home') }}">
                        <div class="brand-logo"><img class="logo" src="../../../app-assets/images/logo/logo.png" /></div>
                        <h2 class="brand-text mb-0">SchoolManager</h2>
                    </a></li>
                <li class="nav-item nav-toggle"><a class="nav-link modern-nav-toggle pr-0" data-toggle="collapse"><i class="bx bx-x d-block d-xl-none font-medium-4 primary"></i><i class="toggle-icon bx bx-disc font-medium-4 d-none d-xl-block primary" data-ticon="bx-disc"></i></a></li>
            </ul>
        </div>
        <div class="shadow-bottom" style="background: linear-gradient(180deg, #1a233af0 44%, #1a233abf 73%, #2c303c00);"></div>
        <div class="main-menu-content">
            <ul class="navigation navigation-main" id="main-menu-navigation" data-menu="menu-navigation" data-icon-style="lines">
                <li class=" nav-item"><a href="{{ route('home') }}"><i class="menu-livicon" data-icon="desktop"></i><span class="menu-title" data-i18n="Dashboard">Accueil</span><span class="badge badge-primary badge-pill badge-round float-right mr-2">2</span></a>
                    <ul class="menu-content">
                        <li class="active"><a href="{{ route('home') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="eCommerce">Accueil</span></a>
                            <li><a href="{{ route('add_school') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Analytics">Etablissements</span></a>
                            </li>
                        </li>
                    </ul>
                </li>


                <li class=" navigation-header"><span>Vos Fonctionnalités</span>
                </li>

                <li class=" nav-item"><a href="{{ route('add_school') }}">
                    <i class="menu-livicon" data-icon="building"></i>
                    <span class="menu-title" data-i18n="Colors">Etablissements</span></a>
                </li>
                <li class=" nav-item"><a href="{{ route('add_user') }}">
                    <i class="menu-livicon" data-icon="user"></i>
                    <span class="menu-title" data-i18n="Colors">Utilisateurs</span></a>
                </li>
                <li class=" nav-item"><a href="{{ route('add_student_home') }}">
                    <i class="menu-livicon" data-icon="users"></i>
                    <span class="menu-title" data-i18n="Colors">Eleves</span></a>
                </li>
                <li class=" nav-item"><a href="#"><i class="menu-livicon" data-icon="notebook"></i><span class="menu-title" data-i18n="Invoice">Academique</span></a>
                    <ul class="menu-content">
                        <li><a href="{{ route('add_class') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice List">Classes</span></a>
                        </li>
                       
                        <li><a href="{{ route('course_home') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice">Matieres</span></a>
                        </li>
                        <li><a href="{{ route('notes_home') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice List">Notes</span></a>
                        </li>
                        <li><a href="{{ route('enseignement_home') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice">Enseignements</span></a>
                        </li>
                        <li><a href="#"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice">Conduites</span></a>
                        </li>
                    </ul>
                </li>

                <li class=" nav-item"><a href="#"><i class="menu-livicon" data-icon="briefcase"></i><span class="menu-title" data-i18n="Invoice">Administration</span></a>
                    <ul class="menu-content">
                        <li><a href="{{ route('add_year') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice List">Annees</span></a>
                        </li>
                        <li><a href="{{ route('tranches_scholarites_home') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice List">Tranches Scholarite</span></a>
                        </li>
                        <li><a href="{{ route('inscriptions_home') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice List">Inscriptions</span></a>
                        </li>
                        <li><a href="{{ route('historique_inscriptions_home') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice List">Historique Inscriptions</span></a>

                        <li><a href="{{ route('sequence_evaluation') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice">Sequence Evaluation</span></a>
                        </li>
                        <li><a href="{{ route('add_year') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice List">Historique d'inscriptions</span></a>
                        </li>
                    </ul>
                </li>

                <li class=" nav-item"><a href="#"><i class="menu-livicon" data-icon="user"></i><span class="menu-title" data-i18n="Invoice">Mon Compte</span></a>
                    <ul class="menu-content">
                        <li><a href="{{ route('myaccount') }}"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice List">Mon Profil</span></a>
                        </li>
                        <li>
                            <a href="#" onclick="event.preventDefault();document.getElementById('logout-form').submit();"><i class="bx bx-right-arrow-alt"></i><span class="menu-item" data-i18n="Invoice">Deconnextion</span></a>
                            <form id="logout-form" action="{{ route('logout') }}" method="POST" class="d-none">
                                @csrf
                            </form>
                        </li>
                        
                    </ul>
                </li>
                
            </ul>
        </div>
    </div>
    

                    <!-- END: Main Menu-->