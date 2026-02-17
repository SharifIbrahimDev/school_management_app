<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Section;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserManagementFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $user;

    protected $school;

    protected $section;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school = School::factory()->create(['name' => 'Test School']);

        $this->user = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'proprietor',
        ]);

        $this->section = Section::create([
            'school_id' => $this->school->id,
            'section_name' => 'Primary',
        ]);
    }

    public function test_can_list_users()
    {
        $response = $this->actingAs($this->user, 'api')->getJson("/api/schools/{$this->school->id}/users");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'data' => [
                        '*' => ['id', 'full_name', 'email', 'role', 'is_active'],
                    ],
                ],
            ]);
    }

    public function test_can_create_user()
    {
        $userData = [
            'full_name' => 'New Staff',
            'email' => 'staff@example.com',
            'password' => 'password123',
            'role' => 'teacher',
            'phone_number' => '1234567890',
            'address' => '123 Teacher St',
            'is_active' => true,
        ];

        $response = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/users", $userData);

        $response->assertStatus(201)
            ->assertJsonPath('data.full_name', 'New Staff')
            ->assertJsonPath('data.role', 'teacher');

        $this->assertDatabaseHas('users', [
            'email' => 'staff@example.com',
            'role' => 'teacher',
            'phone_number' => '1234567890',
            'address' => '123 Teacher St',
        ]);
    }

    public function test_can_update_user()
    {
        $staff = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'teacher',
        ]);

        $response = $this->actingAs($this->user, 'api')->putJson("/api/schools/{$this->school->id}/users/{$staff->id}", [
            'full_name' => 'Updated Name',
            'role' => 'principal',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.full_name', 'Updated Name')
            ->assertJsonPath('data.role', 'principal');
    }

    public function test_can_delete_user()
    {
        $staff = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'teacher',
        ]);

        $response = $this->actingAs($this->user, 'api')->deleteJson("/api/schools/{$this->school->id}/users/{$staff->id}");

        $response->assertStatus(200);
        $this->assertDatabaseMissing('users', ['id' => $staff->id]);
    }

    public function test_can_assign_sections_to_user()
    {
        $staff = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'teacher',
        ]);

        $response = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/users/{$staff->id}/assign-sections", [
            'section_ids' => [$this->section->id],
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.sections.0.section_name', 'Primary');

        $this->assertDatabaseHas('user_section', [
            'user_id' => $staff->id,
            'section_id' => $this->section->id,
        ]);
    }
}
