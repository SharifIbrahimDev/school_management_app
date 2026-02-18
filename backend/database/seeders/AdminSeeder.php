<?php

namespace Database\Seeders;

use App\Models\School;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Ensure a school exists for the admin
        $school = School::first();
        if (!$school) {
            $school = School::create([
                'name' => 'System Administration',
                'short_code' => 'SYS',
                'is_active' => true,
            ]);
        }

        // Create the Super Admin
        $email = 'admin@daynapp.com';
        $user = User::where('email', $email)->first();

        if (!$user) {
            User::create([
                'full_name' => 'Super Administrator',
                'email' => $email,
                'password' => Hash::make('admin123'),
                'role' => 'admin',
                'school_id' => $school->id,
                'is_active' => true,
                'email_verified_at' => now(),
            ]);
            $this->command->info("Admin created: $email / admin123");
        } else {
            $user->update(['role' => 'admin']);
            $this->command->info("User $email updated to Admin role.");
        }
    }
}
