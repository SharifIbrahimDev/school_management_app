<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\ParentModel;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class ImportController extends Controller
{
    /**
     * Import users (Parents, Teachers) from CSV
     */
    public function importUsers(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
            'role' => 'required|in:parent,teacher,admin',
        ]);

        $file = $request->file('file');
        $role = $request->input('role');
        $path = $file->getRealPath();

        // Simple CSV parsing
        $data = array_map('str_getcsv', file($path));
        $header = array_shift($data); // Assume first row is header

        // Validate header structure (Basic check)
        $requiredColumns = ['name', 'email', 'phone'];
        foreach ($requiredColumns as $col) {
            if (! in_array($col, $header)) {
                return response()->json(['message' => "Missing required column: $col"], 422);
            }
        }

        $importedCount = 0;
        $errors = [];

        DB::beginTransaction();
        try {
            foreach ($data as $index => $row) {
                if (count($row) !== count($header)) {
                    continue;
                }

                $rowMap = array_combine($header, $row);

                // Basic validation
                if (empty($rowMap['email']) || empty($rowMap['name'])) {
                    $errors[] = 'Row '.($index + 2).': Missing name or email';

                    continue;
                }

                // Check if email exists
                if (User::where('email', $rowMap['email'])->exists()) {
                    $errors[] = 'Row '.($index + 2).": Email already exists (${rowMap['email']})";

                    continue;
                }

                $user = User::create([
                    'name' => $rowMap['name'],
                    'email' => $rowMap['email'],
                    'password' => Hash::make('password123'), // Default password
                    'role' => $role,
                    // 'phone_number' => $rowMap['phone'] ?? null, // If column exists in user table
                ]);

                if ($role === 'parent') {
                    // Create associated parent record if applicable
                    // ParentModel::create(['user_id' => $user->id, ...]);
                }

                $importedCount++;
            }

            DB::commit();

            return response()->json([
                'message' => 'Import processed',
                'imported_count' => $importedCount,
                'errors' => $errors,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Import Error: '.$e->getMessage());

            return response()->json(['message' => 'Import failed', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Import Students from CSV
     */
    public function importStudents(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
            'school_id' => 'exists:schools,id', // Optional validation
        ]);

        $file = $request->file('file');
        $path = $file->getRealPath();

        $data = array_map('str_getcsv', file($path));
        $header = array_shift($data);

        // Expected columns: first_name, last_name, admission_number, dob, gender, class_id
        $requiredColumns = ['first_name', 'last_name', 'admission_number'];
        foreach ($requiredColumns as $col) {
            if (! in_array($col, $header)) {
                return response()->json(['message' => "Missing required column: $col"], 422);
            }
        }

        $importedCount = 0;
        $errors = [];

        DB::beginTransaction();
        try {
            foreach ($data as $index => $row) {
                if (count($row) !== count($header)) {
                    continue;
                }
                $rowMap = array_combine($header, $row);

                if (Student::where('admission_number', $rowMap['admission_number'])->exists()) {
                    $errors[] = 'Row '.($index + 2).': Admission number exists';

                    continue;
                }

                Student::create([
                    'first_name' => $rowMap['first_name'],
                    'last_name' => $rowMap['last_name'],
                    'other_names' => $rowMap['other_names'] ?? null,
                    'admission_number' => $rowMap['admission_number'],
                    'date_of_birth' => $rowMap['dob'] ?? null,
                    'gender' => $rowMap['gender'] ?? 'other',
                    'class_id' => $rowMap['class_id'] ?? null, // ID must exist
                    'school_id' => $request->school_id ?? 1, // Default or validated
                    'status' => 'active',
                ]);

                $importedCount++;
            }

            DB::commit();

            return response()->json([
                'message' => 'Students imported successfully',
                'imported_count' => $importedCount,
                'errors' => $errors,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json(['message' => 'Import failed', 'error' => $e->getMessage()], 500);
        }
    }
}
