<?php

namespace Database\Seeders;

use App\Models\School;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create a demo school
        $school = School::create([
            'name' => 'Demo School',
            'short_code' => 'DS',
            'address' => '123 Education Street, Learning City',
            'phone' => '+1234567890',
            'email' => 'info@demoschool.com',
            'is_active' => true,
        ]);

        // Create a proprietor user
        User::create([
            'email' => 'proprietor@demoschool.com',
            'password' => Hash::make('password'),
            'full_name' => 'John Proprietor',
            'role' => 'proprietor',
            'school_id' => $school->id,
            'is_active' => true,
            'email_verified_at' => now(),
        ]);

        // Create a principal user
        User::create([
            'email' => 'principal@demoschool.com',
            'password' => Hash::make('password'),
            'full_name' => 'Jane Principal',
            'role' => 'principal',
            'school_id' => $school->id,
            'is_active' => true,
            'email_verified_at' => now(),
        ]);

        // Create a bursar user
        User::create([
            'email' => 'bursar@demoschool.com',
            'password' => Hash::make('password'),
            'full_name' => 'Bob Bursar',
            'role' => 'bursar',
            'school_id' => $school->id,
            'is_active' => true,
            'email_verified_at' => now(),
        ]);

        $this->command->info('Demo school and users created successfully!');
        $this->command->info('Proprietor: proprietor@demoschool.com / password');
        $this->command->info('Principal: principal@demoschool.com / password');
        $this->command->info('Bursar: bursar@demoschool.com / password');
    }
}
