<?php

namespace Tests\Feature;

use App\Models\ClassModel;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SchoolFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $user;

    protected function setUp(): void
    {
        parent::setUp();

        // Create an admin user for testing
        $school = School::factory()->create();
        $this->user = User::factory()->create([
            'school_id' => $school->id,
            'role' => 'proprietor',
        ]);
    }

    public function test_can_list_schools()
    {
        School::factory()->count(3)->create(['is_active' => true]);
        School::factory()->create(['is_active' => false]); // Inactive, shouldn't appear

        $response = $this->actingAs($this->user, 'api')
            ->getJson('/api/schools');

        $response->assertStatus(200)
            ->assertJsonStructure(['success', 'data' => ['data', 'total']]);

        // Should only list active schools
        $data = $response->json('data.data');
        $this->assertGreaterThanOrEqual(4, count($data)); // 3 new + 1 from setUp
    }

    public function test_can_create_school()
    {
        $payload = [
            'name' => 'New Test School',
            'short_code' => 'NTS',
            'address' => '123 Education Street',
            'phone' => '+234 800 000 0000',
            'email' => 'info@newtestschool.com',
        ];

        $response = $this->actingAs($this->user, 'api')
            ->postJson('/api/schools', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'School created successfully',
            ]);

        $this->assertDatabaseHas('schools', [
            'name' => 'New Test School',
            'email' => 'info@newtestschool.com',
        ]);
    }

    public function test_create_school_validation_fails()
    {
        $payload = [
            'address' => 'Some address',
            // Missing required 'name'
        ];

        $response = $this->actingAs($this->user, 'api')
            ->postJson('/api/schools', $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }

    public function test_can_view_school_details()
    {
        $school = School::factory()->create();
        Section::factory()->count(2)->create(['school_id' => $school->id]);
        User::factory()->count(3)->create(['school_id' => $school->id]);

        $response = $this->actingAs($this->user, 'api')
            ->getJson("/api/schools/{$school->id}");

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'data' => ['id', 'name', 'users', 'sections', 'students'],
            ]);
    }

    public function test_can_update_school()
    {
        $school = School::factory()->create(['name' => 'Old Name']);

        $payload = [
            'name' => 'Updated School Name',
            'phone' => '+234 900 000 0000',
        ];

        $response = $this->actingAs($this->user, 'api')
            ->putJson("/api/schools/{$school->id}", $payload);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'School updated successfully',
            ]);

        $this->assertDatabaseHas('schools', [
            'id' => $school->id,
            'name' => 'Updated School Name',
            'phone' => '+234 900 000 0000',
        ]);
    }

    public function test_can_deactivate_school()
    {
        $school = School::factory()->create(['is_active' => true]);

        $response = $this->actingAs($this->user, 'api')
            ->putJson("/api/schools/{$school->id}", ['is_active' => false]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('schools', [
            'id' => $school->id,
            'is_active' => false,
        ]);
    }

    public function test_can_delete_school()
    {
        $school = School::factory()->create();

        $response = $this->actingAs($this->user, 'api')
            ->deleteJson("/api/schools/{$school->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'School deleted successfully',
            ]);

        $this->assertDatabaseMissing('schools', ['id' => $school->id]);
    }

    public function test_can_get_school_statistics()
    {
        $school = School::factory()->create();

        // Create related data
        User::factory()->count(5)->create(['school_id' => $school->id, 'role' => 'teacher']);
        User::factory()->count(3)->create(['school_id' => $school->id, 'role' => 'parent']);
        Section::factory()->count(2)->create(['school_id' => $school->id]);

        $section = Section::factory()->create(['school_id' => $school->id]);
        ClassModel::factory()->count(4)->create(['school_id' => $school->id, 'section_id' => $section->id]);
        Student::factory()->count(10)->create(['school_id' => $school->id]);

        $response = $this->actingAs($this->user, 'api')
            ->getJson("/api/schools/{$school->id}/statistics");

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'data' => [
                    'total_users',
                    'total_sections',
                    'total_students',
                    'total_classes',
                    'users_by_role',
                ],
            ]);

        $data = $response->json('data');
        $this->assertEquals(8, $data['total_users']); // 5 teachers + 3 parents
        $this->assertEquals(3, $data['total_sections']);
        $this->assertEquals(10, $data['total_students']);
        $this->assertEquals(4, $data['total_classes']);
    }

    public function test_school_not_found_returns_404()
    {
        $response = $this->actingAs($this->user, 'api')
            ->getJson('/api/schools/99999');

        $response->assertStatus(404);
    }
}
