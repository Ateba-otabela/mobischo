<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Annee;
use App\Models\Eleve;
use App\Models\Classe;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class EleveController extends Controller
{
    //

    public function add_student_home(Request $request)
    {
        $schools = Etablissement::orderBy('Nom')->get();
        $selectedSchoolCode = $request->query('CodeEtablissement');
        return view('students.add_student_home',compact(
            'schools',
            'selectedSchoolCode'
        ));
    }
    public function add_student(Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        if (!$school) {
            return redirect()->route('add_student_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $years = Annee::all();
        $year = $years->first();
        $classes = $school->classes()->orderBy('LibelleClasse')->get();
        $class = null;

        if ($classes->isEmpty()) {
            return redirect()->route('add_student_home', [
                'CodeEtablissement' => $school->CodeEtablissement,
            ])
                ->withErrors(['CodeEtablissement' => 'Aucune classe n’est enregistrée pour cet établissement.']);
        }

        if ($request->filled('CodeClasse')) {
            $class = $classes->firstWhere('CodeClasse', $request->CodeClasse);
            if (!$class) {
                return redirect()->route('add_student_home')
                    ->withErrors(['CodeClasse' => 'La classe choisie ne fait pas partie de cet établissement.']);
            }
        } else {
            $class = $classes->first();
        }

        $students = $class
            ? $class->students()->with(['classe', 'parent'])->get()
            : collect();

        return view('students.add_student',compact(
            'class',
            'school',
            'years',
            'year',
            'students',
            'classes'
        ));

    }

    public function sorted_students(Request $request)
    {
        $school = Etablissement::find($request->CodeEtablissement);
        if (!$school) {
            return redirect()->route('add_student_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $class = $school->classes()->where('CodeClasse', $request->CodeClasse)->first();
        if (!$class) {
            return redirect()->route('add_student_home')
                ->withErrors(['CodeClasse' => 'La classe choisie ne fait pas partie de cet établissement.']);
        }

        $year = Annee::find($request->CodeAnnee);
        if (!$year) {
            return redirect()->route('add_student', [
                'CodeEtablissement' => $school->CodeEtablissement,
                'CodeClasse' => $class->CodeClasse,
            ])->withErrors(['CodeAnnee' => 'Veuillez choisir une année scolaire existante.']);
        }

        $students = Eleve::where('CodeAnnee', $year->CodeAnnee)
            ->where('CodeClasse', $class->CodeClasse)
            ->whereHas('classe', function ($query) use ($school) {
                $query->where('CodeEtablissement', $school->CodeEtablissement);
            })
            ->with(['classe', 'parent'])
            ->get();
        $years = Annee::all();
        $classes = $school->classes()->orderBy('LibelleClasse')->get();

        return view('students.add_student',compact(
            'class',
            'year',
            'school',
            'years',
            'students',
            'classes'
        ));

    }

    public function import_students(Request $request)
    {
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 6, 36, [
            0 => 'CodeEleve',
            1 => 'CodeAnnee',
            2 => 'CodeClasse',
            3 => 'CodeConduite',
            4 => 'Nom',
            5 => 'Prenom',
            6 => 'DateNaissance',
            7 => 'LieuNaissance',
            8 => 'Sex',
            9 => 'Nationalite',
            10 => 'dateinscription',
            11 => 'photo',
            12 => 'Excl',
            13 => 'Nomp',
            14 => 'TelP',
            15 => 'Nomm',
            16 => 'REGION',
            17 => 'DEPART',
            18 => 'RELIGION',
            19 => 'SITREG',
            23 => 'ACTIVEEPS',
            24 => 'PROFP',
            25 => 'NOMT',
            28 => 'PROFM',
            29 => 'ADRESSE',
            30 => 'TELT',
            31 => 'PERSONCON',
            32 => 'RESERVE1',
            33 => 'RESERVE2',
            34 => 'RESERVE3',
            35 => 'RESERVE4',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
            2 => 'required|string|max:255',
            3 => 'nullable|string|max:255',
            4 => 'nullable|string|max:255',
            5 => 'nullable|string|max:255',
            6 => 'nullable|string|max:255',
            7 => 'nullable|string|max:255',
            8 => 'nullable|string|max:255',
            9 => 'nullable|string|max:255',
            10 => 'nullable|string|max:255',
            11 => 'nullable|string|max:255',
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
            32 => 'nullable|string|max:255',
            33 => 'nullable|string|max:255',
            34 => 'nullable|string|max:255',
            35 => 'nullable|string|max:255',
        ]);
        foreach ($rows as $index => $row) {
            if (!Annee::where('CodeAnnee', trim($row[1]))->exists()) {
                return redirect('add_student_home')
                    ->withErrors(['csv_file' => 'L’année scolaire de la ligne '.($index + 1).' n’existe pas.']);
            }

            if (!Classe::where('CodeClasse', trim($row[2]))->exists()) {
                return redirect('add_student_home')
                    ->withErrors(['csv_file' => 'La classe de la ligne '.($index + 1).' n’existe pas.']);
            }
        }

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                $student = Eleve::firstOrNew(['CodeEleve' => $data[0]]);
                $student->fill([
                    'CodeAnnee' => $data[1],
                    'CodeClasse' => $data[2],
                ]);

                $legacyFields = [
                    3 => 'CodeConduite',
                    4 => 'Nom',
                    5 => 'Prenom',
                    6 => 'DateNaissance',
                    7 => 'LieuNaissance',
                    8 => 'Sex',
                    9 => 'Nationalite',
                    10 => 'dateinscription',
                    11 => 'photo',
                    12 => 'Excl',
                    13 => 'Nomp',
                    14 => 'TelP',
                    15 => 'Nomm',
                    16 => 'REGION',
                    17 => 'DEPART',
                    18 => 'RELIGION',
                    19 => 'SITREG',
                    23 => 'ACTIVEEPS',
                    24 => 'PROFP',
                    25 => 'NOMT',
                    28 => 'PROFM',
                    29 => 'ADRESSE',
                    30 => 'TELT',
                    31 => 'PERSONCON',
                    32 => 'RESERVE1',
                    33 => 'RESERVE2',
                    34 => 'RESERVE3',
                    35 => 'RESERVE4',
                ];

                foreach ($legacyFields as $column => $field) {
                    if (array_key_exists($column, $data)
                        && (!$student->exists || $data[$column] !== '')) {
                        $student->{$field} = $data[$column];
                    }
                }

                if (!$student->exists && !array_key_exists(10, $data)) {
                    $student->dateinscription = '2022-09-20 03:36:41';
                }

                $student->save();
            }
        });

        return redirect('add_student_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

}
