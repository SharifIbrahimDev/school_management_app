<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Syllabus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SyllabusController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Syllabus::with(['section', 'classModel', 'subject']);

        if ($request->has('section_id')) {
            $query->where('section_id', $request->section_id);
        }
        if ($request->has('class_id')) {
            $query->where('class_id', $request->class_id);
        }
        if ($request->has('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        $syllabuses = $query->get();

        return response()->json([
            'success' => true,
            'data' => $syllabuses,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'required|exists:sections,id',
            'class_id' => 'required|exists:classes,id',
            'subject_id' => 'required|exists:subjects,id',
            'topic' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $syllabus = Syllabus::create(array_merge($request->all(), [
            'school_id' => $request->user()->school_id ?? 1,
            'status' => 'pending',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Syllabus topic added',
            'data' => $syllabus->load(['section', 'classModel', 'subject']),
        ], 201);
    }

    public function update(Request $request, $id): JsonResponse
    {
        $syllabus = Syllabus::findOrFail($id);
        
        $validator = Validator::make($request->all(), [
            'status' => 'sometimes|in:pending,in_progress,completed',
            'completion_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $data = $request->all();
        if (isset($data['status']) && $data['status'] === 'completed' && !isset($data['completion_date'])) {
            $data['completion_date'] = now();
        }

        $syllabus->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Syllabus updated successfully',
            'data' => $syllabus->load(['section', 'classModel', 'subject']),
        ]);
    }

    public function destroy($id): JsonResponse
    {
        $syllabus = Syllabus::findOrFail($id);
        $syllabus->delete();
        return response()->json(['success' => true, 'message' => 'Syllabus topic deleted']);
    }
}
