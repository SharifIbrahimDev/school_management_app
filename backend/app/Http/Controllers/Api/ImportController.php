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
            'role' => 'required|in:parent,teacher,admin,principal,bursar',
        ]);

        $file = $request->file('file');
        $role = $request->input('role');
        $path = $file->getRealPath();

        // Simple CSV parsing
        $data = array_map('str_getcsv', file($path));
        $header = array_shift($data); // Assume first row is header

        // Validate header structure
        $requiredColumns = ['name', 'email'];
        foreach ($requiredColumns as $col) {
            if (!in_array($col, $header)) {
                return response()->json(['message' => "Missing required column: $col"], 422);
            }
        }

        $importedCount = 0;
        $errors = [];

        DB::beginTransaction();
        try {
            foreach ($data as $index => $row) {
                if (count($row) !== count($header)) continue;
                $rowMap = array_combine($header, $row);

                if (empty($rowMap['email']) || empty($rowMap['name'])) {
                    $errors[] = 'Row ' . ($index + 2) . ': Missing name or email';
                    continue;
                }

                if (User::where('email', $rowMap['email'])->exists()) {
                    $errors[] = 'Row ' . ($index + 2) . ": Email already exists ({$rowMap['email']})";
                    continue;
                }
                
                // Determine School ID (from request or default to 1 for demo)
                $schoolId = $request->input('school_id', 1);

                $user = User::create([
                    'full_name' => $rowMap['name'], // Map CSV 'name' to DB 'full_name'
                    'email' => $rowMap['email'],
                    'password' => Hash::make('password123'),
                    'role' => $role,
                    'phone_number' => $rowMap['phone'] ?? null,
                    'school_id' => $schoolId,
                    'is_active' => true,
                ]);

                // Create associated records if needed (e.g. Teacher profile) but User model handles basic auth.

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
     * Import Students from CSV (All-in-One: Section -> Class -> Student)
     */
    public function importStudents(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
            'school_id' => 'required|exists:schools,id',
            'auto_assign_fees' => 'sometimes|boolean'
        ]);

        $file = $request->file('file');
        $path = $file->getRealPath();

        $data = array_map('str_getcsv', file($path));
        $header = array_shift($data);

        // Required for All-in-One: section_name, class_name, first_name, last_name
        $requiredColumns = ['section_name', 'class_name', 'first_name', 'last_name'];
        foreach ($requiredColumns as $col) {
            if (! in_array($col, $header)) {
                return response()->json(['message' => "All-in-One Import requires column: $col"], 422);
            }
        }

        $importedCount = 0;
        $errors = [];
        $schoolId = $request->school_id;
        $shouldAssignFees = filter_var($request->input('auto_assign_fees', true), FILTER_VALIDATE_BOOLEAN);

        DB::beginTransaction();
        try {
            foreach ($data as $index => $row) {
                if (count($row) !== count($header)) continue;
                $rowMap = array_combine($header, $row);

                // 1. Get or Create Section
                $section = \App\Models\Section::firstOrCreate(
                    ['school_id' => $schoolId, 'section_name' => trim($rowMap['section_name'])],
                    ['is_active' => true]
                );

                // 2. Get or Create Class inside that section
                $class = \App\Models\ClassModel::firstOrCreate(
                    [
                        'school_id' => $schoolId, 
                        'section_id' => $section->id, 
                        'class_name' => trim($rowMap['class_name'])
                    ],
                    ['is_active' => true, 'capacity' => 30]
                );

                // 3. Validation: Admission Number
                if (!empty($rowMap['admission_number'])) {
                    if (Student::where('admission_number', $rowMap['admission_number'])->exists()) {
                        $errors[] = 'Row '.($index + 2).': Admission number exists';
                        continue;
                    }
                }

                // 4. Create Student
                $studentName = trim($rowMap['first_name'] . ' ' . $rowMap['last_name']);
                $student = Student::create([
                    'school_id' => $schoolId,
                    'section_id' => $section->id,
                    'class_id' => $class->id,
                    'student_name' => $studentName,
                    'admission_number' => !empty($rowMap['admission_number']) ? $rowMap['admission_number'] : null,
                    'date_of_birth' => !empty($rowMap['dob']) ? $rowMap['dob'] : null,
                    'gender' => strtolower($rowMap['gender'] ?? 'other'),
                    'is_active' => true,
                ]);

                // 5. Auto-Assign Fees
                if ($shouldAssignFees) {
                    $activeFees = \App\Models\Fee::where('school_id', $schoolId)
                        ->where('is_active', true)
                        ->where(function($q) use ($class) {
                            $q->where('fee_scope', 'school')
                              ->orWhere(function($sq) use ($class) {
                                  $sq->where('fee_scope', 'section')->where('section_id', $class->section_id);
                              })
                              ->orWhere(function($sq) use ($class) {
                                  $sq->where('fee_scope', 'class')->where('class_id', $class->id);
                              });
                        })
                        ->get();

                    foreach ($activeFees as $f) {
                        \App\Models\Fee::create([
                            'school_id' => $schoolId,
                            'section_id' => $f->section_id,
                            'session_id' => $f->session_id,
                            'term_id' => $f->term_id,
                            'class_id' => $f->class_id,
                            'student_id' => $student->id,
                            'fee_name' => $f->fee_name,
                            'amount' => $f->amount,
                            'fee_scope' => 'student',
                            'description' => $f->description,
                            'is_active' => true,
                        ]);
                    }
                }

                $importedCount++;
            }

            DB::commit();

            return response()->json([
                'message' => 'All-in-One Import successful',
                'imported_count' => $importedCount,
                'errors' => $errors,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Import failed', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Map Parents to Students
     */
    public function mapParents(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
            'school_id' => 'required|exists:schools,id',
        ]);

        $file = $request->file('file');
        $data = array_map('str_getcsv', file($file->getRealPath()));
        $header = array_shift($data);

        $requiredColumns = ['parent_email', 'student_admission_number'];
        foreach ($requiredColumns as $col) {
            if (!in_array($col, $header)) return response()->json(['message' => "Missing: $col"], 422);
        }

        $count = 0; $errors = [];
        foreach ($data as $index => $row) {
            if (count($row) !== count($header)) continue;
            $rowMap = array_combine($header, $row);

            $parent = User::where('email', $rowMap['parent_email'])->where('role', 'parent')->first();
            $student = Student::where('admission_number', $rowMap['student_admission_number'])->where('school_id', $request->school_id)->first();

            if (!$parent) { $errors[] = "Row ".($index+2).": Parent not found"; continue; }
            if (!$student) { $errors[] = "Row ".($index+2).": Student not found"; continue; }

            $student->update(['parent_id' => $parent->id]);
            $count++;
        }

        return response()->json(['message' => 'Mapping completed', 'mapped_count' => $count, 'errors' => $errors]);
    }

    /**
     * Assign Teachers to Classes
     */
    public function assignTeachers(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
            'school_id' => 'required|exists:schools,id',
        ]);

        $file = $request->file('file');
        $data = array_map('str_getcsv', file($file->getRealPath()));
        $header = array_shift($data);

        $requiredColumns = ['teacher_email', 'class_id'];
        foreach ($requiredColumns as $col) {
            if (!in_array($col, $header)) return response()->json(['message' => "Missing: $col"], 422);
        }

        $count = 0; $errors = [];
        foreach ($data as $index => $row) {
            if (count($row) !== count($header)) continue;
            $rowMap = array_combine($header, $row);

            $teacher = User::where('email', $rowMap['teacher_email'])->where('role', 'teacher')->first();
            $class = \App\Models\ClassModel::where('id', $rowMap['class_id'])->where('school_id', $request->school_id)->first();

            if (!$teacher) { $errors[] = "Row ".($index+2).": Teacher not found"; continue; }
            if (!$class) { $errors[] = "Row ".($index+2).": Class not found"; continue; }

            $class->update(['form_teacher_id' => $teacher->id]);
            $count++;
        }

        return response()->json(['message' => 'Assignments completed', 'assigned_count' => $count, 'errors' => $errors]);
    }

    /**
     * Import Sections from CSV
     */
    public function importSections(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
            'school_id' => 'required|exists:schools,id',
        ]);

        $file = $request->file('file');
        $path = $file->getRealPath();
        $data = array_map('str_getcsv', file($path));
        $header = array_shift($data);

        $requiredColumns = ['section_name'];
        foreach ($requiredColumns as $col) {
            if (!in_array($col, $header)) {
                return response()->json(['message' => "Missing required column: $col"], 422);
            }
        }

        $importedCount = 0;
        $errors = [];

        DB::beginTransaction();
        try {
            foreach ($data as $index => $row) {
                if (count($row) !== count($header)) continue;
                $rowMap = array_combine($header, $row);

                if (empty($rowMap['section_name'])) {
                     $errors[] = 'Row '.($index + 2).': Missing section name';
                     continue;
                }
                
                if (\App\Models\Section::where('school_id', $request->school_id)
                        ->where('section_name', $rowMap['section_name'])->exists()) {
                     $errors[] = 'Row '.($index + 2).': Section already exists';
                     continue;
                 }

                \App\Models\Section::create([
                    'school_id' => $request->school_id,
                    'section_name' => $rowMap['section_name'],
                    'description' => $rowMap['description'] ?? null,
                    'is_active' => filter_var($rowMap['is_active'] ?? true, FILTER_VALIDATE_BOOLEAN),
                ]);
                $importedCount++;
            }
            DB::commit();
             return response()->json([
                'message' => 'Sections imported successfully',
                'imported_count' => $importedCount,
                'errors' => $errors,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Import failed', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Import Classes from CSV
     */
    public function importClasses(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
            'school_id' => 'required|exists:schools,id',
        ]);

        $file = $request->file('file');
        $path = $file->getRealPath();
        $data = array_map('str_getcsv', file($path));
        $header = array_shift($data);

        $requiredColumns = ['class_name', 'section_id'];
        foreach ($requiredColumns as $col) {
            if (!in_array($col, $header)) {
                return response()->json(['message' => "Missing required column: $col"], 422);
            }
        }

        $importedCount = 0;
        $errors = [];

        DB::beginTransaction();
        try {
            foreach ($data as $index => $row) {
                if (count($row) !== count($header)) continue;
                $rowMap = array_combine($header, $row);

                 if (empty($rowMap['class_name']) || empty($rowMap['section_id'])) {
                     $errors[] = 'Row '.($index + 2).': Missing name or section_id';
                     continue;
                }

                \App\Models\ClassModel::create([
                    'school_id' => $request->school_id,
                    'section_id' => $rowMap['section_id'],
                    'class_name' => $rowMap['class_name'],
                    'description' => $rowMap['description'] ?? null,
                    'capacity' => $rowMap['capacity'] ?? 30,
                    'is_active' => filter_var($rowMap['is_active'] ?? true, FILTER_VALIDATE_BOOLEAN),
                ]);
                $importedCount++;
            }
            DB::commit();
            return response()->json([
                'message' => 'Classes imported successfully',
                'imported_count' => $importedCount,
                'errors' => $errors,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Import failed', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Import Fees from CSV
     */
    public function importFees(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt',
            'school_id' => 'required|exists:schools,id',
        ]);

        $file = $request->file('file');
        $path = $file->getRealPath();
        $data = array_map('str_getcsv', file($path));
        $header = array_shift($data);

        $requiredColumns = ['fee_name', 'amount', 'fee_scope', 'session_id', 'term_id', 'section_id'];
        foreach ($requiredColumns as $col) {
             if (!in_array($col, $header)) {
                return response()->json(['message' => "Missing required column: $col"], 422);
            }
        }

        $importedCount = 0;
        $errors = [];

        DB::beginTransaction();
        try {
            foreach ($data as $index => $row) {
                if (count($row) !== count($header)) continue;
                $rowMap = array_combine($header, $row);

                if (empty($rowMap['fee_name']) || empty($rowMap['amount'])) {
                     $errors[] = 'Row '.($index + 2).': Missing fee_name or amount';
                     continue;
                }

                \App\Models\Fee::create([
                    'school_id' => $request->school_id,
                    'fee_name' => $rowMap['fee_name'],
                    'amount' => $rowMap['amount'],
                    'description' => $rowMap['description'] ?? null,
                    'fee_scope' => $rowMap['fee_scope'] ?? 'school',
                    'section_id' => $rowMap['section_id'],
                    'class_id' => $rowMap['class_id'] ?? null,
                    'session_id' => $rowMap['session_id'],
                    'term_id' => $rowMap['term_id'],
                    'is_active' => filter_var($rowMap['is_active'] ?? true, FILTER_VALIDATE_BOOLEAN),
                ]);
                $importedCount++;
            }
            DB::commit();
             return response()->json([
                'message' => 'Fees imported successfully',
                'imported_count' => $importedCount,
                'errors' => $errors,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Import failed', 'error' => $e->getMessage()], 500);
        }
    }
}
