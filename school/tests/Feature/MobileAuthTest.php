<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class MobileAuthTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
                'foreign_key_constraints' => true,
            ],
        ]);
        DB::purge('sqlite');

        Schema::create('users', function (Blueprint $table) {
            $table->string('code')->primary();
            $table->string('nom')->nullable();
            $table->string('prenom')->nullable();
            $table->string('contacts')->nullable();
            $table->string('sex')->nullable();
            $table->string('email')->nullable();
            $table->string('login')->nullable();
            $table->string('account_type')->default('parent');
            $table->string('text_password')->nullable();
            $table->string('password')->nullable();
            $table->string('address')->nullable();
            $table->boolean('admin')->default(false);
            $table->string('CodeEtablissement')->nullable();
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamps();
        });
    }

    protected function createUser(array $attributes): User
    {
        return User::forceCreate([
            'code' => $attributes['code'],
            'nom' => $attributes['nom'] ?? 'Nom',
            'prenom' => $attributes['prenom'] ?? 'Prenom',
            'contacts' => $attributes['contacts'] ?? '0600000000',
            'sex' => $attributes['sex'] ?? 'M',
            'email' => $attributes['email'] ?? sprintf('%s@example.com', $attributes['login'] ?? $attributes['code']),
            'login' => $attributes['login'],
            'account_type' => $attributes['account_type'] ?? 'parent',
            'text_password' => $attributes['text_password'] ?? null,
            'password' => $attributes['password'] ?? null,
            'address' => $attributes['address'] ?? 'Address',
            'admin' => $attributes['admin'] ?? false,
            'CodeEtablissement' => $attributes['CodeEtablissement'] ?? 'school-a',
        ]);
    }

    public function test_parent_login_returns_mobile_token_without_text_password(): void
    {
        $user = $this->createUser([
            'code' => 'parent-001',
            'login' => 'parent.demo',
            'account_type' => 'parent',
            'text_password' => 'secret-parent',
            'password' => bcrypt('secret-parent'),
            'CodeEtablissement' => 'school-a',
        ]);

        $response = $this->postJson('/api/mobile/login', [
            'action' => 'LOGIN',
            'login' => 'parent.demo',
            'text_password' => 'secret-parent',
        ]);

        $response->assertOk();
        $payload = $response->json();

        $this->assertSame('parent.demo', $payload[0]['login']);
        $this->assertSame('parent', $payload[0]['account_type']);
        $this->assertSame('parent-001', $payload[0]['code']);
        $this->assertArrayNotHasKey('text_password', $payload[0]);

        $token = $payload[0]['token'];
        $this->assertNotEmpty($token);
        $storedToken = PersonalAccessToken::findToken($token);

        $this->assertNotNull($storedToken);
        $this->assertTrue($storedToken->can('mobischo:mobile'));
        $this->assertFalse($storedToken->can('ai:chat'));

        $this->assertDatabaseHas('personal_access_tokens', [
            'name' => 'mobischo-mobile',
        ]);
    }

    public function test_teacher_principal_and_administrator_logins_return_mobile_tokens(): void
    {
        $this->createUser([
            'code' => 'teacher-001',
            'login' => 'teacher.demo',
            'account_type' => 'enseignant',
            'text_password' => 'secret-teacher',
            'password' => bcrypt('secret-teacher'),
            'CodeEtablissement' => 'school-a',
        ]);

        $this->createUser([
            'code' => 'principal-001',
            'login' => 'principal.demo',
            'account_type' => 'principal',
            'text_password' => 'secret-principal',
            'password' => bcrypt('secret-principal'),
            'CodeEtablissement' => 'school-a',
        ]);

        $this->createUser([
            'code' => 'admin-001',
            'login' => 'admin.demo',
            'account_type' => 'administrateur',
            'text_password' => 'secret-admin',
            'password' => bcrypt('secret-admin'),
            'CodeEtablissement' => 'school-a',
        ]);

        $teacherResponse = $this->postJson('/api/mobile/login', [
            'action' => 'LOGIN',
            'login' => 'teacher.demo',
            'text_password' => 'secret-teacher',
        ]);
        $teacherResponse->assertOk();
        $teacherToken = PersonalAccessToken::findToken($teacherResponse->json('0.token'));
        $this->assertNotNull($teacherToken);
        $this->assertTrue($teacherToken->can('mobischo:mobile'));

        $principalResponse = $this->postJson('/api/mobile/login', [
            'action' => 'LOGIN',
            'login' => 'principal.demo',
            'text_password' => 'secret-principal',
        ]);
        $principalResponse->assertOk();
        $principalMobileToken = PersonalAccessToken::findToken($principalResponse->json('0.token'));
        $principalAiToken = PersonalAccessToken::findToken($principalResponse->json('0.ai_token'));
        $this->assertNotNull($principalMobileToken);
        $this->assertTrue($principalMobileToken->can('mobischo:mobile'));
        $this->assertNotNull($principalAiToken);
        $this->assertTrue($principalAiToken->can('ai:chat'));

        $adminResponse = $this->postJson('/api/mobile/login', [
            'action' => 'LOGIN',
            'login' => 'admin.demo',
            'text_password' => 'secret-admin',
        ]);
        $adminResponse->assertOk();
        $adminToken = PersonalAccessToken::findToken($adminResponse->json('0.token'));
        $this->assertNotNull($adminToken);
        $this->assertTrue($adminToken->can('mobischo:mobile'));
    }

    public function test_logout_revokes_current_token_and_requires_authentication(): void
    {
        $user = $this->createUser([
            'code' => 'parent-logout',
            'login' => 'logout.demo',
            'account_type' => 'parent',
            'text_password' => 'secret-logout',
            'password' => bcrypt('secret-logout'),
            'CodeEtablissement' => 'school-a',
        ]);

        $this->postJson('/api/mobile/logout')->assertUnauthorized();

        $token = $user->createToken('mobischo-mobile', ['mobischo:mobile']);
        $this->withToken($token->plainTextToken)
            ->postJson('/api/mobile/logout')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }
}
