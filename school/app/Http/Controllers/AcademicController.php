<?php

namespace App\Http\Controllers;

use App\Models\Note;
use App\Models\Annee;
use App\Models\Classe;
use App\Models\Matiere;
use App\Models\Enseignement;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use App\Models\SequenceEvaluation;
use Illuminate\Support\Facades\Storage;

class AcademicController extends Controller
{
    //
    public function add_year()
    {
        $years = Annee::all();
        return view('academic.add_year',compact('years'));
    }

    public function add_year_complete(Request $request)
    {
        $new_year = Annee::create([
            'CodeAnnee'=>$request->CodeAnnee,
            'Libelle'=>$request->Libelle
        ]);
        $new_year->save();
        return redirect('add_year')->with(['message'=>"L'année scholaire ".$request->libelle." a ete ajoute avec succes", 'alert'=>'border-success']);
    }
    public function save_year(Request $request, $year_id)
    {
        $year = Annee::find($year_id);

        $year->Libelle = $request->Libelle;
        $year->CodeAnnee = $request->CodeAnnee;
        $year->save();

        return redirect('add_year');
    }
    public function delete_year($year_id)
    {
        $year = Annee::find($year_id);
        $year->delete();
        return redirect('add_year')->with(['message'=>"L'année scholaire ".$request->libelle." a ete suprimmee avec succes", 'alert'=>'border-success']);
    }


    public function add_class()
    {
        $classes = Classe::all();
        $schools = Etablissement::all();
        $schools = Etablissement::all();
        return view('class.add_class',compact(
            'classes',
            'schools'
        ));
    }
    public function add_class_complete(Request $request)
    {
        $new_class = Classe::create([
            'LibelleClasse'=>$request->LibelleClasse,
            'CodeClasse'=>$request->CodeClasse,
            'CodeTypeClasse'=>$request->CodeTypeClasse,
            'CodeCycle'=>$request->CodeCycle,
            'CodeSpecialite'=>$request->CodeSpecialite,
            'codetypeinscrip'=>$request->codetypeinscrip,
            'CodeEtablissement'=>$request->CodeEtablissement
        ]);
        $new_class->save();
        return \redirect('add_class')->with(['message'=>'La classe a été ajoutée avec succès','alert'=>'border-success']);
    
    }
    public function save_class(Request $request, $class_id)
    {
        $class = Classe::find($class_id);
        $class->LibelleClasse = $request->LibelleClasse;
        $class->CodeClasse = $request->CodeClasse;
        $class->CodeTypeClasse = $request->CodeTypeClasse;
        $class->CodeCycle = $request->CodeCycle;
        $class->CodeSpecialite = $request->CodeSpecialite;
        $class->codetypeinscrip = $request->codetypeinscrip;
        $class->CodeEtablissement = $request->CodeEtablissement;
        $class->save();
        return redirect('add_class')->with(['message'=>'La classe a été modifiée avec succès','alert'=>'border-success']);;
    }
    public function delete_class($class_id)
    {
        $class = Classe::find($class_id);
        $class->delete();

        return redirect('add_class')->with(["message"=>"La classe ".$class->LibelleClasse." a ete suprimmee avec succes", "alert"=>"border-success"]);

    }

    public function sequence_evaluation()
    {
        $sequence_evaluations = SequenceEvaluation::all();
        return view('academic.sequence_evaluation',compact(
            'sequence_evaluations'
        ));
    }

    public function course_home()
    {
        $schools = Etablissement::all();
        return view('academic.course_home',compact(
            'schools'
        ));
    }

    public function courses(Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        return view('academic.courses',compact(
            'school'
        ));
    }

    public function enseignement_home()
    {
        $schools = Etablissement::all();
        // $list = ['11201','12301'];
        // shuffle($list);
        // foreach(Enseignement::all() as $enseignement){
        //     $enseignement->CodeEtablissement = $list[0];
        //     $enseignement->save();
        // }
        return view('academic.enseignement_home',compact(
            'schools'
        ));
    }

    public function enseignements(Request $request)
    {
        $classe = NULL;
        $classes = Classe::all();
        $school = Etablissement::find($request->CodeEtablissement);
        $enseignements = Enseignement::all();
        return view('academic.enseignements2',compact(
            'school',
            'classe',
            'classes',
            'enseignements'
        ));
    }

    public function sorted_enseignements(Request $request)
    {
        $classe = NULL;
        $classes = Classe::all();
        $school = Etablissement::find($request->CodeEtablissement);
        $enseignements = Enseignement::where('CodeClasse','=',$request->CodeClasse)->get();
        return view('academic.enseignements2',compact(
            'school',
            'classe',
            'classes',
            'enseignements'
        ));
    }

    public function notes_home()
    {
        $schools = Etablissement::all();
        return view('academic.notes_home',compact(
            'schools'
        ));
    }

    public function notes_choose_class(Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        return view('academic.notes_choose_class',compact(
            'school'
        ));
    }
    public function notes($CodeClasse, $CodeEtablissement)
    {
        $classe = Classe::find($CodeClasse);
        $sequence = NULL;
        $year = NULL;
        $classes = Classe::all();
        $enseignement = Enseignement::where('CodeClasse','=',$CodeClasse)->first();
        // dd($enseignement->etablissement);
        // dd($enseignement);
        $school = Etablissement::find($CodeEtablissement);

        // dd($enseignement);
        $notes = $enseignement->notes;
        $note = $notes[0];
        
        $sequence_evaluations = SequenceEvaluation::all();
        $years = Annee::all();
        return view('academic.notes',compact(
            'school',
            'classe',
            'classes',
            'notes',
            'enseignement',
            'note',
            'sequence_evaluations',
            'years',
            'sequence',
            'year'
        ));
    }

