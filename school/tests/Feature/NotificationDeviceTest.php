<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationDeviceTest extends TestCase
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

        Schema::create('user_devices', function (Blueprint $table) {
            $table->id();
            $table->string('user_code');
            $table->text('fcm_token');
            $table->string('token_hash', 64)->unique();
            $table->string('platform');
            $table->boolean('is_active')->default(true);
            $table->timestamp('revoked_at')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamp('token_updated_at')->nullable();
            $table->timestamps();
        });
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function authenticateAs(string $code, string $accountType = 'parent'): User
    {
        $user = (new User())->forceFill([
            'code' => $code,
            'account_type' => $accountType,
            'admin' => false,
        ]);

        Sanctum::actingAs($user, ['mobischo:mobile']);

        return $user;
    }

    public function test_unauthenticated_registration_is_rejected(): void
    {
        $this->postJson('/api/notifications/devices', [
            'fcm_token' => 'fixture-fcm-token',
            'platform' => 'android',
        ])->assertUnauthorized();
    }

    public function test_authenticated_user_can_register_device_without_returning_token(): void
    {
        $this->authenticateAs('parent-001');
        $token = 'fixture-fcm-token-one';

        $this->postJson('/api/notifications/devices', [
            'fcm_token' => $token,
            'platform' => 'android',
        ])->assertOk()
            ->assertJson([
                'success' => true,
                'message' => 'Device registered successfully',
            ])
            ->assertDontSee($token);

        $this->assertDatabaseHas('user_devices', [
            'user_code' => 'parent-001',
            'fcm_token' => $token,
            'token_hash' => hash('sha256', $token),
            'platform' => 'android',
            'is_active' => 1,
        ]);
    }

    public function test_registering_the_same_token_twice_does_not_create_duplicate_rows(): void
    {
        $this->authenticateAs('teacher-001', 'enseignant');
        $payload = [
            'fcm_token' => 'fixture-fcm-token-two',
            'platform' => 'android',
        ];

        $this->postJson('/api/notifications/devices', $payload)->assertOk();
        $this->postJson('/api/notifications/devices', $payload)->assertOk();

        $this->assertDatabaseCount('user_devices', 1);
    }

    public function test_registration_updates_existing_device_and_reassigns_authenticated_owner(): void
    {
        Carbon::setTestNow('2026-01-01 10:00:00');
        $token = 'fixture-fcm-token-three';
        $this->authenticateAs('teacher-002', 'enseignant');
        $this->postJson('/api/notifications/devices', [
            'fcm_token' => $token,
            'platform' => 'android',
        ])->assertOk();

        $originalTokenUpdatedAt = DB::table('user_devices')
            ->where('token_hash', hash('sha256', $token))
            ->value('token_updated_at');
        DB::table('user_devices')->where('token_hash', hash('sha256', $token))->update([
            'is_active' => false,
            'revoked_at' => now(),
        ]);

        Carbon::setTestNow('2026-01-02 10:00:00');
        $this->authenticateAs('principal-001', 'principal');
        $this->postJson('/api/notifications/devices', [
            'fcm_token' => $token,
            'platform' => 'ios',
        ])->assertOk();

        $device = DB::table('user_devices')
            ->where('token_hash', hash('sha256', $token))
            ->first();

        $this->assertSame('principal-001', $device->user_code);
        $this->assertSame('ios', $device->platform);
        $this->assertSame(1, (int) $device->is_active);
        $this->assertNull($device->revoked_at);
        $this->assertSame($originalTokenUpdatedAt, $device->token_updated_at);
        $this->assertSame('2026-01-02 10:00:00', $device->last_seen_at);
        $this->assertDatabaseCount('user_devices', 1);
    }

    public function test_user_code_is_not_accepted_as_registration_authority(): void
    {
        $this->authenticateAs('teacher-003', 'enseignant');

        $this->postJson('/api/notifications/devices', [
            'user_code' => 'someone-else',
            'fcm_token' => 'fixture-fcm-token-four',
            'platform' => 'android',
        ])->assertUnprocessable();

        $this->assertDatabaseCount('user_devices', 0);
    }

    public function test_authenticated_user_cannot_revoke_another_users_device(): void
    {
        $token = 'fixture-fcm-token-five';
        $this->authenticateAs('parent-002');
        $this->postJson('/api/notifications/devices', [
            'fcm_token' => $token,
            'platform' => 'android',
        ])->assertOk();

        $this->authenticateAs('teacher-004', 'enseignant');
        $this->deleteJson('/api/notifications/devices', [
            'fcm_token' => $token,
        ])->assertNotFound();

        $this->assertDatabaseHas('user_devices', [
            'user_code' => 'parent-002',
            'token_hash' => hash('sha256', $token),
            'is_active' => 1,
            'revoked_at' => null,
        ]);
    }

    public function test_authenticated_user_can_revoke_own_device_without_deleting_it(): void
    {
        Carbon::setTestNow('2026-01-03 10:00:00');
        $token = 'fixture-fcm-token-six';
        $this->authenticateAs('admin-001', 'administrateur');
        $this->postJson('/api/notifications/devices', [
            'fcm_token' => $token,
            'platform' => 'android',
        ])->assertOk();

        Carbon::setTestNow('2026-01-04 10:00:00');
        $this->deleteJson('/api/notifications/devices', [
            'fcm_token' => $token,
        ])->assertOk()
            ->assertJson([
                'success' => true,
                'message' => 'Device revoked successfully',
            ])
            ->assertDontSee($token);

        $this->assertDatabaseCount('user_devices', 1);
        $this->assertDatabaseHas('user_devices', [
            'user_code' => 'admin-001',
            'token_hash' => hash('sha256', $token),
            'is_active' => 0,
            'revoked_at' => '2026-01-04 10:00:00',
        ]);
    }
}