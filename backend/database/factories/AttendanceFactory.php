<?php

namespace Database\Factories;

use App\Models\Attendance;
use App\Models\ClassModel;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class AttendanceFactory extends Factory
{
    protected $model = Attendance::class;

    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'class_id' => ClassModel::factory(),
            'student_id' => Student::factory(),
            'date' => fake()->date(),
            'status' => fake()->randomElement(['present', 'absent', 'late', 'excused']),
            'remark' => fake()->sentence(),
            'recorded_by' => User::factory(),
        ];
    }
}
