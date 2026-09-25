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
use Illuminate\Support\Facades\Storage;

class UserController extends Controller
{
    //
    public function add_user()
    {
        $users = User::all();
        $schools = Etablissement::all();
        // foreach($users as $user){
        //     $student->code = NULL;
        //     $student->save();
        // }
        // return response()->json($users);
        return view('users.add_user',compact('users','schools'));
    }
    public function add_user_complete(Request $request)
    {
        function GenerateUserCode(){
            $number = mt_rand(10000000, 99999999); // better than rand()
            $number = abs($number);
            if (UserCodeExists($number)){
                return GenerateUserCode();
            }
            $a = (int)$number;
            return abs($a);
        }
        
        function UserCodeExists($code){
            return User::wherecode($code)->exists();
        }

        $school = Etablissement::find($request->school_id);
        if ($request->account_type == 'administrateur'){
            
            $validated = $request->validate([
                'login' => 'required|unique:users',
                'prenom' => 'required',
                'nom' => 'required',
                'contacts' => 'required',
                'code' => 'required|unique:users',
            ]);

            $new_user = User::create([
                'nom'=>$request->nom,
                'prenom'=>$request->prenom,
                'account_type'=>$request->account_type,
                'sex'=>$request->sex,
                'contacts'=>$request->contacts,
                'password'=>Hash::make($request->password),
                'text_password'=>$request->password,
                'code'=>$request->code,
                'login'=>$request->login
            ]);
        }
        else if ($request->account_type == 'parent'){
            
            $validated = $request->validate([
              
                'prenom' => 'required',
                'nom' => 'required',
                'contacts' => 'required',
               
            ]);

            $new_user = User::create([
                'nom'=>$request->nom,
                'prenom'=>$request->prenom,
                'account_type'=>$request->account_type,
                'sex'=>$request->sex,
                'contacts'=>$request->contacts,
                'password'=>Hash::make($request->password),
                'text_password'=>$request->password,
                'login'=>GenerateUserCode(),
                'code'=>GenerateUserCode()
            ]);
        }
        else  if ($request->account_type == 'enseignant'){
            $validated = $request->validate([
                'reserve1' => 'required',
                'prenom' => 'required',
                'nom' => 'required',
                'contacts' => 'required',
                'matricule' => 'required',
                'code' => 'required|unique:users',
            ]);

            $new_user = User::create([
                'nom'=>$request->nom,
                'prenom'=>$request->prenom,
                'account_type'=>$request->account_type,
                'sex'=>$request->sex,
                'login'=>$request->nom.$school->CodeEtablissement,
                'contacts'=>$request->contacts,
                'password'=>Hash::make($request->password),
                'text_password'=>$request->password,
                'reserve1'=>$request->reserve1,
                'matricule'=>$request->matricule,
                'code'=>$request->code,
            ]);

        }

        $new_user->save();
        if ($request->account_type == 'administrateur'){
            $new_user->admin = True;
            $new_user->save();
        }
        else if ($request->account_type == 'enseignant' or 'parent'){
            $new_user->CodeEtablissement = $school->CodeEtablissement;
            $new_user->save();
        }
        else if ($request->account_type == 'parent'){
            $new_user->addresse = $request->adresse;
        }

        return redirect('add_user');
    }

    public function save_user(Request $request, $user_id)
    {   
        $user = User::find($user_id);
        $user->nom = $request->nom;
        $user->prenom = $request->prenom;
        $user->account_type = $request->account_type;
        $user->sex = $request->sex;
        $user->login = $request->login;
        $user->code = $request->code;
        $user->contacts = $request->contacts;
        $user->text_password = $request->password;
        $user->password = Hash::make($request->password);
        $user->save();

        if($user->account_type != 'administrateur'){
            $school = Etablissement::find($request->school_id);
            $user->CodeEtablissement = $school->CodeEtablissement;
            $user->save();
        }

        if($request->RepPhoto){
            $filename = time().'.'.$request->RepPhoto->extension();
            $path = $request->file('RepPhoto')->storeAs(
                'profile_pictures',
                $filename,
                'public'
            );
            $user->photo_path=$path;
        }
        if ($request->account_type == 'administrateur'){
            $user->admin = True;
            $user->save();
        }
        else{
            $user->admin = False;
            $user->save();
        }

        $user->save();

        return \redirect('add_user')->with(['message'=>"L'utilisateur a été modifié avec succès",'alert'=>'border-success']);
    }

