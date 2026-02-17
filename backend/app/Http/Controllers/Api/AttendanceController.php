<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    /**
     * Get attendance for a class on a specific date
     */
    public function index(Request $request)
    {
        $request->validate([
            'class_id' => 'required|exists:classes,id',
            'date' => 'required|date',
        ]);

        $attendances = Attendance::with(['student:id,first_name,last_name,admission_number'])
            ->where('class_id', $request->class_id)
            ->whereDate('date', $request->date)
            ->get();

        return response()->json($attendances);
    }

    /**
     * Store (Mark) attendance for bulk or single
     */
    public function store(Request $request)
    {
        $request->validate([
            'class_id' => 'required|exists:classes,id',
            'date' => 'required|date',
            'attendances' => 'required|array',
            'attendances.*.student_id' => 'required|exists:students,id',
            'attendances.*.status' => 'required|in:present,absent,late,excused',
        ]);

        $schoolId = $request->user()->school_id ?? 1;
        $userId = $request->user()->id;
        $date = $request->date;
        $classId = $request->class_id;

        DB::beginTransaction();
        try {
            $upsertData = [];
            foreach ($request->attendances as $record) {
                Attendance::updateOrCreate(
                    [
                        'student_id' => $record['student_id'],
                        'date' => $date,
                    ],
                    [
                        'school_id' => $schoolId,
                        'class_id' => $classId,
                        'status' => $record['status'],
                        'remark' => $record['remark'] ?? null,
                        'recorded_by' => $userId,
                    ]
                );
            }
            DB::commit();

            return response()->json(['message' => 'Attendance saved successfully']);
        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json(['message' => 'Failed to save attendance', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Get student attendance history
     */
    public function studentHistory(Request $request, $studentId)
    {
        $history = Attendance::where('student_id', $studentId)
            ->orderBy('date', 'desc')
            ->paginate(20);

        return response()->json($history);
    }

    /**
     * Get attendance summary for a section on a specific date
     */
    public function sectionSummary(Request $request)
    {
        $request->validate([
            'section_id' => 'required|exists:sections,id',
            'date' => 'required|date',
        ]);

        $sectionId = $request->section_id;
        $date = $request->date;

        $totalStudents = \App\Models\Student::where('section_id', $sectionId)
            ->where('is_active', true)
            ->count();

        $presentCount = Attendance::where('date', $date)
            ->whereHas('student', function ($query) use ($sectionId) {
                $query->where('section_id', $sectionId);
            })
            ->where('status', 'present')
            ->count();

        $absentCount = Attendance::where('date', $date)
            ->whereHas('student', function ($query) use ($sectionId) {
                $query->where('section_id', $sectionId);
            })
            ->where('status', 'absent')
            ->count();

        return response()->json([
            'success' => true,
            'data' => [
                'total_students' => $totalStudents,
                'present_count' => $presentCount,
                'absent_count' => $absentCount,
                'recorded_count' => $presentCount + $absentCount,
                'percentage_present' => $totalStudents > 0 ? round(($presentCount / $totalStudents) * 100, 2) : 0,
            ],
        ]);
    }
}
