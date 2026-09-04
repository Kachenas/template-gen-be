<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthenticatedSessionControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_valid_credentials_return_a_token(): void
    {
        User::factory()->create([
            'email' => 'jane.customer@example.com',
            'password' => 'correct-horse-battery-staple',
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'jane.customer@example.com',
            'password' => 'correct-horse-battery-staple',
        ]);

        $response->assertOk()->assertJsonStructure(['token', 'user' => ['id', 'email']]);
    }

    public function test_incorrect_password_returns_422_with_generic_message(): void
    {
        User::factory()->create([
            'email' => 'jane.customer@example.com',
            'password' => 'correct-horse-battery-staple',
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'jane.customer@example.com',
            'password' => 'wrong-password',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['email' => 'These credentials do not match our records.']);
    }

    public function test_unknown_email_returns_422_with_generic_message(): void
    {
        $response = $this->postJson('/api/login', [
            'email' => 'nobody@example.com',
            'password' => 'correct-horse-battery-staple',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['email' => 'These credentials do not match our records.']);
    }

    public function test_microsoft_linked_account_cannot_log_in_with_a_password(): void
    {
        User::factory()->create([
            'email' => 'agent@example.com',
            'microsoft_id' => 'microsoft-object-id',
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'agent@example.com',
            'password' => 'password',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['email' => 'These credentials do not match our records.']);
    }

    public function test_logout_revokes_the_current_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('client-portal');

        $response = $this->withToken($token->plainTextToken)->postJson('/api/logout');

        $response->assertNoContent();
    }

    public function test_logout_requires_authentication(): void
    {
        $response = $this->postJson('/api/logout');

        $response->assertUnauthorized();
    }
}
