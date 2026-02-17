<?php

namespace Database\Factories;

use App\Models\ClassModel;
use App\Models\Exam;
use App\Models\School;
use App\Models\Subject;
use Illuminate\Database\Eloquent\Factories\Factory;

class ExamFactory extends Factory
{
    protected $model = Exam::class;

    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'class_id' => ClassModel::factory(),
            'subject_id' => Subject::factory(),
            'title' => fake()->randomElement(['First Term Mid-Term', 'First Term Final', 'Second Term Mid-Term']),
            'max_score' => 100,
            'date' => fake()->date(),
        ];
    }
}
