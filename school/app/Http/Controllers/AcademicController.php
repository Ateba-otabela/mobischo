<?php

namespace App\Http\Controllers;

use App\Models\Note;
use App\Models\Annee;
use App\Models\Classe;
use App\Models\Eleve;
use App\Models\Matiere;
use App\Models\Enseignement;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use App\Models\SequenceEvaluation;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\DB;

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
        $validated = $request->validate([
            'CodeAnnee' => 'required|string|unique:annees,CodeAnnee',
            'Libelle' => 'required|string',
        ]);

        $new_year = Annee::create([
            'CodeAnnee' => $validated['CodeAnnee'],
            'Libelle' => $validated['Libelle'],
        ]);
        return redirect('add_year')->with(['message'=>"L'année scolaire ".$new_year->Libelle." a été ajoutée avec succès", 'alert'=>'border-success']);
    }
    public function save_year(Request $request, $year_id)
    {
        $year = Annee::findOrFail($year_id);
        $validated = $request->validate([
            'CodeAnnee' => [
                'required',
                'string',
                Rule::unique('annees', 'CodeAnnee')->ignore($year_id, 'CodeAnnee'),
            ],
            'Libelle' => 'required|string',
        ]);

        $year->Libelle = $validated['Libelle'];
        $year->CodeAnnee = $validated['CodeAnnee'];
        $year->save();

        return redirect('add_year');
    }
    public function delete_year($year_id)
    {
        $year = Annee::findOrFail($year_id);
        $label = $year->Libelle;
        $year->delete();
        return redirect('add_year')->with(['message'=>"L'année scolaire ".$label." a été supprimée avec succès", 'alert'=>'border-success']);
    }


    public function add_class(Request $request)
    {
        $schools = Etablissement::orderBy('Nom')->get();
        $selectedSchoolCode = $request->query('CodeEtablissement');
        $selectedSchool = $selectedSchoolCode
            ? Etablissement::find($selectedSchoolCode)
            : null;
        if ($selectedSchoolCode && !$selectedSchool) {
            return redirect()->route('add_class')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $classes = $selectedSchool
            ? $selectedSchool->classes()->with('etablissement')->get()
            : Classe::with('etablissement')->orderBy('LibelleClasse')->get();
        return view('class.add_class',compact(
            'classes',
            'schools',
            'selectedSchool'
        ));
    }
    public function add_class_complete(Request $request)
    {
        $validated = $request->validate([
            'LibelleClasse' => 'required|string',
            'CodeClasse' => 'required|string|unique:classes,CodeClasse',
            'CodeTypeClasse' => 'required|string',
            'CodeCycle' => 'required|string',
            'CodeSpecialite' => 'required|string',
            'codetypeinscrip' => 'required|string',
            'CodeEtablissement' => 'required|string|exists:etablissements,CodeEtablissement',
        ]);

        $new_class = Classe::create([
            'LibelleClasse' => $validated['LibelleClasse'],
            'CodeClasse' => $validated['CodeClasse'],
            'CodeTypeClasse' => $validated['CodeTypeClasse'],
            'CodeCycle' => $validated['CodeCycle'],
            'CodeSpecialite' => $validated['CodeSpecialite'],
            'codetypeinscrip' => $validated['codetypeinscrip'],
            'CodeEtablissement' => $validated['CodeEtablissement'],
        ]);
        return \redirect('add_class')->with(['message'=>'La classe a été ajoutée avec succès','alert'=>'border-success']);
    
    }
    public function save_class(Request $request, $class_id)
    {
        $class = Classe::findOrFail($class_id);
        $validated = $request->validate([
            'LibelleClasse' => 'required|string',
            'CodeClasse' => [
                'required',
                'string',
                Rule::unique('classes', 'CodeClasse')->ignore($class_id, 'CodeClasse'),
            ],
            'CodeTypeClasse' => 'required|string',
            'CodeCycle' => 'required|string',
            'CodeSpecialite' => 'required|string',
            'codetypeinscrip' => 'required|string',
            'CodeEtablissement' => 'required|string|exists:etablissements,CodeEtablissement',
        ]);
        $class->LibelleClasse = $validated['LibelleClasse'];
        $class->CodeClasse = $validated['CodeClasse'];
        $class->CodeTypeClasse = $validated['CodeTypeClasse'];
        $class->CodeCycle = $validated['CodeCycle'];
        $class->CodeSpecialite = $validated['CodeSpecialite'];
        $class->codetypeinscrip = $validated['codetypeinscrip'];
        $class->CodeEtablissement = $validated['CodeEtablissement'];
        $class->save();
        return redirect('add_class')->with(['message'=>'La classe a été modifiée avec succès','alert'=>'border-success']);;
    }
    public function delete_class($class_id)
    {
        $class = Classe::findOrFail($class_id);
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
        if (!$school) {
            return redirect()->route('course_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        return view('academic.courses', compact('school'));
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
        $school = Etablissement::find($request->CodeEtablissement);
        if (!$school) {
            return redirect()->route('enseignement_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $classe = null;
        $classes = $school->classes()->orderBy('LibelleClasse')->get();
        $enseignements = $school->enseignements()->with(['matiere', 'classe', 'enseignant'])->get();
        return view('academic.enseignements2',compact(
            'school',
            'classe',
            'classes',
            'enseignements'
        ));
    }

    public function sorted_enseignements(Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        if (!$school) {
            return redirect()->route('enseignement_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $classes = $school->classes()->orderBy('LibelleClasse')->get();
        $classe = $classes->firstWhere('CodeClasse', $request->CodeClasse);
        if (!$classe) {
            return redirect()->route('enseignements', [
                'CodeEtablissement' => $school->CodeEtablissement,
            ])->withErrors(['CodeClasse' => 'La classe choisie ne fait pas partie de cet établissement.']);
        }

        $enseignements = $school->enseignements()
            ->where('CodeClasse', $classe->CodeClasse)
            ->with(['matiere', 'classe', 'enseignant'])
            ->get();
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
        if (!$school) {
            return redirect()->route('notes_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        return view('academic.notes_choose_class',compact(
            'school'
        ));
    }
    public function notes($CodeClasse, $CodeEtablissement)
    {
        $school = Etablissement::find($CodeEtablissement);
        if (!$school) {
            return redirect()->route('notes_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $classe = $school->classes()->where('CodeClasse', $CodeClasse)->first();
        if (!$classe) {
            return redirect()->route('notes_choose_class', [
                'CodeEtablissement' => $school->CodeEtablissement,
            ])->withErrors(['CodeClasse' => 'La classe choisie ne fait pas partie de cet établissement.']);
        }

        $sequence = null;
        $year = null;
        $classes = $school->classes()->get();
        $enseignement = $school->enseignements()
            ->where('CodeClasse', $classe->CodeClasse)
            ->whereHas('matiere')
            ->with(['matiere', 'classe'])
            ->first();
        $notes = $enseignement
            ? $enseignement->notes()
                ->whereHas('sequence_evaluation')
                ->whereHas('annee')
                ->whereHas('eleve.classe', function ($query) use ($school, $classe) {
                    $query->where('CodeClasse', $classe->CodeClasse)
                        ->where('CodeEtablissement', $school->CodeEtablissement);
                })
                ->with(['sequence_evaluation', 'annee', 'eleve'])
                ->get()
            : collect();
        $note = $notes->first();
        
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
        $school = Etablissement::find($request->CodeEtablissement);
        if (!$school) {
            return redirect()->route('notes_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $classe = $school->classes()->where('CodeClasse', $request->CodeClasse)->first();
        if (!$classe) {
            return redirect()->route('notes_choose_class', [
                'CodeEtablissement' => $school->CodeEtablissement,
            ])->withErrors(['CodeClasse' => 'La classe choisie ne fait pas partie de cet établissement.']);
        }

        $sequence = SequenceEvaluation::find($request->CodeEvaluation);
        $year = Annee::find($request->CodeAnnee);
        if (!$sequence || !$year) {
            return redirect()->route('notes_choose_class', [
                'CodeEtablissement' => $school->CodeEtablissement,
            ])->withErrors(['notes' => 'Veuillez choisir une séquence et une année existantes.']);
        }

        $classes = $school->classes()->get();
        $enseignement = $school->enseignements()
            ->where('CodeClasse', $classe->CodeClasse)
            ->where('CodeEnseignement', $request->CodeEnseignement)
            ->whereHas('matiere')
            ->with(['matiere', 'classe'])
            ->first();
        if (!$enseignement) {
            return redirect()->route('notes_choose_class', [
                'CodeEtablissement' => $school->CodeEtablissement,
            ])->withErrors(['notes' => 'L’enseignement choisi ne fait pas partie de cette classe.']);
        }

        $notes = Note::where('CodeEvaluation', $sequence->CodeEvaluation)
            ->where('CodeEnseignement', $enseignement->CodeEnseignement)
            ->where('CodeAnnee', $year->CodeAnnee)
            ->whereHas('sequence_evaluation')
            ->whereHas('annee')
            ->whereHas('eleve.classe', function ($query) use ($school, $classe) {
                $query->where('CodeClasse', $classe->CodeClasse)
                    ->where('CodeEtablissement', $school->CodeEtablissement);
            })
            ->with(['sequence_evaluation', 'annee', 'enseignement.classe', 'eleve'])
            ->get();
        $note = $notes->first();
        
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
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 7, 7, [
            'CodeClasse', 'CodeTypeClasse', 'LibelleClasse', 'CodeCycle',
            'CodeSpecialite', 'codetypeinscrip', 'CodeEtablissement',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
            2 => 'required|string|max:255',
            3 => 'required|string|max:255',
            4 => 'required|string|max:255',
            5 => 'required|string|max:255',
            6 => 'required|string|max:255',
        ]);
        foreach ($rows as $index => $row) {
            if (!Etablissement::where('CodeEtablissement', trim($row[6]))->exists()) {
                return redirect('add_class')
                    ->withErrors(['csv_file' => 'L’établissement de la ligne '.($index + 1).' n’existe pas.']);
            }
        }

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                Classe::updateOrCreate(
                    ['CodeClasse' => $data[0]],
                    [
                        'CodeTypeClasse' => $data[1],
                        'LibelleClasse' => $data[2],
                        'CodeCycle' => $data[3],
                        'CodeSpecialite' => $data[4],
                        'codetypeinscrip' => $data[5],
                        'CodeEtablissement' => $data[6],
                    ]
                );
            }
        });

        return redirect('add_class')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }


    public function import_courses(Request $request)
    {
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 4, 4, [
            'CodeMatiere', 'LibelleMatiere', 'ordre', 'CodeEtablissement',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
            2 => 'required|string|max:255',
            3 => 'required|string|max:255',
        ]);
        foreach ($rows as $index => $row) {
            if (!Etablissement::where('CodeEtablissement', trim($row[3]))->exists()) {
                return redirect('course_home')
                    ->withErrors(['csv_file' => 'L’établissement de la ligne '.($index + 1).' n’existe pas.']);
            }
        }

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                Matiere::updateOrCreate(
                    ['CodeMatiere' => $data[0]],
                    [
                        'LibelleMatiere' => $data[1],
                        'ordre' => $data[2],
                        'CodeEtablissement' => $data[3],
                    ]
                );
            }
        });

        return redirect('course_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }



    public function import_notes(Request $request)
    {
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 9, 9, [
            'CodeEnseignement', 'CodeEleve', 'CodeEvaluation', 'CodeAppreciation',
            'valeur', 'coef', 'Total', 'Dateeng', 'CodeAnnee',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
            2 => 'required|string|max:255',
            3 => 'nullable|string|max:255',
            4 => 'nullable|string|max:255',
            5 => 'nullable|string|max:255',
            6 => 'nullable|string|max:255',
            7 => 'nullable|string|max:255',
            8 => 'required|string|max:255',
        ]);
        foreach ($rows as $index => $row) {
            $validReferences = Enseignement::where('CodeEnseignement', trim($row[0]))->exists()
                && Eleve::where('CodeEleve', trim($row[1]))->exists()
                && SequenceEvaluation::where('CodeEvaluation', trim($row[2]))->exists()
                && Annee::where('CodeAnnee', trim($row[8]))->exists();
            if (!$validReferences) {
                return redirect('notes_home')
                    ->withErrors(['csv_file' => 'Une référence de la ligne '.($index + 1).' est invalide.']);
            }
        }

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                Note::create([
                    'CodeEnseignement' => $data[0],
                    'CodeEleve' => $data[1],
                    'CodeEvaluation' => $data[2],
                    'CodeAppreciation' => $data[3],
                    'valeur' => $data[4],
                    'coef' => $data[5],
                    'Total' => $data[6],
                    'Dateeng' => $data[7],
                    'CodeAnnee' => $data[8],
                ]);
            }
        });

        return redirect('notes_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

    public function import_enseignements(Request $request)
    {
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 17, 17, [
            'CodeEnseignement', 'CodeMatiere', 'code', 'CodeClasse', 'CodeEtablissement',
            'Coefficient', 'CodeSpecialite', 'CodeCycle', 'Dateens', 'CodeEnseignant2',
            'DateModif', 'NBRHEURE', 'RESERVE1', 'RESERVE2', 'RESERVE3', 'RESERVE4',
            'RESERVE5',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
            2 => 'required|string|max:255',
            3 => 'required|string|max:255',
            4 => 'required|string|max:255',
            5 => 'nullable|string|max:255',
            6 => 'nullable|string|max:255',
            7 => 'nullable|string|max:255',
            8 => 'nullable|date',
            9 => 'nullable|string|max:255',
            10 => 'nullable|string|max:255',
            11 => 'nullable|string|max:255',
            12 => 'nullable|string|max:255',
            13 => 'nullable|string|max:255',
            14 => 'nullable|string|max:255',
            15 => 'nullable|string|max:255',
            16 => 'nullable|string|max:255',
        ]);
        foreach ($rows as $index => $row) {
            $schoolCode = trim($row[4]);
            $classExists = Classe::where('CodeClasse', trim($row[3]))
                ->where('CodeEtablissement', $schoolCode)
                ->exists();
            $subjectExists = Matiere::where('CodeMatiere', trim($row[1]))
                ->where('CodeEtablissement', $schoolCode)
                ->exists();
            $teacherExists = \App\Models\User::where('code', trim($row[2]))->exists();
            $secondaryTeacherExists = trim($row[9]) === ''
                || \App\Models\User::where('code', trim($row[9]))->exists();

            if (!Etablissement::where('CodeEtablissement', $schoolCode)->exists()
                || !$classExists
                || !$subjectExists
                || !$teacherExists
                || !$secondaryTeacherExists) {
                return redirect('enseignement_home')
                    ->withErrors(['csv_file' => 'Une référence de classe, matière, enseignant ou établissement de la ligne '.($index + 1).' est invalide.']);
            }
        }

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                Enseignement::updateOrCreate(
                    ['CodeEnseignement' => $data[0]],
                    [
                        'CodeMatiere' => $data[1],
                        'code' => $data[2],
                        'CodeClasse' => $data[3],
                        'CodeEtablissement' => $data[4],
                        'Coefficient' => $data[5],
                        'CodeSpecialite' => $data[6],
                        'CodeCycle' => $data[7],
                        'Dateens' => $data[8] === '' ? null : $data[8],
                        'CodeEnseignant2' => $data[9],
                        'DateModif' => $data[10],
                        'NBRHEURE' => $data[11],
                        'RESERVE1' => $data[12],
                        'RESERVE2' => $data[13],
                        'RESERVE3' => $data[14],
                        'RESERVE4' => $data[15],
                        'RESERVE5' => $data[16],
                    ]
                );
            }
        });

        return redirect('enseignement_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

    public function import_years(Request $request)
    {
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 2, 2, [
            'CodeAnnee', 'Libelle',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
        ]);

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                Annee::updateOrCreate(
                    ['CodeAnnee' => $data[0]],
                    ['Libelle' => $data[1]]
                );
            }
        });

        return redirect('add_year')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

    public function import_sequences(Request $request)
    {
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 2, 2, [
            'CodeEvaluation', 'LibelleEvaluation',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
        ]);

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                SequenceEvaluation::updateOrCreate(
                    ['CodeEvaluation' => $data[0]],
                    ['LibelleEvaluation' => $data[1]]
                );
            }
        });

        return redirect('sequence_evaluation')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }
}   
