<?php

namespace App\Http\Controllers;

use App\Models\Annee;
use App\Models\Classe;
use App\Models\Inscription;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use App\Models\TrancheScholarite;
use App\Models\HistoriqueInscription;
use Illuminate\Support\Facades\Storage;

class AdministrationController extends Controller
{
    //
    public function tranches_scholarites_home()
    {
        $schools = Etablissement::all();
        return view('administration.tranches_scholarites_home',compact(
            'schools'
        ));
    }

    public function tranches(Request $request)
    {
        
        $school = Etablissement::find($request->CodeEtablissement);
        return view('administration.tranches',compact(
            'school'
        ));
    }

    public function inscriptions_home()
    {
        $schools = Etablissement::all();
        return view('administration.inscriptions_home',compact(
            'schools'
        ));
    }

    public function inscriptions(Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        $years = Annee::all();
        $tranches = TrancheScholarite::all();
        $inscriptions = Inscription::all()->take(100);
        $classe = NULL;
        $year = NULL;
        $tranche = NULL;
        return view('administration.inscriptions',compact(
            'school',
            'years',
            'classe',
            'year',
            'inscriptions',
            'tranches',
            'tranche'
        ));
    }

    public function sorted_inscriptions(Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        $years = Annee::all();
        $tranches = TrancheScholarite::all();
        $inscriptions = []; 
        $year = Annee::find($request->CodeAnnee);
        $tranche = TrancheScholarite::find($request->code);
        $classe = Classe::find($request->CodeClasse);
        
        foreach($classe->students->where('CodeAnnee','=',$year->CodeAnnee) as $student){
            foreach($student->inscriptions as $inscription){
                if($tranche->code == $inscription->Tranche){
                    $inscriptions[]=$inscription;
                }
            }
        }
        
        // $inscriptions = Inscription::where('CodeAnnee','=',$request->CodeAnnee)->get();
        // dd($inscriptions);

        return view('administration.inscriptions',compact(
            'school',
            'years',
            'inscriptions',
            'classe',
            'year',
            'tranches',
            'tranche'
        ));
    }

    public function historique_inscriptions_home()
    {
        $schools = Etablissement::all();
        return view('administration.historique_inscriptions_home',compact(
            'schools'
        ));
    }

    public function historique_inscriptions(Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        $years = Annee::all();
        $tranches = TrancheScholarite::all();
        $inscriptions = HistoriqueInscription::all()->take(100);
        $classe = NULL;
        $year = NULL;
        $tranche = NULL;
        return view('administration.historique_inscriptions',compact(
            'school',
            'years',
            'classe',
            'year',
            'inscriptions',
            'tranches',
            'tranche'
        ));
    }

    public function sorted_historique_inscriptions(Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        $years = Annee::all();
        $tranches = TrancheScholarite::all();
        $inscriptions = []; 
        $year = Annee::find($request->CodeAnnee);
        $tranche = TrancheScholarite::find($request->code);
        $classe = Classe::find($request->CodeClasse);
        // dd($year);
        foreach($classe->students->where('CodeAnnee','=',$year->CodeAnnee) as $student){
            foreach($student->inscriptions as $inscription){
                dd($inscription->historique_inscriptions);
                foreach($inscription->historique_inscriptions as $historique_inscription){
                    if($tranche->code == $historique_inscription->Tranche){
                        $inscriptions[]=$historique_inscription;
                    }
                }
                
            }
        }
        
        // $inscriptions = Inscription::where('CodeAnnee','=',$request->CodeAnnee)->get();
        // dd($inscriptions);

        return view('administration.historique_inscriptions',compact(
            'school',
            'years',
            'inscriptions',
            'classe',
            'year',
            'tranches',
            'tranche'
        ));
    }


    public function import_tranches(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'tranches_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    $current_tranche = TrancheScholarite::find(trim($data[0]));
                    if($current_tranche){
                        $current_tranche->delete();
                    }
                    $tranche = TrancheScholarite::create([
                        'code'=>trim($data[0]),
                        'libellet'=>trim($data[1])
                    ]);

                    $tranche->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('tranches_scholarites_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }


    public function import_inscriptions(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'inscriptions_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    // $current_inscription = Inscription::find(trim($data[1]));
                    // if($current_inscription){
                    //     $current_inscription->delete();
                    // }
                    $inscription = Inscription::create([
                        'NUMFAC'=>trim($data[0]),
                        'CodeInscription'=>trim($data[1]),
                        'CodeEleve'=>trim($data[2]),
                        'DateInscription'=>trim($data[3]),
                        'Tranche'=>trim($data[4]),
                        'codeannee'=>trim($data[5]),
                        'Montantins'=>trim($data[6]),
                        'Avance'=>trim($data[7]),
                        'Reste'=>trim($data[8]),
                        'Montantt'=>trim($data[9]),
                        'libinscrip'=>trim($data[10]),
                        'heure'=>trim($data[11]),
                        'caissier'=>trim($data[12]), 
                        'remise'=>trim($data[13])
                    ]);

                    $inscription->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('inscriptions_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

    public function import_historique_inscriptions(Request $request)
    {
        if($request->csv_file){
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'historique_inscriptions_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);
            // dd($new_path);
            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    // $current_inscription = Inscription::find(trim($data[1]));
                    // if($current_inscription){
                    //     $current_inscription->delete();
                    // }
                    $inscription = HistoriqueInscription::create([
                        'NUMFAC'=>trim($data[0]),
                        'CodeInscription'=>trim($data[1]),
                        'CodeEleve'=>trim($data[2]),
                        'DateInscription'=>trim($data[3]),
                        'Tranche'=>trim($data[4]),
                        'codeannee'=>trim($data[5]),
                        'Montantins'=>trim($data[6]),
                        'Avance'=>trim($data[7]),
                        'Reste'=>trim($data[8]),
                        'Montantt'=>trim($data[9]),
                        'libinscrip'=>trim($data[10]),
                        'heure'=>trim($data[11]),
                        'caissier'=>trim($data[12]), 
                        'remise'=>trim($data[13])
                    ]);

                    $inscription->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
            
        } 
        return redirect('historique_inscriptions_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

}
