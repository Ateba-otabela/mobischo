<?php

use Illuminate\Http\Request;
use App\Http\Controllers\API;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AiChatController;
use App\Http\Controllers\PrincipalTeacherController;
use App\Http\Controllers\NotificationDeviceController;

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

Route::post('/mobile/login',[API::class,'mobileLogin'])->withoutMiddleware('throttle:api')
->middleware('throttle:2000000:1');

Route::post('/mobile/logout', [API::class, 'mobileLogout'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::post('/notifications/devices', [NotificationDeviceController::class, 'register'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::delete('/notifications/devices', [NotificationDeviceController::class, 'revoke'])
    ->middleware(['auth:sanctum', 'throttle:60,1']);

Route::post('/ai/chat', [AiChatController::class, 'chat'])
    ->middleware(['auth:sanctum', 'throttle:15,1']);

Route::get('/principal/teacher-classes', [PrincipalTeacherController::class, 'index'])
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
