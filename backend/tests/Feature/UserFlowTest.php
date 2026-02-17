<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Section;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class UserFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $school;

    protected $admin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school = School::factory()->create();
        $this->admin = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'proprietor',
        ]);
    }

    public function test_can_list_users_for_school()
    {
        User::factory()->count(5)->create(['school_id' => $this->school->id]);

        // Create users for another school (shouldn't appear)
        $otherSchool = School::factory()->create();
        User::factory()->count(3)->create(['school_id' => $otherSchool->id]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/users");

        $response->assertStatus(200)
            ->assertJsonStructure(['success', 'data' => ['data', 'total']]);

        // Should include 5 new + 1 admin from setUp = 6 users
        $data = $response->json('data.data');
        $this->assertEquals(6, count($data));
    }

    public function test_can_filter_users_by_role()
    {
        User::factory()->count(3)->create([
            'school_id' => $this->school->id,
            'role' => 'teacher',
        ]);

        User::factory()->count(2)->create([
            'school_id' => $this->school->id,
            'role' => 'parent',
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/users?role=teacher");

        $response->assertStatus(200);

        $data = $response->json('data.data');
        $this->assertEquals(3, count($data));

        foreach ($data as $user) {
            $this->assertEquals('teacher', $user['role']);
        }
    }

    public function test_can_filter_users_by_active_status()
    {
        User::factory()->count(2)->create([
            'school_id' => $this->school->id,
            'is_active' => true,
        ]);

        User::factory()->count(1)->create([
            'school_id' => $this->school->id,
            'is_active' => false,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/users?is_active=1");

        $response->assertStatus(200);

        $data = $response->json('data.data');
        // 2 new active + 1 admin = 3
        $this->assertEquals(3, count($data));
    }

    public function test_can_create_user()
    {
        $payload = [
            'full_name' => 'John Doe Teacher',
            'email' => 'john.teacher@school.com',
            'password' => 'SecurePassword123',
            'role' => 'teacher',
            'phone_number' => '+234 800 123 4567',
            'address' => '123 Teacher Street',
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/users", $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'User created successfully',
            ]);

        $this->assertDatabaseHas('users', [
            'school_id' => $this->school->id,
            'email' => 'john.teacher@school.com',
            'full_name' => 'John Doe Teacher',
            'role' => 'teacher',
        ]);

        // Verify password was hashed
        $user = User::where('email', 'john.teacher@school.com')->first();
        $this->assertTrue(Hash::check('SecurePassword123', $user->password));
    }

    public function test_create_user_validation_fails()
    {
        $payload = [
            'full_name' => 'Test User',
            // Missing required fields: email, password, role
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/users", $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email', 'password', 'role']);
    }

    public function test_email_must_be_unique()
    {
        $existingUser = User::factory()->create([
            'school_id' => $this->school->id,
            'email' => 'existing@school.com',
        ]);

        $payload = [
            'full_name' => 'Another User',
            'email' => 'existing@school.com', // Duplicate
            'password' => 'password123',
            'role' => 'teacher',
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/users", $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_role_must_be_valid()
    {
        $payload = [
            'full_name' => 'Test User',
            'email' => 'test@school.com',
            'password' => 'password123',
            'role' => 'invalid_role', // Invalid
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/users", $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['role']);
    }

    public function test_can_view_user_details()
    {
        $user = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'teacher',
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/users/{$user->id}");

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'data' => ['id', 'full_name', 'email', 'role', 'school', 'sections'],
            ]);
    }

    public function test_can_update_user()
    {
        $user = User::factory()->create([
            'school_id' => $this->school->id,
            'full_name' => 'Old Name',
            'role' => 'teacher',
        ]);

        $payload = [
            'full_name' => 'Updated Name',
            'phone_number' => '+234 900 000 0000',
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->putJson("/api/schools/{$this->school->id}/users/{$user->id}", $payload);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'User updated successfully',
            ]);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'full_name' => 'Updated Name',
            'phone_number' => '+234 900 000 0000',
        ]);
    }

    public function test_can_update_user_password()
    {
        $user = User::factory()->create([
            'school_id' => $this->school->id,
        ]);

        $payload = [
            'password' => 'NewSecurePassword456',
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->putJson("/api/schools/{$this->school->id}/users/{$user->id}", $payload);

        $response->assertStatus(200);

        $user->refresh();
        $this->assertTrue(Hash::check('NewSecurePassword456', $user->password));
    }

    public function test_can_deactivate_user()
    {
        $user = User::factory()->create([
            'school_id' => $this->school->id,
            'is_active' => true,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->putJson("/api/schools/{$this->school->id}/users/{$user->id}", [
                'is_active' => false,
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'is_active' => false,
        ]);
    }

    public function test_can_delete_user()
    {
        $user = User::factory()->create(['school_id' => $this->school->id]);

        $response = $this->actingAs($this->admin, 'api')
            ->deleteJson("/api/schools/{$this->school->id}/users/{$user->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'User deleted successfully',
            ]);

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }

    public function test_can_assign_sections_to_user()
    {
        $user = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'teacher',
        ]);

        $sections = Section::factory()->count(3)->create([
            'school_id' => $this->school->id,
        ]);

        $sectionIds = $sections->pluck('id')->toArray();

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/users/{$user->id}/assign-sections", [
                'section_ids' => $sectionIds,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Sections assigned to user successfully',
            ]);

        $user->refresh();
        $this->assertCount(3, $user->sections);
    }

    public function test_can_reassign_sections_to_user()
    {
        $user = User::factory()->create(['school_id' => $this->school->id]);

        $oldSections = Section::factory()->count(2)->create(['school_id' => $this->school->id]);
        $user->sections()->attach($oldSections->pluck('id'));

        $newSections = Section::factory()->count(3)->create(['school_id' => $this->school->id]);

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/users/{$user->id}/assign-sections", [
                'section_ids' => $newSections->pluck('id')->toArray(),
            ]);

        $response->assertStatus(200);

        $user->refresh();
        $this->assertCount(3, $user->sections);
    }

    public function test_cannot_access_user_from_different_school()
    {
        $otherSchool = School::factory()->create();
        $otherUser = User::factory()->create(['school_id' => $otherSchool->id]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/users/{$otherUser->id}");

        $response->assertStatus(404);
    }

    public function test_user_has_role_helper_methods()
    {
        $teacher = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'teacher',
        ]);

        $this->assertTrue($teacher->hasRole('teacher'));
        $this->assertFalse($teacher->hasRole('parent'));
        $this->assertTrue($teacher->hasAnyRole(['teacher', 'parent']));
        $this->assertFalse($teacher->hasAnyRole(['parent', 'proprietor']));
    }
}
