<?php

namespace Database\Factories;

use App\Models\School;
use App\Models\Section;
use Illuminate\Database\Eloquent\Factories\Factory;

class SectionFactory extends Factory
{
    protected $model = Section::class;

    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'section_name' => fake()->randomElement(['Primary', 'Secondary', 'Creche', 'Nursery']),
            'description' => fake()->sentence(),
            'is_active' => true,
        ];
    }
}
