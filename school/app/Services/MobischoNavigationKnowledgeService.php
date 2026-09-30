<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Str;

class MobischoNavigationKnowledgeService
{
    public function __construct(private PrincipalContextService $principalContext)
    {
    }

    public function forUser(User $user): array
    {
        $context = $this->principalContext->resolveForAi($user);
        if ($context === null) {
            return ['confirmed' => false, 'role' => 'unknown', 'navigation' => []];
        }

        $role = $context['role'];
        $navigation = match ($role) {
            'parent' => [
                'dashboard' => 'Tableau de bord parent',
                'bottom_navigation' => [
                    ['label' => 'MOBISCHO', 'screen' => 'Accueil parent'],
                    ['label' => 'ABSENCES', 'screen' => 'MyChildrenAbsences'],
                    ['label' => 'MES ENFANTS', 'screen' => 'MyChildren'],
                    ['label' => 'NOTES', 'screen' => 'MyChildrenNotes'],
                    ['label' => 'AI', 'screen' => 'Mobischo AI'],
                ],
                'shortcuts' => [
                    ['label' => 'RETARD ET ABSENCE', 'screen' => 'MyChildrenAbsences'],
                    ['label' => 'NOTES', 'path' => 'NOTES → sélectionner un enfant → année/période'],
                    ['label' => 'SCOLARITE', 'path' => 'SCOLARITE → sélectionner un enfant → inscriptions'],
                    ['label' => 'DEVOIR & MESSAGE', 'path' => 'DEVOIR & MESSAGE → Devoirs ou Messages'],
                    ['label' => 'Messages', 'screen' => 'Liste des convocations reçues'],
                ],
                'drawer' => [
                    'NOTES', 'ABSENCES', 'HISTORIQUE D\'INSCRIPTIONS', 'MESSAGES', 'MON COMPTE',
                ],
            ],
            'enseignant' => [
                'dashboard' => 'Tableau de bord enseignant',
                'bottom_navigation' => [
                    ['label' => 'MOBISCHO', 'screen' => 'Accueil enseignant'],
                    ['label' => "REGISTRE D'APPEL", 'screen' => 'AbsencesScreen'],
                    ['label' => 'NOTES', 'screen' => 'MarkScreen'],
                    ['label' => 'MATIERES', 'screen' => 'CoursesScreen'],
                    ['label' => 'AI', 'screen' => 'Mobischo AI'],
                ],
                'shortcuts' => [
                    ['label' => "REGISTRE D'APPEL", 'screen' => 'Ajout et consultation des présences'],
                    ['label' => 'MESSAGES', 'screen' => 'TeacherConvocationList'],
                    ['label' => 'NOTES', 'screen' => 'MarkScreen'],
                    ['label' => 'MATIERES', 'screen' => 'CoursesScreen'],
                    ['label' => 'DEVOIR & MESSAGE', 'screen' => 'TeacherDevoirsScreen'],
                ],
                'drawer' => [
                    'MES NOTES', "HEURES D'ABSENCES", 'MES COLLEGUES', 'CONVOCATIONS', 'MON COMPTE',
                ],
            ],
            'principal', 'principal_encadreur', 'administrateur', 'encadreur' => [
                'dashboard' => 'Principal — Encadreur',
                'bottom_navigation' => [
                    ['label' => 'MOBISCHO', 'screen' => 'Tableau de bord'],
                    ['label' => 'Classes', 'screen' => 'Classes et élèves'],
                    ['label' => 'Présence', 'screen' => 'Présences des classes'],
                    ['label' => 'AI', 'screen' => 'Mobischo AI'],
                ],
                'sidebar' => [
                    'Rapports des professeurs',
                    'Alertes de présence',
                    'Appels des professeurs',
                    'Convoquer',
                ],
                'authorization_note' => $role === 'encadreur'
                    ? 'Les données sont limitées aux classes attribuées à cet Encadreur.'
                    : 'Les données sont limitées à l’établissement du compte authentifié.',
            ],
            'admin' => [
                'dashboard' => 'Tableau de bord administrateur',
                'bottom_navigation' => [
                    ['label' => 'MOBISCHO', 'screen' => 'Accueil'],
                    ['label' => 'UTILISATEURS', 'screen' => 'UsersScreen'],
                    ['label' => 'NOTES', 'screen' => 'MarkScreen'],
                    ['label' => 'AI', 'screen' => 'Mobischo AI'],
                ],
                'authorization_note' => 'Les données IA restent limitées à l’établissement du compte authentifié.',
            ],
            default => [],
        };

        return ['confirmed' => $navigation !== [], 'role' => $role, 'navigation' => $navigation];
    }

