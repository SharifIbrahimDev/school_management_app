<?php

namespace Tests\Feature;

use App\Models\ClassModel;
use App\Models\Fee;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StudentFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $school;

    protected $admin;

    protected $section;

    protected $class;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school = School::factory()->create();
        $this->admin = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'proprietor',
        ]);

        $this->section = Section::factory()->create(['school_id' => $this->school->id]);
        $this->class = ClassModel::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
        ]);
    }

    public function test_can_list_students_for_school()
    {
        Student::factory()->count(10)->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
        ]);

        // Create students for another school (shouldn't appear)
        $otherSchool = School::factory()->create();
        $otherSection = Section::factory()->create(['school_id' => $otherSchool->id]);
        $otherClass = ClassModel::factory()->create([
            'school_id' => $otherSchool->id,
            'section_id' => $otherSection->id,
        ]);
        Student::factory()->count(5)->create([
            'school_id' => $otherSchool->id,
            'section_id' => $otherSection->id,
            'class_id' => $otherClass->id,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/students");

        $response->assertStatus(200)
            ->assertJsonStructure(['success', 'data' => ['data', 'total']]);

        $data = $response->json('data.data');
        $this->assertEquals(10, count($data));
    }

    public function test_can_filter_students_by_section()
    {
        $anotherSection = Section::factory()->create(['school_id' => $this->school->id]);
        $anotherClass = ClassModel::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $anotherSection->id,
        ]);

        Student::factory()->count(3)->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
        ]);

        Student::factory()->count(2)->create([
            'school_id' => $this->school->id,
            'section_id' => $anotherSection->id,
            'class_id' => $anotherClass->id,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/students?section_id={$this->section->id}");

        $response->assertStatus(200);

        $data = $response->json('data.data');
        $this->assertEquals(3, count($data));
    }

    public function test_can_filter_students_by_class()
    {
        Student::factory()->count(4)->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/students?class_id={$this->class->id}");

        $response->assertStatus(200);

        $data = $response->json('data.data');
        $this->assertEquals(4, count($data));
    }

    public function test_can_filter_students_by_parent()
    {
        $parent = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'parent',
        ]);

        Student::factory()->count(2)->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'parent_id' => $parent->id,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/students?parent_id={$parent->id}");

        $response->assertStatus(200);

        $data = $response->json('data.data');
        $this->assertEquals(2, count($data));
    }

    public function test_can_search_students()
    {
        Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'student_name' => 'John Unique Doe',
            'admission_number' => 'UNIQUE123',
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/students?search=Unique");

        $response->assertStatus(200);

        $data = $response->json('data.data');
        $this->assertGreaterThanOrEqual(1, count($data));
    }

    public function test_can_create_student()
    {
        $payload = [
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'student_name' => 'Test Student',
            'admission_number' => 'STD/2024/001',
            'date_of_birth' => '2015-05-15',
            'gender' => 'male',
            'address' => '123 Student Street',
            'parent_name' => 'Parent Name',
            'parent_phone' => '+234 800 123 4567',
            'parent_email' => 'parent@example.com',
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/students", $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Student created successfully',
            ]);

        $this->assertDatabaseHas('students', [
            'school_id' => $this->school->id,
            'student_name' => 'Test Student',
            'admission_number' => 'STD/2024/001',
        ]);
    }

    public function test_create_student_validation_fails()
    {
        $payload = [
            'student_name' => 'Test Student',
            // Missing required fields: section_id, class_id
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/students", $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['section_id', 'class_id']);
    }

    public function test_admission_number_must_be_unique()
    {
        Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'admission_number' => 'DUPLICATE123',
        ]);

        $payload = [
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'student_name' => 'Another Student',
            'admission_number' => 'DUPLICATE123', // Duplicate
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/students", $payload);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['admission_number']);
    }

    public function test_can_link_student_to_parent_user()
    {
        $parent = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'parent',
        ]);

        $payload = [
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'student_name' => 'Test Student',
            'parent_id' => $parent->id,
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/students", $payload);

        $response->assertStatus(201);

        $student = Student::where('student_name', 'Test Student')->first();
        $this->assertEquals($parent->id, $student->parent_id);
    }

    public function test_can_view_student_details()
    {
        $student = Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/students/{$student->id}");

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'data' => ['id', 'student_name', 'school', 'section', 'class_model'],
            ]);
    }

    public function test_can_update_student()
    {
        $student = Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'student_name' => 'Old Name',
        ]);

        $payload = [
            'student_name' => 'Updated Name',
            'address' => 'New Address',
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->putJson("/api/schools/{$this->school->id}/students/{$student->id}", $payload);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Student updated successfully',
            ]);

        $this->assertDatabaseHas('students', [
            'id' => $student->id,
            'student_name' => 'Updated Name',
            'address' => 'New Address',
        ]);
    }

    public function test_can_transfer_student_to_different_class()
    {
        $newClass = ClassModel::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
        ]);

        $student = Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->putJson("/api/schools/{$this->school->id}/students/{$student->id}", [
                'class_id' => $newClass->id,
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('students', [
            'id' => $student->id,
            'class_id' => $newClass->id,
        ]);
    }

    public function test_can_deactivate_student()
    {
        $student = Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'is_active' => true,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->putJson("/api/schools/{$this->school->id}/students/{$student->id}", [
                'is_active' => false,
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('students', [
            'id' => $student->id,
            'is_active' => false,
        ]);
    }

    public function test_can_delete_student()
    {
        $student = Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->deleteJson("/api/schools/{$this->school->id}/students/{$student->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Student deleted successfully',
            ]);

        $this->assertDatabaseMissing('students', ['id' => $student->id]);
    }

    public function test_can_get_student_transactions()
    {
        $student = Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
        ]);

        Transaction::factory()->count(3)->create([
            'school_id' => $this->school->id,
            'student_id' => $student->id,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/students/{$student->id}/transactions");

        $response->assertStatus(200)
            ->assertJsonStructure(['success', 'data' => ['data', 'total']]);

        $data = $response->json('data.data');
        $this->assertEquals(3, count($data));
    }

    public function test_can_get_student_payment_summary()
    {
        $student = Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
        ]);

        // Create some transactions
        Transaction::factory()->create([
            'school_id' => $this->school->id,
            'student_id' => $student->id,
            'transaction_type' => 'income',
            'amount' => 50000,
        ]);

        // Create fee for the class
        Fee::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'amount' => 100000,
            'is_active' => true,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/students/{$student->id}/payment-summary");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => ['total_paid', 'total_fees', 'balance', 'payment_count'],
            ]);

        $data = $response->json('data');
        $this->assertEquals(50000, $data['total_paid']);
        $this->assertEquals(100000, $data['total_fees']);
        $this->assertEquals(50000, $data['balance']);
    }

    public function test_can_bulk_import_students()
    {
        $payload = [
            'students' => [
                [
                    'section_id' => $this->section->id,
                    'class_id' => $this->class->id,
                    'student_name' => 'Import Student 1',
                    'admission_number' => 'IMP001',
                ],
                [
                    'section_id' => $this->section->id,
                    'class_id' => $this->class->id,
                    'student_name' => 'Import Student 2',
                    'admission_number' => 'IMP002',
                ],
            ],
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/students/import", $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => ['imported_count' => 2],
            ]);

        $this->assertDatabaseHas('students', ['admission_number' => 'IMP001']);
        $this->assertDatabaseHas('students', ['admission_number' => 'IMP002']);
    }

    public function test_bulk_import_skips_duplicates()
    {
        Student::factory()->create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'admission_number' => 'EXISTING001',
        ]);

        $payload = [
            'students' => [
                [
                    'section_id' => $this->section->id,
                    'class_id' => $this->class->id,
                    'student_name' => 'Good Student',
                    'admission_number' => 'NEW001',
                ],
                [
                    'section_id' => $this->section->id,
                    'class_id' => $this->class->id,
                    'student_name' => 'Duplicate Student',
                    'admission_number' => 'EXISTING001', // Duplicate
                ],
            ],
        ];

        $response = $this->actingAs($this->admin, 'api')
            ->postJson("/api/schools/{$this->school->id}/students/import", $payload);

        $response->assertStatus(207); // Multi-status (some success, some errors)

        $data = $response->json('data');
        $this->assertEquals(1, $data['imported_count']);
        $this->assertEquals(1, $data['error_count']);
    }

    public function test_cannot_access_student_from_different_school()
    {
        $otherSchool = School::factory()->create();
        $otherSection = Section::factory()->create(['school_id' => $otherSchool->id]);
        $otherClass = ClassModel::factory()->create([
            'school_id' => $otherSchool->id,
            'section_id' => $otherSection->id,
        ]);
        $otherStudent = Student::factory()->create([
            'school_id' => $otherSchool->id,
            'section_id' => $otherSection->id,
            'class_id' => $otherClass->id,
        ]);

        $response = $this->actingAs($this->admin, 'api')
            ->getJson("/api/schools/{$this->school->id}/students/{$otherStudent->id}");

        $response->assertStatus(404);
    }
}
