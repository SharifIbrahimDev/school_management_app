<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AcademicSession;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AcademicSessionController extends Controller
{
    /**
     * Display academic sessions for a school
     */
    public function index(Request $request, string $schoolId): JsonResponse
    {
        $sessions = AcademicSession::where('school_id', $schoolId)
            ->with(['section', 'terms'])
            ->when($request->has('section_id'), function ($query) use ($request) {
                $query->where('section_id', $request->section_id);
            })
            ->when($request->has('is_active'), function ($query) use ($request) {
                $query->where('is_active', $request->boolean('is_active'));
            })
            ->orderBy('start_date', 'desc')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $sessions,
        ]);
    }

    /**
     * Store a newly created academic session
     */
    public function store(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'required|exists:sections,id',
            'session_name' => 'required|string|max:255',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after:start_date',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $session = AcademicSession::create([
            'school_id' => $schoolId,
            'section_id' => $request->section_id,
            'session_name' => $request->session_name,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'is_active' => $request->is_active ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Academic session created successfully',
            'data' => $session->load('section'),
        ], 201);
    }

    /**
     * Display the specified academic session
     */
    public function show(string $schoolId, string $id): JsonResponse
    {
        $session = AcademicSession::where('school_id', $schoolId)
            ->with(['section', 'terms', 'fees', 'transactions'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $session,
        ]);
    }

    /**
     * Update the specified academic session
     */
    public function update(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'sometimes|required|exists:sections,id',
            'session_name' => 'sometimes|required|string|max:255',
            'start_date' => 'sometimes|required|date',
            'end_date' => 'sometimes|required|date',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $session = AcademicSession::where('school_id', $schoolId)->findOrFail($id);
        $session->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Academic session updated successfully',
            'data' => $session->load('section'),
        ]);
    }

    /**
     * Remove the specified academic session
     */
    public function destroy(string $schoolId, string $id): JsonResponse
    {
        $session = AcademicSession::where('school_id', $schoolId)->findOrFail($id);
        $session->delete();

        return response()->json([
            'success' => true,
            'message' => 'Academic session deleted successfully',
        ]);
    }
}
