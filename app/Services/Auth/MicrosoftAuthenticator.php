<?php

namespace App\Services\Auth;

use App\Models\User;
use Illuminate\Support\Str;
use Laravel\Socialite\Contracts\User as SocialiteUser;

class MicrosoftAuthenticator
{
    /**
     * Find the local agent account for a Microsoft identity, creating it on first login.
     */
    public function findOrCreateAgent(SocialiteUser $microsoftUser): User
    {
        $user = User::where('microsoft_id', $microsoftUser->getId())
            ->orWhere('email', $microsoftUser->getEmail())
            ->first();

        if ($user) {
            $user->forceFill([
                'microsoft_id' => $microsoftUser->getId(),
                'name' => $microsoftUser->getName(),
                'email_verified_at' => $user->email_verified_at ?? now(),
            ])->save();

            return $user;
        }

        return User::forceCreate([
            'microsoft_id' => $microsoftUser->getId(),
            'name' => $microsoftUser->getName(),
            'email' => $microsoftUser->getEmail(),
            'password' => Str::password(40),
            'email_verified_at' => now(),
        ]);
    }
}
