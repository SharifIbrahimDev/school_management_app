<?php

namespace Database\Factories;

use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class TransactionFactory extends Factory
{
    protected $model = Transaction::class;

    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'section_id' => Section::factory(),
            'student_id' => Student::factory(),
            'transaction_type' => fake()->randomElement(['income', 'expense']),
            'amount' => fake()->numberBetween(10000, 100000),
            'transaction_date' => fake()->dateTimeBetween('-1 year', 'now'),
            'payment_method' => fake()->randomElement(['cash', 'bank_transfer', 'cheque', 'mobile_money']), // Fixed allowed values
            'description' => fake()->sentence(),
            'reference_number' => 'TXN/'.fake()->unique()->numberBetween(1000, 9999),
            'recorded_by' => User::factory(),
        ];
    }
}
