<?php

use Illuminate\Http\Request;
use App\Http\Controllers\API;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\AiChatController;
use App\Http\Controllers\PrincipalTeacherController;
use App\Http\Controllers\NotificationDeviceController;
use App\Http\Controllers\MobileNotificationController;
use App\Services\FcmNotificationService;
use App\Services\PrincipalContextService;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::post('/school_manager',[API::class,'school_manager'])->withoutMiddleware('throttle:api')
->middleware('throttle:2000000:1');

Route::post('/parent/absence-justifications', [API::class, 'school_manager'])
    ->middleware(['auth:sanctum', 'abilities:mobischo:mobile', 'throttle:60,1']);

Route::post('/dashboard/alerts', [API::class, 'school_manager'])
    ->middleware(['auth:sanctum', 'abilities:mobischo:mobile', 'throttle:60,1']);

Route::post('/mobile/login',[API::class,'mobileLogin'])->withoutMiddleware('throttle:api')
->middleware('throttle:2000000:1');

Route::post('/mobile/login-diagnostic', [API::class, 'mobileLoginDiagnostic'])
    ->middleware('throttle:5,1');

Route::post('/mobile/logout', [API::class, 'mobileLogout'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::post('/notifications/devices', [NotificationDeviceController::class, 'register'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::delete('/notifications/devices', [NotificationDeviceController::class, 'revoke'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::get('/notifications', [MobileNotificationController::class, 'index'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::post('/notifications/read-all', [MobileNotificationController::class, 'markAllAsRead'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::patch('/notifications/{notificationId}/read', [MobileNotificationController::class, 'markAsRead'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::get('/notification-diagnostic', function (Request $request, FcmNotificationService $fcm) {
    if (!(new PrincipalContextService())->isPrincipal($request->user())) {
        return response()->json(['status' => 'forbidden'], 403);
    }

    try {
        $result = $fcm->sendToUser(
            '672320608',
            'MOBISCHO Test',
            'This is a direct Firebase notification test.',
            [
                'type' => 'diagnostic',
                'source' => 'manual_test',
            ]
        );

        return response()->json([
            'status' => $result['status'] ?? 'unknown',
            'attempted' => (int) ($result['attempted'] ?? 0),
            'succeeded' => (int) ($result['succeeded'] ?? 0),
            'failed' => (int) ($result['failed'] ?? 0),
            'invalidated' => (int) ($result['invalidated'] ?? 0),
            'errors' => array_values(array_map(static fn (array $error) => [
                'http_status' => $error['http_status'] ?? null,
                'status' => $error['status'] ?? null,
                'firebase_status' => $error['firebase_status'] ?? null,
                'message' => $error['message'] ?? null,
            ], $result['errors'] ?? [])),
        ]);
    } catch (\Throwable $exception) {
        $message = $exception->getMessage();
        $message = preg_replace('/Bearer\s+\S+/i', 'Bearer [redacted]', $message) ?? $message;
        $message = preg_replace('/\bya29\.[A-Za-z0-9._~-]+/', '[redacted]', $message) ?? $message;
        $message = preg_replace('/-----BEGIN [^-]+-----.*?-----END [^-]+-----/s', '[redacted]', $message) ?? $message;
        $message = substr($message, 0, 500);
        $status = str_contains(strtolower($message), 'credential') || str_contains(strtolower($message), 'project id')
            ? 'configuration_error'
            : (str_contains(strtolower($message), 'oauth') ? 'oauth_error' : 'send_error');

        Log::error('Temporary FCM diagnostic failed.', [
            'exception' => get_class($exception),
            'status' => $status,
            'message' => $message,
        ]);

        return response()->json([
            'status' => $status,
            'attempted' => 0,
            'succeeded' => 0,
            'failed' => 0,
            'invalidated' => 0,
            'errors' => [[
                'status' => $status,
                'message' => $message,
            ]],
        ], 500);
    }
})->middleware(['auth:sanctum', 'throttle:5,1']);

Route::post('/ai/chat', [AiChatController::class, 'chat'])
    ->middleware(['auth:sanctum', 'throttle:15,1']);

Route::get('/principal/teacher-classes', [PrincipalTeacherController::class, 'index'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);
Route::get('/principal/teachers/{teacherCode}/attendance', [PrincipalTeacherController::class, 'attendance'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
    Route::get('/ai/conversations', [AiChatController::class, 'index']);
    Route::post('/ai/conversations', [AiChatController::class, 'store']);
    Route::get('/ai/conversations/{conversation}', [AiChatController::class, 'show']);
    Route::post('/ai/conversations/{conversation}/messages', [AiChatController::class, 'sendMessage']);
    Route::delete('/ai/conversations/{conversation}', [AiChatController::class, 'destroy']);
});

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();

});
