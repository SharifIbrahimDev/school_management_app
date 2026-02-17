<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LessonPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class LessonPlanController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = LessonPlan::with(['section', 'classModel', 'subject', 'teacher']);

        if ($request->has('section_id')) {
            $query->where('section_id', $request->section_id);
        }
        if ($request->has('class_id')) {
            $query->where('class_id', $request->class_id);
        }
        if ($request->has('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }

        $plans = $query->orderBy('week_number', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $plans,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'required|exists:sections,id',
            'class_id' => 'required|exists:classes,id',
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'week_number' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $plan = LessonPlan::create(array_merge($request->all(), [
            'school_id' => $request->user()->school_id ?? 1,
            'teacher_id' => $request->user()->id,
            'status' => 'submitted',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Lesson plan submitted successfully',
            'data' => $plan->load(['section', 'classModel', 'subject', 'teacher']),
        ], 201);
    }

    public function show($id): JsonResponse
    {
        $plan = LessonPlan::with(['section', 'classModel', 'subject', 'teacher'])->findOrFail($id);
        return response()->json(['success' => true, 'data' => $plan]);
    }

    public function update(Request $request, $id): JsonResponse
    {
        $plan = LessonPlan::findOrFail($id);
        
        $validator = Validator::make($request->all(), [
            'status' => 'sometimes|in:draft,submitted,approved,rejected',
            'remarks' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $plan->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Lesson plan updated successfully',
            'data' => $plan->load(['section', 'classModel', 'subject', 'teacher']),
        ]);
    }

    public function destroy($id): JsonResponse
    {
        $plan = LessonPlan::findOrFail($id);
        $plan->delete();
        return response()->json(['success' => true, 'message' => 'Lesson plan deleted']);
    }
}