    // public function course_notes($CodeEnseignement)
    // {
    //     $marks = Note::where('CodeEnseignement','=',$CodeEnseignement);
    //     return json_encode($marks);
    // }

    public function sorted_notes(Request $request)
    {
        $classe = Classe::find($request->CodeClasse);
        $sequence = SequenceEvaluation::find($request->CodeEvaluation);
        $year = Annee::find($request->CodeAnnee);
        $classes = Classe::all();
        $school = Etablissement::find($request->CodeEtablissement);

        $enseignement = Enseignement::find($request->CodeEnseignement);
        $notes = Note::where('CodeEvaluation','=',$request->CodeEvaluation)->where('CodeEnseignement','=',$enseignement->CodeEnseignement)->where('CodeAnnee','=',$year->CodeAnnee)->get();
        
        $note = $notes[0];
        
        $sequence_evaluations = SequenceEvaluation::all();
        $years = Annee::all();
        return view('academic.notes',compact(
            'school',
            'classe',
            'classes',
            'notes',
            'enseignement',
            'note',
            'sequence_evaluations',
            'years',
            'sequence',
            'year'
        ));
    }

    public function import_classes(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'classes_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    $current_class = Classe::find(trim($data[0]));
                    if($current_class){
                        $current_class->delete();
                    }
                    $class = Classe::create([
                        'CodeClasse'=>trim($data[0]),
                        'CodeTypeClasse'=>trim($data[1]),
                        'LibelleClasse'=>trim($data[2]),
                        'CodeCycle'=>trim($data[3]),
                        'CodeSpecialite'=>trim($data[4]),
                        'codetypeinscrip'=>trim($data[5]),
                        'CodeEtablissement'=>trim($data[6])
                    ]);

                    $class->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('add_class')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }


    public function import_courses(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'matieres_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    $current_course = Matiere::find(trim($data[0]));
                    if($current_course){
                        $current_course->delete();
                    }
                    $course = Matiere::create([
                        'CodeMatiere'=>trim($data[0]),
                        'LibelleMatiere'=>trim($data[1]),
                        'ordre'=>trim($data[2]),
                        'CodeEtablissement'=>trim($data[3]),
                        'CodeEtablissement'=>11201
                    ]);

                    $course->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('course_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }



    public function import_notes(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'notes_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    $current_note = Note::find(trim($data[0]));
                    if($current_note){
                        $current_note->delete();
                    }
                    $note = Note::create([
                        'Codeenseignement'=>trim($data[0]),
                        'CodeEleve'=>trim($data[1]),
                        'CodeEvaluation'=>trim($data[2]),
                        'CodeAppreciation'=>trim($data[3]),
                        'Valeur'=>trim($data[4]),
                        'coef'=>trim($data[5]),
                        'total'=>trim($data[6]),
                        'Dateeng'=>trim($data[7]),
                        'codeannee'=>trim($data[8])
                    ]);

                    $note->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('notes_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

    public function import_enseignements(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'enseignements_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    $current_enseignement = Enseignement::find(trim($data[0]));
                    
                    if($current_enseignement){
                        $current_enseignement->delete();
                    }
                    
                    // if(trim($data[4]) == 'NULL'){
                    //     $code_etablissement = 11201;
                    // }else{
                    //     $code_etablissement = trim($data[4]);
                    // }

                    $enseignement = Enseignement::create([
                        'CodeEnseignement'=>trim($data[0]),
                        'CodeMatiere'=>trim($data[1]),
                        'code'=>trim($data[2]),
                        'CodeClasse'=>trim($data[3]),
                        'CodeEtablissement'=>trim($data[4]),
                        'Coefficient'=>trim($data[5]),
                        'CodeSpecialite'=>trim($data[6]),
                        'CodeCycle'=>trim($data[7]),
                        'Dateens'=>trim($data[8]),
                        'CodeEnseignant2'=>trim($data[9]),
                        'DateModif'=>trim($data[10]),
                        'NBRHEURE'=>trim($data[11]),
                        'RESERVE1'=>trim($data[12]),
                        'RESERVE2'=>trim($data[13]),
                        'RESERVE3'=>trim($data[14]),
                        'RESERVE4'=>trim($data[15]),
                        'RESERVE5'=>trim($data[16]),
                    ]);

                    $enseignement->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('enseignement_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

    public function import_years(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'years_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    $current_year = Annee::find(trim($data[0]));
                    if($current_year){
                        $current_year->delete();
                    }
                    $year = Annee::create([
                        'CodeAnnee'=>trim($data[0]),
                        'Libelle'=>trim($data[1])
                    ]);

                    $year->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('add_year')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

    public function import_sequences(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'sequences_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    $current_sequence = SequenceEvaluation::find(trim($data[0]));
                    if($current_sequence){
                        $current_sequence->delete();
                    }
                    $sequence = SequenceEvaluation::create([
                        'CodeEvaluation'=>trim($data[0]),
                        'LibelleEvaluation'=>trim($data[1])
                    ]);
                    $sequence->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('sequence_evaluation')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }
}   
