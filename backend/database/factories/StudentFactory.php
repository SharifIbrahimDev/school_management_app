<?php

namespace Database\Factories;

use App\Models\ClassModel;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use Illuminate\Database\Eloquent\Factories\Factory;

class StudentFactory extends Factory
{
    protected $model = Student::class;

    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'section_id' => Section::factory(),
            'class_id' => ClassModel::factory(),
            'student_name' => fake()->name(),
            'admission_number' => 'STD/'.fake()->unique()->numberBetween(1000, 9999),
            'date_of_birth' => fake()->date('Y-m-d', '-10 years'),
            'gender' => fake()->randomElement(['male', 'female']),
            'address' => fake()->address(),
            'parent_name' => fake()->name(),
            'parent_phone' => fake()->phoneNumber(),
            'parent_email' => fake()->unique()->safeEmail(),
            'is_active' => true,
        ];
    }
}
