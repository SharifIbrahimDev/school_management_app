<?php

namespace Database\Factories;

use App\Models\AcademicSession;
use App\Models\ClassModel;
use App\Models\Fee;
use App\Models\School;
use App\Models\Section;
use App\Models\Term;
use Illuminate\Database\Eloquent\Factories\Factory;

class FeeFactory extends Factory
{
    protected $model = Fee::class;

    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'section_id' => Section::factory(),
            'class_id' => ClassModel::factory(),
            'session_id' => AcademicSession::factory(),
            'term_id' => Term::factory(), // Corrected from term string
            'fee_name' => fake()->randomElement(['Tuition Fee', 'Exam Fee', 'Library Fee', 'Lab Fee']),
            'amount' => fake()->numberBetween(50000, 200000),
            'fee_scope' => 'class', // Default scope
            'is_active' => true,
        ];
    }
}
