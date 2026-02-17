<?php

namespace Database\Factories;

use App\Models\AcademicSession;
use App\Models\School;
use App\Models\Section;
use App\Models\Term;
use Illuminate\Database\Eloquent\Factories\Factory;

class TermFactory extends Factory
{
    protected $model = Term::class;

    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'section_id' => Section::factory(),
            'session_id' => AcademicSession::factory(),
            'term_name' => fake()->randomElement(['1st Term', '2nd Term', '3rd Term']),
            'start_date' => fake()->date(),
            'end_date' => fake()->date(),
            'is_active' => true,
        ];
    }
}
