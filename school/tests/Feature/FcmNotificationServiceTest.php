<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserDevice;
use App\Services\FcmNotificationService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FcmNotificationServiceTest extends TestCase
{
    use RefreshDatabase;

    protected string $serviceAccountPath;

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
        ]);
        DB::purge('sqlite');

        Schema::create('users', function (Blueprint $table) {
            $table->string('code')->primary();
            $table->string('account_type')->nullable();
            $table->boolean('admin')->default(false);
            $table->string('nom')->nullable();
            $table->string('prenom')->nullable();
            $table->timestamps();
        });

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

        $this->serviceAccountPath = tempnam(sys_get_temp_dir(), 'fcm_sa_');
        file_put_contents($this->serviceAccountPath, json_encode([
            'type' => 'service_account',
            'project_id' => 'mobischo-8f908',
            'private_key_id' => 'test-key-id',
            'private_key' => $this->testPrivateKeyPem(),
            'client_email' => 'firebase-adminsdk@test-project.iam.gserviceaccount.com',
            'client_id' => '1234567890',
            'auth_uri' => 'https://accounts.google.com/o/oauth2/auth',
            'token_uri' => 'https://oauth2.googleapis.com/token',
            'auth_provider_x509_cert_url' => 'https://www.googleapis.com/oauth2/v1/certs',
            'client_x509_cert_url' => 'https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk%40test-project.iam.gserviceaccount.com',
        ]));

        config([
            'services.fcm.project_id' => 'mobischo-8f908',
            'services.fcm.credentials_path' => $this->serviceAccountPath,
        ]);
    }

    protected function tearDown(): void
    {
        if (is_file($this->serviceAccountPath)) {
            unlink($this->serviceAccountPath);
        }

        parent::tearDown();
    }

    public function test_service_configuration_is_loaded_correctly(): void
    {
        $this->assertSame('mobischo-8f908', config('services.fcm.project_id'));
        $this->assertSame($this->serviceAccountPath, config('services.fcm.credentials_path'));
        $this->assertFileExists(config('services.fcm.credentials_path'));
    }

    public function test_jwt_generation_logic(): void
    {
        $service = new FcmNotificationService();
        $payload = [
            'project_id' => 'mobischo-8f908',
            'client_email' => 'firebase-adminsdk@test-project.iam.gserviceaccount.com',
            'private_key' => $this->testPrivateKeyPem(),
            'token_uri' => 'https://oauth2.googleapis.com/token',
        ];

        $jwt = $service->buildJwtAssertion($payload, 1700000000);
        $parts = explode('.', $jwt);
        $this->assertCount(3, $parts);

        $claims = json_decode(base64_decode(strtr($parts[1], '-_', '+/')), true);

        $this->assertSame('firebase-adminsdk@test-project.iam.gserviceaccount.com', $claims['iss']);
        $this->assertSame('https://www.googleapis.com/auth/firebase.messaging', $claims['scope']);
        $this->assertSame('https://oauth2.googleapis.com/token', $claims['aud']);
        $this->assertSame(1700000000, $claims['iat']);
        $this->assertSame(1700003600, $claims['exp']);

        $signature = explode('.', $jwt)[2];
        $this->assertNotSame('', $signature);
        $this->assertMatchesRegularExpression('/^[A-Za-z0-9_-]+$/', $signature);
    }

    public function test_oauth_token_request_handling(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'access-token-123',
                'expires_in' => 3600,
                'token_type' => 'Bearer',
            ], 200),
        ]);

        $service = new FcmNotificationService();
        $token = $service->getAccessToken();

        $this->assertSame('access-token-123', $token);
        Http::assertSent(function ($request) {
            return str_contains($request->url(), 'oauth2.googleapis.com/token')
                && $request['grant_type'] === 'urn:ietf:params:oauth:grant-type:jwt-bearer';
        });
    }

    public function test_fcm_request_construction(): void
    {
        $service = new FcmNotificationService();

        $request = $service->buildFcmRequest('abc-device-token', 'Title', 'Body', ['type' => 'test']);

        $this->assertSame('abc-device-token', $request['message']['token']);
        $this->assertSame('Title', $request['message']['notification']['title']);
        $this->assertSame('Body', $request['message']['notification']['body']);
        $this->assertSame('test', $request['message']['data']['type']);
    }

    public function test_successful_fcm_response(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'access-token-123',
                'token_type' => 'Bearer',
                'expires_in' => 3600,
            ], 200),
            'https://fcm.googleapis.com/v1/projects/mobischo-8f908/messages:send' => Http::response([
                'name' => 'projects/mobischo-8f908/messages/message-id-123',
            ], 200),
        ]);

        $service = new FcmNotificationService();
        $result = $service->sendToToken('device-token-123', 'MOBISCHO Test', 'Push notifications are working.', ['type' => 'test']);

        $this->assertTrue($result['success']);
        $this->assertSame('projects/mobischo-8f908/messages/message-id-123', $result['message_id']);

        Http::assertSent(function ($request) {
            return str_contains($request->url(), 'fcm.googleapis.com/v1/projects/mobischo-8f908/messages:send')
                && $request->hasHeader('Authorization', 'Bearer access-token-123')
                && $request->hasHeader('Content-Type', 'application/json')
                && ($request['message']['token'] ?? null) === 'device-token-123'
                && ($request['message']['notification']['title'] ?? null) === 'MOBISCHO Test'
                && ($request['message']['notification']['body'] ?? null) === 'Push notifications are working.'
                && ($request['message']['data']['type'] ?? null) === 'test';
        });
    }

    public function test_invalid_unregistered_token_handling_marks_device_inactive(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'access-token-123',
                'token_type' => 'Bearer',
                'expires_in' => 3600,
            ], 200),
            'https://fcm.googleapis.com/v1/projects/mobischo-8f908/messages:send' => Http::response([
                'error' => [
                    'status' => 'INVALID_ARGUMENT',
                    'message' => 'Requested entity was not found. The registration token is not valid.',
                ],
            ], 400),
        ]);

        $service = new FcmNotificationService();
        $result = $service->sendToToken('invalid-token', 'Title', 'Body');

        $this->assertSame('invalid_token', $result['status']);
        $this->assertFalse(($result['success'] ?? true));
    }

    public function test_generic_firebase_failure_is_not_marked_invalid(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'access-token-123',
                'token_type' => 'Bearer',
                'expires_in' => 3600,
            ], 200),
            'https://fcm.googleapis.com/v1/projects/mobischo-8f908/messages:send' => Http::response([
                'error' => [
                    'status' => 'INTERNAL',
                    'message' => 'Server error encountered while sending message.',
                ],
            ], 500),
        ]);

        $service = new FcmNotificationService();
        $result = $service->sendToToken('device-token', 'Title', 'Body');

        $this->assertSame('error', $result['status']);
        $this->assertFalse($result['success']);
    }

    public function test_send_to_user_sends_to_each_active_device_and_invalidates_bad_tokens(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'access-token-123',
                'token_type' => 'Bearer',
                'expires_in' => 3600,
            ], 200),
            'https://fcm.googleapis.com/v1/projects/mobischo-8f908/messages:send' => function ($request) {
                $payload = $request->data();
                $token = $payload['message']['token'] ?? '';

                if ($token === 'valid-token-1') {
                    return Http::response(['name' => 'projects/mobischo-8f908/messages/msg-1'], 200);
                }

                return Http::response([
                    'error' => [
                        'status' => 'INVALID_ARGUMENT',
                        'message' => 'The registration token is not valid.',
                    ],
                ], 400);
            },
        ]);

        UserDevice::query()->create([
            'user_code' => 'student-001',
            'fcm_token' => 'valid-token-1',
            'token_hash' => hash('sha256', 'valid-token-1'),
            'platform' => 'android',
            'is_active' => true,
        ]);

        UserDevice::query()->create([
            'user_code' => 'student-001',
            'fcm_token' => 'invalid-token-2',
            'token_hash' => hash('sha256', 'invalid-token-2'),
            'platform' => 'ios',
            'is_active' => true,
        ]);

        $service = new FcmNotificationService();
        $summary = $service->sendToUser('student-001', 'Title', 'Body', ['type' => 'test']);

        $this->assertSame(2, $summary['attempted']);
        $this->assertSame(1, $summary['succeeded']);
        $this->assertSame(1, $summary['failed']);
        $this->assertSame(1, $summary['invalidated']);

        $this->assertDatabaseHas('user_devices', [
            'user_code' => 'student-001',
            'fcm_token' => 'invalid-token-2',
            'is_active' => 0,
        ]);
    }

    public function test_protected_test_endpoint_requires_authorization(): void
    {
        $this->postJson('/api/notifications/test', ['user_code' => '672320608'])
            ->assertUnauthorized();
    }

    public function test_protected_test_endpoint_sends_notice_to_target_user_code(): void
    {
        $user = User::forceCreate([
            'code' => '672320608',
            'account_type' => 'parent',
            'admin' => false,
            'nom' => 'Test',
            'prenom' => 'User',
        ]);

        $this->assertNotNull($user);

        UserDevice::query()->create([
            'user_code' => '672320608',
            'fcm_token' => 'valid-user-token',
            'token_hash' => hash('sha256', 'valid-user-token'),
            'platform' => 'android',
            'is_active' => true,
        ]);

        Http::fake([
            'https://oauth2.googleapis.com/token' => Http::response([
                'access_token' => 'access-token-123',
                'token_type' => 'Bearer',
                'expires_in' => 3600,
            ], 200),
            'https://fcm.googleapis.com/v1/projects/mobischo-8f908/messages:send' => Http::response([
                'name' => 'projects/mobischo-8f908/messages/msg-user-1',
            ], 200),
        ]);

        Sanctum::actingAs($user, ['mobischo:mobile']);

        $this->postJson('/api/notifications/test', ['user_code' => '672320608'])
            ->assertOk()
            ->assertJsonPath('message', 'Test notification dispatched.')
            ->assertJsonPath('data.attempted', 1)
            ->assertJsonPath('data.succeeded', 1);
    }

    protected function testPrivateKeyPem(): string
    {
        return <<<'PEM'
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAsmRPhCqRxgzKGJBKH9nBm3YYDFUlBlcuVSlTPKBDwJe5Db4d
821vRPkfSvfz7//jjeBOeyjRRzCLbg0oLdvjKua7Om21kuAvlcxF20Q/NJmZc2xQ
e8ku8qJB3Valq/OrWiFfxc7rChGhbtjycI3Eku6+2vuZvYJtbrAVkzKLKPxAFOeS
Zj0lu4Ojz+SOBNuACySwjWtviVD+KuaHDGITnR0rfxOiisl6BpokxbD2yt8DS3RN
ANdbXAfpxFChdf3yMWstR0g1TPUAFhUZgF3YXONa6OgJQnFiCqT7Q9K0ayk0r2KE
7CkEra03el09M+t05gAkc/a5qPFmO6skz31U/wIDAQABAoIBACESg8Nm+PuUp2sC
ZRuejUw7Cp5OsryIMSjMrofQ1n7AIiiwFHFq2nQZE3ocmfbmo9NLwIEIwjPGhjLy
8X3/BBCSEif06vK96VSGOHU8I9OmnlJNxGYOmEuXVUqpo7FLTXs6ML1FbUHCnwEj
615+ifELngqPFqORqKQatQVDG5WPTyi7jZkPFUpV7l+HFPVaie6iZMxZZZA9YYhy
cxINmK8SB4b4uPdbIQD8wq729lmwsitaQY/D9ZG7qRYjkWyMMYOtK15v6KIsDwdk
tFHNJj9SxXcS2Bwu2JJI5QRT9ejYdxDEybksmYFMF4gNaPqpICJsg8m1sNcIPfXV
+8zNQQECgYEA34AuLpd+IZsRwtPY29XqEX/nLj6dS1lJNMPAlWctZBXbOUFpuqD3
AMjbMAyIRzsLen+WlIc0wX98U8CAQ22FrFRecWy3mqD6ZPIgR58JbnRd7d6pCdzP
GoKA1xXWriYFzmGK1pl0a2XTyZnhF4HRHG7JqaNSVziRH227Pdq4W0ECgYEAzFTz
lAC1siJ75KmBTF05K0ONq8zMqxXMq1GSrNH8ii2nMiVixmkVLGrsxNut0fn0aA14
D1M2sdh5UngFpDGQdby2ydo+MrX+X5DvjvOLnbAzZ7EHhD4WJfbwMpDS+ac7a9ct
+R9Jt7U1/j7GNR4QLFACTlpINoORr5AI5hjG4D8CgYBzUbkCc0oyXse4RgST0XkX
lG4dL1OLqEMchZBdxkHmbVyS20yJbjpkXj6yORUr46xVhXWVp3myCWyF7kKACAe7
1kBwt864ay0nXsMHEWkVY9d/P67qltMJc6K01+DQNHA0f6Hafo1SSNURJWO99E6I
JCXLcKiwtlAy7jR5gtwywQKBgDCU6i0AVjL6W/asDp/3ckZFE4QLd4Yd8sGw7WzF
qIO6Awy7Mtb12SDsc0sC6DsKcP/kY+1Q3ao/S+k9vCmj1zMHIXawuyUXfFmAflTA
tytQ34gB4UWh9WYlZkq/gEn3Zvtm9/lJZR+WqDXA+yNZ+IJwq3uxn4XGlnblihgb
P/3FAoGAOQqMT/8nvKIwuiyPk17qdgqr1hSsXPSPUK4vpXyjjkaK2dlZ2pHa3p14
eaQZFCz5WHZbdQ/vBpeed6rub7gdrD3ZejfQ8NQZCiwgmY/m81HsBUCGiUAULXmJ
hpKD6Mdp1ByVi3wg1SBGEgKGbRGCU4hK0jCka2pb0oFkN2eUpqQ=
-----END RSA PRIVATE KEY-----
PEM;
    }
}
