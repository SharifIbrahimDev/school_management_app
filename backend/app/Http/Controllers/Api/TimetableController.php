<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Timetable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class TimetableController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $schoolId = $user->school_id;

        $query = Timetable::with(['classModel', 'section', 'subject', 'teacher'])
            ->where('school_id', $schoolId);

        if ($request->has('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }
        
        // Filter by current logged in teacher if no specific id is requested and user is a teacher
        if (!$request->has('teacher_id') && $user->role === 'teacher') {
            $query->where('teacher_id', $user->id);
        }

        if ($request->has('class_id')) {
            $query->where('class_id', $request->class_id);
        }

        if ($request->has('day_of_week')) {
            $query->where('day_of_week', $request->day_of_week);
        }

        $timetable = $query->orderBy('start_time')->get();

        return response()->json([
            'success' => true,
            'data' => $timetable,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'class_id' => 'required|exists:classes,id',
            'section_id' => 'required|exists:sections,id',
            'subject_id' => 'required|exists:subjects,id',
            'teacher_id' => 'required|exists:users,id',
            'day_of_week' => 'required|string',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $entry = Timetable::create(array_merge($request->all(), [
            'school_id' => $request->user()->school_id,
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Timetable entry created successfully',
            'data' => $entry,
        ], 201);
    }
}