    public function assign_student_choose_class($parent_id,Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
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
        $all_students = Eleve::all();
        // dd($all_students);

        $students =  Eleve::select('*')->where('CodeClasse', '=', $class->CodeClasse)->where('CodeAnnee', '=', $annee->CodeAnnee)->get();
        $parent = User::find($parent_id);
        // $students = $students->toArray();
        // dd($students);

        return view('users.choose_student',compact(
            'students',
            'parent'
        ));
    }

    public function assign_student_complete($parent_id, $student_id,$code_annee)
    {
        $parent = User::find($parent_id);
        $student = Eleve::where('CodeEleve','=',$student_id)->where('CodeAnnee','=',$code_annee)->first();
        $student->code = $parent->code;
        $student->save();
        // dd($student->parent);

        $parent->login = $parent->nom.$student->classe->etablissement->CodeEtablissement.$student->CodeClasse.$student->CodeEleve;
        $parent->save();
        
        return redirect('add_user')->with(['message'=>"L'eleve ".$student->Nom." ".$student->Prenom." a été assigné avec succès a ".$parent->nom." ".$parent->prenom,'alert'=>'border-success']);
        
    }

    public function remove_student($parent_id, $student_id)
    {
        $parent = User::find($parent_id);
        $student = Eleve::find($student_id);
        $student->code = NULL;
        $student->save();
        
        return redirect('add_user')->with(['message'=>"L'eleve ".$student->Nom." ".$student->Prenom." a été enlevé avec succès a ".$parent->nom." ".$parent->prenom,'alert'=>'border-success']);
    }

    public function import_users(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'user_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    
                    $current_user = User::find(trim($data[0]));
                    if($current_user){
                        $current_user->delete();
                    }
                    $user = User::create([
                        'code'=>trim($data[0]),
                        'nom'=>trim($data[1]),
                        'prenom'=>trim($data[2]),
                        'DateDeNaissance'=>trim($data[3]),
                        'LieuDeNaissance'=>trim($data[4]),
                        'nationalite'=>trim($data[5]),
                        'sex'=>trim($data[6]),
                        'DatePriseService'=>trim($data[7]),
                        'login'=>trim($data[8]),
                        'contacts'=>trim($data[9]),
                        'cdegrade'=>trim($data[10]),
                        'nbrand'=>trim($data[11]),
                        'matricule'=>trim($data[12]),
                        'reserve1'=>trim($data[13]),
                        'reserve2'=>trim($data[14]),
                        'reserve3'=>trim($data[15]),
                        'reserve4'=>trim($data[16]),
                        'reserve5'=>trim($data[17]),
                        'reserve6'=>trim($data[18]),
                        'cat'=>trim($data[19]),
                        'echel'=>trim($data[20]),
                        'statut'=>trim($data[21]),
                        'reserve7'=>trim($data[22]),
                        'reserve8'=>trim($data[23]),
                        'reserve9'=>trim($data[24]),
                        'CodeBank'=>trim($data[25]),
                        'numcpt'=>trim($data[26]),
                        'ribcpt'=>trim($data[27]),
                        'TauhH'=>trim($data[28]),
                        'syndicat'=>trim($data[29]),
                        'NumAssure'=>trim($data[30]),
                        'CodeEtablissement'=>trim($data[31]),
                        'password'=>'$2y$10$JuTQ/qgM75boawWtIg4VxOR7Wxlq9pliljVAaLsQlo1n1AuvOXqRW',
                        'text_password'=>'00000000'
                    ]);

                    $user->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('add_user')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

}
