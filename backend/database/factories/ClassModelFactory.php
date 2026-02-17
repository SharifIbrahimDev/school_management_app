<?php

namespace Database\Factories;

use App\Models\ClassModel;
use App\Models\School;
use App\Models\Section;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ClassModelFactory extends Factory
{
    protected $model = ClassModel::class;

    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'section_id' => Section::factory(),
            'class_name' => fake()->randomElement(['Grade 1', 'Grade 2', 'JSS 1', 'SSS 1']),
            'description' => fake()->sentence(),
            'form_teacher_id' => User::factory(),
            'capacity' => fake()->numberBetween(20, 50),
            'is_active' => true,
        ];
    }
}
