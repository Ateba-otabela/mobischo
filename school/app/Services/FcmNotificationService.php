<?php

namespace App\Services;

use App\Models\UserDevice;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class FcmNotificationService
{
    public function sendToToken(
        string $fcmToken,
        string $title,
        string $body,
        array $data = []
    ): array {
        $accessToken = $this->getAccessToken();
        $payload = $this->buildFcmRequest($fcmToken, $title, $body, $data);

        $response = Http::withToken($accessToken, 'Bearer')
            ->acceptJson()
            ->post($this->getSendUrl(), $payload);

        if ($response->successful()) {
            Log::info('FCM HTTP send succeeded.', [
                'http_status' => $response->status(),
                'message_id' => $response->json('name'),
            ]);

            return [
                'success' => true,
                'message_id' => $response->json('name'),
                'status' => 'success',
                'http_status' => $response->status(),
            ];
        }

        $errorStatus = $response->json('error.status');
        $status = $errorStatus ?? $response->status();
        $message = (string) ($response->json('error.message') ?? 'FCM request failed.');
        $message = $this->sanitizeErrorMessage($message, $fcmToken);
        $invalidToken = $this->isInvalidRegistrationTokenError($status, $message, $response->json('error'));

        Log::warning('FCM HTTP send failed.', [
            'http_status' => $response->status(),
            'fcm_error_status' => $errorStatus,
            'fcm_error_message' => $response->json('error.message'),
        ]);

        return [
            'success' => false,
            'status' => $invalidToken ? 'invalid_token' : 'error',
            'error' => $message,
            'http_status' => $response->status(),
            'fcm_error_status' => $errorStatus,
        ];
    }

    public function sendToUser(
        string $userCode,
        string $title,
        string $body,
        array $data = []
    ): array {
        if (!Schema::hasTable('user_devices')) {
            Log::warning('FCM delivery skipped because user_devices is unavailable.', [
                'user_code' => $userCode,
            ]);

            return [
                'status' => 'device_registry_unavailable',
                'attempted' => 0,
                'succeeded' => 0,
                'failed' => 0,
                'invalidated' => 0,
                'errors' => [[
                    'status' => 'device_registry_unavailable',
                    'message' => 'The FCM device registry is unavailable.',
                ]],
            ];
        }

        $devices = UserDevice::query()
            ->where('user_code', $userCode)
            ->where('is_active', true)
            ->whereNull('revoked_at')
            ->get();

        $attempted = 0;
        $succeeded = 0;
        $failed = 0;
        $invalidated = 0;
        $errors = [];

        Log::info('FCM active devices resolved.', [
            'user_code' => $userCode,
            'active_device_count' => $devices->count(),
        ]);

        foreach ($devices as $device) {
            $attempted++;
            $token = (string) $device->fcm_token;

            try {
                $result = $this->sendToToken($token, $title, $body, $data);
            } catch (\Throwable $exception) {
                $safeMessage = $this->sanitizeErrorMessage($exception->getMessage(), $token);
                Log::error('FCM device send threw an exception.', [
                    'user_code' => $userCode,
                    'exception' => get_class($exception),
                    'error' => $safeMessage,
                ]);

                throw new \RuntimeException($safeMessage, (int) $exception->getCode(), $exception);
            }

            Log::info('FCM device send result.', [
                'user_code' => $userCode,
                'http_status' => $result['http_status'] ?? null,
                'fcm_status' => $result['fcm_error_status'] ?? $result['status'] ?? null,
                'fcm_error_message' => isset($result['error']) ? $this->sanitizeErrorMessage((string) $result['error'], $token) : null,
                'success' => (bool) ($result['success'] ?? false),
                'message_id' => $result['message_id'] ?? null,
            ]);

            if (($result['success'] ?? false) === true) {
                $succeeded++;
                continue;
            }

            $failed++;
            $errors[] = [
                'http_status' => $result['http_status'] ?? null,
                'status' => $result['status'] ?? 'error',
                'firebase_status' => $result['fcm_error_status'] ?? null,
                'message' => $this->sanitizeErrorMessage((string) ($result['error'] ?? 'FCM request failed.'), $token),
            ];

            if (($result['status'] ?? null) === 'invalid_token') {
                $device->is_active = false;
                $device->revoked_at = now();
                $device->save();
                $invalidated++;
            }
        }

        $status = $attempted === 0
            ? 'no_active_device'
            : ($failed === 0 ? 'accepted' : ($succeeded > 0 ? 'partial' : 'rejected'));

        return [
            'status' => $status,
            'attempted' => $attempted,
            'succeeded' => $succeeded,
            'failed' => $failed,
            'invalidated' => $invalidated,
            'errors' => $errors,
        ];
    }

    public function buildFcmRequest(string $fcmToken, string $title, string $body, array $data = []): array
    {
        $messageData = $data;
        if (!array_key_exists('type', $messageData)) {
            $messageData['type'] = 'notification';
        }

        return [
            'message' => [
                'token' => $fcmToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => $messageData,
            ],
        ];
    }

    public function getAccessToken(): string
    {
        $serviceAccount = $this->readServiceAccount();
        $jwtAssertion = $this->buildJwtAssertion($serviceAccount);

        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwtAssertion,
        ]);

        Log::info('FCM OAuth token response received.', [
            'http_status' => $response->status(),
            'success' => $response->successful(),
            'oauth_error' => $response->json('error'),
            'oauth_error_description' => $response->json('error_description'),
        ]);

        if ($response->failed()) {
            $errorMessage = (string) ($response->json('error_description') ?? $response->json('error') ?? 'Google OAuth token request failed.');
            throw new \RuntimeException('FCM OAuth request failed: ' . $errorMessage);
        }

        $token = (string) $response->json('access_token');

        if ($token === '') {
            throw new \RuntimeException('Google OAuth response did not include an access_token.');
        }

        return $token;
    }

    public function buildJwtAssertion(array $serviceAccount, ?int $issuedAt = null): string
    {
        $issuedAt = $issuedAt ?? time();
        $header = [
            'alg' => 'RS256',
            'typ' => 'JWT',
        ];

        $claims = [
            'iss' => (string) $serviceAccount['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $issuedAt,
            'exp' => $issuedAt + 3600,
        ];

        $encodedHeader = $this->base64UrlEncode(json_encode($header));
        $encodedClaims = $this->base64UrlEncode(json_encode($claims));
        $signingInput = $encodedHeader . '.' . $encodedClaims;

        $privateKey = (string) $serviceAccount['private_key'];
        if (openssl_sign($signingInput, $signature, $privateKey, OPENSSL_ALGO_SHA256) === false) {
            throw new \RuntimeException('Unable to sign the Firebase JWT assertion.');
        }

        return $signingInput . '.' . $this->base64UrlEncode($signature);
    }

    protected function readServiceAccount(): array
    {
        $credentialsPath = trim((string) config('services.fcm.credentials_path', ''));
        if ($credentialsPath === '' || !is_file($credentialsPath) || !is_readable($credentialsPath)) {
            throw new \RuntimeException('FCM service-account credentials path is not configured or readable.');
        }

        $credentialContents = @file_get_contents($credentialsPath);
        if ($credentialContents === false) {
            throw new \RuntimeException('Unable to read the configured FCM service-account credentials file.');
        }

        $payload = json_decode($credentialContents, true);
        if (!is_array($payload)) {
            throw new \RuntimeException('FCM service-account credentials file is not valid JSON.');
        }

        $requiredKeys = ['project_id', 'client_email', 'private_key', 'token_uri'];
        foreach ($requiredKeys as $requiredKey) {
            if (!array_key_exists($requiredKey, $payload) || trim((string) $payload[$requiredKey]) === '') {
                throw new \RuntimeException('FCM service-account credentials are missing the required field: ' . $requiredKey . '.');
            }
        }

        return $payload;
    }

    protected function isInvalidRegistrationTokenError(string $status, string $message, ?array $errorPayload = null): bool
    {
        $candidates = [$status, $message];

        if (is_array($errorPayload)) {
            $candidates[] = (string) ($errorPayload['status'] ?? '');
            $candidates[] = (string) ($errorPayload['message'] ?? '');
        }

        $combined = strtolower(implode(' ', array_filter($candidates, static fn ($candidate) => trim((string) $candidate) !== '')));

        return str_contains($combined, 'invalid registration token')
            || str_contains($combined, 'not a valid fcm registration token')
            || str_contains($combined, 'registration token is not valid')
            || str_contains($combined, 'unregistered device')
            || str_contains($combined, 'not registered');
    }

    protected function sanitizeErrorMessage(string $message, string $fcmToken): string
    {
        $message = str_replace($fcmToken, '[redacted]', $message);
        $message = preg_replace('/Bearer\s+\S+/i', 'Bearer [redacted]', $message) ?? $message;
        $message = preg_replace('/\bya29\.[A-Za-z0-9._~-]+/', '[redacted]', $message) ?? $message;
        $message = preg_replace('/-----BEGIN [^-]+-----.*?-----END [^-]+-----/s', '[redacted]', $message) ?? $message;

        return substr($message, 0, 500);
    }

    protected function getSendUrl(): string
    {
        $projectId = trim((string) config('services.fcm.project_id', ''));
        if ($projectId === '') {
            throw new \RuntimeException('FCM project ID is not configured.');
        }

        return 'https://fcm.googleapis.com/v1/projects/' . $projectId . '/messages:send';
    }

    protected function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
