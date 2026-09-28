<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationDeviceController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        if ($request->exists('user_code')) {
            return response()->json(['message' => 'The user_code field is not accepted.'], 422);
        }

        $validated = $request->validate([
            'fcm_token' => 'required|string|max:4096',
            'platform' => 'required|in:android,ios',
        ]);

        $user = $request->user();
        if (!$user instanceof User) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $fcmToken = $validated['fcm_token'];
        $tokenHash = hash('sha256', $fcmToken);
        $now = now();

        DB::transaction(function () use ($user, $fcmToken, $tokenHash, $validated, $now) {
            $device = UserDevice::where('token_hash', $tokenHash)
                ->lockForUpdate()
                ->first();

            if ($device) {
                if ($device->fcm_token !== $fcmToken) {
                    $device->token_updated_at = $now;
                }

                $device->user_code = (string) $user->code;
                $device->fcm_token = $fcmToken;
                $device->platform = $validated['platform'];
                $device->is_active = true;
                $device->revoked_at = null;
                $device->last_seen_at = $now;
                $device->save();

                return;
            }

            UserDevice::create([
                'user_code' => (string) $user->code,
                'fcm_token' => $fcmToken,
                'token_hash' => $tokenHash,
                'platform' => $validated['platform'],
                'is_active' => true,
                'last_seen_at' => $now,
                'token_updated_at' => $now,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Device registered successfully',
        ]);
    }

    public function revoke(Request $request): JsonResponse
    {
        if ($request->exists('user_code')) {
            return response()->json(['message' => 'The user_code field is not accepted.'], 422);
        }

        $validated = $request->validate([
            'fcm_token' => 'required|string|max:4096',
        ]);

        $user = $request->user();
        if (!$user instanceof User) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $device = UserDevice::where('token_hash', hash('sha256', $validated['fcm_token']))
            ->where('user_code', (string) $user->code)
            ->first();

        if (!$device) {
            return response()->json(['message' => 'Device not found.'], 404);
        }

        $device->is_active = false;
        $device->revoked_at = now();
        $device->save();

        return response()->json([
            'success' => true,
            'message' => 'Device revoked successfully',
        ]);
    }
}