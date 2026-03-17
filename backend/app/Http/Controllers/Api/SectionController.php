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
        if ($request->user() && $request->user()->role !== 'proprietor') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Only the System Proprietor can create sections.',
            ], 403);
        }

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
        if ($request->user() && $request->user()->role !== 'proprietor') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Only the System Proprietor can update sections.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'section_name'          => 'sometimes|required|string|max:255',
            'description'           => 'nullable|string',
            'is_active'             => 'sometimes|boolean',
            'assigned_principal_ids' => 'sometimes|array',
            'assigned_principal_ids.*' => 'exists:users,id',
            'assigned_bursar_ids'   => 'sometimes|array',
            'assigned_bursar_ids.*' => 'exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors'  => $validator->errors(),
            ], 422);
        }

        $section = Section::where('school_id', $schoolId)->findOrFail($id);

        // Update basic fields (excluding role-assignment arrays)
        $section->update($request->only(['section_name', 'description', 'is_active']));

        // Sync principals: keep existing non-principal users, replace principal users
        if ($request->has('assigned_principal_ids')) {
            $existingNonPrincipalIds = $section->users()
                ->where('role', '!=', 'principal')
                ->pluck('users.id')
                ->toArray();
            $newIds = array_merge($existingNonPrincipalIds, $request->assigned_principal_ids);
            $section->users()->sync($newIds);
        }

        // Sync bursars: keep existing non-bursar users, replace bursar users
        if ($request->has('assigned_bursar_ids')) {
            $existingNonBursarIds = $section->users()
                ->where('role', '!=', 'bursar')
                ->pluck('users.id')
                ->toArray();
            $newIds = array_merge($existingNonBursarIds, $request->assigned_bursar_ids);
            $section->users()->sync($newIds);
        }

        return response()->json([
            'success' => true,
            'message' => 'Section updated successfully',
            'data'    => $section->load('users'),
        ]);
    }

    /**
     * Remove the specified section
     */
    public function destroy(Request $request, string $schoolId, string $id): JsonResponse
    {
        if ($request->user() && $request->user()->role !== 'proprietor') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Only the System Proprietor can delete sections.',
            ], 403);
        }

        $section = Section::where('school_id', $schoolId)->findOrFail($id);
        $section->delete();

        return response()->json([
            'success' => true,
            'message' => 'Section deleted successfully',
        ]);
    }

    /**
     * Assign users to a section (optionally filtered by role).
     *
     * If 'role' is provided (e.g. 'principal' or 'bursar'), only users of
     * that role are replaced; users of other roles remain untouched.
     * If no 'role' is provided, all section users are replaced (original behaviour).
     */
    public function assignUsers(Request $request, string $schoolId, string $id): JsonResponse
    {
        if ($request->user() && $request->user()->role !== 'proprietor') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Only the System Proprietor can assign users to sections.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'user_ids'   => 'required|array',
            'user_ids.*' => 'exists:users,id',
            'role'       => 'sometimes|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors'  => $validator->errors(),
            ], 422);
        }

        $section = Section::where('school_id', $schoolId)->findOrFail($id);

        if ($request->has('role') && $request->role) {
            // Remove users of the given role, then attach the new ones
            $existingOtherIds = $section->users()
                ->where('role', '!=', $request->role)
                ->pluck('users.id')
                ->toArray();
            $newIds = array_merge($existingOtherIds, $request->user_ids);
            $section->users()->sync($newIds);
        } else {
            // Replace all section users (original behaviour)
            $section->users()->sync($request->user_ids);
        }

        return response()->json([
            'success' => true,
            'message' => 'Users assigned to section successfully',
            'data'    => $section->load('users'),
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
