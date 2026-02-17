<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ClassModel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ClassController extends Controller
{
    /**
     * Display classes for a school
     */
    public function index(Request $request, string $schoolId): JsonResponse
    {
        $classes = ClassModel::where('school_id', $schoolId)
            ->with(['section', 'students', 'fees'])
            ->when($request->has('section_id'), function ($query) use ($request) {
                $query->where('section_id', $request->section_id);
            })
            ->when($request->has('form_teacher_id'), function ($query) use ($request) {
                $query->where('form_teacher_id', $request->form_teacher_id);
            })
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $classes,
        ]);
    }

    /**
     * Store a newly created class
     */
    public function store(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'required|exists:sections,id',
            'class_name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'form_teacher_id' => 'nullable|exists:users,id',
            'capacity' => 'nullable|integer|min:1',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $class = ClassModel::create([
            'school_id' => $schoolId,
            'section_id' => $request->section_id,
            'class_name' => $request->class_name,
            'description' => $request->description,
            'form_teacher_id' => $request->form_teacher_id,
            'capacity' => $request->capacity,
            'is_active' => $request->is_active ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Class created successfully',
            'data' => $class->load(['section', 'formTeacher']),
        ], 201);
    }

    /**
     * Display the specified class
     */
    public function show(string $schoolId, string $id): JsonResponse
    {
        $class = ClassModel::where('school_id', $schoolId)
            ->with(['section', 'students', 'fees'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $class,
        ]);
    }

    /**
     * Update the specified class
     */
    public function update(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'sometimes|required|exists:sections,id',
            'class_name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'form_teacher_id' => 'nullable|exists:users,id',
            'capacity' => 'nullable|integer|min:1',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $class = ClassModel::where('school_id', $schoolId)->findOrFail($id);
        $class->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Class updated successfully',
            'data' => $class->load(['section', 'formTeacher']),
        ]);
    }

    /**
     * Remove the specified class
     */
    public function destroy(string $schoolId, string $id): JsonResponse
    {
        $class = ClassModel::where('school_id', $schoolId)->findOrFail($id);
        $class->delete();

        return response()->json([
            'success' => true,
            'message' => 'Class deleted successfully',
        ]);
    }

    /**
     * Get class statistics
     */
    public function statistics(string $schoolId, string $id): JsonResponse
    {
        $class = ClassModel::where('school_id', $schoolId)->findOrFail($id);

        $stats = [
            'total_students' => $class->students()->count(),
            'active_students' => $class->students()->where('is_active', true)->count(),
            'total_fees' => $class->fees()->where('is_active', true)->sum('amount'),
            'fees_count' => $class->fees()->where('is_active', true)->count(),
            'students_by_gender' => $class->students()
                ->selectRaw('gender, COUNT(*) as count')
                ->groupBy('gender')
                ->pluck('count', 'gender'),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }
}
