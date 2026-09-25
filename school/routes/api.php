<?php

use Illuminate\Http\Request;
use App\Http\Controllers\API;
use Illuminate\Support\Facades\Route;

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

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();

});
