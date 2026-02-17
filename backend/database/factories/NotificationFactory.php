<?php

namespace Database\Factories;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class NotificationFactory extends Factory
{
    protected $model = Notification::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'type' => fake()->randomElement(['info', 'warning', 'success', 'error', 'payment', 'attendance']),
            'title' => fake()->sentence(4),
            'message' => fake()->sentence(10),
            'data' => null,
            'is_read' => fake()->boolean(40), // 40% chance of being read
            'read_at' => fake()->boolean(40) ? fake()->dateTimeBetween('-1 week', 'now') : null,
        ];
    }

    public function unread(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_read' => false,
            'read_at' => null,
        ]);
    }

    public function read(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_read' => true,
            'read_at' => now(),
        ]);
    }

    public function withData(array $data): static
    {
        return $this->state(fn (array $attributes) => [
            'data' => $data,
        ]);
    }
}
