<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\RegisterUserRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class RegisteredUserController extends Controller
{
    /**
     * Register a new client portal user and issue an API token.
     */
    public function store(RegisterUserRequest $request): JsonResponse
    {
        $user = User::create($request->safe()->only(['name', 'email', 'password']))->refresh();

        $token = $user->createToken('client-portal')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $user,
        ], 201);
    }
}
