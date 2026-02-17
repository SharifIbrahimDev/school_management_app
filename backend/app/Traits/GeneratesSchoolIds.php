<?php

namespace App\Traits;

use App\Models\School;
use App\Models\User;
use App\Models\Student;

trait GeneratesSchoolIds
{
    /**
     * Generate a unique registration ID for a user in a school based on their role
     */
    public function generateRegistrationId(int $schoolId, string $role): string
    {
        $school = School::findOrFail($schoolId);
        $shortCode = strtoupper($school->short_code);
        
        $prefixes = [
            'proprietor' => 'PROP',
            'principal' => 'PRIN',
            'bursar' => 'BURS',
            'teacher' => 'TCHR',
            'parent' => 'PRNT',
        ];

        $rolePrefix = $prefixes[strtolower($role)] ?? 'USER';
        $searchPrefix = $shortCode . '-' . $rolePrefix . '-';

        $lastUser = User::where('school_id', $schoolId)
            ->where('registration_id', 'like', $searchPrefix . '%')
            ->orderBy('id', 'desc')
            ->first();

        $nextNumber = 1;
        if ($lastUser) {
            // Extract the last number after the last hyphen
            $parts = explode('-', $lastUser->registration_id);
            $lastPart = end($parts);
            if (is_numeric($lastPart)) {
                $nextNumber = (int)$lastPart + 1;
            }
        }

        return sprintf('%s-%s-%03d', $shortCode, $rolePrefix, $nextNumber);
    }

    /**
     * Generate a unique admission number for a student in a school
     */
    public function generateAdmissionNumber(int $schoolId): string
    {
        $school = School::findOrFail($schoolId);
        $shortCode = $school->short_code;
        
        $lastStudent = Student::where('school_id', $schoolId)
            ->whereNotNull('admission_number')
            ->orderBy('id', 'desc')
            ->first();

        $nextNumber = 1;
        if ($lastStudent && preg_match('/-(\d+)$/', $lastStudent->admission_number, $matches)) {
            $nextNumber = (int)$matches[1] + 1;
        }

        return sprintf('%s-STU-%03d', strtoupper($shortCode), $nextNumber);
    }
}
