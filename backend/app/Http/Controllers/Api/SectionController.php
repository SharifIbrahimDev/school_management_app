<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Section;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SectionController extends Controller
{
    /**
     * Display sections for a school
     */
    public function index(Request $request, string $schoolId): JsonResponse
    {
        $sections = Section::where('school_id', $schoolId)
            ->with(['users', 'classes', 'students'])
            ->when($request->has('is_active'), function ($query) use ($request) {
                $query->where('is_active', $request->boolean('is_active'));
            })
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $sections,
        ]);
    }

    /**
     * Store a newly created section
     */
    public function store(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $section = Section::create([
            'school_id' => $schoolId,
            'section_name' => $request->section_name,
            'description' => $request->description,
            'is_active' => $request->is_active ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Section created successfully',
            'data' => $section,
        ], 201);
    }

    /**
     * Display the specified section
     */
    public function show(string $schoolId, string $id): JsonResponse
    {
        $section = Section::where('school_id', $schoolId)
            ->with(['users', 'classes', 'students', 'academicSessions'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $section,
        ]);
    }

    /**
     * Update the specified section
     */
    public function update(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $section = Section::where('school_id', $schoolId)->findOrFail($id);
        $section->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Section updated successfully',
            'data' => $section,
        ]);
    }

    /**
     * Remove the specified section
     */
    public function destroy(string $schoolId, string $id): JsonResponse
    {
        $section = Section::where('school_id', $schoolId)->findOrFail($id);
        $section->delete();

        return response()->json([
            'success' => true,
            'message' => 'Section deleted successfully',
        ]);
    }

    /**
     * Assign users to a section
     */
    public function assignUsers(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'user_ids' => 'required|array',
            'user_ids.*' => 'exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $section = Section::where('school_id', $schoolId)->findOrFail($id);
        $section->users()->sync($request->user_ids);

        return response()->json([
            'success' => true,
            'message' => 'Users assigned to section successfully',
            'data' => $section->load('users'),
        ]);
    }

    /**
     * Get section statistics
     */
    public function statistics(string $schoolId, string $id): JsonResponse
    {
        $section = Section::where('school_id', $schoolId)->findOrFail($id);

        $stats = [
            'total_users' => $section->users()->count(),
            'total_classes' => $section->classes()->count(),
            'total_students' => $section->students()->count(),
            'active_sessions' => $section->academicSessions()->where('is_active', true)->count(),
            'users_by_role' => $section->users()
                ->selectRaw('role, COUNT(*) as count')
                ->groupBy('role')
                ->pluck('count', 'role'),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }
}
