<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Student;
use App\Models\Classroom;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use Illuminate\Support\Facades\Storage;

class EtablissementController extends Controller
{

    function GenerateSchoolCode(){
        $number = mt_rand(10000, 99999); // better than rand()
        $number = abs($number);
        if (SchoolCodeExists($number)){
            return GenerateSchoolCode();
        }
        $a = (int)$number;
        return abs($a);
    }
    
    function SchoolCodeExists($school_code){
        return Etablissment::whereschool_code($school_code)->exists();
    }
    //
    public function add_school()
    {   
        $schools = Etablissement::all();
        return view('school.add_school',compact('schools'));
    }
    
    public function delete_school($school_id)
    {   
        $school = Etablissement::find($school_id);
        $school->delete();
        return redirect('add_school')->with(['message'=>"L'etablissement a été supprimée avec succès",'alert'=>'border-info']);
    }

    public function add_school_complete(Request $request)
    {   
        $validated = $request->validate([
            'Nom' => 'required',
            'Tel' => 'required',
            'CodeEtablissement' => 'required',
            'Adresse' => 'required',
            'Fax' => 'required',
        ]);

        $school = Etablissement::create([
            'Nom'=>$request->Nom,
            'Tel'=>$request->Tel,
            'CodeEtablissement'=>$request->CodeEtablissement,
            'Adresse'=>$request->Adresse,
            'Fax'=>$request->Fax,
                    
        ]);
        $school->save();

        if($request->RepPhoto){
            $filename = time().'.'.$request->RepPhoto->extension();
            $path = $request->file('RepPhoto')->storeAs(
                'logo',
                $filename,
                'public'
            );
            $school->RepPhoto=$path;
            $school->save();
        }

        return \redirect('add_school');
    }

    public function save_school($school_id,Request $request)
    {   
        $school = Etablissement::find($school_id);
        $school->Nom = $request->Nom;
        $school->Tel = $request->Tel;
        $school->Adresse = $request->Adresse;
        $school->Fax = $request->Fax;
        $school->CodeEtablissement = $request->CodeEtablissement;
        $school->save();

        if($request->REPPHOTO){
            $filename = time().'.'.$request->REPPHOTO->extension();
            $path = $request->file('REPPHOTO')->storeAs(
                'REPPHOTO',
                $filename,
                'public'
            );
            $school->REPPHOTO=$path;
        } 
        $school->save();

        return redirect('add_school')->with(['message'=>"L'etablissement a été modifiée avec succès",'alert'=>'border-success']);
    }

    public function import_schools(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'etablissement_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    $current_school = Etablissement::find(trim($data[0]));
                    if($current_school){
                        $current_school->delete();
                    }
                    $school = Etablissement::create([
                        'CodeEtablissement'=>trim($data[0]),
                        'Pays'=>trim($data[1]),
                        'Nom'=>trim($data[2]),
                        'Adresse'=>'Yaounde',
                        'Tel'=>trim($data[4]),
                        'Fax'=>trim($data[3]),
                        'REPPHOTO'=>NULL
                    ]);

                    $school->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('add_school')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }
}
