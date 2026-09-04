<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Services\Auth\MicrosoftAuthenticator;
use Illuminate\Http\JsonResponse;
use Laravel\Socialite\Facades\Socialite;

class MicrosoftAuthController extends Controller
{
    public function __construct(private readonly MicrosoftAuthenticator $authenticator) {}

    /**
     * Redirect the agent to Microsoft to begin the OAuth flow.
     */
    public function redirect(): JsonResponse
    {
        $url = Socialite::driver('microsoft')->stateless()->redirect()->getTargetUrl();

        return response()->json(['url' => $url]);
    }

    /**
     * Handle the callback from Microsoft and issue a Sanctum token.
     */
    public function callback(): JsonResponse
    {
        try {
            $microsoftUser = Socialite::driver('microsoft')->stateless()->user();
        } catch (\Exception) {
            return response()->json(['message' => 'Microsoft authentication failed.'], 401);
        }

        $user = $this->authenticator->findOrCreateAgent($microsoftUser);

        $token = $user->createToken('agent-portal')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $user,
        ]);
    }
}
