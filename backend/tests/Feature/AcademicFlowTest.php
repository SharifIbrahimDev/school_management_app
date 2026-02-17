<?php

namespace Tests\Feature;

use App\Models\ClassModel;
use App\Models\Exam;
use App\Models\School;
use App\Models\Student;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AcademicFlowTest extends TestCase
{
    use RefreshDatabase; // Resets DB for each test

    protected $user;

    protected $school;

    protected $class;

    protected function setUp(): void
    {
        parent::setUp();

        // Setup world
        $this->school = School::factory()->create([
            'name' => 'Test School',
        ]);

        $this->user = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'teacher', // or admin
        ]);

        // Create Section first
        $section = \App\Models\Section::create([
            'school_id' => $this->school->id,
            'section_name' => 'A',
        ]);

        $this->class = ClassModel::create([
            'school_id' => $this->school->id,
            'section_id' => $section->id,
            'class_name' => 'JSS 1',
        ]);
    }

    public function test_can_create_subject()
    {
        $response = $this->actingAs($this->user, 'api')->postJson('/api/schools/'.$this->school->id.'/subjects', [
            'name' => 'Physics',
            'code' => 'PHY101',
            'class_id' => $this->class->id,
            'teacher_id' => $this->user->id,
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['name' => 'Physics']);

        $this->assertDatabaseHas('subjects', ['name' => 'Physics']);
    }

    public function test_can_mark_attendance()
    {
        $student = Student::create([
            'school_id' => $this->school->id,
            'student_name' => 'John Doe',
            'admission_number' => 'STD/001',
            'class_id' => $this->class->id,
            'section_id' => $this->class->section_id,
        ]);

        $date = now()->format('Y-m-d');

        $response = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/attendance", [
            'class_id' => $this->class->id,
            'date' => $date,
            'attendances' => [
                [
                    'student_id' => $student->id,
                    'status' => 'present',
                ],
            ],
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('attendances', [
            'student_id' => $student->id,
            'date' => $date,
            'status' => 'present',
        ]);
    }

    public function test_can_create_exam_and_grade()
    {
        $subject = Subject::create([
            'school_id' => $this->school->id,
            'name' => 'Math',
            'class_id' => $this->class->id,
        ]);

        $student = Student::create([
            'school_id' => $this->school->id,
            'student_name' => 'John Doe',
            'admission_number' => 'STD/001',
            'class_id' => $this->class->id,
            'section_id' => $this->class->section_id,
        ]);

        // 1. Create Exam
        $examResponse = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/exams", [
            'class_id' => $this->class->id,
            'subject_id' => $subject->id,
            'title' => 'Mid-Term',
            'max_score' => 100,
        ]);

        $examResponse->assertStatus(201);
        $examId = $examResponse->json('id');

        // 2. Grade Student
        $gradeResponse = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/exams/$examId/results", [
            'results' => [
                [
                    'student_id' => $student->id,
                    'score' => 85.5,
                ],
            ],
        ]);

        $gradeResponse->assertStatus(200);
        $this->assertDatabaseHas('exam_results', [
            'exam_id' => $examId,
            'student_id' => $student->id,
            'score' => 85.50,
        ]);
    }
}
