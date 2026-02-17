<?php

namespace Tests\Feature;

use App\Models\ClassModel;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ClassStudentFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $user;

    protected $school;

    protected $section;

    protected $teacher;

    protected $parent;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school = School::factory()->create(['name' => 'Test School']);

        $this->user = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'proprietor',
        ]);

        $this->teacher = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'teacher',
        ]);

        $this->parent = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'parent',
        ]);

        $this->section = Section::create([
            'school_id' => $this->school->id,
            'section_name' => 'Secondary',
        ]);
    }

    public function test_can_create_class_with_teacher()
    {
        $classData = [
            'section_id' => $this->section->id,
            'class_name' => 'SS1 A',
            'description' => 'Science Class',
            'form_teacher_id' => $this->teacher->id,
            'capacity' => 30,
            'is_active' => true,
        ];

        $response = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/classes", $classData);

        $response->assertStatus(201)
            ->assertJsonFragment([
                'class_name' => 'SS1 A',
                'form_teacher_id' => $this->teacher->id,
                'capacity' => 30,
            ]);

        $this->assertDatabaseHas('classes', [
            'class_name' => 'SS1 A',
            'form_teacher_id' => $this->teacher->id,
        ]);
    }

    public function test_can_create_student_with_parent()
    {
        $class = ClassModel::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_name' => 'SS1 A',
        ]);

        $studentData = [
            'section_id' => $this->section->id,
            'class_id' => $class->id,
            'student_name' => 'John Doe',
            'admission_number' => 'AD-001',
            'gender' => 'male',
            'parent_id' => $this->parent->id,
            'parent_name' => 'Mr. Doe',
        ];

        $response = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/students", $studentData);

        $response->assertStatus(201)
            ->assertJsonFragment([
                'student_name' => 'John Doe',
                'parent_id' => $this->parent->id,
            ]);

        $this->assertDatabaseHas('students', [
            'student_name' => 'John Doe',
            'parent_id' => $this->parent->id,
        ]);
    }

    public function test_can_list_students_filtered_by_class()
    {
        $classA = ClassModel::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_name' => 'Class A',
        ]);

        $classB = ClassModel::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_name' => 'Class B',
        ]);

        Student::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $classA->id,
            'student_name' => 'Student A',
        ]);

        Student::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $classB->id,
            'student_name' => 'Student B',
        ]);

        $response = $this->actingAs($this->user, 'api')->getJson("/api/schools/{$this->school->id}/students?class_id={$classA->id}");

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.data')
            ->assertJsonFragment(['student_name' => 'Student A'])
            ->assertJsonMissing(['student_name' => 'Student B']);
    }
}
