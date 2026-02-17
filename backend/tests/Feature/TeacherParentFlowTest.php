<?php

namespace Tests\Feature;

use App\Models\ClassModel;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TeacherParentFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $proprietor;

    protected $school;

    protected $section;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school = School::factory()->create(['name' => 'Test School']);

        $this->proprietor = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'proprietor',
        ]);

        $this->section = Section::create([
            'school_id' => $this->school->id,
            'section_name' => 'Secondary',
        ]);
    }

    public function test_can_list_teachers_with_assignments()
    {
        $teacher = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'teacher',
            'full_name' => 'Teacher One',
        ]);

        $class = ClassModel::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_name' => 'SS1 A',
            'form_teacher_id' => $teacher->id,
        ]);

        Subject::create([
            'school_id' => $this->school->id,
            'name' => 'Mathematics',
            'class_id' => $class->id,
            'teacher_id' => $teacher->id,
        ]);

        $response = $this->actingAs($this->proprietor, 'api')->getJson("/api/schools/{$this->school->id}/users?role=teacher");

        $response->assertStatus(200)
            ->assertJsonFragment(['full_name' => 'Teacher One']);

        // Verify teacher details include assignments
        $teacherResponse = $this->actingAs($this->proprietor, 'api')->getJson("/api/schools/{$this->school->id}/users/{$teacher->id}");

        $teacherResponse->assertStatus(200)
            ->assertJsonPath('data.classes.0.class_name', 'SS1 A')
            ->assertJsonPath('data.subjects.0.name', 'Mathematics');
    }

    public function test_can_list_parents_with_linked_students()
    {
        $parent = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'parent',
            'full_name' => 'Parent One',
        ]);

        $class = ClassModel::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_name' => 'SS1 A',
        ]);

        Student::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $class->id,
            'parent_id' => $parent->id,
            'student_name' => 'Child One',
        ]);

        $response = $this->actingAs($this->proprietor, 'api')->getJson("/api/schools/{$this->school->id}/users?role=parent");

        $response->assertStatus(200)
            ->assertJsonFragment(['full_name' => 'Parent One']);

        // Verify parent details include linked students
        $parentResponse = $this->actingAs($this->proprietor, 'api')->getJson("/api/schools/{$this->school->id}/users/{$parent->id}");

        $parentResponse->assertStatus(200)
            ->assertJsonPath('data.students.0.student_name', 'Child One');
    }
}
