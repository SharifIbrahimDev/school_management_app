<?php

namespace Tests\Feature;

use App\Models\ClassModel;
use App\Models\Exam;
use App\Models\ExamResult;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExamFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $user;

    protected $schoolId = 1;

    protected $class;

    protected $subject;

    protected $students;

    protected function setUp(): void
    {
        parent::setUp();

        $school = School::factory()->create();
        $this->schoolId = $school->id;

        $this->user = User::factory()->create([
            'school_id' => $this->schoolId,
            'role' => 'teacher',
        ]);

        $section = Section::factory()->create(['school_id' => $this->schoolId]);
        $this->class = ClassModel::factory()->create([
            'school_id' => $this->schoolId,
            'section_id' => $section->id,
        ]);

        $this->subject = Subject::factory()->create([
            'school_id' => $this->schoolId,
        ]);

        $this->students = Student::factory()->count(3)->create([
            'school_id' => $this->schoolId,
            'class_id' => $this->class->id,
        ]);
    }

    public function test_can_create_exam()
    {
        $payload = [
            'class_id' => $this->class->id,
            'subject_id' => $this->subject->id,
            'title' => 'First Term Mathematics',
            'max_score' => 100,
            'date' => now()->format('Y-m-d'),
        ];

        $response = $this->actingAs($this->user, 'api')
            ->postJson("/api/schools/{$this->schoolId}/exams", $payload);

        $response->assertStatus(201)
            ->assertJson(['title' => 'First Term Mathematics']);
    }

    public function test_can_list_exams()
    {
        Exam::factory()->create([
            'school_id' => $this->schoolId,
            'class_id' => $this->class->id,
            'subject_id' => $this->subject->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->getJson("/api/schools/{$this->schoolId}/exams?class_id={$this->class->id}");

        $response->assertStatus(200)
            ->assertJsonCount(1);
    }

    public function test_can_save_bulk_results()
    {
        $exam = Exam::factory()->create([
            'school_id' => $this->schoolId,
            'class_id' => $this->class->id,
            'subject_id' => $this->subject->id,
        ]);

        $payload = [
            'results' => [
                ['student_id' => $this->students[0]->id, 'score' => 85, 'remark' => 'Excellent'],
                ['student_id' => $this->students[1]->id, 'score' => 55, 'remark' => 'Pass'],
                ['student_id' => $this->students[2]->id, 'score' => 30, 'remark' => 'Fail'],
            ],
        ];

        $response = $this->actingAs($this->user, 'api')
            ->postJson("/api/schools/{$this->schoolId}/exams/{$exam->id}/results", $payload);

        $response->assertStatus(200)
            ->assertJson(['message' => 'Results saved successfully']);

        $this->assertDatabaseCount('exam_results', 3);
        $this->assertDatabaseHas('exam_results', [
            'student_id' => $this->students[0]->id,
            'grade' => 'A',
        ]);
        $this->assertDatabaseHas('exam_results', [
            'student_id' => $this->students[2]->id,
            'grade' => 'F',
        ]);
    }

    public function test_can_get_results_for_exam()
    {
        $exam = Exam::factory()->create();
        ExamResult::factory()->create([
            'exam_id' => $exam->id,
            'student_id' => $this->students[0]->id,
            'score' => 75,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->getJson("/api/schools/{$this->schoolId}/exams/{$exam->id}/results");

        $response->assertStatus(200)
            ->assertJsonCount(1);
    }
}
