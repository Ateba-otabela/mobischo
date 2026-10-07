<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Annee;
use App\Models\Eleve;
use App\Models\Classe;
use App\Models\School;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    //
    public function add_user(Request $request)
    {
        $schools = Etablissement::orderBy('Nom')->get();
        $selectedSchoolCode = $request->query('CodeEtablissement');
        $selectedSchool = $selectedSchoolCode
            ? Etablissement::find($selectedSchoolCode)
            : null;
        if ($selectedSchoolCode && !$selectedSchool) {
            return redirect()->route('add_user')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $users = $selectedSchool
            ? User::where('CodeEtablissement', $selectedSchool->CodeEtablissement)
                ->withCount('enfants')
                ->orderBy('nom')
                ->orderBy('prenom')
                ->paginate(25)
                ->appends($request->query())
            : null;

        return view('users.add_user',compact('users','schools', 'selectedSchool'));
    }

    public function edit_user_form($user_id)
    {
        $user = User::with(['enfants', 'encadreurClasses'])->findOrFail($user_id);
        $schools = Etablissement::orderBy('Nom')->get();

        return view('users.partials.edit_user_modal', compact('user', 'schools'));
    }

    public function classes_for_school($school)
    {
        $school = Etablissement::findOrFail($school);

        return response()->json(
            Classe::query()
                ->where('CodeEtablissement', $school->CodeEtablissement)
                ->orderBy('LibelleClasse')
                ->get(['CodeClasse', 'LibelleClasse'])
        );
    }

    public function add_user_complete(Request $request)
    {
        $request->validate([
            'account_type' => 'required|in:administrateur,parent,enseignant,encadreur,principal',
            'password' => 'required|string',
        ]);

        $school = null;
        if ($request->account_type !== 'administrateur') {
            $request->validate([
                'school_id' => 'required|string|exists:etablissements,CodeEtablissement',
            ]);
            $school = Etablissement::findOrFail($request->school_id);
        }

        if ($request->account_type === 'encadreur') {
            $request->validate([
                'class_ids' => 'nullable|array',
                'class_ids.*' => [
                    'required',
                    'string',
                    'distinct',
                    Rule::exists('classes', 'CodeClasse')->where(function ($query) use ($school) {
                        $query->where('CodeEtablissement', $school->CodeEtablissement);
                    }),
                ],
            ]);
        }

        $validated = [];
        if ($request->account_type == 'administrateur') {
            $validated = $request->validate([
                'login' => 'required|unique:users',
                'prenom' => 'required',
                'nom' => 'required',
                'contacts' => 'required',
                'code' => 'required|unique:users',
            ]);
        } elseif ($request->account_type == 'parent') {
            $validated = $request->validate([
                'prenom' => 'required',
                'nom' => 'required',
                'contacts' => 'required',
            ]);
        } elseif ($request->account_type == 'enseignant') {
            $validated = $request->validate([
                'reserve1' => 'required',
                'prenom' => 'required',
                'nom' => 'required',
                'contacts' => 'required',
                'matricule' => 'required',
                'code' => 'required|unique:users',
            ]);
        } elseif (in_array($request->account_type, ['encadreur', 'principal'], true)) {
            $validated = $request->validate([
                'nom' => 'required|string',
                'prenom' => 'required|string',
                'contacts' => 'required|string',
                'sex' => 'required|string',
                'code' => 'required|string|unique:users,code',
            ]);
        }

        DB::transaction(function () use ($request, $school, $validated) {
            $accountType = $request->account_type;
            $code = $validated['code'] ?? (string) $this->generateUniqueUserCode();
            $login = $validated['login'] ?? ($accountType === 'enseignant'
                ? $request->nom . $school->CodeEtablissement
                : (string) $this->generateUniqueUserCode());

            $user = User::create([
                'nom' => $request->nom,
                'prenom' => $request->prenom,
                'account_type' => $accountType,
                'sex' => $request->sex,
                'contacts' => $request->contacts,
                'password' => Hash::make($request->password),
                'text_password' => $request->password,
                'code' => $code,
                'login' => $login,
                'CodeEtablissement' => $school ? $school->CodeEtablissement : null,
                'admin' => $accountType === 'administrateur',
                'reserve1' => $request->reserve1,
                'matricule' => $request->matricule,
            ]);

            if ($accountType === 'encadreur') {
                $this->syncEncadreurClasses($user, $school->CodeEtablissement, $request->input('class_ids', []));
            }
        });

        return redirect('add_user');
    }

    public function save_user(Request $request, $user_id)
    {   
        $user = User::findOrFail($user_id);
        $validated = $request->validate([
            'account_type' => 'required|in:administrateur,parent,enseignant,encadreur,tuteur,principal,principal_encadreur',
            'nom' => 'required|string',
            'prenom' => 'required|string',
            'sex' => 'required|string',
            'login' => 'required|string',
            'code' => ['required', 'string', Rule::unique('users', 'code')->ignore($user_id, 'code')],
            'contacts' => 'required|string',
            'password' => 'required|string',
            'RepPhoto' => 'nullable|image',
        ]);

        $school = null;
        if ($request->account_type != 'administrateur') {
            $request->validate([
                'school_id' => 'required|string|exists:etablissements,CodeEtablissement',
            ]);
            $school = Etablissement::findOrFail($request->school_id);
        }

        if ($request->account_type === 'encadreur') {
            $request->validate([
                'class_ids' => 'nullable|array',
                'class_ids.*' => [
                    'required',
                    'string',
                    'distinct',
                    Rule::exists('classes', 'CodeClasse')->where(function ($query) use ($school) {
                        $query->where('CodeEtablissement', $school->CodeEtablissement);
                    }),
                ],
            ]);
        }

        $oldCode = $user->code;
        DB::transaction(function () use ($request, $user, $school, $oldCode, $validated) {
            $user->nom = $validated['nom'];
            $user->prenom = $validated['prenom'];
            $user->account_type = $validated['account_type'];
            $user->sex = $validated['sex'];
            $user->login = $validated['login'];
            $user->code = $validated['code'];
            $user->contacts = $validated['contacts'];
            $user->text_password = $validated['password'];
            $user->password = Hash::make($validated['password']);
            $user->admin = $validated['account_type'] === 'administrateur';
            if ($school) {
                $user->CodeEtablissement = $school->CodeEtablissement;
            }
            $user->save();

            if ($oldCode !== $user->code) {
                DB::table('encadreur_classes')
                    ->where('code', $oldCode)
                    ->update(['code' => $user->code]);
            }

            if ($validated['account_type'] === 'encadreur') {
                $this->syncEncadreurClasses(
                    $user,
                    $school->CodeEtablissement,
                    $request->input('class_ids', [])
                );
            } else {
                $user->encadreurClasses()->delete();
            }
        });

        if ($request->RepPhoto) {
            $filename = time() . '.' . $request->RepPhoto->extension();
            $user->photo_path = $request->file('RepPhoto')->storeAs(
                'profile_pictures',
                $filename,
                'public'
            );
            $user->save();
        }

        $returnSchool = $request->input('return_school');
        $returnPage = max(1, (int) $request->input('return_page', 1));
        $returnParameters = $returnSchool
            ? ['CodeEtablissement' => $returnSchool, 'page' => $returnPage]
            : [];
        return redirect()
            ->route('add_user', $returnParameters)
            ->with(['message' => "L'utilisateur a été modifié avec succès", 'alert' => 'border-success']);
    }

    private function syncEncadreurClasses(User $user, string $schoolCode, array $classCodes): void
    {
        $classCodes = array_values(array_unique($classCodes));
        $assignments = $user->encadreurClasses();
        $assignments->whereNotIn('CodeClasse', $classCodes)->delete();

        $existingCodes = $user->encadreurClasses()->pluck('CodeClasse')->all();
        $newAssignments = [];
        foreach (array_diff($classCodes, $existingCodes) as $classCode) {
            $newAssignments[] = [
                'code' => $user->code,
                'CodeClasse' => $classCode,
                'CodeEtablissement' => $schoolCode,
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        if ($newAssignments) {
            DB::table('encadreur_classes')->insert($newAssignments);
        }
    }

    private function generateUniqueUserCode(): int
    {
        do {
            $code = random_int(10000000, 99999999);
        } while (User::where('code', $code)->exists());

        return $code;
    }

    public function assign_student_choose_class($parent_id,Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        if (!$school || !User::whereKey($parent_id)->exists()) {
            return redirect()->route('add_user')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un parent et un établissement existants.']);
        }
        $years = Annee::all();

        return view('users.assign_student_choose_class',compact(
            'years',
            'school',
            'parent_id'
        ));

    }
    public function choose_student($parent_id,Request $request)
    {
        $class = Classe::find($request->CodeClasse);
        $annee = Annee::find($request->CodeAnnee);
        $parent = User::find($parent_id);
        if (!$class || !$annee || !$parent) {
            return redirect()->route('add_user')
                ->withErrors(['filters' => 'Le parent, la classe ou l’année scolaire n’existe plus.']);
        }

        $students =  Eleve::select('*')->where('CodeClasse', '=', $class->CodeClasse)->where('CodeAnnee', '=', $annee->CodeAnnee)->get();

        return view('users.choose_student',compact(
            'students',
            'parent'
        ));
    }

    public function assign_student_complete($parent_id, $student_id,$code_annee)
    {
        $parent = User::find($parent_id);
        $student = Eleve::where('CodeEleve','=',$student_id)->where('CodeAnnee','=',$code_annee)->first();
        if (!$parent || !$student || !$student->classe || !$student->classe->etablissement) {
            return redirect()->route('add_user')
                ->withErrors(['student' => 'Le parent, l’élève ou ses informations de classe/établissement sont introuvables.']);
        }

        $student->code = $parent->code;
        $student->save();
        // dd($student->parent);

        $parent->login = $parent->nom.$student->classe->etablissement->CodeEtablissement.$student->CodeClasse.$student->CodeEleve;
        $parent->save();
        
        return redirect('add_user')->with(['message'=>"L'eleve ".$student->Nom." ".$student->Prenom." a été assigné avec succès a ".$parent->nom." ".$parent->prenom,'alert'=>'border-success']);
        
    }

    public function remove_student($parent_id, $student_id)
    {
        $parent = User::findOrFail($parent_id);
        $student = Eleve::findOrFail($student_id);
        $student->code = NULL;
        $student->save();
        
        return redirect('add_user')->with(['message'=>"L'eleve ".$student->Nom." ".$student->Prenom." a été enlevé avec succès a ".$parent->nom." ".$parent->prenom,'alert'=>'border-success']);
    }

    public function import_users(Request $request)
    {
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 32, 32, [
            'code', 'nom', 'prenom', 'DateDeNaissance', 'LieuDeNaissance', 'nationalite',
            'sex', 'DatePriseService', 'login', 'contacts', 'cdegrade', 'nbrand',
            'matricule', 'reserve1', 'reserve2', 'reserve3', 'reserve4', 'reserve5',
            'reserve6', 'cat', 'echel', 'statut', 'reserve7', 'reserve8', 'reserve9',
            'CodeBank', 'numcpt', 'ribcpt', 'TauhH', 'syndicat', 'NumAssure',
            'CodeEtablissement',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
            2 => 'required|string|max:255',
            3 => 'nullable|string|max:255',
            4 => 'nullable|string|max:255',
            5 => 'nullable|string|max:255',
            6 => 'required|string|max:255',
            7 => 'nullable|string|max:255',
            8 => 'required|string|max:255',
            9 => 'required|string|max:255',
            10 => 'nullable|string|max:255',
            11 => 'nullable|integer',
            12 => 'nullable|string|max:255',
            13 => 'nullable|string|max:255',
            14 => 'nullable|string|max:255',
            15 => 'nullable|string|max:255',
            16 => 'nullable|string|max:255',
            17 => 'nullable|string|max:255',
            18 => 'nullable|string|max:255',
            19 => 'nullable|string|max:255',
            20 => 'nullable|string|max:255',
            21 => 'nullable|string|max:255',
            22 => 'nullable|string|max:255',
            23 => 'nullable|string|max:255',
            24 => 'nullable|string|max:255',
            25 => 'nullable|string|max:255',
            26 => 'nullable|string|max:255',
            27 => 'nullable|string|max:255',
            28 => 'nullable|string|max:255',
            29 => 'nullable|string|max:255',
            30 => 'nullable|string|max:255',
            31 => 'nullable|string|max:255',
        ]);

        foreach ($rows as $index => $row) {
            if ($row[31] !== '' && !Etablissement::where('CodeEtablissement', $row[31])->exists()) {
                return redirect('add_user')
                    ->withErrors(['csv_file' => 'L’établissement de la ligne '.($index + 1).' n’existe pas.']);
            }
        }

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                $user = User::firstOrNew(['code' => $data[0]]);
                $user->forceFill([
                        'nom' => $data[1],
                        'prenom' => $data[2],
                        'DateDeNaissance' => $data[3],
                        'LieuDeNaissance' => $data[4],
                        'nationalite' => $data[5],
                        'sex' => $data[6],
                        'DatePriseService' => $data[7],
                        'login' => $data[8],
                        'contacts' => $data[9],
                        'cdegrade' => $data[10],
                        'nbrand' => $data[11] === null || $data[11] === '' ? null : (int) $data[11],
                        'matricule' => $data[12],
                        'reserve1' => $data[13],
                        'reserve2' => $data[14],
                        'reserve3' => $data[15],
                        'reserve4' => $data[16],
                        'reserve5' => $data[17],
                        'reserve6' => $data[18],
                        'cat' => $data[19],
                        'echel' => $data[20],
                        'statut' => $data[21],
                        'reserve7' => $data[22],
                        'reserve8' => $data[23],
                        'reserve9' => $data[24],
                        'CodeBank' => $data[25],
                        'numcpt' => $data[26],
                        'ribcpt' => $data[27],
                        'TauhH' => $data[28],
                        'syndicat' => $data[29],
                        'NumAssure' => $data[30],
                        'CodeEtablissement' => $data[31] === '' ? null : $data[31],
                        'password' => '$2y$10$JuTQ/qgM75boawWtIg4VxOR7Wxlq9pliljVAaLsQlo1n1AuvOXqRW',
                        'text_password' => '00000000',
                ]);
                $user->save();
            }
        });

        return redirect('add_user')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

}
