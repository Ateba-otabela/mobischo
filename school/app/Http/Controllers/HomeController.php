<?php

namespace App\Http\Controllers;


use App\Models\User;
use App\Models\Eleve;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class HomeController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {
        $this->middleware('auth');
    }

    /**
     * Show the application dashboard.
     *
     * @return \Illuminate\Contracts\Support\Renderable
     */
    public function index()
    {
        $user = Auth::user();
        // if (($open = fopen("/home/lmntrix/Desktop/laravel/school/documents/DATA_MOBIL/Data_Annee.csv", "r")) !== FALSE){
        //     while (($data = fgetcsv($open, 1000, ";")) !== FALSE) {        
        //         // dd(trim($data[0]));
        //         $array[] = $data; 
        //     }
        //     fclose($open);
        //     }
        // foreach($array as $row){
        //     // dd($row[0]);
        // }
        // dd($array);

  
        if($user->admin){
            $schools = Etablissement::all();
            $students = Eleve::all();
            $administrateurs = User::where('admin','=',1)->get();
            $parents = User::where('account_type','=','parent')->get();
            $enseignants = User::where('account_type','=','enseignant')->get();
            $encardreurs = User::where('account_type','=','encardreur')->get();

            

            return view('main',compact(
                'schools',
                'students',
                'parents',
                'administrateurs',
                'enseignants',
                'encardreurs'
            ));
        }
        else{
            return view('download_app');
        }
    }


    public function myaccount()
    {
        return view('myaccount');
    }

    public function update_password(Request $request)
    {
        // dd('here');/
        # code... # Validation
         # Validation
         $request->validate([
            'old_password' => 'required',
            'new_password' => 'required|confirmed',
        ]);

        // dd('hello');
        #Match The Old Password
        if(!Hash::check($request->old_password, auth()->user()->password)){
            return back()->with("error", "L'ancien mot de passe ne correspond pas !");
        }


        #Update the new Password
        User::whereCode(auth()->user()->code)->update([
            'password' => Hash::make($request->new_password),
            'text_password' => $request->new_password
        ]);

        return redirect('myaccount')->with(['message'=>"Mot de passe modifié avec succès",'alert'=>'border-success']);

    }
}
