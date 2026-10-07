<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Student;
use App\Models\Classroom;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

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
        $school = Etablissement::findOrFail($school_id);
        $school->delete();
        return redirect('add_school')->with(['message'=>"L'etablissement a été supprimée avec succès",'alert'=>'border-info']);
    }

    public function add_school_complete(Request $request)
    {   
        $validated = $request->validate([
            'Nom' => 'required|string',
            'Tel' => 'required|string',
            'CodeEtablissement' => 'required|string|unique:etablissements,CodeEtablissement',
            'Adresse' => 'required|string',
            'Fax' => 'required|string',
            'RepPhoto' => 'nullable|image',
        ]);

        $school = Etablissement::create([
            'Nom' => $validated['Nom'],
            'Tel' => $validated['Tel'],
            'CodeEtablissement' => $validated['CodeEtablissement'],
            'Adresse' => $validated['Adresse'],
            'Fax' => $validated['Fax'],
                    
        ]);
        $school->save();

        if($request->RepPhoto){
            $filename = time().'.'.$request->file('RepPhoto')->extension();
            $path = $request->file('RepPhoto')->storeAs(
                'logo',
                $filename,
                'public'
            );
            $school->REPPHOTO = $path;
            $school->save();
        }

        return \redirect('add_school');
    }

    public function save_school($school_id,Request $request)
    {   
        $school = Etablissement::findOrFail($school_id);
        $validated = $request->validate([
            'Nom' => 'required|string',
            'Tel' => 'required|string',
            'Adresse' => 'required|string',
            'Fax' => 'required|string',
            'CodeEtablissement' => [
                'required',
                'string',
                Rule::unique('etablissements', 'CodeEtablissement')->ignore($school_id, 'CodeEtablissement'),
            ],
            'REPPHOTO' => 'nullable|image',
        ]);
        $school->Nom = $validated['Nom'];
        $school->Tel = $validated['Tel'];
        $school->Adresse = $validated['Adresse'];
        $school->Fax = $validated['Fax'];
        $school->CodeEtablissement = $validated['CodeEtablissement'];
        $school->save();

        if($request->REPPHOTO){
            $filename = time().'.'.$request->file('REPPHOTO')->extension();
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
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 5, 5, [
            'CodeEtablissement', 'Pays', 'Nom', 'Fax', 'Tel',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
            2 => 'required|string|max:255',
            3 => 'required|string|max:255',
            4 => 'required|string|max:255',
        ]);

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                Etablissement::updateOrCreate(
                    ['CodeEtablissement' => $data[0]],
                    [
                        'Pays' => $data[1],
                        'Nom' => $data[2],
                        'Adresse' => 'Yaounde',
                        'Fax' => $data[3],
                        'Tel' => $data[4],
                    ]
                );
            }
        });

        return redirect('add_school')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }
}
