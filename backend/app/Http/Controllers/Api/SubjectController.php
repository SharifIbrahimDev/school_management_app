<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Subject;
use Illuminate\Http\Request;

class SubjectController extends Controller
{
    /**
     * Display a listing of subjects.
     */
    public function index(Request $request)
    {
        $schoolId = $request->user()->school_id; // Assuming user linked to school

        $query = Subject::with(['academicClass:id,class_name', 'teacher:id,name'])
            ->where('school_id', $schoolId);

        if ($request->has('class_id')) {
            $query->where('class_id', $request->class_id);
        }

        if ($request->has('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }

        $subjects = $query->orderBy('name')->get();

        return response()->json($subjects);
    }

    /**
     * Store a newly created subject in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'class_id' => 'required|exists:classes,id',
            'teacher_id' => 'nullable|exists:users,id',
            'description' => 'nullable|string',
        ]);

        // Ensure user belongs to the school or provide school_id
        $schoolId = $request->user()->school_id ?? 1; // Default fallback

        $subject = Subject::create([
            'school_id' => $schoolId,
            'name' => $validated['name'],
            'code' => $validated['code'],
            'class_id' => $validated['class_id'],
            'teacher_id' => $validated['teacher_id'] ?? null,
            'description' => $validated['description'] ?? null,
        ]);

        return response()->json($subject->load(['academicClass:id,class_name', 'teacher:id,name']), 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $subject = Subject::with(['academicClass', 'teacher'])->findOrFail($id);

        return response()->json($subject);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $subject = Subject::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'code' => 'nullable|string|max:50',
            'class_id' => 'sometimes|exists:classes,id',
            'teacher_id' => 'nullable|exists:users,id',
            'description' => 'nullable|string',
        ]);

        $subject->update($validated);

        return response()->json($subject->load(['academicClass:id,class_name', 'teacher:id,name']));
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $subject = Subject::findOrFail($id);
        $subject->delete();

        return response()->json(['message' => 'Subject deleted successfully']);
    }
}
