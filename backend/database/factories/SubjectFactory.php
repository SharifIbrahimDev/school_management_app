<?php

namespace Database\Factories;

use App\Models\ClassModel;
use App\Models\School;
use App\Models\Subject;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class SubjectFactory extends Factory
{
    protected $model = Subject::class;

    public function definition(): array
    {
        $name = fake()->unique()->randomElement(['Mathematics', 'English', 'Physics', 'Chemistry', 'Biology', 'History']);

        return [
            'school_id' => School::factory(),
            'name' => $name,
            'code' => strtoupper(substr($name, 0, 3)).fake()->numberBetween(100, 999),
            'class_id' => ClassModel::factory(),
            'teacher_id' => User::factory(),
            'description' => fake()->sentence(),
        ];
    }
}
