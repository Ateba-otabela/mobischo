<?php

namespace App\Providers;

use App\Services\PrincipalContextService;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AuthServiceProvider extends ServiceProvider
{
    /**
     * The policy mappings for the application.
     *
     * @var array<class-string, class-string>
     */
    protected $policies = [
        // 'App\Models\Model' => 'App\Policies\ModelPolicy',
    ];

    /**
     * Register any authentication / authorization services.
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Gate::define('mobischo:mobile', function ($user) {
            $accountType = strtolower(trim((string) ($user->account_type ?? '')));

            return (bool) $user->admin || in_array($accountType, [
                'parent',
                'enseignant',
                'principal',
                'encadreur',
                'principal_encadreur',
                'administrateur',
            ], true);
        });

        Gate::define('ai:chat', function ($user) {
            return $user instanceof \App\Models\User
                && app(PrincipalContextService::class)->canUseAi($user);
        });
    }
}
