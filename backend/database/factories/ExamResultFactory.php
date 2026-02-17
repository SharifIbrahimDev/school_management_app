<?php

namespace Database\Factories;

use App\Models\Exam;
use App\Models\ExamResult;
use App\Models\Student;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ExamResultFactory extends Factory
{
    protected $model = ExamResult::class;

    public function definition(): array
    {
        $score = fake()->numberBetween(0, 100);

        return [
            'exam_id' => Exam::factory(),
            'student_id' => Student::factory(),
            'score' => $score,
            'grade' => $this->calculateGrade($score),
            'remark' => fake()->sentence(),
            'graded_by' => User::factory(),
        ];
    }

    protected function calculateGrade($score)
    {
        if ($score >= 70) {
            return 'A';
        }
        if ($score >= 60) {
            return 'B';
        }
        if ($score >= 50) {
            return 'C';
        }
        if ($score >= 45) {
            return 'D';
        }
        if ($score >= 40) {
            return 'E';
        }

        return 'F';
    }
}
