<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Term;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class TermController extends Controller
{
    /**
     * Display terms for a school
     */
    public function index(Request $request, string $schoolId): JsonResponse
    {
        $terms = Term::where('school_id', $schoolId)
            ->with(['section', 'academicSession'])
            ->when($request->has('section_id'), function ($query) use ($request) {
                $query->where('section_id', $request->section_id);
            })
            ->when($request->has('session_id'), function ($query) use ($request) {
                $query->where('session_id', $request->session_id);
            })
            ->when($request->has('is_active'), function ($query) use ($request) {
                $query->where('is_active', $request->boolean('is_active'));
            })
            ->orderBy('start_date', 'desc')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $terms,
        ]);
    }

    /**
     * Store a newly created term
     */
    public function store(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'required|exists:sections,id',
            'session_id' => 'required|exists:academic_sessions,id',
            'term_name' => 'required|string|max:255',
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

        $term = Term::create([
            'school_id' => $schoolId,
            'section_id' => $request->section_id,
            'session_id' => $request->session_id,
            'term_name' => $request->term_name,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'is_active' => $request->is_active ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Term created successfully',
            'data' => $term->load(['section', 'academicSession']),
        ], 201);
    }

    /**
     * Display the specified term
     */
    public function show(string $schoolId, string $id): JsonResponse
    {
        $term = Term::where('school_id', $schoolId)
            ->with(['section', 'academicSession', 'fees', 'transactions'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $term,
        ]);
    }

    /**
     * Update the specified term
     */
    public function update(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'sometimes|required|exists:sections,id',
            'session_id' => 'sometimes|required|exists:academic_sessions,id',
            'term_name' => 'sometimes|required|string|max:255',
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

        $term = Term::where('school_id', $schoolId)->findOrFail($id);
        $term->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Term updated successfully',
            'data' => $term->load(['section', 'academicSession']),
        ]);
    }

    /**
     * Remove the specified term
     */
    public function destroy(string $schoolId, string $id): JsonResponse
    {
        $term = Term::where('school_id', $schoolId)->findOrFail($id);
        $term->delete();

        return response()->json([
            'success' => true,
            'message' => 'Term deleted successfully',
        ]);
    }
}
