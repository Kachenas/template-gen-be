<?php

use App\Http\Controllers\Auth\AuthenticatedSessionController;
use App\Http\Controllers\Auth\MicrosoftAuthController;
use App\Http\Controllers\Auth\RegisteredUserController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::prefix('auth/microsoft')->name('auth.microsoft.')->group(function () {
    Route::get('/redirect', [MicrosoftAuthController::class, 'redirect'])->name('redirect');
    Route::get('/callback', [MicrosoftAuthController::class, 'callback'])->name('callback');
});

Route::post('/register', [RegisteredUserController::class, 'store'])->name('register');
Route::post('/login', [AuthenticatedSessionController::class, 'store'])->middleware('throttle:login')->name('login');
Route::post('/logout', [AuthenticatedSessionController::class, 'destroy'])->middleware('auth:sanctum')->name('logout');

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
