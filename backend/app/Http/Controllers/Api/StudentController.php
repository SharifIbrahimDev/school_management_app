<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Traits\GeneratesSchoolIds;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class StudentController extends Controller
{
    use GeneratesSchoolIds;
    /**
     * Display students for a school
     */
    public function index(Request $request, string $schoolId): JsonResponse
    {
        $students = Student::where('school_id', $schoolId)
            ->with(['school', 'sections', 'classModel', 'transactions'])
            ->when($request->has('section_id'), function ($query) use ($request) {
                $query->whereHas('sections', function ($q) use ($request) {
                    $q->where('sections.id', $request->section_id);
                });
            })
            ->when($request->has('class_id'), function ($query) use ($request) {
                $query->where('class_id', $request->class_id);
            })
            ->when($request->has('parent_id'), function ($query) use ($request) {
                $query->where('parent_id', $request->parent_id);
            })
            ->when($request->has('is_active'), function ($query) use ($request) {
                $query->where('is_active', $request->boolean('is_active'));
            })
            ->when($request->has('search'), function ($query) use ($request) {
                $query->where(function ($q) use ($request) {
                    $q->where('student_name', 'like', '%'.$request->search.'%')
                        ->orWhere('admission_number', 'like', '%'.$request->search.'%')
                        ->orWhere('parent_name', 'like', '%'.$request->search.'%')
                        ->orWhere('parent_phone', 'like', '%'.$request->search.'%');
                });
            })
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $students,
        ]);
    }

    /**
     * Store a newly created student
     */
    public function store(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'required|exists:sections,id',
            'section_ids' => 'sometimes|array',
            'section_ids.*' => 'exists:sections,id',
            'class_id' => 'required|exists:classes,id',
            'student_name' => 'required|string|max:255',
            'admission_number' => 'nullable|string|max:100|unique:students,admission_number',
            'date_of_birth' => 'nullable|date',
            'gender' => 'nullable|in:male,female,other',
            'address' => 'nullable|string',
            'parent_name' => 'nullable|string|max:255',
            'parent_phone' => 'nullable|string|max:50',
            'parent_email' => 'nullable|email|max:255',
            'photo_url' => 'nullable|url|max:500',
            'parent_id' => 'nullable|exists:users,id',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $admissionNumber = $request->admission_number ?? $this->generateAdmissionNumber((int)$schoolId);

        $student = Student::create([
            'school_id' => $schoolId,
            'class_id' => $request->class_id,
            'student_name' => $request->student_name,
            'admission_number' => $admissionNumber,
            'date_of_birth' => $request->date_of_birth,
            'gender' => $request->gender,
            'address' => $request->address,
            'parent_name' => $request->parent_name,
            'parent_phone' => $request->parent_phone,
            'parent_email' => $request->parent_email,
            'photo_url' => $request->photo_url,
            'parent_id' => $request->parent_id,
            'is_active' => $request->is_active ?? true,
        ]);

        // Attach sections
        $sectionIds = $request->section_ids ?? [$request->section_id];
        $student->sections()->attach($sectionIds);

        return response()->json([
            'success' => true,
            'message' => 'Student created successfully',
            'data' => $student->load(['sections', 'classModel', 'parent']),
        ], 201);
    }

    /**
     * Display the specified student
     */
    public function show(string $schoolId, string $id): JsonResponse
    {
        $student = Student::where('school_id', $schoolId)
            ->with(['school', 'sections', 'classModel', 'transactions'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $student,
        ]);
    }

    /**
     * Update the specified student
     */
    public function update(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'sometimes|required|exists:sections,id',
            'section_ids' => 'sometimes|array',
            'section_ids.*' => 'exists:sections,id',
            'class_id' => 'sometimes|required|exists:classes,id',
            'student_name' => 'sometimes|required|string|max:255',
            'admission_number' => 'nullable|string|max:100|unique:students,admission_number,'.$id,
            'date_of_birth' => 'nullable|date',
            'gender' => 'nullable|in:male,female,other',
            'address' => 'nullable|string',
            'parent_name' => 'nullable|string|max:255',
            'parent_phone' => 'nullable|string|max:50',
            'parent_email' => 'nullable|email|max:255',
            'photo_url' => 'nullable|url|max:500',
            'parent_id' => 'nullable|exists:users,id',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $student = Student::where('school_id', $schoolId)->findOrFail($id);
        
        $data = $request->except(['section_id', 'section_ids']);
        $student->update($data);

        if ($request->has('section_ids')) {
            $student->sections()->sync($request->section_ids);
        } elseif ($request->has('section_id')) {
            $student->sections()->sync([$request->section_id]);
        }

        // Ensure full_name is included in the response for frontend compatibility
        $student->full_name = $student->student_name;

        return response()->json([
            'success' => true,
            'message' => 'Student updated successfully',
            'data' => $student->load(['sections', 'classModel', 'parent']),
        ]);
    }

    /**
     * Remove the specified student
     */
    public function destroy(string $schoolId, string $id): JsonResponse
    {
        $student = Student::where('school_id', $schoolId)->findOrFail($id);
        $student->delete();

        return response()->json([
            'success' => true,
            'message' => 'Student deleted successfully',
        ]);
    }

    /**
     * Get student transactions
     */
    public function transactions(string $schoolId, string $id): JsonResponse
    {
        $student = Student::where('school_id', $schoolId)->findOrFail($id);

        $transactions = $student->transactions()
            ->with(['academicSession', 'term', 'recorder'])
            ->orderBy('transaction_date', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $transactions,
        ]);
    }

    /**
     * Get student payment summary
     */
    public function paymentSummary(string $schoolId, string $id): JsonResponse
    {
        $student = Student::where('school_id', $schoolId)->with('sections')->findOrFail($id);
        $sectionIds = $student->sections->pluck('id')->toArray();

        $summary = [
            'total_paid' => $student->transactions()->where('transaction_type', 'income')->sum('amount'),
            'total_fees' => 0, // Will be calculated from fees assigned to student's class
            'balance' => 0, // total_fees - total_paid
            'payment_count' => $student->transactions()->where('transaction_type', 'income')->count(),
            'last_payment' => $student->transactions()
                ->where('transaction_type', 'income')
                ->orderBy('transaction_date', 'desc')
                ->first(),
        ];

        // Calculate total fees across all relevant scopes and all sections the student belongs to
        $totalFees = \App\Models\Fee::where('school_id', $schoolId)
            ->whereIn('section_id', $sectionIds)
            ->where('is_active', true)
            ->where(function ($query) use ($student) {
                // Section-wide fees (class_id and student_id are null)
                $query->where(function ($q) {
                    $q->whereNull('class_id')->whereNull('student_id');
                })
                // Class-specific fees
                ->orWhere(function ($q) use ($student) {
                    $q->where('class_id', $student->class_id)->whereNull('student_id');
                })
                // Student-specific fees (inclusive of discounts/scholarships)
                ->orWhere('student_id', $student->id);
            })
            ->sum('amount');

        $summary['total_fees'] = (float)$totalFees;
        $summary['balance'] = (float)($totalFees - $summary['total_paid']);

        return response()->json([
            'success' => true,
            'data' => $summary,
        ]);
    }

    /**
     * Bulk import students
     */
    public function import(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'students' => 'required|array',
            'students.*.section_id' => 'required|exists:sections,id',
            'students.*.class_id' => 'required|exists:classes,id',
            'students.*.student_name' => 'required|string|max:255',
            'students.*.admission_number' => 'nullable|string|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $imported = [];
        $errors = [];

        foreach ($request->students as $index => $studentData) {
            try {
                // Check for duplicate admission number
                if (isset($studentData['admission_number'])) {
                    $exists = Student::where('admission_number', $studentData['admission_number'])->exists();
                    if ($exists) {
                        $errors[] = "Row {$index}: Admission number already exists";

                        continue;
                    }
                }

                $sectionId = $studentData['section_id'];
                unset($studentData['section_id']);

                $student = Student::create(array_merge($studentData, ['school_id' => $schoolId]));
                $student->sections()->attach($sectionId);
                
                $imported[] = $student->load('sections');
            } catch (\Exception $e) {
                $errors[] = "Row {$index}: ".$e->getMessage();
            }
        }

        return response()->json([
            'success' => count($errors) === 0,
            'message' => count($imported).' students imported successfully',
            'data' => [
                'imported_count' => count($imported),
                'error_count' => count($errors),
                'errors' => $errors,
                'students' => $imported,
            ],
        ], count($errors) > 0 ? 207 : 201);
    }
}
