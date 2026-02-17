<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Fee;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class FeeController extends Controller
{
    /**
     * Display fees for a school
     */
    public function index(Request $request, string $schoolId): JsonResponse
    {
        $fees = Fee::where('school_id', $schoolId)
            ->with(['section', 'academicSession', 'term', 'classModel'])
            ->when($request->has('section_id'), function ($query) use ($request) {
                $query->where('section_id', $request->section_id);
            })
            ->when($request->has('session_id'), function ($query) use ($request) {
                $query->where('session_id', $request->session_id);
            })
            ->when($request->has('term_id'), function ($query) use ($request) {
                $query->where('term_id', $request->term_id);
            })
            ->when($request->has('class_id'), function ($query) use ($request) {
                $query->where('class_id', $request->class_id);
            })
            ->when($request->has('student_id'), function ($query) use ($request) {
                $query->where('student_id', $request->student_id);
            })
            ->when($request->has('fee_scope'), function ($query) use ($request) {
                $query->where('fee_scope', $request->fee_scope);
            })
            ->when($request->has('is_active'), function ($query) use ($request) {
                $query->where('is_active', $request->boolean('is_active'));
            })
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $fees,
        ]);
    }

    /**
     * Store a newly created fee
     */
    public function store(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'required|exists:sections,id',
            'session_id' => 'required|exists:academic_sessions,id',
            'term_id' => 'required|exists:terms,id',
            'class_id' => 'nullable|exists:classes,id',
            'fee_name' => 'required|string|max:255',
            'amount' => 'required|numeric',
            'fee_scope' => 'required|in:class,section,school,student',
            'student_id' => 'nullable|exists:students,id',
            'description' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // Validate fee_scope and class_id relationship
        if ($request->fee_scope === 'class' && ! $request->class_id) {
            return response()->json([
                'success' => false,
                'message' => 'class_id is required when fee_scope is "class"',
            ], 422);
        }

        if ($request->fee_scope === 'student' && ! $request->student_id) {
            return response()->json([
                'success' => false,
                'message' => 'student_id is required when fee_scope is "student"',
            ], 422);
        }

        $fee = Fee::create([
            'school_id' => $schoolId,
            'section_id' => $request->section_id,
            'session_id' => $request->session_id,
            'term_id' => $request->term_id,
            'class_id' => $request->class_id,
            'student_id' => $request->student_id,
            'fee_name' => $request->fee_name,
            'amount' => $request->amount,
            'fee_scope' => $request->fee_scope,
            'description' => $request->description,
            'is_active' => $request->is_active ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Fee created successfully',
            'data' => $fee->load(['section', 'academicSession', 'term', 'classModel']),
        ], 201);
    }

    /**
     * Display the specified fee
     */
    public function show(string $schoolId, string $id): JsonResponse
    {
        $fee = Fee::where('school_id', $schoolId)
            ->with(['section', 'academicSession', 'term', 'classModel'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $fee,
        ]);
    }

    /**
     * Update the specified fee
     */
    public function update(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'sometimes|required|exists:sections,id',
            'session_id' => 'sometimes|required|exists:academic_sessions,id',
            'term_id' => 'sometimes|required|exists:terms,id',
            'class_id' => 'nullable|exists:classes,id',
            'fee_name' => 'sometimes|required|string|max:255',
            'amount' => 'sometimes|required|numeric',
            'fee_scope' => 'sometimes|required|in:class,section,school,student',
            'student_id' => 'nullable|exists:students,id',
            'description' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $fee = Fee::where('school_id', $schoolId)->findOrFail($id);
        $fee->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Fee updated successfully',
            'data' => $fee->load(['section', 'academicSession', 'term', 'classModel']),
        ]);
    }

    /**
     * Remove the specified fee
     */
    public function destroy(string $schoolId, string $id): JsonResponse
    {
        $fee = Fee::where('school_id', $schoolId)->findOrFail($id);
        $fee->delete();

        return response()->json([
            'success' => true,
            'message' => 'Fee deleted successfully',
        ]);
    }

    /**
     * Get fee summary by scope
     */
    public function summary(Request $request, string $schoolId): JsonResponse
    {
        $query = Fee::where('school_id', $schoolId)
            ->where('is_active', true);

        if ($request->has('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->has('session_id')) {
            $query->where('session_id', $request->session_id);
        }

        if ($request->has('term_id')) {
            $query->where('term_id', $request->term_id);
        }

        $summary = [
            'total_fees' => $query->sum('amount'),
            'fees_by_scope' => $query->selectRaw('fee_scope, COUNT(*) as count, SUM(amount) as total')
                ->groupBy('fee_scope')
                ->get(),
            'fees_count' => $query->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => $summary,
        ]);
    }
}
