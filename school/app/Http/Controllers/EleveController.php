<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Annee;
use App\Models\Eleve;
use App\Models\Classe;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class EleveController extends Controller
{
    //

    public function add_student_home()
    {
        $schools = Etablissement::all();
        return view('students.add_student_home',compact(
            'schools'
        ));
    }
    public function add_student(Request $request)
    {
        $students = array();
        // $year = '';
        // $class = '';
        $school = Etablissement::find($request->CodeEtablissement);
        $years = Annee::all();
        $year = $years->first();

        if($request->class){
            $class = Classe::find($request->CodeClasse);
        }
        else{
            $class = $school->classes->first();
        }
        
        foreach($school->classes->first()->students as $student){
            $students[] = $student;
        } 

        return view('students.add_student',compact(
            'class',
            'school',
            'years',
            'year',
            'students'
        ));

    }

    public function sorted_students(Request $request)
    {
        // $students = array();
        // dd($request);
        $class = Classe::find($request->CodeClasse);
        $year = Annee::find($request->CodeAnnee);

        // dd($year);
        $students = Eleve::where('CodeAnnee','=',$request->CodeAnnee)->where('CodeClasse','=',$class->CodeClasse)->get();
        $school = Etablissement::find($request->CodeEtablissement);
        $years = Annee::all(); 

        return view('students.add_student',compact(
            'class',
            'year',
            'school',
            'years',
            'students'
        ));

    }

    public function import_students(Request $request)
    {
        if($request->csv_file){
            // dd('yes');
            $filename = time().'.'.$request->csv_file->extension();
            $path = $request->file('csv_file')->storeAs(
                'eleves_imports',
                $filename,
                'public'
            );
            $new_path = Storage::url($path);

            if (($open = fopen(public_path($new_path), "r")) !== FALSE){
                $i=0;
                while (($data = fgetcsv($open, 1000, ";")) !== FALSE){
                    $current_student = Eleve::find(trim($data[0]));
                    if($current_student){
                        $current_student->delete();
                    }
                    
                    if(isset($data[1])) {
                        try{
                            $codeannee = trim((int)$data[1]);   
                        }catch(Exception $e){
                            $codeannee = $i;
                        }
                        
                    }else{
                        $codeannee = $i;
                    }

                    if(isset($data[6])) {
                        $date_of_birth = trim($data[6]);   
                    }else{
                        $date_of_birth = "";
                    }
                    
                    if(isset($data[7])) {
                        $place_of_birth = trim($data[7]);   
                    }else{
                        $place_of_birth = "";
                    }

                    if(isset($data[8])) {
                        $sex = trim($data[8]);   
                    }else{
                        $sex = "";
                    }

                    if(isset($data[9])) {
                        $nationalite = trim($data[9]);   
                    }else{
                        $nationalite = "";
                    }
                    if(isset($data[10])) {
                        $date_inscription = trim($data[10]);   
                    }else{
                        $date_inscription = '2022-09-20 03:36:41';
                    }
                    if(isset($data[11])) {
                        $photo = trim($data[11]);   
                    }else{
                        $photo = "";
                    }
                    if(isset($data[12])) {
                        $excl = trim($data[12]);   
                    }else{
                        $excl = "";
                    }
                    if(isset($data[13])) {
                        $nomp = trim($data[13]);   
                    }else{
                        $nomp = "";
                    }
                    if(isset($data[14])) {
                        $telp = trim($data[14]);   
                    }else{
                        $telp = "";
                    }
                    if(isset($data[15])) {
                        $nomm = trim($data[15]);   
                    }else{
                        $nomm = "";
                    }
                    if(isset($data[16])) {
                        $region = trim($data[16]);   
                    }else{
                        $region = "";
                    }
                    if(isset($data[17])) {
                        $depart = trim($data[17]);   
                    }else{
                        $depart = "";
                    }
                    if(isset($data[18])) {
                        $religion = trim($data[18]);   
                    }else{
                        $religion = "";
                    }
                    if(isset($data[19])) {
                        $sitreg = trim($data[19]);   
                    }else{
                        $sitreg = "";
                    }
                    if(isset($data[23])) {
                        $activeeps = trim($data[23]);   
                    }else{
                        $activeeps = "";
                    }
                    if(isset($data[24])) {
                        $profp = trim($data[14]);   
                    }else{
                        $profp = "";
                    }
                    if(isset($data[25])) {
                        $nomt = trim($data[25]);   
                    }else{
                        $nomt = "";
                    }
                    if(isset($data[28])) {
                        $profm = trim($data[28]);   
                    }else{
                        $profm = "";
                    }
                    if(isset($data[29])) {
                        $address = trim($data[29]);   
                    }else{
                        $address = "";
                    }
                    if(isset($data[30])) {
                        $telt = trim($data[30]);   
                    }else{
                        $telt = "";
                    }
                    if(isset($data[31])) {
                        $personcon = trim($data[31]);   
                    }else{
                        $personcon = "";
                    }
                    if(isset($data[32])) {
                        $reserve1 = trim($data[32]);   
                    }else{
                        $reserve1 = "";
                    }
                    if(isset($data[33])) {
                        $reserve2 = trim($data[33]);   
                    }else{
                        $reserve2 = "";
                    }
                    if(isset($data[34])) {
                        $reserve3 = trim($data[34]);   
                    }else{
                        $reserve3 = "";
                    }
                    if(isset($data[35])) {
                        $reserve4 = trim($data[35]);   
                    }else{
                        $reserve4 = "";
                    }
                    

                    $eleve = Eleve::create([
                        'CodeEleve'=>trim($data[0]),
                        'CodeAnnee'=>$codeannee,
                        'CodeClasse'=>trim($data[2]),
                        'CodeConduite'=>trim($data[3]),
                        'Nom'=>trim($data[4]),
                        'Prenom'=>trim($data[5]),
                        'DateNaissance'=>$date_of_birth,
                        'LieuNaissance'=>$place_of_birth,
                        'Sex'=>$sex,
                        'Nationalite'=>$nationalite,
                        'dateinscription'=>$date_inscription,
                        'photo'=>$photo,
                        'Excl'=>$excl,
                        'Nomp'=>$nomp,
                        'TelP'=>$telp,
                        'Image'=>'',
                        'strimage'=>'',
                        'Nomm'=>$nomm,
                        'REGION'=>$region,
                        'DEPART'=>$depart,
                        'RELIGION'=>$religion,
                        'SITREG'=>$sitreg,
                        'ACTIVEEPS'=>$activeeps,
                        'PROFP'=>$profp,
                        'NOMT'=>$nomt,
                        'PROFM'=>$profm,
                        'ADRESSE'=>$address,
                        'RESIDENT'=>'',
                        'TELM'=>'',
                        'TELT'=>$telt,
                        'PERSONCON'=>$personcon,
                        'RESERVE1'=>'',
                        'RESERVE2'=>'',
                        'RESERVE3'=>'',
                        'RESERVE4'=>''
                    ]);
                    $i+=1;
                    $eleve->save();       
                    // dd(trim($data[0]));
                    // $array[] = $data;
                }
                fclose($open);
            }
        } 
        return redirect('add_student')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

}
