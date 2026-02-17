<?php

namespace Database\Factories;

use App\Models\AcademicSession;
use App\Models\School;
use App\Models\Section;
use Illuminate\Database\Eloquent\Factories\Factory;

class AcademicSessionFactory extends Factory
{
    protected $model = AcademicSession::class;

    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'section_id' => Section::factory(),
            'session_name' => fake()->year().'/'.(fake()->year() + 1),
            'start_date' => fake()->date(),
            'end_date' => fake()->date(),
            'is_active' => true,
        ];
    }
}
