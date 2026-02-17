<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SecurityFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $school1;

    protected $school2;

    protected $userSchool1;

    protected $userSchool2;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school1 = School::factory()->create(['name' => 'School A']);
        $this->school2 = School::factory()->create(['name' => 'School B']);

        $this->userSchool1 = User::factory()->create([
            'school_id' => $this->school1->id,
            'role' => 'proprietor',
        ]);

        $this->userSchool2 = User::factory()->create([
            'school_id' => $this->school2->id,
            'role' => 'proprietor',
        ]);
    }

    public function test_can_access_own_school_routes()
    {
        $response = $this->actingAs($this->userSchool1, 'api')
            ->getJson("/api/schools/{$this->school1->id}/students");

        $response->assertStatus(200);
    }

    public function test_cannot_access_other_school_routes()
    {
        // User from School 1 tries to access School 2's students
        $response = $this->actingAs($this->userSchool1, 'api')
            ->getJson("/api/schools/{$this->school2->id}/students");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized access to this school.',
            ]);
    }

    public function test_middleware_protection_on_users_route()
    {
        $response = $this->actingAs($this->userSchool1, 'api')
            ->getJson("/api/schools/{$this->school2->id}/users");

        $response->assertStatus(403);
    }

    public function test_middleware_protection_on_sections_route()
    {
        $response = $this->actingAs($this->userSchool1, 'api')
            ->getJson("/api/schools/{$this->school2->id}/sections");

        $response->assertStatus(403);
    }
}