    public function answerNavigationQuestion(User $user, string $message): ?string
    {
        $normalized = Str::lower(Str::ascii(trim($message)));
        if (!$this->isNavigationQuestion($normalized) || $this->asksForLiveData($normalized)) {
            return null;
        }

        $context = $this->principalContext->resolveForAi($user);
        if ($context === null) {
            return null;
        }

        $role = $context['role'];
        if ($role === 'parent') {
            if (Str::contains($normalized, ['absenc', 'retard', 'attendance'])) {
                return 'Depuis le tableau de bord parent, ouvrez RETARD ET ABSENCE.';
            }
            if (Str::contains($normalized, ['note', 'mark', 'grade', 'resultat'])) {
                return 'Ouvrez NOTES depuis le tableau de bord parent, sélectionnez votre enfant, puis l’année et la période.';
            }
            if (Str::contains($normalized, ['scolarite', 'frais', 'inscription'])) {
                return 'Ouvrez SCOLARITE depuis le tableau de bord parent, puis sélectionnez votre enfant.';
            }
            if (Str::contains($normalized, ['devoir', 'homework'])) {
                return 'Ouvrez DEVOIR & MESSAGE, puis choisissez l’onglet Devoirs.';
            }
            if (Str::contains($normalized, ['convocation', 'message'])) {
                return 'Ouvrez MESSAGES depuis le tableau de bord parent, ou DEVOIR & MESSAGE puis l’onglet Messages pour consulter les convocations.';
            }
            if (Str::contains($normalized, ['enfant', 'children'])) {
                return 'Ouvrez MES ENFANTS depuis le tableau de bord parent.';
            }
        }

        if ($role === 'enseignant') {
            if (Str::contains($normalized, ['absenc', 'attendance', 'appel'])) {
                return "Ouvrez REGISTRE D'APPEL depuis le tableau de bord enseignant.";
            }
            if (Str::contains($normalized, ['note', 'mark', 'grade'])) {
                return 'Ouvrez NOTES depuis le tableau de bord enseignant.';
            }
            if (Str::contains($normalized, ['matiere', 'subject', 'course'])) {
                return 'Ouvrez MATIERES depuis le tableau de bord enseignant.';
            }
            if (Str::contains($normalized, ['convocation'])) {
                return 'Ouvrez CONVOCATIONS dans le menu enseignant.';
            }
            if (Str::contains($normalized, ['devoir', 'homework'])) {
                return 'Ouvrez DEVOIR & MESSAGE depuis le tableau de bord enseignant.';
            }
        }

        if (in_array($role, ['principal', 'principal_encadreur', 'administrateur', 'encadreur'], true)) {
            if (Str::contains($normalized, ['presence', 'attendance', 'absence', 'retard'])) {
                return 'Ouvrez Présence dans la navigation principale. Pour les appels détaillés, ouvrez Appels des professeurs dans le menu latéral.';
            }
            if (Str::contains($normalized, ['classe', 'class', 'eleve', 'student'])) {
                return 'Ouvrez Classes dans la navigation principale, puis choisissez une classe.';
            }
            if (Str::contains($normalized, ['rapport', 'report'])) {
                return 'Ouvrez Rapports des professeurs dans le menu latéral.';
            }
            if (Str::contains($normalized, ['alerte', 'alert'])) {
                return 'Ouvrez Alertes de présence dans le menu latéral.';
            }
            if (Str::contains($normalized, ['convoquer', 'convocation'])) {
                return 'Ouvrez Convoquer dans le menu latéral.';
            }
        }

        if ($role === 'admin' && Str::contains($normalized, ['utilisateur', 'user'])) {
            return 'Ouvrez UTILISATEURS dans la navigation principale.';
        }

        return null;
    }

    private function isNavigationQuestion(string $message): bool
    {
        return Str::contains($message, [
            'where', 'where can i', 'where do i', 'where can i see', 'how do i access',
            'how do i find', 'how do i view', 'how can i find', 'how to see',
            'which menu', 'find in the app', 'ou trouver', 'ou voir', 'ou se trouve',
            'ou puis-je', 'ou consulter', 'comment acceder', 'comment trouver',
            'quel menu', 'dans quel menu',
        ]);
    }

    private function asksForLiveData(string $message): bool
    {
        return Str::contains($message, [
            'how many', 'how much', 'number of', 'count of', 'current', 'currently',
            'combien', 'nombre de', 'actuellement', 'aujourd', 'total',
        ]);
    }
}