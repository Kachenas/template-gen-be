<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Socialite\Facades\Socialite;
use Laravel\Socialite\Two\User as SocialiteUser;
use Tests\TestCase;

class MicrosoftAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_redirect_returns_microsoft_authorization_url(): void
    {
        Socialite::fake('microsoft');

        $response = $this->getJson('/api/auth/microsoft/redirect');

        $response->assertOk()->assertJsonStructure(['url']);
    }

    public function test_callback_creates_a_new_agent_and_issues_a_token(): void
    {
        Socialite::fake('microsoft', SocialiteUser::fake([
            'id' => 'microsoft-object-id',
            'name' => 'Jane Agent',
            'email' => 'jane.agent@example.com',
        ]));

        $response = $this->getJson('/api/auth/microsoft/callback');

        $response->assertOk()->assertJsonStructure(['token', 'user' => ['id', 'email', 'microsoft_id']]);

        $this->assertDatabaseHas('users', [
            'email' => 'jane.agent@example.com',
            'microsoft_id' => 'microsoft-object-id',
        ]);
    }

    public function test_callback_links_an_existing_user_by_email(): void
    {
        $existing = User::factory()->create(['email' => 'jane.agent@example.com']);

        Socialite::fake('microsoft', SocialiteUser::fake([
            'id' => 'microsoft-object-id',
            'name' => 'Jane Agent',
            'email' => 'jane.agent@example.com',
        ]));

        $this->getJson('/api/auth/microsoft/callback')->assertOk();

        $this->assertSame(1, User::count());
        $this->assertSame('microsoft-object-id', $existing->fresh()->microsoft_id);
    }

    public function test_callback_returns_unauthorized_when_microsoft_denies_the_grant(): void
    {
        Socialite::fake('microsoft', fn () => throw new \Exception('access_denied'));

        $response = $this->getJson('/api/auth/microsoft/callback');

        $response->assertStatus(401);
    }
}
