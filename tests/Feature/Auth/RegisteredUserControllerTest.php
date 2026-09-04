<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RegisteredUserControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_valid_payload_creates_user_and_returns_201(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Jane Customer',
            'email' => 'jane.customer@example.com',
            'password' => 'correct-horse-battery-staple',
            'password_confirmation' => 'correct-horse-battery-staple',
        ]);

        $response->assertCreated()->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']]);

        $this->assertDatabaseHas('users', [
            'email' => 'jane.customer@example.com',
            'microsoft_id' => null,
        ]);
    }

    public function test_empty_payload_fails_validation(): void
    {
        $response = $this->postJson('/api/register', []);

        $response->assertUnprocessable()->assertJsonValidationErrors(['name', 'email', 'password']);
    }

    public function test_registration_with_taken_email_fails_validation(): void
    {
        User::factory()->create(['email' => 'jane.customer@example.com']);

        $response = $this->postJson('/api/register', [
            'name' => 'Jane Customer',
            'email' => 'jane.customer@example.com',
            'password' => 'correct-horse-battery-staple',
            'password_confirmation' => 'correct-horse-battery-staple',
        ]);

        $response->assertUnprocessable()->assertJsonValidationErrors(['email']);
    }

    public function test_registration_with_mismatched_password_confirmation_fails_validation(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Jane Customer',
            'email' => 'jane.customer@example.com',
            'password' => 'correct-horse-battery-staple',
            'password_confirmation' => 'does-not-match',
        ]);

        $response->assertUnprocessable()->assertJsonValidationErrors(['password']);
    }
}
