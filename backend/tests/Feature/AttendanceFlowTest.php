<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\ClassModel;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AttendanceFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $user;

    protected $schoolId = 1;

    protected $class;

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

        $this->students = Student::factory()->count(3)->create([
            'school_id' => $this->schoolId,
            'class_id' => $this->class->id,
        ]);
    }

    public function test_can_mark_bulk_attendance()
    {
        $date = now()->format('Y-m-d');
        $payload = [
            'class_id' => $this->class->id,
            'date' => $date,
            'attendances' => [
                ['student_id' => $this->students[0]->id, 'status' => 'present', 'remark' => 'On time'],
                ['student_id' => $this->students[1]->id, 'status' => 'absent', 'remark' => 'Sick'],
                ['student_id' => $this->students[2]->id, 'status' => 'late', 'remark' => 'Bus delayed'],
            ],
        ];

        $response = $this->actingAs($this->user, 'api')
            ->postJson("/api/schools/{$this->schoolId}/attendance", $payload);

        $response->assertStatus(200)
            ->assertJson(['message' => 'Attendance saved successfully']);

        $this->assertDatabaseCount('attendances', 3);
        $this->assertDatabaseHas('attendances', [
            'student_id' => $this->students[0]->id,
            'status' => 'present',
            'date' => $date,
        ]);
    }

    public function test_can_update_existing_attendance()
    {
        $date = now()->format('Y-m-d');

        // Initial mark
        Attendance::create([
            'school_id' => $this->schoolId,
            'class_id' => $this->class->id,
            'student_id' => $this->students[0]->id,
            'date' => $date,
            'status' => 'absent',
            'recorded_by' => $this->user->id,
        ]);

        $payload = [
            'class_id' => $this->class->id,
            'date' => $date,
            'attendances' => [
                ['student_id' => $this->students[0]->id, 'status' => 'present'],
            ],
        ];

        $response = $this->actingAs($this->user, 'api')
            ->postJson("/api/schools/{$this->schoolId}/attendance", $payload);

        $response->assertStatus(200);
        $this->assertDatabaseHas('attendances', [
            'student_id' => $this->students[0]->id,
            'status' => 'present',
            'date' => $date,
        ]);
    }

    public function test_can_list_attendance_for_class_and_date()
    {
        $date = now()->format('Y-m-d');
        Attendance::create([
            'school_id' => $this->schoolId,
            'class_id' => $this->class->id,
            'student_id' => $this->students[0]->id,
            'date' => $date,
            'status' => 'present',
            'recorded_by' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->getJson("/api/schools/{$this->schoolId}/attendance?class_id={$this->class->id}&date={$date}");

        $response->assertStatus(200)
            ->assertJsonCount(1);
    }

    public function test_can_get_student_attendance_history()
    {
        Attendance::factory()->count(5)->create([
            'student_id' => $this->students[0]->id,
            'school_id' => $this->schoolId,
        ]);

        $response = $this->actingAs($this->user, 'api')
            ->getJson("/api/schools/{$this->schoolId}/students/{$this->students[0]->id}/attendance");

        $response->assertStatus(200)
            ->assertJsonStructure(['data', 'total']);
    }
}
