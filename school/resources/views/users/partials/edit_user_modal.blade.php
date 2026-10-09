<div class="modal-header bg-info">
    <h5 class="modal-title white">
        Modifier :
        @if ($user->sex == '0')
            Mr.
        @else
            Mme.
        @endif
        <span class="text-uppercase">{{ $user->nom }} {{ $user->prenom }}</span>
    </h5>
    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
        <i class="bx bx-x"></i>
    </button>
</div>
<div class="modal-body">
    <form id="user-edit-form" class="user-edit-form" action="{{ route('save_user', ['user_id' => $user->code]) }}" method="POST" enctype="multipart/form-data">
        @csrf
        Remplissez le formulaire ci-dessous et validez
        <hr class="line">
        <input type="hidden" name="user_id" value="{{ $user->code }}">
        <input type="hidden" name="return_school" value="{{ request('CodeEtablissement') }}">
        <input type="hidden" name="return_page" value="{{ request('page', 1) }}">

        <div class="row pb-1">
            <div class="col-lg-4 col-12">
                <label>Noms</label>
                <input type="text" name="nom" class="form-control" value="{{ $user->nom }}">
            </div>
            <div class="col-lg-4 col-12">
                <label>Prenoms</label>
                <input type="text" name="prenom" class="form-control" value="{{ $user->prenom }}">
            </div>
            <div class="col-lg-4 col-12">
                <label>Profil</label>
                <select name="account_type" class="form-control js-user-account-type" data-user-id="{{ $user->code }}">
                    @foreach ([
                        'administrateur' => 'Administrateur',
                        'enseignant' => 'Enseignant',
                        'parent' => 'Parent',
                        'encadreur' => 'Encadreur',
                        'principal' => 'Principal',
                        'principal_encadreur' => 'Principal / Encadreur',
                        'tuteur' => 'Tuteur (ancien type)',
                    ] as $type => $label)
                        <option value="{{ $type }}" {{ $user->account_type === $type ? 'selected' : '' }}>{{ $label }}</option>
                    @endforeach
                    @if (!in_array($user->account_type, ['administrateur', 'enseignant', 'parent', 'encadreur', 'principal', 'principal_encadreur', 'tuteur'], true))
                        <option value="{{ $user->account_type }}" selected>{{ $user->account_type }}</option>
                    @endif
                </select>
            </div>
        </div>
        <div class="row pb-1">
            <div class="col-lg-4 col-12">
                <label>Genre</label>
                <select name="sex" class="form-control">
                    <option value="0" {{ $user->sex == '0' ? 'selected' : '' }}>Masculin</option>
                    <option value="1" {{ $user->sex != '0' ? 'selected' : '' }}>Feminin</option>
                </select>
            </div>
            <div class="col-lg-4 col-12">
                <label>Contacts</label>
                <input type="text" name="contacts" class="form-control" value="{{ $user->contacts }}">
            </div>
            <div class="col-lg-4 col-12">
                <label>Photo de Profil</label>
                <input type="file" name="RepPhoto" class="form-control" accept="*">
            </div>
        </div>
        <div class="row pb-1">
            <div class="col-lg-4 col-12">
                <label>Code</label>
                <input type="text" name="code" class="form-control" value="{{ $user->code }}">
            </div>
            <div class="col-lg-4 col-12">
                <label>Login</label>
                <input type="text" class="form-control" name="login" value="{{ $user->login }}">
            </div>
            <div class="col-lg-4 col-12">
                <label>Mot de passe</label>
                <input type="text" value="{{ $user->text_password }}" class="form-control" name="password" required autocomplete="new-password">
            </div>
        </div>
        <div class="row {{ $user->account_type === 'administrateur' ? 'd-none' : '' }}" id="display_school{{ $user->code }}">
            <div class="col-12">
                <label>Etablissement {{ $user->CodeEtablissement }}</label>
                <select name="school_id" class="text-center form-control js-encadreur-school" data-user-id="{{ $user->code }}">
                    @foreach ($schools as $school)
                        <option value="{{ $school->CodeEtablissement }}" {{ $user->CodeEtablissement == $school->CodeEtablissement ? 'selected' : '' }}>{{ $school->Nom }}</option>
                    @endforeach
                </select>
            </div>
        </div>
        <div class="form-group pt-1 js-encadreur-classes-row {{ in_array($user->account_type, ['encadreur', 'enseignant'], true) ? '' : 'd-none' }}"
             id="encadreur-classes-row-{{ $user->code }}"
             data-selected-classes="{{ $user->encadreurClasses->pluck('CodeClasse')->toJson() }}">
            <label>Classes attribuées</label>
            <div class="js-encadreur-classes-list"
                 data-user-id="{{ $user->code }}"
                 data-classes-url="{{ route('admin.users.classes', ['school' => '__SCHOOL__']) }}">
                <span class="text-muted">Chargement des classes...</span>
            </div>
        </div>
        <hr class="line">
        @foreach ($user->enfants as $student)
            <div class="row pb-1">
                <div class="col-lg-8 col-12">
                    <div class="list-left d-flex">
                        <div class="list-icon mr-1">
                            <div class="avatar bg-rgba-info m-0">
                                <div class="avatar-content">
                                    <i class="bx bxs-zap text-info font-size-base"></i>
                                </div>
                            </div>
                        </div>
                        <div class="list-content">
                            <span class="list-title">{{ $student->Nom }} {{ $student->Prenom }}</span>
                            <small class="text-muted d-block">Code Eleve : {{ $student->CodeEleve }}</small>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4 col-12 text-right">
                    <a href="{{ route('remove_student', ['parent_id' => $user->code, 'student_id' => $student->CodeEleve]) }}" class="btn btn-info">Retirer</a>
                </div>
            </div>
        @endforeach
    </form>
</div>
<div class="modal-footer">
    <button type="button" class="btn btn-light-secondary" data-dismiss="modal">
        <i class="bx bx-x d-block d-sm-none"></i>
        <span class="d-none d-sm-block">Annuler</span>
    </button>
    <button type="submit" form="user-edit-form" class="btn btn-info ml-1">
        <i class="bx bx-check d-block d-sm-none"></i>
        <span class="d-none d-sm-block">Sauvegarder</span>
    </button>
</div>
