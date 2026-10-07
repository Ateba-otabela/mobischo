<?php

namespace App\Http\Controllers;

use App\Models\Annee;
use App\Models\Classe;
use App\Models\Inscription;
use Illuminate\Http\Request;
use App\Models\Etablissement;
use App\Models\TrancheScholarite;
use App\Models\HistoriqueInscription;
use App\Models\Eleve;
use Illuminate\Support\Facades\DB;

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
        if (!$school) {
            return redirect()->route('tranches_scholarites_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

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
        if (!$school) {
            return redirect()->route('inscriptions_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $years = Annee::all();
        $tranches = $school->tranches()->get();
        $inscriptions = Inscription::whereHas('eleve.classe', function ($query) use ($school) {
            $query->where('CodeEtablissement', $school->CodeEtablissement);
        })->with(['eleve.classe'])->limit(100)->get();
        $classe = null;
        $year = null;
        $tranche = null;
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
        if (!$school) {
            return redirect()->route('inscriptions_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $years = Annee::all();
        $tranches = $school->tranches()->get();
        $year = Annee::find($request->CodeAnnee);
        $tranche = TrancheScholarite::find($request->code);
        $classe = $school->classes()->where('CodeClasse', $request->CodeClasse)->first();
        if (!$classe || !$year || !$tranche ||
            !$tranches->contains('code', $tranche->code)) {
            return redirect()->route('inscriptions', [
                'CodeEtablissement' => $school->CodeEtablissement,
            ])->withErrors(['filters' => 'Veuillez choisir une classe, une année et une tranche valides pour cet établissement.']);
        }

        $inscriptions = Inscription::where('Tranche', $tranche->code)
            ->where('codeannee', $year->CodeAnnee)
            ->whereHas('eleve', function ($query) use ($classe, $school) {
                $query->where('CodeClasse', $classe->CodeClasse)
                    ->whereHas('classe', function ($classQuery) use ($school) {
                        $classQuery->where('CodeEtablissement', $school->CodeEtablissement);
                    });
            })
            ->with(['eleve.classe'])
            ->get();

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
        if (!$school) {
            return redirect()->route('historique_inscriptions_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $years = Annee::all();
        $tranches = $school->tranches()->get();
        $inscriptions = HistoriqueInscription::whereHas('inscription.eleve.classe', function ($query) use ($school) {
            $query->where('CodeEtablissement', $school->CodeEtablissement);
        })->with(['inscription.eleve.classe'])->limit(100)->get();
        $classe = null;
        $year = null;
        $tranche = null;
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
        if (!$school) {
            return redirect()->route('historique_inscriptions_home')
                ->withErrors(['CodeEtablissement' => 'Veuillez choisir un établissement existant.']);
        }

        $years = Annee::all();
        $tranches = $school->tranches()->get();
        $year = Annee::find($request->CodeAnnee);
        $tranche = TrancheScholarite::find($request->code);
        $classe = $school->classes()->where('CodeClasse', $request->CodeClasse)->first();
        if (!$classe || !$year || !$tranche ||
            !$tranches->contains('code', $tranche->code)) {
            return redirect()->route('historique_inscriptions', [
                'CodeEtablissement' => $school->CodeEtablissement,
            ])->withErrors(['filters' => 'Veuillez choisir une classe, une année et une tranche valides pour cet établissement.']);
        }

        $inscriptions = HistoriqueInscription::where('Tranche', $tranche->code)
            ->where('codeannee', $year->CodeAnnee)
            ->whereHas('inscription.eleve', function ($query) use ($classe, $school) {
                $query->where('CodeClasse', $classe->CodeClasse)
                    ->whereHas('classe', function ($classQuery) use ($school) {
                        $classQuery->where('CodeEtablissement', $school->CodeEtablissement);
                    });
            })
            ->with(['inscription.eleve.classe'])
            ->get();

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
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 2, 2, [
            'code', 'libellet',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
        ]);

        if (!Etablissement::where('CodeEtablissement', '11201')->exists()) {
            return redirect('tranches_scholarites_home')
                ->withErrors(['csv_file' => 'L’établissement par défaut des tranches de scolarité (11201) n’existe pas.']);
        }

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                TrancheScholarite::updateOrCreate(
                    ['code' => $data[0]],
                    ['libellet' => $data[1]]
                );
            }
        });

        return redirect('tranches_scholarites_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }


    public function import_inscriptions(Request $request)
    {
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 14, 14, [
            'NUMFAC', 'CodeInscription', 'CodeEleve', 'DateInscription', 'Tranche',
            'codeannee', 'Montantins', 'Avance', 'Reste', 'Montantt', 'libinscrip',
            'heure', 'caissier', 'remise',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
            2 => 'required|string|max:255',
            3 => 'nullable|date',
            4 => 'nullable|string|max:255',
            5 => 'required|string|max:255',
            6 => 'nullable|numeric|min:0',
            7 => 'nullable|numeric|min:0',
            8 => 'nullable|numeric|min:0',
            9 => 'nullable|numeric|min:0',
            10 => 'nullable|string|max:255',
            11 => 'nullable|string|max:255',
            12 => 'nullable|string|max:255',
            13 => 'nullable|numeric|min:0',
        ]);

        foreach ($rows as $index => $row) {
            if (!Eleve::where('CodeEleve', $row[2])->exists()
                || !Annee::where('CodeAnnee', $row[5])->exists()
                || ($row[4] !== '' && !TrancheScholarite::where('code', $row[4])->exists())) {
                return redirect('inscriptions_home')
                    ->withErrors(['csv_file' => 'Une référence d’élève, d’année ou de tranche de la ligne '.($index + 1).' est invalide.']);
            }
        }

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                Inscription::updateOrCreate(
                    ['NUMFAC' => $data[0]],
                    [
                        'CodeInscription' => $data[1],
                        'CodeEleve' => $data[2],
                        'DateInscription' => $data[3],
                        'Tranche' => $data[4],
                        'codeannee' => $data[5],
                        'Montantins' => $data[6],
                        'Avance' => $data[7],
                        'Reste' => $data[8],
                        'Montantt' => $data[9],
                        'libinscrip' => $data[10],
                        'heure' => $data[11],
                        'caissier' => $data[12],
                        'remise' => $data[13],
                    ]
                );
            }
        });

        return redirect('inscriptions_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

    public function import_historique_inscriptions(Request $request)
    {
        $rows = $this->validateLegacyCsvRows($this->readLegacyCsvRows($request, 14, 14, [
            'NUMFAC', 'CodeInscription', 'CodeEleve', 'DateInscription', 'Tranche',
            'codeannee', 'Montantins', 'Avance', 'Reste', 'Montantt', 'libinscrip',
            'heure', 'caissier', 'remise',
        ]), [
            0 => 'required|string|max:255',
            1 => 'required|string|max:255',
            2 => 'required|string|max:255',
            3 => 'nullable|date',
            4 => 'nullable|string|max:255',
            5 => 'required|string|max:255',
            6 => 'nullable|numeric|min:0',
            7 => 'nullable|numeric|min:0',
            8 => 'nullable|numeric|min:0',
            9 => 'nullable|numeric|min:0',
            10 => 'nullable|string|max:255',
            11 => 'nullable|string|max:255',
            12 => 'nullable|string|max:255',
            13 => 'nullable|numeric|min:0',
        ]);

        foreach ($rows as $index => $row) {
            if (!Eleve::where('CodeEleve', $row[2])->exists()
                || !Annee::where('CodeAnnee', $row[5])->exists()
                || ($row[4] !== '' && !TrancheScholarite::where('code', $row[4])->exists())) {
                return redirect('historique_inscriptions_home')
                    ->withErrors(['csv_file' => 'Une référence d’élève, d’année ou de tranche de la ligne '.($index + 1).' est invalide.']);
            }
        }

        DB::transaction(function () use ($rows): void {
            foreach ($rows as $data) {
                HistoriqueInscription::create([
                    'NUMFAC' => $data[0],
                    'CodeInscription' => $data[1],
                    'CodeEleve' => $data[2],
                    'DateInscription' => $data[3],
                    'Tranche' => $data[4],
                    'codeannee' => $data[5],
                    'Montantins' => $data[6],
                    'Avance' => $data[7],
                    'Reste' => $data[8],
                    'Montantt' => $data[9],
                    'libinscrip' => $data[10],
                    'heure' => $data[11],
                    'caissier' => $data[12],
                    'remise' => $data[13],
                ]);
            }
        });

        return redirect('historique_inscriptions_home')->with(['message'=>"L'importation a été effectuée avec succès",'alert'=>'border-success']);
    }

}
